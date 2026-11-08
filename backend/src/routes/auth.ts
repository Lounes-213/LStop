import { Hono } from 'hono';
import { Env, AuthUser } from '../env';
import { GoogleAuthSchema, RefreshTokenSchema } from '../utils/validation';
import { verifyGoogleIdToken } from '../auth/google';
import { createAccessToken, issueRefreshToken, rotateRefreshToken, revokeAllUserTokens } from '../auth/jwt';
import { generateUUID } from '../utils/crypto';
import { authMiddleware } from '../auth/middleware';

export const authRouter = new Hono<{ Bindings: Env; Variables: { user: AuthUser } }>();

// POST /auth/google
authRouter.post('/google', async (c) => {
  const body = await c.req.json();
  const parsed = GoogleAuthSchema.safeParse(body);

  if (!parsed.success) {
    return c.json({ error: 'Validation failed', details: parsed.error.issues }, 400);
  }

  const { idToken, role } = parsed.data;
  const allowedClientIds = (c.env.GOOGLE_CLIENT_IDS || '')
    .split(',')
    .map(s => s.trim())
    .filter(Boolean);

  let googleUser;
  try {
    googleUser = await verifyGoogleIdToken(idToken, allowedClientIds);
  } catch (err: any) {
    return c.json({ error: 'Invalid Google token', details: err.message }, 401);
  }

  // Check if user exists in D1
  let user = await c.env.DB
    .prepare('SELECT id, google_sub, email, name, avatar_url, role, is_active FROM users WHERE google_sub = ?')
    .bind(googleUser.sub)
    .first<{
      id: string;
      google_sub: string;
      email: string;
      name: string;
      avatar_url?: string;
      role: 'passenger' | 'driver' | 'admin';
      is_active: number;
    }>();

  if (!user) {
    // New registration
    const newUserId = generateUUID();
    await c.env.DB
      .prepare(
        `INSERT INTO users (id, google_sub, email, name, avatar_url, role)
         VALUES (?, ?, ?, ?, ?, ?)`
      )
      .bind(newUserId, googleUser.sub, googleUser.email, googleUser.name, googleUser.picture || null, role)
      .run();

    // If driver, initialize driver record
    if (role === 'driver') {
      await c.env.DB
        .prepare('INSERT INTO drivers (id, approval_status) VALUES (?, ?)')
        .bind(newUserId, 'pending')
        .run();
    }

    user = {
      id: newUserId,
      google_sub: googleUser.sub,
      email: googleUser.email,
      name: googleUser.name,
      avatar_url: googleUser.picture,
      role: role as 'passenger' | 'driver',
      is_active: 1
    };
  }

  if (user.is_active === 0) {
    return c.json({ error: 'Account has been deactivated' }, 403);
  }

  // Issue 15-minute access JWT
  const authUser: AuthUser = {
    userId: user.id,
    email: user.email,
    role: user.role,
    name: user.name
  };
  const accessToken = await createAccessToken(authUser, c.env.JWT_SECRET);

  // Issue rotating refresh token
  const refreshToken = await issueRefreshToken(c.env.DB, user.id);

  return c.json({
    accessToken,
    refreshToken,
    expiresInSeconds: 900, // 15 min
    user: {
      id: user.id,
      email: user.email,
      name: user.name,
      avatarUrl: user.avatar_url,
      role: user.role
    }
  });
});

// POST /auth/refresh
authRouter.post('/refresh', async (c) => {
  const body = await c.req.json();
  const parsed = RefreshTokenSchema.safeParse(body);

  if (!parsed.success) {
    return c.json({ error: 'Missing or invalid refresh token' }, 400);
  }

  const result = await rotateRefreshToken(c.env.DB, parsed.data.refreshToken);
  if (!result) {
    return c.json({ error: 'Invalid, expired, or revoked refresh token' }, 401);
  }

  const authUser: AuthUser = {
    userId: result.userId,
    email: result.email,
    role: result.role,
    name: result.name
  };
  const newAccessToken = await createAccessToken(authUser, c.env.JWT_SECRET);

  return c.json({
    accessToken: newAccessToken,
    refreshToken: result.newRefreshToken,
    expiresInSeconds: 900
  });
});

// POST /auth/logout
authRouter.post('/logout', authMiddleware, async (c) => {
  const user = c.get('user');
  await revokeAllUserTokens(c.env.DB, user.userId);
  return c.json({ success: true, message: 'Logged out successfully' });
});


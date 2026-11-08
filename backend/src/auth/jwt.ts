import { SignJWT, jwtVerify } from 'jose';
import { AuthUser, Env } from '../env';
import { generateSecureToken, hashToken, generateUUID } from '../utils/crypto';

const ACCESS_TOKEN_EXPIRY = '15m'; // Short-lived access token
const REFRESH_TOKEN_EXPIRY_DAYS = 30;

export async function createAccessToken(user: AuthUser, secret: string): Promise<string> {
  const secretKey = new TextEncoder().encode(secret);
  return await new SignJWT({
    userId: user.userId,
    email: user.email,
    role: user.role,
    name: user.name
  })
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setExpirationTime(ACCESS_TOKEN_EXPIRY)
    .setIssuer('https://timizar.dz')
    .setAudience('timizar-app')
    .sign(secretKey);
}

export async function verifyAccessToken(token: string, secret: string): Promise<AuthUser> {
  const secretKey = new TextEncoder().encode(secret);
  const { payload } = await jwtVerify(token, secretKey, {
    issuer: 'https://timizar.dz',
    audience: 'timizar-app'
  });

  return {
    userId: payload.userId as string,
    email: payload.email as string,
    role: payload.role as 'passenger' | 'driver' | 'admin',
    name: payload.name as string
  };
}

export async function issueRefreshToken(db: D1Database, userId: string): Promise<string> {
  const rawToken = generateSecureToken();
  const tokenHash = await hashToken(rawToken);
  const tokenId = generateUUID();
  const expiresAt = Math.floor(Date.now() / 1000) + REFRESH_TOKEN_EXPIRY_DAYS * 86400;

  await db
    .prepare('INSERT INTO refresh_tokens (id, user_id, token_hash, expires_at) VALUES (?, ?, ?, ?)')
    .bind(tokenId, userId, tokenHash, expiresAt)
    .run();

  return rawToken;
}

export async function rotateRefreshToken(
  db: D1Database,
  oldRawToken: string
): Promise<{ newRefreshToken: string; userId: string; role: 'passenger' | 'driver' | 'admin'; email: string; name: string } | null> {
  const oldHash = await hashToken(oldRawToken);
  const now = Math.floor(Date.now() / 1000);

  // Find token
  const tokenRecord = await db
    .prepare(
      `SELECT rt.id, rt.user_id, rt.expires_at, rt.revoked, u.email, u.role, u.name
       FROM refresh_tokens rt
       JOIN users u ON rt.user_id = u.id
       WHERE rt.token_hash = ?`
    )
    .bind(oldHash)
    .first<{
      id: string;
      user_id: string;
      expires_at: number;
      revoked: number;
      email: string;
      role: 'passenger' | 'driver' | 'admin';
      name: string;
    }>();

  if (!tokenRecord || tokenRecord.revoked === 1 || tokenRecord.expires_at < now) {
    // If compromised or expired, revoke all tokens for user if revoked token reused
    if (tokenRecord && tokenRecord.revoked === 1) {
      await db.prepare('UPDATE refresh_tokens SET revoked = 1 WHERE user_id = ?').bind(tokenRecord.user_id).run();
    }
    return null;
  }

  // Revoke old token
  await db.prepare('UPDATE refresh_tokens SET revoked = 1 WHERE id = ?').bind(tokenRecord.id).run();

  // Issue new token
  const newRefreshToken = await issueRefreshToken(db, tokenRecord.user_id);

  return {
    newRefreshToken,
    userId: tokenRecord.user_id,
    role: tokenRecord.role,
    email: tokenRecord.email,
    name: tokenRecord.name
  };
}

export async function revokeAllUserTokens(db: D1Database, userId: string): Promise<void> {
  await db.prepare('UPDATE refresh_tokens SET revoked = 1 WHERE user_id = ?').bind(userId).run();
}


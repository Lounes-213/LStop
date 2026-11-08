import { Context, Next } from 'hono';
import { verifyAccessToken } from './jwt';
import { AuthUser, Env } from '../env';

export async function authMiddleware(c: Context<{ Bindings: Env; Variables: { user: AuthUser } }>, next: Next) {
  const authHeader = c.req.header('Authorization');

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return c.json({ error: 'Unauthorized: Missing or invalid Authorization header' }, 401);
  }

  const token = authHeader.substring(7).trim();

  try {
    const user = await verifyAccessToken(token, c.env.JWT_SECRET);
    c.set('user', user);
    await next();
  } catch (err: any) {
    return c.json({ error: 'Unauthorized: Invalid or expired access token', details: err.message }, 401);
  }
}

export function requireRole(...allowedRoles: Array<'passenger' | 'driver' | 'admin'>) {
  return async (c: Context<{ Bindings: Env; Variables: { user: AuthUser } }>, next: Next) => {
    const user = c.get('user');
    if (!user || !allowedRoles.includes(user.role)) {
      return c.json({ error: 'Forbidden: Insufficient privileges for this role' }, 403);
    }
    await next();
  };
}

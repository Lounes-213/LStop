import { Hono } from 'hono';
import { Env, AuthUser } from '../env';
import { authMiddleware } from '../auth/middleware';
import { FavoritePlaceSchema } from '../utils/validation';
import { generateUUID } from '../utils/crypto';

export const usersRouter = new Hono<{ Bindings: Env; Variables: { user: AuthUser } }>();

usersRouter.use('*', authMiddleware);

// GET /users/me
usersRouter.get('/me', async (c) => {
  const authUser = c.get('user');

  const user = await c.env.DB
    .prepare('SELECT id, email, name, avatar_url, role, phone, created_at FROM users WHERE id = ?')
    .bind(authUser.userId)
    .first();

  if (!user) {
    return c.json({ error: 'User not found' }, 404);
  }

  return c.json({ user });
});

// GET /users/favorites
usersRouter.get('/favorites', async (c) => {
  const authUser = c.get('user');

  const { results } = await c.env.DB
    .prepare('SELECT id, label, address, lat, lng, created_at FROM user_favorites WHERE user_id = ? ORDER BY created_at ASC')
    .bind(authUser.userId)
    .all();

  return c.json({ favorites: results || [] });
});

// POST /users/favorites
usersRouter.post('/favorites', async (c) => {
  const authUser = c.get('user');
  const body = await c.req.json();
  const parsed = FavoritePlaceSchema.safeParse(body);

  if (!parsed.success) {
    return c.json({ error: 'Validation failed', details: parsed.error.issues }, 400);
  }

  const id = generateUUID();
  const { label, address, lat, lng } = parsed.data;

  await c.env.DB
    .prepare('INSERT INTO user_favorites (id, user_id, label, address, lat, lng) VALUES (?, ?, ?, ?, ?, ?)')
    .bind(id, authUser.userId, label, address, lat, lng)
    .run();

  return c.json({
    favorite: { id, label, address, lat, lng }
  }, 201);
});

// DELETE /users/favorites/:id
usersRouter.delete('/favorites/:id', async (c) => {
  const authUser = c.get('user');
  const id = c.req.param('id');

  await c.env.DB
    .prepare('DELETE FROM user_favorites WHERE id = ? AND user_id = ?')
    .bind(id, authUser.userId)
    .run();

  return c.json({ success: true });
});


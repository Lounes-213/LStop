import { Hono } from 'hono';
import { Env, AuthUser } from '../env';
import { authMiddleware } from '../auth/middleware';
import { generateUUID } from '../utils/crypto';

export const uploadsRouter = new Hono<{ Bindings: Env; Variables: { user: AuthUser } }>();

uploadsRouter.use('*', authMiddleware);

// POST /uploads/document
// Direct-to-Worker stream upload into R2
uploadsRouter.post('/document', async (c) => {
  const authUser = c.get('user');
  const contentType = c.req.header('Content-Type') || 'image/jpeg';
  const fileExt = contentType.includes('png') ? 'png' : contentType.includes('pdf') ? 'pdf' : 'jpg';

  const docType = c.req.query('type') || 'doc'; // license, id_card, insurance, gray_card
  const fileKey = `drivers/${authUser.userId}/${docType}_${Date.now()}_${generateUUID().slice(0, 8)}.${fileExt}`;

  const bodyStream = c.req.raw.body;
  if (!bodyStream) {
    return c.json({ error: 'Missing file body stream' }, 400);
  }

  await c.env.BUCKET.put(fileKey, bodyStream, {
    httpMetadata: {
      contentType,
      cacheControl: 'public, max-age=31536000'
    }
  });

  const publicUrl = `/uploads/file/${fileKey}`;

  return c.json({
    success: true,
    fileKey,
    url: publicUrl
  });
});

// GET /uploads/file/*
// Serves uploaded documents
uploadsRouter.get('/file/*', async (c) => {
  const url = new URL(c.req.url);
  const fileKey = url.pathname.replace(/^\/uploads\/file\//, '');

  const object = await c.env.BUCKET.get(fileKey);
  if (!object) {
    return c.json({ error: 'File not found' }, 404);
  }

  const headers = new Headers();
  object.writeHttpMetadata(headers);
  headers.set('etag', object.httpEtag);
  headers.set('Cache-Control', 'public, max-age=31536000');

  return new Response(object.body as any, { headers });
});

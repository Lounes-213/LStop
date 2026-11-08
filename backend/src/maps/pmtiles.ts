import { Context } from 'hono';
import { Env } from '../env';

/**
 * Serves PMTiles from Cloudflare R2 with HTTP Range requests and aggressive edge caching
 */
export async function servePMTiles(c: Context<{ Bindings: Env }>) {
  const url = new URL(c.req.url);
  const path = url.pathname.replace(/^\/tiles\/?/, '');
  const objectKey = path || 'algeria.pmtiles';

  const rangeHeader = c.req.header('Range');

  try {
    const range = rangeHeader ? parseRangeHeader(rangeHeader) : undefined;
    const object = await c.env.BUCKET.get(objectKey, {
      range: range as any,
      onlyIf: c.req.raw.headers
    });

    if (!object || !('body' in object)) {
      return c.json({ error: 'Tile archive not found or not modified', key: objectKey }, 404);
    }

    const headers = new Headers();
    object.writeHttpMetadata(headers);
    headers.set('etag', object.httpEtag);
    headers.set('Cache-Control', 'public, max-age=86400, s-maxage=604800, immutable');
    headers.set('Access-Control-Allow-Origin', '*');

    if (rangeHeader && 'range' in object && object.range) {
      const objRange = object.range as { offset?: number; length?: number };
      const start = objRange.offset ?? 0;
      const end = start + (objRange.length ?? 0) - 1;
      headers.set('Content-Range', `bytes ${start}-${end}/${object.size}`);
      return new Response((object as any).body, {
        status: 206,
        headers
      });
    }

    return new Response((object as any).body, {
      status: 200,
      headers
    });
  } catch (err: any) {
    return c.json({ error: 'Failed to read PMTiles object', details: err.message }, 500);
  }
}

function parseRangeHeader(rangeHeader: string): { offset: number; length?: number } | undefined {
  const match = rangeHeader.match(/bytes=(\d+)-(\d+)?/);
  if (!match) return undefined;
  const offset = parseInt(match[1], 10);
  const end = match[2] ? parseInt(match[2], 10) : undefined;
  const length = end !== undefined ? end - offset + 1 : undefined;
  return length !== undefined ? { offset, length } : { offset };
}

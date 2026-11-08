import { hashToken } from '../utils/crypto';

export function makeRouteCacheKey(lat1: number, lng1: number, lat2: number, lng2: number): string {
  // Round to 3 decimal places (~110m grid) to collapse nearby duplicates
  const rLat1 = lat1.toFixed(3);
  const rLng1 = lng1.toFixed(3);
  const rLat2 = lat2.toFixed(3);
  const rLng2 = lng2.toFixed(3);
  return `${rLat1},${rLng1}:${rLat2},${rLng2}`;
}

export interface CachedRoute {
  distanceKm: number;
  durationMins: number;
  polyline: string;
}

export async function getCachedRoute(db: D1Database, cacheKey: string): Promise<CachedRoute | null> {
  const hash = await hashToken(cacheKey);
  const now = Math.floor(Date.now() / 1000);

  const row = await db
    .prepare('SELECT distance_km, duration_mins, polyline FROM route_cache WHERE route_hash = ? AND expires_at > ?')
    .bind(hash, now)
    .first<{ distance_km: number; duration_mins: number; polyline: string }>();

  if (!row) return null;

  return {
    distanceKm: row.distance_km,
    durationMins: row.duration_mins,
    polyline: row.polyline
  };
}

export async function setCachedRoute(
  db: D1Database,
  cacheKey: string,
  route: CachedRoute,
  ttlSeconds = 86400 // 24 hours
): Promise<void> {
  const hash = await hashToken(cacheKey);
  const expiresAt = Math.floor(Date.now() / 1000) + ttlSeconds;

  await db
    .prepare(
      `INSERT INTO route_cache (route_hash, distance_km, duration_mins, polyline, expires_at)
       VALUES (?, ?, ?, ?, ?)
       ON CONFLICT(route_hash)
       DO UPDATE SET distance_km = ?, duration_mins = ?, polyline = ?, expires_at = ?`
    )
    .bind(hash, route.distanceKm, route.durationMins, route.polyline, expiresAt, route.distanceKm, route.durationMins, route.polyline, expiresAt)
    .run();
}

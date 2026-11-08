import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { Env, AuthUser } from './env';
import { authRouter } from './routes/auth';
import { usersRouter } from './routes/users';
import { driversRouter } from './routes/drivers';
import { tripsRouter } from './routes/trips';
import { uploadsRouter } from './routes/uploads';
import { TomTomService } from './maps/tomtom';
import { servePMTiles } from './maps/pmtiles';
import { BudgetGuardService } from './services/budget_guard';
import { ZoneRoom } from './durable_objects/ZoneRoom';
import { TripCoordinator } from './durable_objects/TripCoordinator';

const app = new Hono<{ Bindings: Env; Variables: { user: AuthUser } }>();

// Enable CORS for Flutter web & mobile API calls
app.use('*', cors({
  origin: '*',
  allowHeaders: ['Authorization', 'Content-Type', 'Range'],
  allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  exposeHeaders: ['Content-Range', 'ETag', 'Content-Length']
}));

// Global usage counter tracking (Cloudflare budget guard)
app.use('*', async (c, next) => {
  const guard = new BudgetGuardService(c.env.DB);
  // Asynchronously record request count (non-blocking)
  c.executionCtx.waitUntil(guard.recordMetric('worker_requests'));
  await next();
});

// Root health check
app.get('/', (c) => {
  return c.json({
    platform: 'Timizar Backend (Algeria Transport)',
    version: '1.0.0',
    status: 'healthy',
    timestamp: new Date().toISOString()
  });
});

// Mount modular subrouters
app.route('/auth', authRouter);
app.route('/users', usersRouter);
app.route('/drivers', driversRouter);
app.route('/trips', tripsRouter);
app.route('/uploads', uploadsRouter);

// TomTom Proxy Routes (Safeguarding API Key)
app.get('/search', async (c) => {
  const query = c.req.query('q') || '';
  const lat = c.req.query('lat') ? parseFloat(c.req.query('lat')!) : undefined;
  const lng = c.req.query('lng') ? parseFloat(c.req.query('lng')!) : undefined;

  const tomtom = new TomTomService(c.env);
  const results = await tomtom.searchPlaces(query, lat, lng);
  return c.json({ results });
});

app.get('/route', async (c) => {
  const lat1 = parseFloat(c.req.query('lat1') || '0');
  const lng1 = parseFloat(c.req.query('lng1') || '0');
  const lat2 = parseFloat(c.req.query('lat2') || '0');
  const lng2 = parseFloat(c.req.query('lng2') || '0');

  if (!lat1 || !lng1 || !lat2 || !lng2) {
    return c.json({ error: 'lat1, lng1, lat2, lng2 query parameters are required' }, 400);
  }

  const tomtom = new TomTomService(c.env);
  const route = await tomtom.calculateRoute(lat1, lng1, lat2, lng2);
  return c.json(route);
});

app.get('/reverse-geocode', async (c) => {
  const lat = parseFloat(c.req.query('lat') || '0');
  const lng = parseFloat(c.req.query('lng') || '0');

  if (!lat || !lng) {
    return c.json({ error: 'lat and lng parameters are required' }, 400);
  }

  const tomtom = new TomTomService(c.env);
  const result = await tomtom.reverseGeocode(lat, lng);
  return c.json(result);
});

// PMTiles map vector tiles proxy
app.get('/tiles/*', servePMTiles);

// Budget guard dynamic throttle config endpoint for mobile clients
app.get('/throttle-config', async (c) => {
  const guard = new BudgetGuardService(c.env.DB);
  const config = await guard.getDriverThrottleConfig();
  return c.json(config);
});

// WebSocket entrypoint for ZoneRoom (Geohash precision 5 spatial hub)
app.get('/ws/zone/:geohash', async (c) => {
  if (c.req.header('Upgrade') !== 'websocket') {
    return c.text('Expected WebSocket Upgrade', 426);
  }

  const geohash = c.req.param('geohash');
  const zoneId = c.env.ZONE_ROOM.idFromName(geohash);
  const zoneStub = c.env.ZONE_ROOM.get(zoneId);

  return zoneStub.fetch(c.req.raw);
});

// WebSocket entrypoint for active TripCoordinator
app.get('/ws/trip/:tripId', async (c) => {
  if (c.req.header('Upgrade') !== 'websocket') {
    return c.text('Expected WebSocket Upgrade', 426);
  }

  const tripId = c.req.param('tripId');
  const tripCoordinatorId = c.env.TRIP_COORDINATOR.idFromName(tripId);
  const tripCoordinatorStub = c.env.TRIP_COORDINATOR.get(tripCoordinatorId);

  return tripCoordinatorStub.fetch(c.req.raw);
});

// Export Durable Object classes for Cloudflare Workers runtime
export { ZoneRoom, TripCoordinator };

export default app;

import { Hono } from 'hono';
import { Env, AuthUser } from '../env';
import { authMiddleware } from '../auth/middleware';
import { TripEstimateSchema, TripRequestSchema, TripRatingSchema } from '../utils/validation';
import { TomTomService } from '../maps/tomtom';
import { calculateAlgerianFare } from '../services/pricing';
import { encodeGeohash, getSurroundingGeohashes } from '../utils/geohash';
import { generateUUID } from '../utils/crypto';

export const tripsRouter = new Hono<{ Bindings: Env; Variables: { user: AuthUser } }>();

tripsRouter.use('*', authMiddleware);

// POST /trips/estimate
tripsRouter.post('/estimate', async (c) => {
  const body = await c.req.json();
  const parsed = TripEstimateSchema.safeParse(body);

  if (!parsed.success) {
    return c.json({ error: 'Invalid coordinates for trip estimate', details: parsed.error.issues }, 400);
  }

  const { pickupLat, pickupLng, dropoffLat, dropoffLng } = parsed.data;
  const tomtom = new TomTomService(c.env);

  const route = await tomtom.calculateRoute(pickupLat, pickupLng, dropoffLat, dropoffLng);
  const fare = calculateAlgerianFare(route.distanceKm, route.durationMins, {
    baseFare: parseFloat(c.env.BASE_FARE_DZD || '150'),
    perKm: parseFloat(c.env.PER_KM_DZD || '40'),
    perMin: parseFloat(c.env.PER_MINUTE_DZD || '5'),
    minFare: parseFloat(c.env.MIN_FARE_DZD || '200')
  });

  return c.json({
    route: {
      distanceKm: route.distanceKm,
      durationMins: route.durationMins,
      coordinates: route.coordinates,
      source: route.source
    },
    fare
  });
});

// POST /trips/request
tripsRouter.post('/request', async (c) => {
  const authUser = c.get('user');
  const body = await c.req.json();
  const parsed = TripRequestSchema.safeParse(body);

  if (!parsed.success) {
    return c.json({ error: 'Invalid trip request payload', details: parsed.error.issues }, 400);
  }

  const { pickupLat, pickupLng, pickupAddress, dropoffLat, dropoffLng, dropoffAddress } = parsed.data;
  const tomtom = new TomTomService(c.env);

  // 1. Calculate route & fare
  const route = await tomtom.calculateRoute(pickupLat, pickupLng, dropoffLat, dropoffLng);
  const fare = calculateAlgerianFare(route.distanceKm, route.durationMins);

  // 2. Determine pickup geohash cell
  const geohash5 = encodeGeohash(pickupLat, pickupLng, 5);

  // 3. Find candidate drivers in this cell and adjacent cells
  const candidateDriverIds: string[] = [];
  const cellsToQuery = getSurroundingGeohashes(geohash5);

  for (const cell of cellsToQuery) {
    try {
      const zoneId = c.env.ZONE_ROOM.idFromName(cell);
      const zoneStub = c.env.ZONE_ROOM.get(zoneId);
      const res = await zoneStub.fetch(`http://do/internal/available-drivers?lat=${pickupLat}&lng=${pickupLng}&radius=5000`);
      if (res.ok) {
        const drivers: any[] = await res.json();
        for (const d of drivers) {
          if (!candidateDriverIds.includes(d.driverId)) {
            candidateDriverIds.push(d.driverId);
          }
        }
      }
    } catch {
      // Ignore zone fetch error
    }
  }

  // 4. Create trip in D1
  const tripId = generateUUID();
  await c.env.DB
    .prepare(
      `INSERT INTO trips (
        id, passenger_id, status, pickup_lat, pickup_lng, pickup_address,
        dropoff_lat, dropoff_lng, dropoff_address, distance_km, duration_mins,
        fare_dzd, pickup_geohash5, requested_at
      ) VALUES (?, ?, 'requested', ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, unixepoch())`
    )
    .bind(
      tripId, authUser.userId, pickupLat, pickupLng, pickupAddress,
      dropoffLat, dropoffLng, dropoffAddress, route.distanceKm, route.durationMins,
      fare.totalFareDzd, geohash5
    )
    .run();

  // 5. Initiate TripCoordinator Durable Object
  const tripCoordinatorId = c.env.TRIP_COORDINATOR.idFromName(tripId);
  const tripCoordinatorStub = c.env.TRIP_COORDINATOR.get(tripCoordinatorId);

  await tripCoordinatorStub.fetch('http://do/initiate', {
    method: 'POST',
    body: JSON.stringify({
      tripId,
      passengerId: authUser.userId,
      pickup: { lat: pickupLat, lng: pickupLng, address: pickupAddress },
      dropoff: { lat: dropoffLat, lng: dropoffLng, address: dropoffAddress },
      fareDzd: fare.totalFareDzd,
      distanceKm: route.distanceKm,
      durationMins: route.durationMins,
      geohash5,
      candidateDriverIds
    })
  });

  return c.json({
    tripId,
    status: 'requested',
    fare,
    route: {
      distanceKm: route.distanceKm,
      durationMins: route.durationMins,
      coordinates: route.coordinates
    },
    availableDriversNearby: candidateDriverIds.length
  }, 201);
});

// GET /trips/:id
tripsRouter.get('/:id', async (c) => {
  const tripId = c.req.param('id');
  const trip = await c.env.DB
    .prepare(
      `SELECT t.*,
              u.name as passenger_name, u.phone as passenger_phone,
              d_user.name as driver_name, d_user.phone as driver_phone,
              d.rating_avg as driver_rating,
              v.make as vehicle_make, v.model as vehicle_model, v.color as vehicle_color, v.license_plate
       FROM trips t
       JOIN users u ON u.id = t.passenger_id
       LEFT JOIN drivers d ON d.id = t.driver_id
       LEFT JOIN users d_user ON d_user.id = t.driver_id
       LEFT JOIN vehicles v ON v.driver_id = t.driver_id AND v.is_active = 1
       WHERE t.id = ?`
    )
    .bind(tripId)
    .first();

  if (!trip) {
    return c.json({ error: 'Trip not found' }, 404);
  }

  return c.json({ trip });
});

// POST /trips/:id/accept
tripsRouter.post('/:id/accept', async (c) => {
  const authUser = c.get('user');
  const tripId = c.req.param('id');

  const tripCoordinatorId = c.env.TRIP_COORDINATOR.idFromName(tripId);
  const tripCoordinatorStub = c.env.TRIP_COORDINATOR.get(tripCoordinatorId);

  const res = await tripCoordinatorStub.fetch('http://do/accept', {
    method: 'POST',
    body: JSON.stringify({ driverId: authUser.userId })
  });

  const data = await res.json<any>();
  return c.json(data, res.status as any);
});

// POST /trips/:id/reject
tripsRouter.post('/:id/reject', async (c) => {
  const authUser = c.get('user');
  const tripId = c.req.param('id');

  const tripCoordinatorId = c.env.TRIP_COORDINATOR.idFromName(tripId);
  const tripCoordinatorStub = c.env.TRIP_COORDINATOR.get(tripCoordinatorId);

  const res = await tripCoordinatorStub.fetch('http://do/reject', {
    method: 'POST',
    body: JSON.stringify({ driverId: authUser.userId })
  });

  const data = await res.json<any>();
  return c.json(data, res.status as any);
});

// POST /trips/:id/status
tripsRouter.post('/:id/status', async (c) => {
  const tripId = c.req.param('id');
  const body = await c.req.json<{ status: string; reason?: string }>();

  const tripCoordinatorId = c.env.TRIP_COORDINATOR.idFromName(tripId);
  const tripCoordinatorStub = c.env.TRIP_COORDINATOR.get(tripCoordinatorId);

  const res = await tripCoordinatorStub.fetch('http://do/status', {
    method: 'POST',
    body: JSON.stringify(body)
  });

  const data = await res.json<any>();
  return c.json(data, res.status as any);
});

// POST /trips/:id/rate
tripsRouter.post('/:id/rate', async (c) => {
  const authUser = c.get('user');
  const tripId = c.req.param('id');
  const body = await c.req.json();
  const parsed = TripRatingSchema.safeParse(body);

  if (!parsed.success) {
    return c.json({ error: 'Invalid rating', details: parsed.error.issues }, 400);
  }

  const trip = await c.env.DB
    .prepare('SELECT driver_id FROM trips WHERE id = ? AND passenger_id = ? AND status = ?')
    .bind(tripId, authUser.userId, 'completed')
    .first<{ driver_id: string }>();

  if (!trip || !trip.driver_id) {
    return c.json({ error: 'Trip not found or not eligible for rating' }, 400);
  }

  const ratingId = generateUUID();
  await c.env.DB
    .prepare('INSERT INTO ratings (id, trip_id, passenger_id, driver_id, score, comment) VALUES (?, ?, ?, ?, ?, ?)')
    .bind(ratingId, tripId, authUser.userId, trip.driver_id, parsed.data.score, parsed.data.comment || null)
    .run();

  // Update driver average rating
  await c.env.DB
    .prepare(
      `UPDATE drivers
       SET rating_avg = (SELECT AVG(score) FROM ratings WHERE driver_id = ?),
           rating_count = (SELECT COUNT(id) FROM ratings WHERE driver_id = ?)
       WHERE id = ?`
    )
    .bind(trip.driver_id, trip.driver_id, trip.driver_id)
    .run();

  return c.json({ success: true, message: 'Rating recorded' });
});

// GET /trips/history
tripsRouter.get('/history/list', async (c) => {
  const authUser = c.get('user');
  const isDriver = authUser.role === 'driver';

  const query = isDriver
    ? `SELECT t.*, u.name as passenger_name
       FROM trips t
       JOIN users u ON u.id = t.passenger_id
       WHERE t.driver_id = ?
       ORDER BY t.requested_at DESC LIMIT 50`
    : `SELECT t.*, u.name as driver_name, v.make as vehicle_make, v.model as vehicle_model
       FROM trips t
       LEFT JOIN users u ON u.id = t.driver_id
       LEFT JOIN vehicles v ON v.driver_id = t.driver_id
       WHERE t.passenger_id = ?
       ORDER BY t.requested_at DESC LIMIT 50`;

  const { results } = await c.env.DB.prepare(query).bind(authUser.userId).all();
  return c.json({ trips: results || [] });
});

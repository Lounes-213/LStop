import { Hono } from 'hono';
import { Env, AuthUser } from '../env';
import { authMiddleware, requireRole } from '../auth/middleware';
import { DriverOnboardingSchema } from '../utils/validation';
import { generateUUID } from '../utils/crypto';

export const driversRouter = new Hono<{ Bindings: Env; Variables: { user: AuthUser } }>();

driversRouter.use('*', authMiddleware);

// GET /drivers/status
driversRouter.get('/status', async (c) => {
  const authUser = c.get('user');

  const driver = await c.env.DB
    .prepare(
      `SELECT d.id, d.license_number, d.approval_status, d.is_online, d.rating_avg, d.rating_count,
              v.id as vehicle_id, v.make, v.model, v.year, v.color, v.license_plate
       FROM drivers d
       LEFT JOIN vehicles v ON v.driver_id = d.id AND v.is_active = 1
       WHERE d.id = ?`
    )
    .bind(authUser.userId)
    .first();

  if (!driver) {
    return c.json({ error: 'Driver profile not registered' }, 404);
  }

  return c.json({ driver });
});

// POST /drivers/onboard
driversRouter.post('/onboard', async (c) => {
  const authUser = c.get('user');
  const body = await c.req.json();
  const parsed = DriverOnboardingSchema.safeParse(body);

  if (!parsed.success) {
    return c.json({ error: 'Validation failed', details: parsed.error.issues }, 400);
  }

  const { licenseNumber, licenseDocumentUrl, idCardDocumentUrl, insuranceDocumentUrl, vehicle } = parsed.data;

  // Update driver details
  await c.env.DB
    .prepare(
      `INSERT INTO drivers (id, license_number, license_document_url, id_card_document_url, insurance_document_url, approval_status, updated_at)
       VALUES (?, ?, ?, ?, ?, 'pending', unixepoch())
       ON CONFLICT(id) DO UPDATE SET
         license_number = ?,
         license_document_url = ?,
         id_card_document_url = ?,
         insurance_document_url = ?,
         approval_status = 'pending',
         updated_at = unixepoch()`
    )
    .bind(
      authUser.userId, licenseNumber, licenseDocumentUrl, idCardDocumentUrl, insuranceDocumentUrl,
      licenseNumber, licenseDocumentUrl, idCardDocumentUrl, insuranceDocumentUrl
    )
    .run();

  // Insert or update vehicle
  const vehicleId = generateUUID();
  await c.env.DB
    .prepare(
      `INSERT INTO vehicles (id, driver_id, make, model, year, color, license_plate, gray_card_url)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`
    )
    .bind(vehicleId, authUser.userId, vehicle.make, vehicle.model, vehicle.year, vehicle.color, vehicle.licensePlate, vehicle.grayCardUrl || null)
    .run();

  // Update user role to driver
  await c.env.DB
    .prepare('UPDATE users SET role = ? WHERE id = ?')
    .bind('driver', authUser.userId)
    .run();

  return c.json({
    success: true,
    message: 'Dossier chauffeur soumis avec succès. En attente de validation admin.',
    status: 'pending'
  });
});

// POST /drivers/shift
driversRouter.post('/shift', requireRole('driver'), async (c) => {
  const authUser = c.get('user');
  const body = await c.req.json<{ isOnline: boolean }>();

  const isOnline = body.isOnline ? 1 : 0;

  // Check approval
  const driver = await c.env.DB
    .prepare('SELECT approval_status FROM drivers WHERE id = ?')
    .bind(authUser.userId)
    .first<{ approval_status: string }>();

  if (!driver || driver.approval_status !== 'approved') {
    return c.json({
      error: 'Votre compte chauffeur doit être approuvé par un administrateur avant de passer en ligne.',
      status: driver?.approval_status || 'not_registered'
    }, 403);
  }

  await c.env.DB
    .prepare('UPDATE drivers SET is_online = ?, updated_at = unixepoch() WHERE id = ?')
    .bind(isOnline, authUser.userId)
    .run();

  return c.json({
    success: true,
    isOnline: Boolean(isOnline)
  });
});

// GET /drivers/earnings
driversRouter.get('/earnings', requireRole('driver'), async (c) => {
  const authUser = c.get('user');

  const stats = await c.env.DB
    .prepare(
      `SELECT
         COUNT(id) as total_trips,
         COALESCE(SUM(fare_dzd), 0) as total_earnings_dzd,
         COALESCE(SUM(CASE WHEN completed_at >= unixepoch('now', 'start of day') THEN fare_dzd ELSE 0 END), 0) as today_earnings_dzd,
         COALESCE(SUM(CASE WHEN completed_at >= unixepoch('now', '-7 days') THEN fare_dzd ELSE 0 END), 0) as week_earnings_dzd
       FROM trips
       WHERE driver_id = ? AND status = 'completed'`
    )
    .bind(authUser.userId)
    .first<{
      total_trips: number;
      total_earnings_dzd: number;
      today_earnings_dzd: number;
      week_earnings_dzd: number;
    }>();

  return c.json({
    earnings: {
      totalTrips: stats?.total_trips || 0,
      totalEarningsDzd: stats?.total_earnings_dzd || 0,
      todayEarningsDzd: stats?.today_earnings_dzd || 0,
      weekEarningsDzd: stats?.week_earnings_dzd || 0
    }
  });
});

// Admin Approval Endpoints
// GET /drivers/admin/pending
driversRouter.get('/admin/pending', requireRole('admin'), async (c) => {
  const { results } = await c.env.DB
    .prepare(
      `SELECT d.id, d.license_number, d.license_document_url, d.id_card_document_url, d.insurance_document_url,
              d.approval_status, d.created_at,
              u.name, u.email, u.phone,
              v.make as vehicle_make, v.model as vehicle_model, v.year as vehicle_year, v.color as vehicle_color, v.license_plate
       FROM drivers d
       JOIN users u ON u.id = d.id
       LEFT JOIN vehicles v ON v.driver_id = d.id AND v.is_active = 1
       WHERE d.approval_status = 'pending'
       ORDER BY d.created_at ASC`
    )
    .all();

  return c.json({ pendingDrivers: results || [] });
});

// POST /drivers/admin/:id/approve
driversRouter.post('/admin/:id/approve', requireRole('admin'), async (c) => {
  const driverId = c.req.param('id');

  await c.env.DB
    .prepare("UPDATE drivers SET approval_status = 'approved', updated_at = unixepoch() WHERE id = ?")
    .bind(driverId)
    .run();

  return c.json({ success: true, message: 'Chauffeur validé avec succès' });
});

// POST /drivers/admin/:id/reject
driversRouter.post('/admin/:id/reject', requireRole('admin'), async (c) => {
  const driverId = c.req.param('id');
  const body = await c.req.json<{ reason?: string }>().catch(() => ({ reason: undefined }));

  await c.env.DB
    .prepare("UPDATE drivers SET approval_status = 'rejected', updated_at = unixepoch() WHERE id = ?")
    .bind(driverId)
    .run();

  return c.json({ success: true, message: 'Dossier chauffeur rejeté', reason: body.reason });
});



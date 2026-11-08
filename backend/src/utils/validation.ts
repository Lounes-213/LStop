import { z } from 'zod';

export const GoogleAuthSchema = z.object({
  idToken: z.string().min(10, 'Google ID token is required'),
  role: z.enum(['passenger', 'driver']).default('passenger')
});

export const RefreshTokenSchema = z.object({
  refreshToken: z.string().min(10, 'Refresh token is required')
});

export const DriverOnboardingSchema = z.object({
  licenseNumber: z.string().min(4, 'License number is required'),
  licenseDocumentUrl: z.string().url(),
  idCardDocumentUrl: z.string().url(),
  insuranceDocumentUrl: z.string().url(),
  vehicle: z.object({
    make: z.string().min(2),
    model: z.string().min(1),
    year: z.number().int().min(1990).max(2030),
    color: z.string().min(2),
    licensePlate: z.string().min(3),
    grayCardUrl: z.string().url().optional()
  })
});

export const DriverLocationUpdateSchema = z.object({
  latitude: z.number().min(-90).max(90),
  longitude: z.number().min(-180).max(180),
  heading: z.number().min(0).max(360).optional(),
  speed: z.number().min(0).optional(),
  isMoving: z.boolean().default(false)
});

export const TripEstimateSchema = z.object({
  pickupLat: z.number().min(-90).max(90),
  pickupLng: z.number().min(-180).max(180),
  dropoffLat: z.number().min(-90).max(90),
  dropoffLng: z.number().min(-180).max(180)
});

export const TripRequestSchema = z.object({
  pickupLat: z.number().min(-90).max(90),
  pickupLng: z.number().min(-180).max(180),
  pickupAddress: z.string().min(2),
  dropoffLat: z.number().min(-90).max(90),
  dropoffLng: z.number().min(-180).max(180),
  dropoffAddress: z.string().min(2)
});

export const TripRatingSchema = z.object({
  score: z.number().int().min(1).max(5),
  comment: z.string().max(500).optional()
});

export const FavoritePlaceSchema = z.object({
  label: z.string().min(1).max(50),
  address: z.string().min(2),
  lat: z.number().min(-90).max(90),
  lng: z.number().min(-180).max(180)
});

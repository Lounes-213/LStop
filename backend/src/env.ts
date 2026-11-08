export interface Env {
  // Bindings
  DB: D1Database;
  BUCKET: R2Bucket;
  ZONE_ROOM: DurableObjectNamespace;
  TRIP_COORDINATOR: DurableObjectNamespace;

  // Environment Variables
  ENVIRONMENT: string;
  TOMTOM_BASE_URL: string;
  DEFAULT_LAT: string;
  DEFAULT_LNG: string;
  BASE_FARE_DZD: string;
  PER_KM_DZD: string;
  PER_MINUTE_DZD: string;
  MIN_FARE_DZD: string;

  // Secrets
  JWT_SECRET: string;
  TOMTOM_API_KEY: string;
  GOOGLE_CLIENT_IDS: string; // Comma-separated list of client IDs (Android, iOS, Web)
}

export interface AuthUser {
  userId: string;
  email: string;
  role: 'passenger' | 'driver' | 'admin';
  name: string;
}

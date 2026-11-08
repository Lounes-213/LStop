-- Migration 0002: Indexes and views for rapid lookups and zero-cost query efficiency

CREATE INDEX IF NOT EXISTS idx_users_google_sub ON users(google_sub);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_hash ON refresh_tokens(token_hash);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user ON refresh_tokens(user_id);

CREATE INDEX IF NOT EXISTS idx_drivers_online_status ON drivers(approval_status, is_online);
CREATE INDEX IF NOT EXISTS idx_drivers_geohash ON drivers(current_geohash5);

CREATE INDEX IF NOT EXISTS idx_trips_passenger ON trips(passenger_id);
CREATE INDEX IF NOT EXISTS idx_trips_driver ON trips(driver_id);
CREATE INDEX IF NOT EXISTS idx_trips_status ON trips(status);
CREATE INDEX IF NOT EXISTS idx_trips_geohash ON trips(pickup_geohash5);

CREATE INDEX IF NOT EXISTS idx_trip_events_trip ON trip_events(trip_id);
CREATE INDEX IF NOT EXISTS idx_ratings_driver ON ratings(driver_id);
CREATE INDEX IF NOT EXISTS idx_favorites_user ON user_favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_route_cache_expires ON route_cache(expires_at);

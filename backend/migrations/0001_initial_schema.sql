-- Migration 0001: Initial schema for Timizar platform

CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    google_sub TEXT UNIQUE NOT NULL,
    email TEXT NOT NULL,
    name TEXT NOT NULL,
    avatar_url TEXT,
    role TEXT NOT NULL CHECK (role IN ('passenger', 'driver', 'admin')) DEFAULT 'passenger',
    phone TEXT,
    is_active INTEGER NOT NULL DEFAULT 1,
    created_at INTEGER NOT NULL DEFAULT (unixepoch()),
    updated_at INTEGER NOT NULL DEFAULT (unixepoch())
);

CREATE TABLE IF NOT EXISTS refresh_tokens (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash TEXT NOT NULL UNIQUE,
    expires_at INTEGER NOT NULL,
    revoked INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL DEFAULT (unixepoch())
);

CREATE TABLE IF NOT EXISTS drivers (
    id TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    license_number TEXT,
    license_document_url TEXT,
    id_card_document_url TEXT,
    insurance_document_url TEXT,
    approval_status TEXT NOT NULL CHECK (approval_status IN ('pending', 'approved', 'rejected')) DEFAULT 'pending',
    is_online INTEGER NOT NULL DEFAULT 0,
    current_lat REAL,
    current_lng REAL,
    current_geohash5 TEXT,
    rating_avg REAL NOT NULL DEFAULT 5.0,
    rating_count INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL DEFAULT (unixepoch()),
    updated_at INTEGER NOT NULL DEFAULT (unixepoch())
);

CREATE TABLE IF NOT EXISTS vehicles (
    id TEXT PRIMARY KEY,
    driver_id TEXT NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,
    make TEXT NOT NULL,
    model TEXT NOT NULL,
    year INTEGER NOT NULL,
    color TEXT NOT NULL,
    license_plate TEXT NOT NULL,
    gray_card_url TEXT,
    is_active INTEGER NOT NULL DEFAULT 1,
    created_at INTEGER NOT NULL DEFAULT (unixepoch())
);

CREATE TABLE IF NOT EXISTS trips (
    id TEXT PRIMARY KEY,
    passenger_id TEXT NOT NULL REFERENCES users(id),
    driver_id TEXT REFERENCES drivers(id),
    status TEXT NOT NULL CHECK (status IN ('requested', 'offered', 'accepted', 'arriving', 'arrived', 'in_progress', 'completed', 'cancelled_by_passenger', 'cancelled_by_driver', 'timed_out')) DEFAULT 'requested',
    pickup_lat REAL NOT NULL,
    pickup_lng REAL NOT NULL,
    pickup_address TEXT NOT NULL,
    dropoff_lat REAL NOT NULL,
    dropoff_lng REAL NOT NULL,
    dropoff_address TEXT NOT NULL,
    distance_km REAL NOT NULL,
    duration_mins REAL NOT NULL,
    fare_dzd REAL NOT NULL,
    pickup_geohash5 TEXT NOT NULL,
    requested_at INTEGER NOT NULL DEFAULT (unixepoch()),
    accepted_at INTEGER,
    started_at INTEGER,
    completed_at INTEGER,
    cancellation_reason TEXT
);

CREATE TABLE IF NOT EXISTS trip_events (
    id TEXT PRIMARY KEY,
    trip_id TEXT NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL,
    actor_id TEXT NOT NULL,
    payload TEXT,
    created_at INTEGER NOT NULL DEFAULT (unixepoch())
);

CREATE TABLE IF NOT EXISTS ratings (
    id TEXT PRIMARY KEY,
    trip_id TEXT NOT NULL UNIQUE REFERENCES trips(id) ON DELETE CASCADE,
    passenger_id TEXT NOT NULL REFERENCES users(id),
    driver_id TEXT NOT NULL REFERENCES drivers(id),
    score INTEGER NOT NULL CHECK (score >= 1 AND score <= 5),
    comment TEXT,
    created_at INTEGER NOT NULL DEFAULT (unixepoch())
);

CREATE TABLE IF NOT EXISTS user_favorites (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    label TEXT NOT NULL,
    address TEXT NOT NULL,
    lat REAL NOT NULL,
    lng REAL NOT NULL,
    created_at INTEGER NOT NULL DEFAULT (unixepoch())
);

CREATE TABLE IF NOT EXISTS usage_counters (
    date_utc TEXT NOT NULL,
    metric TEXT NOT NULL,
    count INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (date_utc, metric)
);

CREATE TABLE IF NOT EXISTS route_cache (
    route_hash TEXT PRIMARY KEY,
    distance_km REAL NOT NULL,
    duration_mins REAL NOT NULL,
    polyline TEXT NOT NULL,
    expires_at INTEGER NOT NULL
);

# Timizar (تيميزار) • Plateforme de Transport en Algérie

> **Production-grade Algerian ride-hailing & transport platform running 100% within free tiers.**  
> Built as a unified Flutter monorepo with Cloudflare Workers, Durable Objects (WebSocket Hibernation), Cloudflare D1, R2, MapLibre GL, and TomTom API.

---

## 1. Monorepo Topology

```
timizar/
├── pubspec.yaml               # Native Dart workspace & Melos scripts
├── melos.yaml                 # Monorepo configuration
├── package.json               # Root npm orchestrator
├── backend/                   # Cloudflare Workers + Durable Objects (TypeScript)
│   ├── wrangler.toml          # D1, R2, and Durable Object bindings
│   ├── migrations/            # D1 SQLite migrations (schema, indexes, views)
│   └── src/                   # Hono router, ZoneRoom DO, TripCoordinator DO, TomTom proxy
├── packages/
│   └── timizar_core/          # Shared models, Dio client, WS client, theme, l10n, widgets
└── apps/
    ├── timizar_app/           # Passenger application ("Timizar")
    └── timizar_driver/        # Driver application ("Timizar Driver")
```

---

## 2. Hard Constraints & Free-Tier Capacity Proof

The platform is mathematically engineered for **3,000 registered users** and **200 concurrent active users (150 passengers + 50 drivers)** without incurring any hosting costs:

| Service | Free Tier Allowance | Timizar Peak Usage | Usage % | Safety Mechanism |
| :--- | :--- | :--- | :--- | :--- |
| **Cloudflare Workers** | 100,000 req/day | ~9,050 req/day | **~9%** | Edge caching with 24h TTL |
| **Durable Objects** | Free with Hibernation | ~72,000 msgs/peak | **Safe** | WebSocket Hibernation (0 CPU when idle) |
| **Cloudflare D1** | 100,000 writes / 5M reads | ~5,024 writes/day | **~5%** | Driver pings held in RAM; D1 for trips only |
| **Cloudflare R2** | 10M reads / 1M writes | < 1% quota | **< 1%** | 0$ egress, PMTiles cached via CDN |
| **TomTom Routing** | 20,000 routes/month | ~500 req/day | **Fits** | Coords rounded to 110m grid + D1/Edge cache |
| **TomTom Search** | 10,000 suggestions/mo | ~300 req/day | **Fits** | 400ms client debouncing & quick-pick list |

### Dynamic Budget Guard
When daily message volumes reach threshold limits, the backend automatically instructs active drivers to step down update intervals:
- **Normal**: 5s moving, 15s idle (>15m threshold)
- **70% Threshold**: 8s moving, 25s idle (>20m threshold)
- **85% Threshold**: 12s moving, 35s idle (>25m threshold)

---

## 3. Google Cloud OAuth Setup (Google-Only Auth)

Timizar uses **Google Sign-In exclusively** (no email/password, no Firebase Auth).

### Step 1: Create Google Cloud Project
1. Go to [Google Cloud Console](https://console.cloud.google.com/).
2. Create project: `timizar-algeria`.
3. Configure the **OAuth Consent Screen**:
   - User Type: **External**
   - App Name: `Timizar`
   - Scopes: `email`, `profile`, `openid`

### Step 2: Generate SHA-1 Fingerprints (Android)
Generate your debug and release SHA-1 fingerprints:
```bash
# Debug fingerprint (Windows PowerShell)
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```
Copy the `SHA1:` hex string (e.g. `AA:BB:CC:...`).

### Step 3: Create OAuth 2.0 Client IDs
Create three credentials under **APIs & Services > Credentials**:
1. **Android Client ID (Passenger App)**:
   - Package name: `com.timizar.timizar_app`
   - SHA-1: Your Android SHA-1 fingerprint
2. **Android Client ID (Driver App)**:
   - Package name: `com.timizar.timizar_driver`
   - SHA-1: Your Android SHA-1 fingerprint
3. **Web Application Client ID (Backend Verifier)**:
   - Name: `Timizar Backend Verifier`
   - Authorized redirect URIs: `https://timizar.dz/auth/callback`, `http://localhost:8787/auth/callback`

Copy the **Client IDs** and update your backend environment configuration.

---

## 4. Backend Setup & Deployment (Cloudflare)

### Prerequisites
- Node.js >= 20
- Cloudflare Wrangler CLI (`npm install -g wrangler` or `npx wrangler`)

### Step 1: Initialize Cloudflare Resources
```bash
# Log in to Cloudflare
npx wrangler login

# Create D1 SQLite database
npx wrangler d1 create timizar-db

# Create R2 bucket for map tiles and documents
npx wrangler r2 bucket create timizar-storage
```

### Step 2: Apply D1 Database Migrations
```bash
# Local development database
npx wrangler d1 migrations apply timizar-db --local --config backend/wrangler.toml

# Production Cloudflare database
npx wrangler d1 migrations apply timizar-db --remote --config backend/wrangler.toml
```

### Step 3: Set Secrets
```bash
# Set JWT secret (min 32 characters)
npx wrangler secret put JWT_SECRET --config backend/wrangler.toml

# Set TomTom API key (evaluated key provided)
npx wrangler secret put TOMTOM_API_KEY --config backend/wrangler.toml

# Set allowed Google OAuth Client IDs (comma-separated)
npx wrangler secret put GOOGLE_CLIENT_IDS --config backend/wrangler.toml
```

### Step 4: Upload Algeria Vector Map Tiles (PMTiles)
Download or extract `algeria.pmtiles` and upload directly to Cloudflare R2:
```bash
npx wrangler r2 object put timizar-storage/algeria.pmtiles --file=./algeria.pmtiles
```

### Step 5: Start Local Backend / Deploy
```bash
# Run backend locally with D1 and Durable Objects emulation
npm run backend:dev

# Deploy to Cloudflare global network
npm run backend:deploy
```

---

## 5. Flutter Workspace & Applications

### Prerequisites
- Flutter SDK >= 3.44.4 (Dart >= 3.5.0)
- Activated Melos: `dart pub global activate melos`

### Melos Workspace Commands
```bash
# Bootstrap dependencies across core, passenger, and driver apps
dart pub global run melos bootstrap

# Run tests across all packages
dart pub global run melos run test:all

# Run static analysis across all packages
dart pub global run melos run lint:all
```

### Running the Passenger App ("Timizar")
```bash
cd apps/timizar_app
flutter run -d chrome     # Web preview
# OR
flutter run -d android    # Android device/emulator
```

### Running the Driver App ("Timizar Driver")
```bash
cd apps/timizar_driver
flutter run -d chrome     # Web preview
# OR
flutter run -d android    # Android device/emulator
```

---

## 6. Realtime Architecture & Geohash-5 Sharding

1. **Driver Telemetry**: Connected drivers stream locations over WebSocket:
   ```json
   {
     "type": "driver_location",
     "driverId": "d123",
     "latitude": 36.7118,
     "longitude": 4.0459,
     "heading": 45.0,
     "speed": 30.0,
     "isMoving": true
   }
   ```
2. **`ZoneRoom` Durable Object**:
   - Hibernates while drivers are waiting or idle.
   - Maintains driver positions strictly in memory (RAM).
   - Broadcasts updates to passengers subscribed to the same geohash-5 cell (`~4.9km x 4.9km`).
3. **Sequential Matching (`TripCoordinator` DO)**:
   - Sorts available drivers by distance to pickup.
   - Dispatches a **15-second radial countdown offer** to Driver #1.
   - If Driver #1 declines or times out, immediately offers to Driver #2.
   - Once accepted, transitions through `arriving` → `arrived` → `in_progress` → `completed`.

---

## 7. Algerian Localization & Currency

- **Currencies**: Algerian Dinar (DZD / `DA` / `د.ج`).
- **Fare Formula**:
  $$\text{Fare (DZD)} = \max(200, \lceil (150 + 40 \times \text{km} + 5 \times \text{min}) / 10 \rceil \times 10)$$
- **Locales**: French (`fr`), Arabic (`ar`, RTL supported), English (`en`).
- **Emergency Dispatch**: Integrated dialers for Police (`1548`), Protection Civile (`14`), and Gendarmerie (`1055`).

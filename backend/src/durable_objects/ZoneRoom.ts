import { DurableObject } from 'cloudflare:workers';
import { calculateDistanceMeters } from '../utils/geohash';

export interface DriverState {
  driverId: string;
  name: string;
  lat: number;
  lng: number;
  heading?: number;
  speed?: number;
  isAvailable: boolean;
  vehicle?: {
    make: string;
    model: string;
    color: string;
    licensePlate: string;
  };
  lastSeen: number;
}

export class ZoneRoom extends DurableObject {
  // In-memory driver cache (held in DO RAM across hibernations)
  private drivers = new Map<string, DriverState>();

  constructor(ctx: DurableObjectState, env: any) {
    super(ctx, env);
  }

  async fetch(request: Request): Promise<Response> {
    const url = new URL(request.url);

    // 1. WebSocket upgrade request
    if (request.headers.get('Upgrade') === 'websocket') {
      const pair = new WebSocketPair();
      const [client, server] = Object.values(pair);

      const userId = url.searchParams.get('userId') || 'anon';
      const role = url.searchParams.get('role') || 'passenger';

      // Accept WebSocket using Cloudflare WebSocket Hibernation API
      this.ctx.acceptWebSocket(server, [role, `user:${userId}`]);

      // If passenger just connected, send initial nearby driver list immediately
      if (role === 'passenger') {
        const pLat = parseFloat(url.searchParams.get('lat') || '0');
        const pLng = parseFloat(url.searchParams.get('lng') || '0');
        const nearby = this.getNearbyDrivers(pLat, pLng, 3000);
        server.send(JSON.stringify({
          type: 'nearby_drivers',
          drivers: nearby
        }));
      }

      return new Response(null, { status: 101, webSocket: client });
    }

    // 2. Internal HTTP RPC: query available drivers in this cell for trip matching
    if (url.pathname === '/internal/available-drivers') {
      const pLat = parseFloat(url.searchParams.get('lat') || '0');
      const pLng = parseFloat(url.searchParams.get('lng') || '0');
      const radiusMeters = parseFloat(url.searchParams.get('radius') || '3000');
      const drivers = this.getNearbyDrivers(pLat, pLng, radiusMeters, true);
      return new Response(JSON.stringify(drivers), {
        headers: { 'Content-Type': 'application/json' }
      });
    }

    // 3. Internal HTTP RPC: dispatch offer to a specific driver
    if (url.pathname === '/internal/dispatch-offer' && request.method === 'POST') {
      const offer = await request.json<any>();
      const driverSockets = this.ctx.getWebSockets(`user:${offer.driverId}`);
      for (const ws of driverSockets) {
        ws.send(JSON.stringify({
          type: 'ride_offer',
          trip: offer.trip
        }));
      }
      return new Response(JSON.stringify({ dispatched: driverSockets.length > 0 }), {
        headers: { 'Content-Type': 'application/json' }
      });
    }

    return new Response('ZoneRoom Durable Object Active', { status: 200 });
  }

  // Cloudflare WebSocket Hibernation event: incoming message wakes up DO
  async webSocketMessage(ws: WebSocket, message: string | ArrayBuffer) {
    if (typeof message !== 'string') return;

    try {
      const data = JSON.parse(message);

      if (data.type === 'driver_location') {
        const driverId = data.driverId;
        if (!driverId) return;

        const driverState: DriverState = {
          driverId,
          name: data.name || 'Chauffeur',
          lat: data.latitude,
          lng: data.longitude,
          heading: data.heading,
          speed: data.speed,
          isAvailable: data.isAvailable ?? true,
          vehicle: data.vehicle,
          lastSeen: Date.now()
        };

        this.drivers.set(driverId, driverState);

        // Broadcast updated driver position to connected passengers in this cell
        const passengerSockets = this.ctx.getWebSockets('passenger');
        if (passengerSockets.length > 0) {
          const payload = JSON.stringify({
            type: 'driver_moved',
            driver: {
              driverId: driverState.driverId,
              latitude: driverState.lat,
              longitude: driverState.lng,
              heading: driverState.heading,
              isAvailable: driverState.isAvailable
            }
          });

          for (const pWs of passengerSockets) {
            pWs.send(payload);
          }
        }
      } else if (data.type === 'driver_offline') {
        const driverId = data.driverId;
        if (driverId) {
          this.drivers.delete(driverId);
          // Broadcast driver removed
          const passengerSockets = this.ctx.getWebSockets('passenger');
          const payload = JSON.stringify({ type: 'driver_left', driverId });
          for (const pWs of passengerSockets) {
            pWs.send(payload);
          }
        }
      }
    } catch {
      // Ignore malformed WS messages
    }
  }

  async webSocketClose(ws: WebSocket, code: number, reason: string, wasClean: boolean) {
    const tags = this.ctx.getTags(ws);
    const userTag = tags.find(t => t.startsWith('user:'));
    if (userTag) {
      const userId = userTag.replace('user:', '');
      this.drivers.delete(userId);
    }
  }

  async webSocketError(ws: WebSocket, error: unknown) {
    ws.close(1011, 'Internal WebSocket error');
  }

  private getNearbyDrivers(lat: number, lng: number, radiusMeters: number, availableOnly = false): DriverState[] {
    const now = Date.now();
    const staleThresholdMs = 60000; // 60s
    const result: DriverState[] = [];

    for (const [id, driver] of this.drivers.entries()) {
      if (now - driver.lastSeen > staleThresholdMs) {
        this.drivers.delete(id);
        continue;
      }

      if (availableOnly && !driver.isAvailable) {
        continue;
      }

      if (lat !== 0 && lng !== 0) {
        const dist = calculateDistanceMeters(lat, lng, driver.lat, driver.lng);
        if (dist <= radiusMeters) {
          result.push(driver);
        }
      } else {
        result.push(driver);
      }
    }

    return result;
  }
}

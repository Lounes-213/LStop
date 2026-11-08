import { DurableObject } from 'cloudflare:workers';
import { Env } from '../env';

export interface TripState {
  tripId: string;
  passengerId: string;
  driverId?: string;
  status: 'requested' | 'offered' | 'accepted' | 'arriving' | 'arrived' | 'in_progress' | 'completed' | 'cancelled';
  pickup: { lat: number; lng: number; address: string };
  dropoff: { lat: number; lng: number; address: string };
  fareDzd: number;
  distanceKm: number;
  durationMins: number;
  geohash5: string;
  candidateDriverIds: string[];
  currentCandidateIndex: number;
  offerExpiresAt?: number;
}

export class TripCoordinator extends DurableObject<Env> {
  private trip?: TripState;

  constructor(ctx: DurableObjectState, env: Env) {
    super(ctx, env);
  }

  async fetch(request: Request): Promise<Response> {
    const url = new URL(request.url);

    // 1. WebSocket connection for active trip participants (passenger & driver)
    if (request.headers.get('Upgrade') === 'websocket') {
      const pair = new WebSocketPair();
      const [client, server] = Object.values(pair);
      const userId = url.searchParams.get('userId') || 'anon';
      const role = url.searchParams.get('role') || 'passenger';

      this.ctx.acceptWebSocket(server, [role, `user:${userId}`]);

      // If trip state exists, deliver it immediately
      if (this.trip) {
        server.send(JSON.stringify({ type: 'trip_update', trip: this.trip }));
      }

      return new Response(null, { status: 101, webSocket: client });
    }

    // 2. Start Trip Matching flow
    if (url.pathname === '/initiate' && request.method === 'POST') {
      const payload = await request.json<any>();
      this.trip = {
        tripId: payload.tripId,
        passengerId: payload.passengerId,
        status: 'requested',
        pickup: payload.pickup,
        dropoff: payload.dropoff,
        fareDzd: payload.fareDzd,
        distanceKm: payload.distanceKm,
        durationMins: payload.durationMins,
        geohash5: payload.geohash5,
        candidateDriverIds: payload.candidateDriverIds || [],
        currentCandidateIndex: 0
      };

      await this.tryNextDriver();
      return new Response(JSON.stringify({ success: true, trip: this.trip }), {
        headers: { 'Content-Type': 'application/json' }
      });
    }

    // 3. Driver accepts offer
    if (url.pathname === '/accept' && request.method === 'POST') {
      const { driverId } = await request.json<any>();
      if (!this.trip || this.trip.status !== 'offered') {
        return new Response(JSON.stringify({ error: 'Trip offer expired or unavailable' }), { status: 400 });
      }

      this.trip.status = 'accepted';
      this.trip.driverId = driverId;
      delete this.trip.offerExpiresAt;

      // Cancel alarm
      await this.ctx.storage.deleteAlarm();

      // Update D1
      await this.env.DB.prepare('UPDATE trips SET status = ?, driver_id = ?, accepted_at = unixepoch() WHERE id = ?')
        .bind('accepted', driverId, this.trip.tripId)
        .run();

      this.broadcastTripState();
      return new Response(JSON.stringify({ success: true, trip: this.trip }), {
        headers: { 'Content-Type': 'application/json' }
      });
    }

    // 4. Driver rejects offer
    if (url.pathname === '/reject' && request.method === 'POST') {
      const { driverId } = await request.json<any>();
      if (this.trip && this.trip.status === 'offered') {
        // Move to next driver
        this.trip.currentCandidateIndex++;
        await this.tryNextDriver();
      }
      return new Response(JSON.stringify({ success: true }), {
        headers: { 'Content-Type': 'application/json' }
      });
    }

    // 5. Update Status (arriving, arrived, in_progress, completed, cancelled)
    if (url.pathname === '/status' && request.method === 'POST') {
      const { status, reason } = await request.json<any>();
      if (!this.trip) {
        return new Response(JSON.stringify({ error: 'Trip not found' }), { status: 404 });
      }

      this.trip.status = status;
      const now = Math.floor(Date.now() / 1000);

      if (status === 'in_progress') {
        await this.env.DB.prepare('UPDATE trips SET status = ?, started_at = ? WHERE id = ?')
          .bind('in_progress', now, this.trip.tripId)
          .run();
      } else if (status === 'completed') {
        await this.env.DB.prepare('UPDATE trips SET status = ?, completed_at = ? WHERE id = ?')
          .bind('completed', now, this.trip.tripId)
          .run();
      } else if (status.startsWith('cancelled')) {
        await this.env.DB.prepare('UPDATE trips SET status = ?, cancellation_reason = ? WHERE id = ?')
          .bind(status, reason || 'Cancelled', this.trip.tripId)
          .run();
      } else {
        await this.env.DB.prepare('UPDATE trips SET status = ? WHERE id = ?')
          .bind(status, this.trip.tripId)
          .run();
      }

      this.broadcastTripState();
      return new Response(JSON.stringify({ success: true, trip: this.trip }), {
        headers: { 'Content-Type': 'application/json' }
      });
    }

    return new Response('TripCoordinator DO', { status: 200 });
  }

  // Durable Object Alarm: Triggered after 15s driver offer timeout
  async alarm() {
    if (this.trip && this.trip.status === 'offered') {
      this.trip.currentCandidateIndex++;
      await this.tryNextDriver();
    }
  }

  private async tryNextDriver() {
    if (!this.trip) return;

    if (this.trip.currentCandidateIndex >= this.trip.candidateDriverIds.length) {
      // All drivers rejected or timed out
      this.trip.status = 'cancelled';
      await this.env.DB.prepare("UPDATE trips SET status = 'timed_out', cancellation_reason = 'No driver available' WHERE id = ?")
        .bind(this.trip.tripId)
        .run();
      this.broadcastTripState();
      return;
    }

    const targetDriverId = this.trip.candidateDriverIds[this.trip.currentCandidateIndex];
    this.trip.status = 'offered';
    this.trip.offerExpiresAt = Date.now() + 15000; // 15s offer timeout

    // Dispatch offer into the driver's ZoneRoom DO
    const zoneId = this.env.ZONE_ROOM.idFromName(this.trip.geohash5);
    const zoneStub = this.env.ZONE_ROOM.get(zoneId);

    await zoneStub.fetch('http://do/internal/dispatch-offer', {
      method: 'POST',
      body: JSON.stringify({
        driverId: targetDriverId,
        trip: {
          id: this.trip.tripId,
          pickupAddress: this.trip.pickup.address,
          dropoffAddress: this.trip.dropoff.address,
          fareDzd: this.trip.fareDzd,
          distanceKm: this.trip.distanceKm,
          durationMins: this.trip.durationMins,
          expiresInSeconds: 15
        }
      })
    });

    // Set DO Alarm for 15s timeout
    await this.ctx.storage.setAlarm(Date.now() + 15000);
    this.broadcastTripState();
  }

  private broadcastTripState() {
    if (!this.trip) return;
    const sockets = this.ctx.getWebSockets();
    const payload = JSON.stringify({ type: 'trip_update', trip: this.trip });
    for (const ws of sockets) {
      ws.send(payload);
    }
  }
}

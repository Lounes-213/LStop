import { Env } from '../env';
import { getCachedRoute, makeRouteCacheKey, setCachedRoute } from './cache';
import { calculateDistanceMeters } from '../utils/geohash';

export interface RouteResult {
  distanceKm: number;
  durationMins: number;
  coordinates: Array<[number, number]>; // [lat, lng]
  source: 'tomtom' | 'cache' | 'haversine_fallback';
}

export interface PlaceSearchResult {
  id: string;
  name: string;
  address: string;
  lat: number;
  lng: number;
  countrySubdivision?: string;
  municipality?: string;
}

export class TomTomService {
  private apiKey: string;
  private baseUrl: string;
  private db: D1Database;

  constructor(env: Env) {
    this.apiKey = env.TOMTOM_API_KEY;
    this.baseUrl = env.TOMTOM_BASE_URL || 'https://api.tomtom.com';
    this.db = env.DB;
  }

  /**
   * Calculate route with coordinate rounding and 24h caching
   */
  async calculateRoute(lat1: number, lng1: number, lat2: number, lng2: number): Promise<RouteResult> {
    const cacheKey = makeRouteCacheKey(lat1, lng1, lat2, lng2);
    const cached = await getCachedRoute(this.db, cacheKey);

    if (cached) {
      let coords: Array<[number, number]> = [];
      try {
        coords = JSON.parse(cached.polyline);
      } catch {
        coords = [[lat1, lng1], [lat2, lng2]];
      }
      return {
        distanceKm: cached.distanceKm,
        durationMins: cached.durationMins,
        coordinates: coords,
        source: 'cache'
      };
    }

    try {
      const url = `${this.baseUrl}/routing/1/calculateRoute/${lat1},${lng1}:${lat2},${lng2}/json?key=${this.apiKey}&routeType=fastest&traffic=true&travelMode=car`;
      const response = await fetch(url, {
        headers: { 'Accept': 'application/json' }
      });

      if (!response.ok) {
        throw new Error(`TomTom routing API returned ${response.status}`);
      }

      const data: any = await response.json();
      const summary = data.routes?.[0]?.summary;
      const legPoints = data.routes?.[0]?.legs?.[0]?.points;

      if (!summary || !legPoints) {
        throw new Error('Invalid TomTom routing response format');
      }

      const distanceKm = summary.lengthInMeters / 1000;
      const durationMins = summary.travelTimeInSeconds / 60;
      const coordinates: Array<[number, number]> = legPoints.map((p: any) => [p.latitude, p.longitude]);

      // Cache the result
      await setCachedRoute(this.db, cacheKey, {
        distanceKm,
        durationMins,
        polyline: JSON.stringify(coordinates)
      });

      return {
        distanceKm,
        durationMins,
        coordinates,
        source: 'tomtom'
      };
    } catch (err) {
      // Fallback: Haversine distance with estimated 30 km/h average city speed in Algeria
      const meters = calculateDistanceMeters(lat1, lng1, lat2, lng2);
      const roadCorrection = 1.35; // City road winding factor
      const distanceKm = (meters * roadCorrection) / 1000;
      const durationMins = (distanceKm / 30) * 60; // 30 km/h avg speed

      return {
        distanceKm: Math.max(0.5, parseFloat(distanceKm.toFixed(2))),
        durationMins: Math.max(2, Math.ceil(durationMins)),
        coordinates: [[lat1, lng1], [(lat1 + lat2) / 2, (lng1 + lng2) / 2], [lat2, lng2]],
        source: 'haversine_fallback'
      };
    }
  }

  /**
   * Search places with bias to Algeria (countrySet=DZ) and user location
   */
  async searchPlaces(query: string, lat?: number, lng?: number): Promise<PlaceSearchResult[]> {
    if (!query || query.trim().length < 2) return [];

    const centerLat = lat ?? 36.7118; // Default Tizi Ouzou
    const centerLng = lng ?? 4.0459;

    try {
      const url = `${this.baseUrl}/search/2/search/${encodeURIComponent(query)}.json?key=${this.apiKey}&countrySet=DZ&lat=${centerLat}&lon=${centerLng}&radius=60000&language=fr-FR&limit=8`;
      const response = await fetch(url);

      if (!response.ok) {
        throw new Error(`TomTom search API returned ${response.status}`);
      }

      const data: any = await response.json();
      const results: PlaceSearchResult[] = (data.results || []).map((r: any) => ({
        id: r.id || `${r.position.lat},${r.position.lon}`,
        name: r.poi?.name || r.address?.freeformAddress || query,
        address: r.address?.freeformAddress || `${r.address?.municipality || ''}, Algérie`,
        lat: r.position.lat,
        lng: r.position.lon,
        countrySubdivision: r.address?.countrySubdivision,
        municipality: r.address?.municipality
      }));

      return results;
    } catch {
      // Return regional fallbacks if search call fails
      return [
        {
          id: 'dz-fallback-1',
          name: query,
          address: `${query}, Tizi Ouzou, Algérie`,
          lat: centerLat + 0.005,
          lng: centerLng + 0.005,
          municipality: 'Tizi Ouzou'
        }
      ];
    }
  }

  /**
   * Reverse geocode a latitude/longitude coordinate
   */
  async reverseGeocode(lat: number, lng: number): Promise<{ address: string; municipality?: string }> {
    try {
      const url = `${this.baseUrl}/search/2/reverseGeocode/${lat},${lng}.json?key=${this.apiKey}&language=fr-FR`;
      const response = await fetch(url);

      if (!response.ok) {
        throw new Error(`TomTom reverseGeocode API returned ${response.status}`);
      }

      const data: any = await response.json();
      const address = data.addresses?.[0]?.address;

      if (address) {
        return {
          address: address.freeformAddress || `${lat.toFixed(4)}, ${lng.toFixed(4)}`,
          municipality: address.municipality || address.countrySubdivision
        };
      }
    } catch {
      // Fallback
    }

    return {
      address: `${lat.toFixed(4)}, ${lng.toFixed(4)}`
    };
  }
}

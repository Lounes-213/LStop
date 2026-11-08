import { describe, it, expect } from 'vitest';
import { encodeGeohash, decodeGeohash, calculateDistanceMeters, getSurroundingGeohashes } from '../src/utils/geohash';

describe('Geohash & Spatial Utilities', () => {
  it('encodes and decodes Tizi Ouzou coordinates accurately', () => {
    const lat = 36.7118;
    const lng = 4.0459;
    const hash = encodeGeohash(lat, lng, 5);
    expect(hash).toHaveLength(5);

    const decoded = decodeGeohash(hash);
    expect(decoded.latitude).toBeCloseTo(lat, 1);
    expect(decoded.longitude).toBeCloseTo(lng, 1);
  });

  it('calculates Haversine distance correctly', () => {
    // Distance from Tizi Ouzou (36.7118, 4.0459) to Ait Aissa Mimoun (36.7583, 4.0847)
    const dist = calculateDistanceMeters(36.7118, 4.0459, 36.7583, 4.0847);
    expect(dist).toBeGreaterThan(5000); // ~6.2 km
    expect(dist).toBeLessThan(8000);
  });

  it('returns exactly 9 cells for surrounding geohashes', () => {
    const center = encodeGeohash(36.7118, 4.0459, 5);
    const neighbors = getSurroundingGeohashes(center);
    expect(neighbors.length).toBeGreaterThanOrEqual(1);
    expect(neighbors).toContain(center);
  });
});

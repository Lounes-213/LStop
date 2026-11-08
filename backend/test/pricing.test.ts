import { describe, it, expect } from 'vitest';
import { calculateAlgerianFare } from '../src/services/pricing';

describe('Algerian DZD Fare Calculation', () => {
  it('enforces minimum fare of 200 DZD for short rides', () => {
    // 0.5 km, 2 minutes
    const fare = calculateAlgerianFare(0.5, 2);
    expect(fare.totalFareDzd).toBeGreaterThanOrEqual(200);
  });

  it('calculates regular ride accurately and rounds to 10 DZD', () => {
    // 10 km, 15 minutes
    // Base: 150 DZD, Distance: 10 * 40 = 400 DZD, Time: 15 * 5 = 75 DZD => Raw = 625 => Rounded to 630 DZD
    const fare = calculateAlgerianFare(10, 15);
    expect(fare.baseFareDzd).toBe(150);
    expect(fare.distanceFareDzd).toBe(400);
    expect(fare.timeFareDzd).toBe(75);
    expect(fare.totalFareDzd).toBe(630);
    expect(fare.totalFareDzd % 10).toBe(0);
  });
});


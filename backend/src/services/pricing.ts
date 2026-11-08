export interface FareBreakdown {
  baseFareDzd: number;
  distanceFareDzd: number;
  timeFareDzd: number;
  totalFareDzd: number;
  distanceKm: number;
  durationMins: number;
}

export function calculateAlgerianFare(
  distanceKm: number,
  durationMins: number,
  config?: {
    baseFare?: number;
    perKm?: number;
    perMin?: number;
    minFare?: number;
  }
): FareBreakdown {
  const baseFare = config?.baseFare ?? 150;
  const perKm = config?.perKm ?? 40;
  const perMin = config?.perMin ?? 5;
  const minFare = config?.minFare ?? 200;

  const distanceFare = distanceKm * perKm;
  const timeFare = durationMins * perMin;
  const rawTotal = baseFare + distanceFare + timeFare;

  // Round up to nearest 10 DZD for Algerian dinar currency standards
  let total = Math.ceil(Math.max(rawTotal, minFare) / 10) * 10;

  return {
    baseFareDzd: baseFare,
    distanceFareDzd: Math.round(distanceFare),
    timeFareDzd: Math.round(timeFare),
    totalFareDzd: total,
    distanceKm: parseFloat(distanceKm.toFixed(2)),
    durationMins: Math.ceil(durationMins)
  };
}


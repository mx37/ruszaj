export interface CityBounds {
  minLat: number;
  maxLat: number;
  minLon: number;
  maxLon: number;
}

export const CITY_BOUNDS: Record<string, CityBounds> = {
  Warszawa: { minLat: 52.05, maxLat: 52.40, minLon: 20.75, maxLon: 21.30 },
  Kraków: { minLat: 49.95, maxLat: 50.20, minLon: 19.70, maxLon: 20.20 },
  Gdańsk: { minLat: 54.25, maxLat: 54.55, minLon: 18.45, maxLon: 18.85 },
  Wrocław: { minLat: 51.00, maxLat: 51.25, minLon: 16.80, maxLon: 17.25 },
  Poznań: { minLat: 52.25, maxLat: 52.55, minLon: 16.70, maxLon: 17.15 },
  Bydgoszcz: { minLat: 53.00, maxLat: 53.25, minLon: 17.80, maxLon: 18.25 },
  Toruń: { minLat: 52.95, maxLat: 53.15, minLon: 18.45, maxLon: 18.75 },
  Łódź: { minLat: 51.60, maxLat: 51.90, minLon: 19.25, maxLon: 19.65 },
  Katowice: { minLat: 50.10, maxLat: 50.35, minLon: 18.80, maxLon: 19.20 },
  Lublin: { minLat: 51.10, maxLat: 51.35, minLon: 22.35, maxLon: 22.75 },
  Szczecin: { minLat: 53.25, maxLat: 53.55, minLon: 14.35, maxLon: 14.85 },
};

import { type Coordinates } from './common.js';

export interface Stop {
  id: string;
  name: string;
  coordinates: Coordinates;
  parentId?: string;
  stopCode?: string;
  level?: number;
  tz?: string;
  modes?: string[];
  distanceMeters?: number;
}

export interface NearbyStopsParams {
  lat: number;
  lon: number;
  radius: number;
  limit: number;
}

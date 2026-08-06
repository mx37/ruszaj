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

export interface StopRoute {
  id: string;
  shortName: string;
  longName: string;
  mode: string;
  agencyName: string;
  routeColor?: string;
}

export interface StopDetails extends Stop {
  routes: StopRoute[];
}

export interface Departure {
  mode: string;
  realTime: boolean;
  headsign: string;
  tripId: string;
  routeShortName: string;
  routeLongName: string;
  displayName: string;
  agencyName: string;
  scheduledDeparture: string;
  departure: string;
  track?: string;
  cancelled: boolean;
  tripCancelled: boolean;
  bikesAllowed: boolean;
}

export interface DeparturesParams {
  stopId: string;
  time?: string;
  limit?: number;
  direction?: 'EARLIER' | 'LATER';
}

export interface DeparturesResult {
  stop: Stop;
  departures: Departure[];
  previousPageCursor?: string;
  nextPageCursor?: string;
}

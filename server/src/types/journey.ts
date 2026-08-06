import { type Coordinates } from './common.js';

export interface JourneyStop {
  id: string;
  name: string;
  coordinates: Coordinates;
  arrival?: string;
  departure?: string;
  track?: string;
  cancelled?: boolean;
}

export interface JourneyLeg {
  mode: string;
  from: JourneyStop;
  to: JourneyStop;
  departure: string;
  arrival: string;
  scheduledDeparture: string;
  scheduledArrival: string;
  durationSeconds: number;
  distanceMeters?: number;
  headsign?: string;
  routeShortName?: string;
  routeLongName?: string;
  routeColor?: string;
  agencyName?: string;
  cancelled?: boolean;
  intermediateStops: JourneyStop[];
  geometry?: string;
  geometryPrecision?: number;
}

export interface Journey {
  id: string;
  departure: string;
  arrival: string;
  durationSeconds: number;
  transfers: number;
  legs: JourneyLeg[];
}

export interface JourneysResult {
  from: JourneyStop;
  to: JourneyStop;
  journeys: Journey[];
  previousPageCursor?: string;
  nextPageCursor?: string;
}

export interface JourneySearchParams {
  from: string;
  to: string;
  time?: string;
  arriveBy?: boolean;
  maxTransfers?: number;
  transitModes?: string[];
  numItineraries?: number;
  pageCursor?: string;
  walkingOnly?: boolean;
}

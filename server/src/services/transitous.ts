import {
  health as motisHealth,
  plan as motisPlan,
  stopInfo as motisStopInfo,
  stops as motisStops,
  stoptimes as motisStoptimes,
  type Itinerary,
  type Leg,
  type Mode,
  type Place,
  type Route,
  type StopTime,
} from '@motis-project/motis-client';
import {
  type Journey,
  type JourneyLeg,
  type JourneySearchParams,
  type JourneyStop,
  type JourneysResult,
} from '../types/journey.js';
import {
  type Departure,
  type DeparturesParams,
  type DeparturesResult,
  type NearbyStopsParams,
  type Stop,
  type StopDetails,
} from '../types/stop.js';

export interface TransitousServiceConfig {
  baseUrl: string;
  userAgent: string;
  fetch?: typeof globalThis.fetch;
}

export interface TransitousHealth {
  realtime: boolean;
}

export interface TransitousService {
  isHealthy(): Promise<TransitousHealth>;
  searchJourneys(params: JourneySearchParams): Promise<JourneysResult>;
  getNearbyStops(params: NearbyStopsParams): Promise<Stop[]>;
  getStop(stopId: string): Promise<StopDetails>;
  getDepartures(params: DeparturesParams): Promise<DeparturesResult>;
}

/**
 * Single gateway to the transit data provider (Transitous / MOTIS).
 *
 * Nothing outside this module may import `@motis-project/motis-client`
 * or know the upstream URL. Swapping Transitous for a self-hosted MOTIS
 * must only touch this file (and the config).
 */
export function createTransitousService(config: TransitousServiceConfig): TransitousService {
  const fetch = config.fetch;
  const requestOptions = {
    baseUrl: config.baseUrl,
    headers: { 'User-Agent': config.userAgent },
    querySerializer: { array: { explode: false, style: 'form' } },
    ...(fetch ? { fetch } : {}),
  } as const;

  return {
    async isHealthy(): Promise<TransitousHealth> {
      const res = await motisHealth({ ...requestOptions, throwOnError: true });
      return { realtime: res.data.rt === true };
    },

    async searchJourneys(params: JourneySearchParams): Promise<JourneysResult> {
      const res = await motisPlan({
        ...requestOptions,
        throwOnError: true,
        query: {
          fromPlace: params.from,
          toPlace: params.to,
          ...(params.time ? { time: params.time } : {}),
          ...(params.arriveBy !== undefined ? { arriveBy: params.arriveBy } : {}),
          ...(params.maxTransfers !== undefined ? { maxTransfers: params.maxTransfers } : {}),
          ...(params.transitModes ? { transitModes: params.transitModes as Mode[] } : {}),
          ...(params.numItineraries !== undefined ? { numItineraries: params.numItineraries } : {}),
          ...(params.pageCursor ? { pageCursor: params.pageCursor } : {}),
          directModes: ['WALK'],
        },
      });

      return {
        from: toJourneyStop(res.data.from),
        to: toJourneyStop(res.data.to),
        journeys: res.data.itineraries.map(toJourney),
        ...(res.data.previousPageCursor ? { previousPageCursor: res.data.previousPageCursor } : {}),
        ...(res.data.nextPageCursor ? { nextPageCursor: res.data.nextPageCursor } : {}),
      };
    },

    async getNearbyStops(params: NearbyStopsParams): Promise<Stop[]> {
      const { min, max } = bboxAround(params.lat, params.lon, params.radius);
      const res = await motisStops({
        ...requestOptions,
        throwOnError: true,
        query: { min, max, grouped: true, modes: ['TRANSIT'] },
      });

      const stops = res.data
        .map((place) => toStop(place, { lat: params.lat, lon: params.lon }))
        .sort((a, b) => (a.distanceMeters ?? Infinity) - (b.distanceMeters ?? Infinity));

      return stops.slice(0, params.limit);
    },

    async getStop(stopId: string): Promise<StopDetails> {
      const res = await motisStopInfo({
        ...requestOptions,
        throwOnError: true,
        query: { stopId, language: ['pl'] },
      });

      return {
        ...toStop(res.data.place),
        routes: res.data.routes.map(toStopRoute),
      };
    },

    async getDepartures(params: DeparturesParams): Promise<DeparturesResult> {
      const res = await motisStoptimes({
        ...requestOptions,
        throwOnError: true,
        query: {
          stopId: params.stopId,
          ...(params.time ? { time: params.time } : {}),
          ...(params.limit !== undefined ? { n: params.limit } : {}),
          ...(params.direction ? { direction: params.direction } : {}),
          realtimeMode: 'REALTIME',
        },
      });

      return {
        stop: toStop(res.data.place),
        departures: res.data.stopTimes.map(toDeparture),
        ...(res.data.previousPageCursor ? { previousPageCursor: res.data.previousPageCursor } : {}),
        ...(res.data.nextPageCursor ? { nextPageCursor: res.data.nextPageCursor } : {}),
      };
    },
  };
}

function toDeparture(stopTime: StopTime): Departure {
  return {
    mode: stopTime.mode,
    realTime: stopTime.realTime,
    headsign: stopTime.headsign,
    tripId: stopTime.tripId,
    routeShortName: stopTime.routeShortName,
    routeLongName: stopTime.routeLongName,
    displayName: stopTime.displayName,
    agencyName: stopTime.agencyName,
    scheduledDeparture: stopTime.place.scheduledDeparture ?? stopTime.place.departure ?? '',
    departure: stopTime.place.departure ?? stopTime.place.scheduledDeparture ?? '',
    ...(stopTime.place.track ? { track: stopTime.place.track } : {}),
    cancelled: stopTime.cancelled,
    tripCancelled: stopTime.tripCancelled,
    bikesAllowed: stopTime.bikesAllowed,
  };
}

function toStopRoute(route: Route): StopDetails['routes'][number] {
  return {
    id: route.routeId,
    shortName: route.routeShortName,
    longName: route.routeLongName,
    mode: route.mode,
    agencyName: route.agencyName,
    ...(route.routeColor ? { routeColor: route.routeColor } : {}),
  };
}

function bboxAround(lat: number, lon: number, radiusMeters: number): { min: string; max: string } {
  const metersPerDegLat = 111320;
  const latDelta = radiusMeters / metersPerDegLat;
  const lonDelta = radiusMeters / (metersPerDegLat * Math.cos((lat * Math.PI) / 180));
  return {
    min: `${lat - latDelta},${lon - lonDelta}`,
    max: `${lat + latDelta},${lon + lonDelta}`,
  };
}

function haversineMeters(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const toRad = (deg: number) => (deg * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
  return 6371000 * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function toStop(place: Place, ref?: { lat: number; lon: number }): Stop {
  return {
    id: place.stopId ?? '',
    name: place.name,
    coordinates: { lat: place.lat, lon: place.lon },
    ...(place.parentId ? { parentId: place.parentId } : {}),
    ...(place.stopCode ? { stopCode: place.stopCode } : {}),
    ...(place.level !== undefined ? { level: place.level } : {}),
    ...(place.tz ? { tz: place.tz } : {}),
    ...(place.modes && place.modes.length > 0 ? { modes: place.modes } : {}),
    ...(ref
      ? { distanceMeters: Math.round(haversineMeters(ref.lat, ref.lon, place.lat, place.lon)) }
      : {}),
  };
}

function toJourneyStop(place: Place): JourneyStop {
  return {
    id: place.stopId ?? '',
    name: place.name,
    coordinates: { lat: place.lat, lon: place.lon },
    ...(place.arrival ? { arrival: place.arrival } : {}),
    ...(place.departure ? { departure: place.departure } : {}),
    ...(place.track ? { track: place.track } : {}),
    ...(place.cancelled ? { cancelled: true } : {}),
  };
}

function toJourney(itinerary: Itinerary): Journey {
  return {
    id: itinerary.id,
    departure: itinerary.startTime,
    arrival: itinerary.endTime,
    durationSeconds: itinerary.duration,
    transfers: itinerary.transfers,
    legs: itinerary.legs.map(toJourneyLeg),
  };
}

function toJourneyLeg(leg: Leg): JourneyLeg {
  return {
    mode: leg.mode,
    from: toJourneyStop(leg.from),
    to: toJourneyStop(leg.to),
    departure: leg.startTime,
    arrival: leg.endTime,
    scheduledDeparture: leg.scheduledStartTime,
    scheduledArrival: leg.scheduledEndTime,
    durationSeconds: leg.duration,
    ...(leg.distance ? { distanceMeters: leg.distance } : {}),
    ...(leg.headsign ? { headsign: leg.headsign } : {}),
    ...(leg.routeShortName ? { routeShortName: leg.routeShortName } : {}),
    ...(leg.routeLongName ? { routeLongName: leg.routeLongName } : {}),
    ...(leg.routeColor ? { routeColor: leg.routeColor } : {}),
    ...(leg.agencyName ? { agencyName: leg.agencyName } : {}),
    ...(leg.cancelled ? { cancelled: true } : {}),
    intermediateStops: (leg.intermediateStops ?? []).map(toJourneyStop),
  };
}

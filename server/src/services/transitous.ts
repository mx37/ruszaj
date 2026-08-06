import {
  health as motisHealth,
  plan as motisPlan,
  type Itinerary,
  type Leg,
  type Mode,
  type Place,
} from '@motis-project/motis-client';
import {
  type Journey,
  type JourneyLeg,
  type JourneySearchParams,
  type JourneyStop,
  type JourneysResult,
} from '../types/journey.js';

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

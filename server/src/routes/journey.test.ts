import { describe, expect, it, vi } from 'vitest';
import { loadConfig } from '../config.js';
import { buildApp } from '../app.js';

const PLAN_PATH = '/api/v6/plan';

const planBody = {
  requestParameters: {},
  debugOutput: {},
  from: { name: 'Warszawa', stopId: 'pl-Warszawa', lat: 52.23, lon: 21.01 },
  to: { name: 'Kraków', stopId: 'pl-Krakow', lat: 50.06, lon: 19.94 },
  direct: [],
  itineraries: [
    {
      id: 'itinerary-1',
      startTime: '2026-08-06T10:00:00+02:00',
      endTime: '2026-08-06T12:30:00+02:00',
      duration: 9000,
      transfers: 1,
      legs: [
        {
          mode: 'WALK',
          from: { name: 'Warszawa', stopId: 'pl-Warszawa', lat: 52.23, lon: 21.01, departure: '2026-08-06T10:00:00+02:00' },
          to: { name: 'Warszawa Centralna', stopId: 'pl-wawa:7010', lat: 52.23, lon: 21.01, arrival: '2026-08-06T10:05:00+02:00' },
          startTime: '2026-08-06T10:00:00+02:00',
          endTime: '2026-08-06T10:05:00+02:00',
          scheduledStartTime: '2026-08-06T10:00:00+02:00',
          scheduledEndTime: '2026-08-06T10:05:00+02:00',
          duration: 300,
          distance: 400,
          legGeometry: '',
          intermediateStops: [],
        },
        {
          mode: 'RAIL',
          from: { name: 'Warszawa Centralna', stopId: 'pl-wawa:7010', lat: 52.23, lon: 21.01, departure: '2026-08-06T10:10:00+02:00' },
          to: { name: 'Kraków Główny', stopId: 'pl-krk:7110', lat: 50.06, lon: 19.94, arrival: '2026-08-06T12:25:00+02:00' },
          startTime: '2026-08-06T10:10:00+02:00',
          endTime: '2026-08-06T12:25:00+02:00',
          scheduledStartTime: '2026-08-06T10:10:00+02:00',
          scheduledEndTime: '2026-08-06T12:25:00+02:00',
          duration: 8100,
          headsign: 'Kraków Główny',
          routeShortName: 'EIP 1',
          routeLongName: 'Intercity',
          routeColor: '#FF0000',
          agencyName: 'PKP Intercity',
          tripId: 'trip-1',
          legGeometry: '',
          intermediateStops: [],
        },
      ],
    },
  ],
  previousPageCursor: '',
  nextPageCursor: 'cursor-next',
};

function appWithFetch(fetch: typeof globalThis.fetch) {
  const config = loadConfig({});
  return buildApp(config, { fetch });
}

describe('GET /v1/journeys', () => {
  it('maps MOTIS plan response to ruszaj journeys', async () => {
    const fetchMock = vi.fn(async (input: Request | URL | string) => {
      const url = input instanceof Request ? input.url : String(input);
      expect(url).toContain(PLAN_PATH);
      return new Response(JSON.stringify(planBody), {
        status: 200,
        headers: { 'content-type': 'application/json' },
      });
    });
    const app = appWithFetch(fetchMock);

    const res = await app.inject({
      method: 'GET',
      url: '/v1/journeys?from=52.23,21.01&to=50.06,19.94',
    });

    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(body.from).toEqual({ id: 'pl-Warszawa', name: 'Warszawa', coordinates: { lat: 52.23, lon: 21.01 } });
    expect(body.journeys).toHaveLength(1);
    expect(body.journeys[0]).toMatchObject({
      id: 'itinerary-1',
      departure: '2026-08-06T10:00:00+02:00',
      arrival: '2026-08-06T12:30:00+02:00',
      durationSeconds: 9000,
      transfers: 1,
    });
    expect(body.journeys[0].legs).toHaveLength(2);
    expect(body.journeys[0].legs[0]).toMatchObject({ mode: 'WALK', distanceMeters: 400, intermediateStops: [] });
    expect(body.journeys[0].legs[1]).toMatchObject({
      mode: 'RAIL',
      headsign: 'Kraków Główny',
      routeShortName: 'EIP 1',
      agencyName: 'PKP Intercity',
    });
    expect(body.nextPageCursor).toBe('cursor-next');

    const firstCall = fetchMock.mock.calls[0]![0];
    const planUrl = firstCall instanceof Request ? firstCall.url : String(firstCall);
    expect(planUrl).toContain('/api/v6/plan');
    await app.close();
  });

  it('rejects missing required params', async () => {
    const app = appWithFetch(async () =>
      new Response('{}', { status: 200, headers: { 'content-type': 'application/json' } }),
    );
    const res = await app.inject({ method: 'GET', url: '/v1/journeys?from=52.23,21.01' });
    expect(res.statusCode).toBe(400);
    expect(res.json().error.code).toBe('VALIDATION_ERROR');
    await app.close();
  });

  it('passes arriveBy and maxTransfers through to MOTIS', async () => {
    let captured: URL | undefined;
    const app = appWithFetch(async (input: Request | URL | string) => {
      captured = new URL(input instanceof Request ? input.url : String(input));
      return new Response(JSON.stringify(planBody), {
        status: 200,
        headers: { 'content-type': 'application/json' },
      });
    });

    const res = await app.inject({
      method: 'GET',
      url: '/v1/journeys?from=52.23,21.01&to=50.06,19.94&arriveBy=true&maxTransfers=2&transitModes=BUS,TRAM',
    });

    expect(res.statusCode).toBe(200);
    expect(captured?.searchParams.get('arriveBy')).toBe('true');
    expect(captured?.searchParams.get('maxTransfers')).toBe('2');
    expect(captured?.searchParams.get('transitModes')).toBe('BUS,TRAM');
    await app.close();
  });
});

import { describe, expect, it, vi } from 'vitest';
import { loadConfig } from '../config.js';
import { buildApp } from '../app.js';

const stopsBody = [
  { name: 'Warszawa Centralna', stopId: 'pl-wawa:7010', parentId: 'pl-wawa', lat: 52.2287, lon: 21.0056, modes: ['RAIL', 'SUBWAY'] },
  { name: 'Warszawa Śródmieście', stopId: 'pl-wawa:7006', parentId: 'pl-wawa', lat: 52.2299, lon: 21.0122, modes: ['RAIL'] },
  { name: 'Nowy Świat-Uniwersytet', stopId: 'pl-wawa:2107', lat: 52.2396, lon: 21.0176, modes: ['BUS', 'TRAM'] },
];

describe('GET /v1/stops/nearby', () => {
  it('returns stops sorted by distance within radius', async () => {
    const fetchMock = vi.fn(async (input: Request | URL | string) => {
      const url = input instanceof Request ? input.url : String(input);
      expect(url).toContain('/api/v6/map/stops');
      return new Response(JSON.stringify(stopsBody), {
        status: 200,
        headers: { 'content-type': 'application/json' },
      });
    });
    const app = buildApp(loadConfig({}), { fetch: fetchMock });

    const res = await app.inject({
      method: 'GET',
      url: '/v1/stops/nearby?lat=52.2297&lon=21.0122&radius=1000&limit=5',
    });

    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(body).toHaveLength(3);
    expect(body[0]).toMatchObject({
      id: 'pl-wawa:7006',
      name: 'Warszawa Śródmieście',
      distanceMeters: expect.any(Number),
    });
    expect(body[0].distanceMeters).toBeLessThanOrEqual(body[1].distanceMeters);
    expect(body.map((s: { name: string }) => s.name)).toEqual([
      'Warszawa Śródmieście',
      'Warszawa Centralna',
      'Nowy Świat-Uniwersytet',
    ]);
    await app.close();
  });

  it('validates lat and lon', async () => {
    const app = buildApp(loadConfig({}));
    const res = await app.inject({ method: 'GET', url: '/v1/stops/nearby?lat=99&lon=21' });
    expect(res.statusCode).toBe(400);
    await app.close();
  });

  it('requires lat and lon', async () => {
    const app = buildApp(loadConfig({}));
    const res = await app.inject({ method: 'GET', url: '/v1/stops/nearby' });
    expect(res.statusCode).toBe(400);
    await app.close();
  });
});

describe('GET /v1/stops/:id', () => {
  it('returns stop details with routes', async () => {
    const fetchMock = vi.fn(async (input: Request | URL | string) => {
      const url = input instanceof Request ? input.url : String(input);
      expect(url).toContain('/api/v6/stop?');
      return new Response(
        JSON.stringify({
          place: {
            name: 'Warszawa Centralna',
            stopId: 'pl-wawa:7010',
            parentId: 'pl-wawa',
            lat: 52.2287,
            lon: 21.0056,
            stopCode: 'WAR',
            tz: 'Europe/Warsaw',
            modes: ['RAIL'],
          },
          routes: [
            {
              routeId: 'route-1',
              routeShortName: 'EIP 1',
              routeLongName: 'Intercity',
              mode: 'RAIL',
              agencyId: 'a1',
              agencyName: 'PKP Intercity',
              agencyUrl: 'https://example.com',
              routeColor: '#FF0000',
            },
          ],
        }),
        { status: 200, headers: { 'content-type': 'application/json' } },
      );
    });
    const app = buildApp(loadConfig({}), { fetch: fetchMock });

    const res = await app.inject({ method: 'GET', url: '/v1/stops/pl-wawa%3A7010' });

    expect(res.statusCode).toBe(200);
    expect(res.json()).toEqual({
      id: 'pl-wawa:7010',
      name: 'Warszawa Centralna',
      coordinates: { lat: 52.2287, lon: 21.0056 },
      parentId: 'pl-wawa',
      stopCode: 'WAR',
      tz: 'Europe/Warsaw',
      modes: ['RAIL'],
      routes: [
        {
          id: 'route-1',
          shortName: 'EIP 1',
          longName: 'Intercity',
          mode: 'RAIL',
          agencyName: 'PKP Intercity',
          routeColor: '#FF0000',
        },
      ],
    });
    await app.close();
  });
});

describe('GET /v1/stops/:id/departures', () => {
  const stoptimesBody = {
    stopTimes: [
      {
        place: {
          name: 'Warszawa Centralna',
          stopId: 'pl-wawa:7010',
          lat: 52.2287,
          lon: 21.0056,
          departure: '2026-08-06T12:15:00+02:00',
          scheduledDeparture: '2026-08-06T12:10:00+02:00',
          track: '3',
        },
        mode: 'RAIL',
        realTime: true,
        headsign: 'Kraków Główny',
        tripId: 'trip-1',
        routeShortName: 'EIP 1',
        routeLongName: 'Intercity',
        displayName: 'EIP 1',
        agencyName: 'PKP Intercity',
        cancelled: false,
        tripCancelled: false,
        bikesAllowed: false,
      },
      {
        place: {
          name: 'Warszawa Centralna',
          stopId: 'pl-wawa:7010',
          lat: 52.2287,
          lon: 21.0056,
          departure: '2026-08-06T12:30:00+02:00',
          scheduledDeparture: '2026-08-06T12:30:00+02:00',
        },
        mode: 'RAIL',
        realTime: false,
        headsign: 'Gdańsk Główny',
        tripId: 'trip-2',
        routeShortName: 'EIP 2',
        routeLongName: 'Intercity',
        displayName: 'EIP 2',
        agencyName: 'PKP Intercity',
        cancelled: true,
        tripCancelled: true,
        bikesAllowed: true,
      },
    ],
    place: { name: 'Warszawa Centralna', stopId: 'pl-wawa:7010', lat: 52.2287, lon: 21.0056 },
    previousPageCursor: '',
    nextPageCursor: 'cursor-2',
  };

  it('maps MOTIS stoptimes to departures', async () => {
    const fetchMock = vi.fn(async (input: Request | URL | string) => {
      const url = input instanceof Request ? input.url : String(input);
      expect(url).toContain('/api/v6/stoptimes');
      return new Response(JSON.stringify(stoptimesBody), {
        status: 200,
        headers: { 'content-type': 'application/json' },
      });
    });
    const app = buildApp(loadConfig({}), { fetch: fetchMock });

    const res = await app.inject({
      method: 'GET',
      url: '/v1/stops/pl-wawa%3A7010/departures?limit=5',
    });

    expect(res.statusCode).toBe(200);
    expect(res.json()).toEqual({
      stop: {
        id: 'pl-wawa:7010',
        name: 'Warszawa Centralna',
        coordinates: { lat: 52.2287, lon: 21.0056 },
      },
      departures: [
        {
          mode: 'RAIL',
          realTime: true,
          headsign: 'Kraków Główny',
          tripId: 'trip-1',
          routeShortName: 'EIP 1',
          routeLongName: 'Intercity',
          displayName: 'EIP 1',
          agencyName: 'PKP Intercity',
          scheduledDeparture: '2026-08-06T12:10:00+02:00',
          departure: '2026-08-06T12:15:00+02:00',
          track: '3',
          cancelled: false,
          tripCancelled: false,
          bikesAllowed: false,
        },
        {
          mode: 'RAIL',
          realTime: false,
          headsign: 'Gdańsk Główny',
          tripId: 'trip-2',
          routeShortName: 'EIP 2',
          routeLongName: 'Intercity',
          displayName: 'EIP 2',
          agencyName: 'PKP Intercity',
          scheduledDeparture: '2026-08-06T12:30:00+02:00',
          departure: '2026-08-06T12:30:00+02:00',
          cancelled: true,
          tripCancelled: true,
          bikesAllowed: true,
        },
      ],
      nextPageCursor: 'cursor-2',
    });
    await app.close();
  });

  it('rejects invalid direction', async () => {
    const app = buildApp(loadConfig({}));
    const res = await app.inject({
      method: 'GET',
      url: '/v1/stops/pl-wawa%3A7010/departures?direction=SIDEWAYS',
    });
    expect(res.statusCode).toBe(400);
    await app.close();
  });
});

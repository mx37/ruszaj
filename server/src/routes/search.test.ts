import { describe, expect, it, vi } from 'vitest';
import { loadConfig } from '../config.js';
import { buildApp } from '../app.js';

const geocodeBody = [
  {
    type: 'STOP',
    name: 'Warszawa Centralna',
    id: 'pl-wawa:7010',
    lat: 52.2287,
    lon: 21.0056,
    country: 'PL',
    tz: 'Europe/Warsaw',
    areas: [],
    tokens: [],
    modes: ['RAIL'],
    score: 1,
  },
  {
    type: 'PLACE',
    name: 'Warszawa',
    id: 'pl-wawa',
    lat: 52.2297,
    lon: 21.0122,
    country: 'PL',
    tz: 'Europe/Warsaw',
    areas: [],
    tokens: [],
    score: 0.9,
  },
];

describe('GET /v1/search', () => {
  it('maps MOTIS geocode results', async () => {
    const fetchMock = vi.fn(async (input: Request | URL | string) => {
      const url = input instanceof Request ? input.url : String(input);
      expect(url).toContain('/api/v1/geocode');
      return new Response(JSON.stringify(geocodeBody), {
        status: 200,
        headers: { 'content-type': 'application/json' },
      });
    });
    const app = buildApp(loadConfig({}), { fetch: fetchMock });

    const res = await app.inject({ method: 'GET', url: '/v1/search?q=Warszawa&limit=5' });

    expect(res.statusCode).toBe(200);
    expect(res.json()).toEqual([
      {
        id: 'pl-wawa:7010',
        name: 'Warszawa Centralna',
        type: 'STOP',
        coordinates: { lat: 52.2287, lon: 21.0056 },
        country: 'PL',
        tz: 'Europe/Warsaw',
        modes: ['RAIL'],
        score: 1,
      },
      {
        id: 'pl-wawa',
        name: 'Warszawa',
        type: 'PLACE',
        coordinates: { lat: 52.2297, lon: 21.0122 },
        country: 'PL',
        tz: 'Europe/Warsaw',
        score: 0.9,
      },
    ]);
    await app.close();
  });

  it('requires q and validates types', async () => {
    const app = buildApp(loadConfig({}));
    const missing = await app.inject({ method: 'GET', url: '/v1/search' });
    expect(missing.statusCode).toBe(400);
    const badType = await app.inject({ method: 'GET', url: '/v1/search?q=x&types=WRONG' });
    expect(badType.statusCode).toBe(400);
    await app.close();
  });
});

import { describe, expect, it, vi } from 'vitest';
import { createTransitousService } from '../services/transitous.js';

function mockFetch(status: number, body: unknown) {
  return vi.fn(async (_input: Request | URL | string, _init?: RequestInit) => {
    return new Response(JSON.stringify(body), {
      status,
      headers: { 'content-type': 'application/json' },
    });
  });
}

describe('transitous service', () => {
  it('sends User-Agent header and uses base url', async () => {
    const fetchMock = mockFetch(200, { rt: true });
    const service = createTransitousService({
      baseUrl: 'https://api.transitous.org',
      userAgent: 'Ruszaj/0.1.0 (+https://github.com/mx37/ruszaj)',
      fetch: fetchMock,
    });

    const health = await service.isHealthy();

    expect(health).toEqual({ realtime: true });
    const [input] = fetchMock.mock.calls[0]!;
    const request = input instanceof Request ? input : new Request(input);
    expect(request.url).toBe('https://api.transitous.org/api/v1/health');
    expect(request.headers.get('User-Agent')).toBe('Ruszaj/0.1.0 (+https://github.com/mx37/ruszaj)');
  });

  it('reports realtime false when upstream omits it', async () => {
    const service = createTransitousService({
      baseUrl: 'https://api.transitous.org',
      userAgent: 'Ruszaj/test',
      fetch: mockFetch(200, {}),
    });

    expect(await service.isHealthy()).toEqual({ realtime: false });
  });

  it('throws on upstream errors', async () => {
    const service = createTransitousService({
      baseUrl: 'https://api.transitous.org',
      userAgent: 'Ruszaj/test',
      fetch: mockFetch(500, { msg: 'boom' }),
    });

    await expect(service.isHealthy()).rejects.toThrow();
  });
});

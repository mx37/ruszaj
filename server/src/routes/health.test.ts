import { describe, expect, it } from 'vitest';
import { loadConfig } from '../config.js';
import { buildApp } from '../app.js';

describe('health', () => {
  it('GET /health returns ok with version', async () => {
    const config = loadConfig({});
    const app = buildApp(config);
    const res = await app.inject({ method: 'GET', url: '/health' });
    expect(res.statusCode).toBe(200);
    expect(res.json()).toEqual({
      status: 'ok',
      version: config.appVersion,
      uptimeSeconds: expect.any(Number),
    });
    await app.close();
  });

  it('loadConfig applies defaults', () => {
    const config = loadConfig({});
    expect(config.port).toBe(8080);
    expect(config.transitousBaseUrl).toBe('https://api.transitous.org');
  });
});

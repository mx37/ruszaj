import { health as motisHealth } from '@motis-project/motis-client';

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
    ...(fetch ? { fetch } : {}),
  } as const;

  return {
    async isHealthy(): Promise<TransitousHealth> {
      const res = await motisHealth({ ...requestOptions, throwOnError: true });
      return { realtime: res.data.rt === true };
    },
  };
}

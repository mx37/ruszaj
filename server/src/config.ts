export interface Config {
  host: string;
  port: number;
  appVersion: string;
  transitousBaseUrl: string;
  userAgent: string;
  logLevel: string;
}

const DEFAULT_USER_AGENT = 'Ruszaj/0.1.0 (+https://github.com/ruszaj)';

export function loadConfig(env: NodeJS.ProcessEnv = process.env): Config {
  return {
    host: env.HOST ?? '0.0.0.0',
    port: Number(env.PORT ?? 8080),
    appVersion: env.APP_VERSION ?? '0.1.0',
    transitousBaseUrl: env.TRANSITOUS_BASE_URL ?? 'https://api.transitous.org',
    userAgent: env.USER_AGENT ?? DEFAULT_USER_AGENT,
    logLevel: env.LOG_LEVEL ?? 'info',
  };
}

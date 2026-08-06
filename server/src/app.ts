import Fastify, { type FastifyInstance } from 'fastify';
import { AppError } from './errors.js';
import { type Config } from './config.js';
import { createTransitousService } from './services/transitous.js';
import { healthRoutes } from './routes/health.js';
import { journeyRoutes } from './routes/journey.js';

export function buildApp(config: Config, deps?: { fetch?: typeof globalThis.fetch }): FastifyInstance {
  const app = Fastify({
    logger: { level: config.logLevel },
  });

  const transitous = createTransitousService({
    baseUrl: config.transitousBaseUrl,
    userAgent: config.userAgent,
    ...(deps?.fetch ? { fetch: deps.fetch } : {}),
  });

  app.setErrorHandler((error, _request, reply) => {
    if (error instanceof AppError) {
      return reply.code(error.statusCode).send({ error: { code: error.code, message: error.message } });
    }
    if (error instanceof Error && 'validation' in error) {
      return reply
        .code(400)
        .send({ error: { code: 'VALIDATION_ERROR', message: error.message } });
    }
    app.log.error(error);
    return reply
      .code(500)
      .send({ error: { code: 'INTERNAL_ERROR', message: 'Internal server error' } });
  });

  app.register(healthRoutes, { prefix: '/health', config });
  app.register(journeyRoutes, { prefix: '/v1/journeys', transitous });

  return app;
}

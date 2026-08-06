import Fastify, { type FastifyInstance } from 'fastify';
import { AppError } from './errors.js';
import { type Config } from './config.js';
import { healthRoutes } from './routes/health.js';

export function buildApp(config: Config): FastifyInstance {
  const app = Fastify({
    logger: { level: config.logLevel },
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

  return app;
}

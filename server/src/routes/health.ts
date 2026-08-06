import { type FastifyPluginAsync } from 'fastify';
import { type Config } from '../config.js';

export const healthRoutes: FastifyPluginAsync<{ config: Config }> = async (app, { config }) => {
  app.get('/', async () => ({
    status: 'ok',
    version: config.appVersion,
    uptimeSeconds: Math.round(process.uptime()),
  }));
};

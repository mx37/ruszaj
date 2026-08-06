import { type FastifyPluginAsync } from 'fastify';
import { type TransitousService } from '../services/transitous.js';

export const stopRoutes: FastifyPluginAsync<{ transitous: TransitousService }> = async (
  app,
  { transitous },
) => {
  app.get('/nearby', {
    schema: {
      querystring: {
        type: 'object',
        additionalProperties: false,
        required: ['lat', 'lon'],
        properties: {
          lat: { type: 'number', minimum: -90, maximum: 90 },
          lon: { type: 'number', minimum: -180, maximum: 180 },
          radius: { type: 'integer', minimum: 1, maximum: 5000, default: 500 },
          limit: { type: 'integer', minimum: 1, maximum: 100, default: 20 },
        },
      },
    },
    handler: async (request) => {
      const { lat, lon, radius, limit } = request.query as {
        lat: number;
        lon: number;
        radius: number;
        limit: number;
      };
      return transitous.getNearbyStops({ lat, lon, radius, limit });
    },
  });

  app.get('/:id/departures', {
    schema: {
      params: {
        type: 'object',
        additionalProperties: false,
        required: ['id'],
        properties: {
          id: { type: 'string', minLength: 1 },
        },
      },
      querystring: {
        type: 'object',
        additionalProperties: false,
        properties: {
          time: { type: 'string', format: 'date-time' },
          limit: { type: 'integer', minimum: 1, maximum: 100, default: 20 },
          direction: { type: 'string', enum: ['EARLIER', 'LATER'] },
        },
      },
    },
    handler: async (request) => {
      const { id } = request.params as { id: string };
      const query = request.query as { time?: string; limit?: number; direction?: 'EARLIER' | 'LATER' };
      return transitous.getDepartures({
        stopId: id,
        ...(query.time ? { time: query.time } : {}),
        ...(query.limit !== undefined ? { limit: query.limit } : {}),
        ...(query.direction ? { direction: query.direction } : {}),
      });
    },
  });

  app.get('/:id', {
    schema: {
      params: {
        type: 'object',
        additionalProperties: false,
        required: ['id'],
        properties: {
          id: { type: 'string', minLength: 1 },
        },
      },
    },
    handler: async (request) => {
      const { id } = request.params as { id: string };
      return transitous.getStop(id);
    },
  });
};

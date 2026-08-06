import { type FastifyPluginAsync } from 'fastify';
import { type TransitousService } from '../services/transitous.js';

interface JourneyQuery {
  from: string;
  to: string;
  time?: string;
  arriveBy?: boolean;
  maxTransfers?: number;
  numItineraries?: number;
  transitModes?: string;
  pageCursor?: string;
}

export const journeyRoutes: FastifyPluginAsync<{ transitous: TransitousService }> = async (
  app,
  { transitous },
) => {
  app.get('/', {
    schema: {
      querystring: {
        type: 'object',
        additionalProperties: false,
        required: ['from', 'to'],
        properties: {
          from: { type: 'string', minLength: 1 },
          to: { type: 'string', minLength: 1 },
          time: { type: 'string', format: 'date-time' },
          arriveBy: { type: 'boolean' },
          maxTransfers: { type: 'integer', minimum: 0 },
          numItineraries: { type: 'integer', minimum: 1 },
          transitModes: { type: 'string' },
          pageCursor: { type: 'string' },
        },
      },
    },
    handler: async (request) => {
      const q = request.query as JourneyQuery;
      const transitModes = q.transitModes
        ? q.transitModes
            .split(',')
            .map((mode) => mode.trim())
            .filter(Boolean)
        : undefined;

      return transitous.searchJourneys({
        from: q.from,
        to: q.to,
        ...(q.time ? { time: q.time } : {}),
        ...(q.arriveBy !== undefined ? { arriveBy: q.arriveBy } : {}),
        ...(q.maxTransfers !== undefined ? { maxTransfers: q.maxTransfers } : {}),
        ...(q.numItineraries !== undefined ? { numItineraries: q.numItineraries } : {}),
        ...(transitModes && transitModes.length > 0 ? { transitModes } : {}),
        ...(q.pageCursor ? { pageCursor: q.pageCursor } : {}),
      });
    },
  });
};

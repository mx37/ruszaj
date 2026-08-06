import { type FastifyPluginAsync } from 'fastify';
import { type TransitousService } from '../services/transitous.js';
import { validationError } from '../errors.js';
import { type SearchResultType } from '../types/search.js';

const VALID_TYPES = new Set<SearchResultType>(['ADDRESS', 'PLACE', 'STOP']);

export const searchRoutes: FastifyPluginAsync<{ transitous: TransitousService }> = async (
  app,
  { transitous },
) => {
  app.get('/', {
    schema: {
      querystring: {
        type: 'object',
        additionalProperties: false,
        required: ['q'],
        properties: {
          q: { type: 'string', minLength: 1 },
          limit: { type: 'integer', minimum: 1, maximum: 100, default: 10 },
          types: { type: 'string' },
          lat: { type: 'number', minimum: -90, maximum: 90 },
          lon: { type: 'number', minimum: -180, maximum: 180 },
        },
      },
    },
    handler: async (request) => {
      const query = request.query as {
        q: string;
        limit?: number;
        types?: string;
        lat?: number;
        lon?: number;
      };

      const types = query.types
        ? (query.types
            .split(',')
            .map((type) => type.trim())
            .filter(Boolean) as SearchResultType[])
        : undefined;

      if (types && types.some((type) => !VALID_TYPES.has(type))) {
        throw validationError('types must be one of ADDRESS, PLACE, STOP');
      }

      return transitous.search({
        text: query.q,
        ...(query.limit !== undefined ? { limit: query.limit } : {}),
        ...(types && types.length > 0 ? { types } : {}),
        ...(query.lat !== undefined ? { lat: query.lat } : {}),
        ...(query.lon !== undefined ? { lon: query.lon } : {}),
      });
    },
  });
};

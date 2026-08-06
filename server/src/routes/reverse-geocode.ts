import { type FastifyPluginAsync } from 'fastify';
import { type TransitousService } from '../services/transitous.js';

export const reverseGeocodeRoutes: FastifyPluginAsync<{ transitous: TransitousService }> = async (
  app,
  { transitous },
) => {
  app.get('/reverse-geocode', {
    schema: {
      querystring: {
        type: 'object',
        additionalProperties: false,
        required: ['lat', 'lon'],
        properties: {
          lat: { type: 'number', minimum: -90, maximum: 90 },
          lon: { type: 'number', minimum: -180, maximum: 180 },
        },
      },
    },
    handler: async (request) => {
      const { lat, lon } = request.query as { lat: number; lon: number };
      return transitous.reverseGeocode(lat, lon);
    },
  });
};

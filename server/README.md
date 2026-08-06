# Ruszaj Server

Backend API for the Ruszaj public transport app.

The server is a thin, stable facade over a transit data provider. Today it uses
[Transitous](https://transitous.org/) (MOTIS 2 API), but the Flutter client only
ever talks to Ruszaj's own endpoints (`/v1/...`). Swapping Transitous for a
self-hosted MOTIS only touches `src/services/transitous.ts` and the config.

## Quick start

```bash
npm install
cp .env.example .env
npm run dev          # http://0.0.0.0:8080
```

## Scripts

| Script | Description |
| --- | --- |
| `npm run dev` | watch mode via tsx |
| `npm run build` | compile to `dist/` |
| `npm start` | run compiled output |
| `npm test` | vitest run |
| `npm run typecheck` | `tsc --noEmit` |

## Configuration

Environment variables, see `.env.example`:

| Variable | Default | Description |
| --- | --- | --- |
| `HOST` | `0.0.0.0` | listen host |
| `PORT` | `8080` | listen port |
| `LOG_LEVEL` | `info` | pino log level |
| `TRANSITOUS_BASE_URL` | `https://api.transitous.org` | upstream provider |
| `APP_VERSION` | `0.1.0` | reported by `/health` |
| `USER_AGENT` | `Ruszaj/0.1.0 (+https://github.com/ruszaj)` | sent to Transitous |

## API

All endpoints return JSON. Errors use a stable shape:

```json
{ "error": { "code": "VALIDATION_ERROR", "message": "..." } }
```

### `GET /health`

Service health.

```bash
curl http://localhost:8080/health
```

### `GET /v1/journeys`

Plan a journey. `from` and `to` accept either `lat,lon` coordinates or a stop id.

```
GET /v1/journeys?from=52.2297,21.0122&to=50.0619,19.9368
```

| Param | Type | Notes |
| --- | --- | --- |
| `from` | string | required, `lat,lon` or stop id |
| `to` | string | required, `lat,lon` or stop id |
| `time` | ISO-8601 | departure time (`arriveBy=false`) |
| `arriveBy` | boolean | treat `time` as arrival time |
| `maxTransfers` | integer | max interchanges |
| `transitModes` | string | comma-separated MOTIS modes, e.g. `BUS,TRAM,RAIL` |
| `numItineraries` | integer | number of options |
| `pageCursor` | string | pagination cursor |

Response contains `journeys` with legs, times, realtime state and pagination
cursors (`nextPageCursor` / `previousPageCursor`).

### `GET /v1/stops/nearby`

Stops within a radius of a coordinate, sorted by distance.

```
GET /v1/stops/nearby?lat=52.2297&lon=21.0122&radius=500&limit=20
```

| Param | Type | Default | Notes |
| --- | --- | --- | --- |
| `lat` | number | - | required, -90..90 |
| `lon` | number | - | required, -180..180 |
| `radius` | integer | 500 | meters, 1..5000 |
| `limit` | integer | 20 | 1..100 |

### `GET /v1/stops/:id`

Stop metadata and routes serving it.

```bash
curl http://localhost:8080/v1/stops/pl-wawa%3A7010
```

### `GET /v1/stops/:id/departures`

Upcoming departures with realtime data.

```
GET /v1/stops/pl-wawa%3A7010/departures?limit=20
```

| Param | Type | Default | Notes |
| --- | --- | --- | --- |
| `time` | ISO-8601 | now | anchor time |
| `limit` | integer | 20 | 1..100 |
| `direction` | `EARLIER`/`LATER` | `LATER` | page direction |

### `GET /v1/search`

Geocoding / autocomplete for stops, places and addresses.

```
GET /v1/search?q=Warszawa%20Centralna&limit=10
```

| Param | Type | Default | Notes |
| --- | --- | --- | --- |
| `q` | string | - | required, search text |
| `limit` | integer | 10 | 1..100 |
| `types` | string | all | comma-separated `ADDRESS,PLACE,STOP` |
| `lat`, `lon` | number | - | bias results towards coordinate |

## Architecture

```
routes/            HTTP layer, request validation, Ruszaj DTOs
  ├── health.ts    GET /health
  ├── journey.ts   GET /v1/journeys
  ├── stops.ts     GET /v1/stops/nearby, /:id, /:id/departures
  └── search.ts    GET /v1/search
services/
  └── transitous.ts  only place that knows MOTIS / Transitous
types/             ruszaj-neutral DTOs shared with the Flutter client
```

The MOTIS client (`@motis-project/motis-client`) is only imported inside
`services/transitous.ts`. No route or DTO leaks upstream concepts.

## Data sources and attribution

Ruszaj's transit data is provided by
[Transitous](https://transitous.org/sources/), an open-source aggregation of
public transport schedules and realtime feeds. Transitous also makes use of
[OpenStreetMap](https://www.openstreetmap.org/copyright) data.

## Privacy

Search queries and coordinates entered by users are forwarded to the Transitous
API to compute journeys, departures and geocoding results. Transitous and its
upstream data sources receive that data. See the root README for the overall
privacy approach.

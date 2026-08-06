import { type Coordinates } from './common.js';

export type SearchResultType = 'ADDRESS' | 'PLACE' | 'STOP';

export interface SearchResult {
  id: string;
  name: string;
  type: SearchResultType;
  coordinates: Coordinates;
  level?: number;
  street?: string;
  houseNumber?: string;
  country?: string;
  zip?: string;
  tz?: string;
  modes?: string[];
  score: number;
}

export interface SearchParams {
  text: string;
  limit?: number;
  types?: SearchResultType[];
  lat?: number;
  lon?: number;
  city?: string;
}

export interface MissingPersonSighting {
  reported_by: string;
  location: string;
  timestamp: number;
  notes?: string;
  lat?: number;
  lng?: number;
}

export interface MissingPerson {
  id: string;
  name: string;
  age: number;
  gender: string;
  last_seen_location: string;
  lat?: number;
  lng?: number;
  description: string;
  photo_url?: string;
  contact_phone?: string;
  status: 'MISSING' | 'FOUND' | 'SEARCHING' | 'SIGHTED';
  reported_at: number;
  reported_by: string;
  sightings: MissingPersonSighting[];
}

export type MissingPersonStatusFilter = 'ALL' | 'MISSING' | 'FOUND';

export interface CreateMissingPersonPayload {
  name: string;
  age: number;
  gender?: string;
  last_seen_location: string;
  lat?: number;
  lng?: number;
  description?: string;
  photo_url?: string;
  contact_phone?: string;
  status?: string;
  reported_by?: string;
}

export interface CreateSightingPayload {
  reported_by?: string;
  location: string;
  timestamp?: number;
  notes?: string;
  lat?: number;
  lng?: number;
}

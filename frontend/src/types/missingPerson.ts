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
  // Disaster incident correlation & physical detection attributes
  incident_id?: string;
  incident_title?: string;
  clothing_last_seen?: string;
  height_cm?: number;
  identifying_marks?: string;
  medical_needs?: string;
  blood_group?: string;
  priority?: 'CRITICAL' | 'HIGH' | 'MEDIUM';
  assigned_team?: string;
  biometric_indexed?: boolean;
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
  incident_id?: string;
  incident_title?: string;
  clothing_last_seen?: string;
  height_cm?: number;
  identifying_marks?: string;
  medical_needs?: string;
  blood_group?: string;
  priority?: string;
  assigned_team?: string;
  biometric_indexed?: boolean;
}

export interface CreateSightingPayload {
  reported_by?: string;
  location: string;
  timestamp?: number;
  notes?: string;
  lat?: number;
  lng?: number;
}

export interface VisualMatch {
  person: MissingPerson;
  similarity_score?: number;
  score?: number;
  confidence_score?: number;
  similarity_percent?: number;
  point_id?: string;
  vector_distance?: number;
  matched_features?: string[];
  notes?: string;
}

export interface VisualSearchResult {
  success: boolean;
  query_photo_preview?: string;
  match_found?: boolean;
  top_match?: VisualMatch;
  matches: VisualMatch[];
  total_candidates_scanned?: number;
  total_matches?: number;
  engine?: string;
  search_latency_ms?: number;
}

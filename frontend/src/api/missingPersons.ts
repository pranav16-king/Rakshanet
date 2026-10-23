import { apiClient } from './client';
import type {
  MissingPerson,
  CreateMissingPersonPayload,
  CreateSightingPayload,
  VisualSearchResult,
} from '../types/missingPerson';

export async function getMissingPersons(
  status?: string,
  search?: string,
  incidentId?: string
): Promise<MissingPerson[]> {
  const params: Record<string, string> = {};
  if (status && status !== 'ALL') {
    params.status = status;
  }
  if (search && search.trim()) {
    params.search = search.trim();
  }
  if (incidentId && incidentId !== 'ALL') {
    params.incident_id = incidentId;
  }

  const response = await apiClient.get<MissingPerson[]>('/api/v1/missing-persons', {
    params,
  });
  return response.data;
}

export async function getMissingPersonById(id: string): Promise<MissingPerson> {
  const response = await apiClient.get<MissingPerson>(`/api/v1/missing-persons/${id}`);
  return response.data;
}

export async function createMissingPerson(
  payload: CreateMissingPersonPayload
): Promise<MissingPerson> {
  const response = await apiClient.post<MissingPerson>(
    '/api/v1/missing-persons',
    payload
  );
  return response.data;
}

export async function updateMissingPersonStatus(
  id: string,
  status: 'MISSING' | 'FOUND'
): Promise<MissingPerson> {
  const response = await apiClient.patch<MissingPerson>(
    `/api/v1/missing-persons/${id}/status`,
    { status }
  );
  return response.data;
}

export async function addMissingPersonSighting(
  id: string,
  payload: CreateSightingPayload
): Promise<MissingPerson> {
  const response = await apiClient.post<MissingPerson>(
    `/api/v1/missing-persons/${id}/sightings`,
    payload
  );
  return response.data;
}

export async function searchMissingPersonByPhoto(
  fileOrBase64: File | string,
  scoreThreshold: number = 0.65
): Promise<VisualSearchResult> {
  let photoBase64: string;

  if (typeof fileOrBase64 === 'string') {
    photoBase64 = fileOrBase64;
  } else {
    photoBase64 = await new Promise<string>((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = () => resolve(reader.result as string);
      reader.onerror = (e) => reject(e);
      reader.readAsDataURL(fileOrBase64);
    });
  }

  const response = await apiClient.post<VisualSearchResult>(
    '/api/v1/missing-persons/search-by-photo',
    {
      photo_base64: photoBase64,
      score_threshold: scoreThreshold,
    }
  );
  return response.data;
}


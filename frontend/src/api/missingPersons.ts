import { apiClient } from './client';
import type {
  MissingPerson,
  CreateMissingPersonPayload,
  CreateSightingPayload,
  VisualSearchResult,
} from '../types/missingPerson';

export async function getMissingPersons(
  status?: string,
  search?: string
): Promise<MissingPerson[]> {
  const params: Record<string, string> = {};
  if (status && status !== 'ALL') {
    params.status = status;
  }
  if (search && search.trim()) {
    params.search = search.trim();
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
  file: File
): Promise<VisualSearchResult> {
  const formData = new FormData();
  formData.append('file', file);

  const response = await apiClient.post<VisualSearchResult>(
    '/api/v1/missing-persons/search-by-photo',
    formData,
    {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    }
  );
  return response.data;
}


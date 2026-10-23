import { apiClient } from './client';
import type {
  Person,
  PeopleFilterTab,
  NewUserPayload,
  UserRole,
} from '../types/people';

function formatTimeAgo(timestampMs?: number): string {
  if (!timestampMs) return '2 min ago';
  const diffSec = Math.floor((Date.now() - timestampMs) / 1000);
  if (diffSec < 60) return `${Math.max(5, diffSec)}s ago`;
  const diffMin = Math.floor(diffSec / 60);
  if (diffMin < 60) return `${diffMin} min ago`;
  const diffHr = Math.floor(diffMin / 60);
  if (diffHr < 24) return `${diffHr}h ago`;
  return `${Math.floor(diffHr / 24)}d ago`;
}

export const peopleApi = {
  getPeople: async (
    filter: PeopleFilterTab = 'all',
    search: string = ''
  ): Promise<Person[]> => {
    try {
      const response = await apiClient.get<any[]>('/api/v1/users', {
        params: { search: search.trim() || undefined },
      });

      if (Array.isArray(response.data) && response.data.length > 0) {
        // Map backend database users to the rich Person model
        const mapped: Person[] = response.data.map((u, i) => {
          let roleNormalized: UserRole = 'Field User';
          const r = (u.role || '').toLowerCase();
          if (r.includes('rescue') || r.includes('commander') || r.includes('responder')) {
            roleNormalized = 'Rescue Team';
          } else if (r.includes('volunteer')) {
            roleNormalized = 'Volunteer';
          } else if (r.includes('admin') || r.includes('organizer') || r.includes('medical') || r.includes('officer')) {
            roleNormalized = 'Organizer';
          }

          const colors: Array<'blue' | 'purple' | 'teal' | 'amber' | 'rose' | 'emerald'> = [
            'blue',
            'purple',
            'teal',
            'emerald',
            'rose',
            'amber',
          ];

          return {
            id: u.id || `usr-${i}`,
            name: u.name,
            role: roleNormalized,
            location: u.location || 'Sector 4B Riverside Colony',
            lastActive: formatTimeAgo(u.last_active),
            status: (u.status === 'Active' ? 'Online' : 'Offline') as 'Online' | 'Offline',
            avatarInitial: (u.name || 'U').charAt(0).toUpperCase(),
            avatarColor: colors[i % colors.length],
            deviceId: u.device_id || `SR-${(u.id || '').replace(/[^A-Za-z0-9]/g, '').slice(-4).toUpperCase() || '8F42'}`,
            phone: u.phone || '+91 98000 00000',
            emergencyContact: {
              name: u.emergency_contact_name || 'Disaster Relief Ops Base',
              relationship: 'Command Depot',
              phone: u.emergency_contact_phone || '+91 98000 11000',
            },
            medicalDetails: {
              bloodType: u.blood_type || 'O+',
              allergies: u.allergies ? (Array.isArray(u.allergies) ? u.allergies : [u.allergies]) : ['None'],
              chronicConditions: [],
              triageNotes: u.triage_notes || 'Registered disaster operational personnel',
              lastUpdated: '15 min ago',
            },
            isAuthorized: false,
          };
        });

        // Filter by tab
        let filtered = mapped;
        if (filter === 'field_users') {
          filtered = filtered.filter((p) => p.role === 'Field User');
        } else if (filter === 'rescue_teams') {
          filtered = filtered.filter((p) => p.role === 'Rescue Team');
        } else if (filter === 'volunteers') {
          filtered = filtered.filter((p) => p.role === 'Volunteer');
        } else if (filter === 'organizers') {
          filtered = filtered.filter((p) => p.role === 'Organizer');
        }

        if (search.trim()) {
          const q = search.toLowerCase();
          filtered = filtered.filter(
            (p) =>
              p.name.toLowerCase().includes(q) ||
              p.location.toLowerCase().includes(q) ||
              p.role.toLowerCase().includes(q) ||
              (p.deviceId && p.deviceId.toLowerCase().includes(q))
          );
        }

        return filtered;
      }
    } catch {
      // API unavailable — return empty list
      return [];
    }

    return [];
  },

  addPerson: async (payload: NewUserPayload): Promise<Person> => {
    const response = await apiClient.post<any>('/api/v1/users', {
      name: payload.name,
      role: payload.role,
      location: payload.location,
      agency: `${payload.role} Division`,
      phone: payload.phone,
      email: `${payload.name.toLowerCase().replace(/[^a-z0-9]/g, '.')}@field.rakshanet.org`,
    });
    const created = response.data;
    const newPerson: Person = {
      id: created.id || `usr-${Date.now()}`,
      name: created.name || payload.name,
      role: payload.role,
      location: payload.location,
      lastActive: 'Just now',
      status: 'Online',
      avatarInitial: payload.name.charAt(0).toUpperCase() || 'U',
      avatarColor: 'teal',
      deviceId: created.device_id || `SR-${Math.random().toString(36).substring(2, 6).toUpperCase()}`,
      phone: payload.phone,
      emergencyContact: {
        name: payload.emergencyContactName,
        relationship: payload.emergencyContactRelation,
        phone: payload.emergencyContactPhone,
      },
      medicalDetails: {
        bloodType: payload.bloodType || 'Unknown',
        allergies: payload.allergies ? payload.allergies.split(',').map((s) => s.trim()) : [],
        chronicConditions: [],
        triageNotes: payload.triageNotes || 'Standard field triage registration',
        lastUpdated: 'Just now',
      },
      isAuthorized: false,
    };
    return newPerson;
  },

  toggleAuthorization: async (personId: string, authorize: boolean): Promise<Person | null> => {
    const response = await apiClient.patch<any>(`/api/v1/users/${personId}`, {
      is_authorized: authorize,
    });
    return response.data ?? null;
  },
};

export default peopleApi;

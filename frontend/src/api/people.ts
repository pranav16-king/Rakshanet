import { apiClient } from './client';
import type {
  Person,
  PeopleFilterTab,
  NewUserPayload,
  UserRole,
} from '../types/people';

const INITIAL_PEOPLE: Person[] = [
  {
    id: 'usr-001',
    name: 'Amit Kumar',
    role: 'Field User',
    location: 'Sector 4B Riverside Colony',
    lastActive: '2 min ago',
    status: 'Online',
    avatarInitial: 'A',
    avatarColor: 'blue',
    deviceId: 'SR-8F42',
    phone: '+91 98765 43210',
    emergencyContact: {
      name: 'Sunita Kumar',
      relationship: 'Spouse',
      phone: '+91 98765 89201',
    },
    medicalDetails: {
      bloodType: 'B+',
      allergies: ['Dust mites', 'Penicillin'],
      chronicConditions: ['Asthma (uses inhaler)'],
      triageNotes: 'Trapped on upper floor with family; supplies needed.',
      lastUpdated: '10 min ago',
    },
    isAuthorized: false,
  },
  {
    id: 'usr-002',
    name: 'Priya Sharma',
    role: 'Field User',
    location: 'Sector 4B Riverside Colony',
    lastActive: '5 min ago',
    status: 'Online',
    avatarInitial: 'P',
    avatarColor: 'purple',
    deviceId: 'SR-9A1C',
    phone: '+91 98111 22334',
    emergencyContact: {
      name: 'Rajesh Sharma',
      relationship: 'Brother',
      phone: '+91 98111 77665',
    },
    medicalDetails: {
      bloodType: 'O+',
      allergies: ['Sulfa drugs'],
      chronicConditions: ['None'],
      triageNotes: 'Sheltered in high school auditorium with 14 villagers.',
      lastUpdated: '20 min ago',
    },
    isAuthorized: false,
  },
  {
    id: 'usr-003',
    name: 'Rahul Mehta',
    role: 'Volunteer',
    location: 'NH-48 Mountain Pass km 74',
    lastActive: '10 min ago',
    status: 'Online',
    avatarInitial: 'R',
    avatarColor: 'teal',
    deviceId: 'SR-3D7B',
    phone: '+91 97234 56789',
    emergencyContact: {
      name: 'Kavita Mehta',
      relationship: 'Parent',
      phone: '+91 97234 11223',
    },
    medicalDetails: {
      bloodType: 'A+',
      allergies: ['None'],
      chronicConditions: ['None'],
      triageNotes: 'Volunteer route scout for Sector 3 landslides.',
      lastUpdated: '1 hour ago',
    },
    isAuthorized: false,
  },
  {
    id: 'usr-004',
    name: 'Sneha Patel',
    role: 'Field User',
    location: 'Industrial Park Gate 3',
    lastActive: '15 min ago',
    status: 'Offline',
    avatarInitial: 'S',
    avatarColor: 'rose',
    deviceId: 'SR-6E2F',
    phone: '+91 99001 12233',
    emergencyContact: {
      name: 'Dev Patel',
      relationship: 'Spouse',
      phone: '+91 99001 99887',
    },
    medicalDetails: {
      bloodType: 'AB+',
      allergies: ['Latex'],
      chronicConditions: ['Type 1 Diabetes (requires insulin)'],
      triageNotes: 'Urgent medical aid requested: low insulin supply.',
      lastUpdated: '15 min ago',
    },
    isAuthorized: false,
  },
  {
    id: 'usr-005',
    name: 'Vikram Singh',
    role: 'Rescue Team',
    location: 'Sector 4B Riverside Colony',
    lastActive: '18 min ago',
    status: 'Online',
    avatarInitial: 'V',
    avatarColor: 'emerald',
    deviceId: 'SR-7G9H',
    phone: '+91 94120 99887',
    emergencyContact: {
      name: 'NDRF Base Station 04',
      relationship: 'Unit HQ',
      phone: '+91 94120 11000',
    },
    medicalDetails: {
      bloodType: 'O+',
      allergies: ['None'],
      chronicConditions: ['None'],
      triageNotes: 'First Responder & Tactical Medic certified.',
      lastUpdated: '2 hours ago',
    },
    isAuthorized: false,
  },
  {
    id: 'usr-006',
    name: 'Ananya Gupta',
    role: 'Organizer',
    location: 'Guindy Metro Relief Shelter',
    lastActive: '25 min ago',
    status: 'Online',
    avatarInitial: 'A',
    avatarColor: 'amber',
    deviceId: 'SR-5L8P',
    phone: '+91 98990 44556',
    emergencyContact: {
      name: 'Alok Gupta',
      relationship: 'Partner',
      phone: '+91 98990 88990',
    },
    medicalDetails: {
      bloodType: 'A-',
      allergies: ['None'],
      chronicConditions: ['None'],
      triageNotes: 'Emergency relief shelter coordinator.',
      lastUpdated: '3 hours ago',
    },
    isAuthorized: false,
  },
  {
    id: 'usr-007',
    name: 'Dr. Farooq Sheikh',
    role: 'Volunteer',
    location: 'South Market Commercial Plaza',
    lastActive: '45 min ago',
    status: 'Offline',
    avatarInitial: 'F',
    avatarColor: 'purple',
    deviceId: 'SR-1B9Q',
    phone: '+91 98332 11445',
    emergencyContact: {
      name: 'Amina Sheikh',
      relationship: 'Spouse',
      phone: '+91 98332 99001',
    },
    medicalDetails: {
      bloodType: 'B+',
      allergies: ['None'],
      chronicConditions: ['None'],
      triageNotes: 'Volunteer General Physician supporting triage outpost.',
      lastUpdated: '4 hours ago',
    },
    isAuthorized: false,
  },
  {
    id: 'usr-008',
    name: 'Capt. Vikram Sengupta',
    role: 'Rescue Team',
    location: 'Sector 4B Riverside Colony',
    lastActive: '4 min ago',
    status: 'Online',
    avatarInitial: 'V',
    avatarColor: 'emerald',
    deviceId: 'SR-99D1',
    phone: '+91 98111 22334',
    emergencyContact: {
      name: 'NDRF 4th Battalion Operations',
      relationship: 'HQ Command',
      phone: '+91 98111 00004',
    },
    medicalDetails: {
      bloodType: 'A+',
      allergies: ['None'],
      chronicConditions: ['None'],
      triageNotes: 'NDRF Field Commander, Boat 01 Deployment.',
      lastUpdated: '30 min ago',
    },
    isAuthorized: false,
  },
  {
    id: 'usr-009',
    name: 'Dr. Sunita Rao',
    role: 'Organizer',
    location: 'Guindy Metro Relief Shelter',
    lastActive: '8 min ago',
    status: 'Online',
    avatarInitial: 'S',
    avatarColor: 'teal',
    deviceId: 'SR-71A2',
    phone: '+91 98222 33445',
    emergencyContact: {
      name: 'Emergency Medical Corps Director',
      relationship: 'Hospital Command',
      phone: '+91 98222 11000',
    },
    medicalDetails: {
      bloodType: 'O+',
      allergies: ['None'],
      chronicConditions: ['None'],
      triageNotes: 'Chief Medical Officer at central relief shelter.',
      lastUpdated: '15 min ago',
    },
    isAuthorized: false,
  },
  {
    id: 'usr-010',
    name: 'Insp. Anita Deshmukh',
    role: 'Rescue Team',
    location: 'South Market Commercial Plaza',
    lastActive: '12 min ago',
    status: 'Online',
    avatarInitial: 'A',
    avatarColor: 'rose',
    deviceId: 'SR-4C21',
    phone: '+91 98333 44556',
    emergencyContact: {
      name: 'SDRF Base HQ',
      relationship: 'Command Depot',
      phone: '+91 98333 11000',
    },
    medicalDetails: {
      bloodType: 'B+',
      allergies: ['None'],
      chronicConditions: ['None'],
      triageNotes: 'SDRF Structural Collapse & Extrication Lead.',
      lastUpdated: '45 min ago',
    },
    isAuthorized: false,
  },
  {
    id: 'usr-011',
    name: 'Deepa K.',
    role: 'Volunteer',
    location: 'Kovalam Coast Sector 1',
    lastActive: '14 min ago',
    status: 'Online',
    avatarInitial: 'D',
    avatarColor: 'amber',
    deviceId: 'SR-1A09',
    phone: '+91 98444 55667',
    emergencyContact: {
      name: 'Coastal Volunteer Union',
      relationship: 'Relief Post',
      phone: '+91 98444 00000',
    },
    medicalDetails: {
      bloodType: 'O+',
      allergies: ['None'],
      chronicConditions: ['None'],
      triageNotes: 'Coastal storm surge warning relay volunteer.',
      lastUpdated: '25 min ago',
    },
    isAuthorized: false,
  },
];

let localPeople = [...INITIAL_PEOPLE];

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
    } catch (err) {
      // Fallback to localPeople
    }

    let filtered = [...localPeople];

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
  },

  addPerson: async (payload: NewUserPayload): Promise<Person> => {
    try {
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
        deviceId: `SR-${Math.random().toString(36).substring(2, 6).toUpperCase()}`,
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
      localPeople = [newPerson, ...localPeople];
      return newPerson;
    } catch {
      const newPerson: Person = {
        id: `usr-${Date.now()}`,
        name: payload.name,
        role: payload.role,
        location: payload.location,
        lastActive: 'Just now',
        status: 'Online',
        avatarInitial: payload.name.charAt(0).toUpperCase() || 'U',
        avatarColor: 'teal',
        deviceId: `SR-${Math.random().toString(36).substring(2, 6).toUpperCase()}`,
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
      localPeople = [newPerson, ...localPeople];
      return newPerson;
    }
  },

  toggleAuthorization: (personId: string, authorize: boolean): Person | undefined => {
    const person = localPeople.find((p) => p.id === personId);
    if (person) {
      person.isAuthorized = authorize;
    }
    return person;
  },
};

export default peopleApi;

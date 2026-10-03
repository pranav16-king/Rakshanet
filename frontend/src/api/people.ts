import { apiClient } from './client';
import type {
  Person,
  PeopleFilterTab,
  NewUserPayload,
} from '../types/people';

const INITIAL_PEOPLE: Person[] = [
  {
    id: 'usr-001',
    name: 'Amit Kumar',
    role: 'Field User',
    location: 'Uttarakhand',
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
    location: 'Uttarakhand',
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
    location: 'Himachal Pradesh',
    lastActive: '10 min ago',
    status: 'Offline',
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
    location: 'Delhi',
    lastActive: '15 min ago',
    status: 'Online',
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
    location: 'Uttarakhand',
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
    location: 'Delhi',
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
    location: 'Himachal Pradesh',
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
];

let localPeople = [...INITIAL_PEOPLE];

export const peopleApi = {
  getPeople: async (
    filter: PeopleFilterTab = 'all',
    search: string = ''
  ): Promise<Person[]> => {
    try {
      const response = await apiClient.get<Person[]>('/people', {
        params: { filter, search },
      });
      return response.data;
    } catch {
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
    }
  },

  addPerson: async (payload: NewUserPayload): Promise<Person> => {
    try {
      const response = await apiClient.post<Person>('/people', payload);
      return response.data;
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

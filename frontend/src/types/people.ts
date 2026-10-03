export type UserRole = 'Field User' | 'Rescue Team' | 'Volunteer' | 'Organizer';

export type UserStatus = 'Online' | 'Offline';

export type PeopleFilterTab = 'all' | 'field_users' | 'rescue_teams' | 'volunteers' | 'organizers';

export interface MedicalDetails {
  bloodType: string;
  allergies: string[];
  chronicConditions: string[];
  triageNotes: string;
  lastUpdated: string;
}

export interface Person {
  id: string;
  name: string;
  role: UserRole;
  location: string;
  lastActive: string;
  status: UserStatus;
  avatarInitial: string;
  avatarColor: 'blue' | 'purple' | 'teal' | 'amber' | 'rose' | 'emerald';
  deviceId?: string;
  phone: string;
  emergencyContact: {
    name: string;
    relationship: string;
    phone: string;
  };
  medicalDetails: MedicalDetails;
  isAuthorized?: boolean; // Controls client-side privacy unmasking for the session
}

export interface NewUserPayload {
  name: string;
  role: UserRole;
  location: string;
  phone: string;
  emergencyContactName: string;
  emergencyContactRelation: string;
  emergencyContactPhone: string;
  bloodType: string;
  allergies: string;
  triageNotes: string;
}

export type UserRole = 'ADMIN' | 'COORDINATOR' | 'FIELD_RESPONDER' | 'VOLUNTEER' | 'DISPATCHER';

export type UserStatus = 'ONLINE' | 'ACTIVE' | 'OFFLINE' | 'DEPLOYED';

export interface User {
  id: string;
  email: string;
  name: string;
  role: UserRole;
  organization?: string;
  phone?: string;
  avatarUrl?: string;
  status: UserStatus;
  lastActive: string;
  location?: {
    lat: number;
    lng: number;
    region?: string;
  };
  createdAt: string;
}

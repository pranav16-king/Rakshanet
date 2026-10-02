export interface UserProfile {
  id: string;
  name: string;
  preferredLanguage: string;
  age?: number;
  bloodGroup?: string;
  emergencyContact?: string;
  medicalNotes?: string;
  createdAt: number;
  updatedAt: number;
}

export interface DeviceIdentity {
  id: string;
  deviceId: string; // e.g. "SR-8F42-A91C"
  publicKey: string; // Ed25519 public key hex
  privateKeyRef: string; // Reference in Android Keystore / encrypted storage
  createdAt: number;
}

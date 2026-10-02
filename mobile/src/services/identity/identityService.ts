import { profileRepository } from '@/database/repositories/profileRepository';
import { DeviceIdentity } from '@/types/profile';

export class IdentityService {
  private currentIdentity: DeviceIdentity | null = null;

  public async getOrGenerateIdentity(): Promise<DeviceIdentity> {
    if (this.currentIdentity) {
      return this.currentIdentity;
    }

    const saved = await profileRepository.getDeviceIdentity();
    if (saved) {
      this.currentIdentity = saved;
      return saved;
    }

    // Generate anonymous hardware-independent ID
    const randomHex = () => Math.random().toString(16).substring(2, 6).toUpperCase();
    const deviceId = `SR-${randomHex()}-${randomHex()}`;

    // Pseudorandom Ed25519 placeholder for Phase 1
    const publicKey = Array.from({ length: 64 }, () => Math.floor(Math.random() * 16).toString(16)).join('');
    const privateKeyRef = `keystore_ref_${Date.now()}`;

    const newIdentity: DeviceIdentity = {
      id: `ident_${Date.now()}`,
      deviceId,
      publicKey,
      privateKeyRef,
      createdAt: Date.now(),
    };

    await profileRepository.saveDeviceIdentity(newIdentity);
    this.currentIdentity = newIdentity;
    return newIdentity;
  }
}

export const identityService = new IdentityService();

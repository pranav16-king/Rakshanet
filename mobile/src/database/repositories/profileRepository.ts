import { dbManager } from '../sqlite';
import { UserProfile, DeviceIdentity } from '@/types/profile';

export class ProfileRepository {
  public async getProfile(): Promise<UserProfile | null> {
    const table = dbManager.getMockTable('user_profile');
    return table.length > 0 ? table[0] : null;
  }

  public async saveProfile(profile: UserProfile): Promise<void> {
    const table = dbManager.getMockTable('user_profile');
    const existingIndex = table.findIndex((p: UserProfile) => p.id === profile.id);
    if (existingIndex >= 0) {
      table[existingIndex] = profile;
    } else {
      table.push(profile);
    }
    dbManager.setMockTable('user_profile', table);
  }

  public async getDeviceIdentity(): Promise<DeviceIdentity | null> {
    const table = dbManager.getMockTable('device_identity');
    return table.length > 0 ? table[0] : null;
  }

  public async saveDeviceIdentity(identity: DeviceIdentity): Promise<void> {
    const table = dbManager.getMockTable('device_identity');
    const existingIndex = table.findIndex((i: DeviceIdentity) => i.id === identity.id);
    if (existingIndex >= 0) {
      table[existingIndex] = identity;
    } else {
      table.push(identity);
    }
    dbManager.setMockTable('device_identity', table);
  }
}

export const profileRepository = new ProfileRepository();

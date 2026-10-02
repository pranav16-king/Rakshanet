import { create } from 'zustand';
import { UserProfile, DeviceIdentity } from '@/types/profile';
import { profileRepository } from '@/database/repositories/profileRepository';
import { identityService } from '@/services/identity/identityService';

interface ProfileState {
  profile: UserProfile | null;
  identity: DeviceIdentity | null;
  isOnboarded: boolean;
  loadProfile: () => Promise<void>;
  saveProfile: (name: string, preferredLanguage?: string) => Promise<void>;
}

export const useProfileStore = create<ProfileState>((set, get) => ({
  profile: null,
  identity: null,
  isOnboarded: false,

  loadProfile: async () => {
    const profile = await profileRepository.getProfile();
    const identity = await identityService.getOrGenerateIdentity();
    set({
      profile,
      identity,
      isOnboarded: !!profile && profile.name.trim().length > 0,
    });
  },

  saveProfile: async (name: string, preferredLanguage = 'en') => {
    const existing = get().profile;
    const now = Date.now();
    const updated: UserProfile = {
      id: existing?.id || `usr_${now}`,
      name,
      preferredLanguage,
      createdAt: existing?.createdAt || now,
      updatedAt: now,
    };

    await profileRepository.saveProfile(updated);
    const identity = await identityService.getOrGenerateIdentity();
    set({
      profile: updated,
      identity,
      isOnboarded: true,
    });
  },
}));

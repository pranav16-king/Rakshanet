import { create } from 'zustand';
import type { User } from '../types';
import apiClient from '../api/client';

interface AuthStoreState {
  user: User | null;
  token: string | null;
  isAuthenticated: boolean;
  isInitializing: boolean;
  isLoading: boolean;
  error: string | null;
  login: (email: string, password: string, rememberMe?: boolean) => Promise<boolean>;
  logout: () => void;
  checkAuth: () => Promise<void>;
  clearError: () => void;
}

const TOKEN_KEY = 'rakshanet_token';
const USER_KEY = 'rakshanet_user';

export const useAuthStore = create<AuthStoreState>((set) => {
  // Listen for 401 unauthorized events dispatched by apiClient
  if (typeof window !== 'undefined') {
    window.addEventListener('auth:unauthorized', () => {
      localStorage.removeItem(TOKEN_KEY);
      localStorage.removeItem(USER_KEY);
      sessionStorage.removeItem(TOKEN_KEY);
      sessionStorage.removeItem(USER_KEY);
      set({
        user: null,
        token: null,
        isAuthenticated: false,
        isInitializing: false,
        error: 'Session expired or invalid. Please sign in.',
      });
    });
  }

  const existingToken = typeof window !== 'undefined' 
    ? (localStorage.getItem(TOKEN_KEY) || sessionStorage.getItem(TOKEN_KEY))
    : null;

  return {
    user: null,
    token: existingToken,
    isAuthenticated: false,
    isInitializing: true,
    isLoading: false,
    error: null,

    login: async (email: string, password: string, rememberMe: boolean = true) => {
      set({ isLoading: true, error: null });
      try {
        const response = await apiClient.post<{ 
          access_token?: string; 
          token?: string; 
          token_type?: string; 
          user: User 
        }>('/api/v1/auth/login', {
          email: email.trim(),
          password,
        });

        const authToken = response.data.access_token || response.data.token;
        const authUser = response.data.user;

        if (!authToken) {
          throw new Error('No access token returned from backend gateway');
        }

        if (rememberMe) {
          localStorage.setItem(TOKEN_KEY, authToken);
          localStorage.setItem(USER_KEY, JSON.stringify(authUser));
          sessionStorage.removeItem(TOKEN_KEY);
          sessionStorage.removeItem(USER_KEY);
        } else {
          sessionStorage.setItem(TOKEN_KEY, authToken);
          sessionStorage.setItem(USER_KEY, JSON.stringify(authUser));
          localStorage.removeItem(TOKEN_KEY);
          localStorage.removeItem(USER_KEY);
        }

        set({
          user: authUser,
          token: authToken,
          isAuthenticated: true,
          isLoading: false,
          error: null,
        });
        return true;
      } catch (err: any) {
        const detail = err?.response?.data?.detail;
        const message = typeof detail === 'string' 
          ? detail 
          : err instanceof Error 
            ? err.message 
            : 'Invalid credentials. Please verify your email and password.';
        set({
          error: message,
          isLoading: false,
          isAuthenticated: false,
        });
        return false;
      }
    },

    logout: () => {
      localStorage.removeItem(TOKEN_KEY);
      localStorage.removeItem(USER_KEY);
      sessionStorage.removeItem(TOKEN_KEY);
      sessionStorage.removeItem(USER_KEY);
      set({
        user: null,
        token: null,
        isAuthenticated: false,
        isInitializing: false,
        error: null,
      });
    },

    checkAuth: async () => {
      const token = typeof window !== 'undefined'
        ? (localStorage.getItem(TOKEN_KEY) || sessionStorage.getItem(TOKEN_KEY))
        : null;

      if (!token) {
        set({
          user: null,
          token: null,
          isAuthenticated: false,
          isInitializing: false,
        });
        return;
      }

      try {
        const response = await apiClient.get<User>('/api/v1/auth/me', {
          headers: { Authorization: `Bearer ${token}` }
        });
        set({
          user: response.data,
          token,
          isAuthenticated: true,
          isInitializing: false,
        });
      } catch (err) {
        // Token is invalid or expired
        localStorage.removeItem(TOKEN_KEY);
        localStorage.removeItem(USER_KEY);
        sessionStorage.removeItem(TOKEN_KEY);
        sessionStorage.removeItem(USER_KEY);
        set({
          user: null,
          token: null,
          isAuthenticated: false,
          isInitializing: false,
        });
      }
    },

    clearError: () => set({ error: null }),
  };
});

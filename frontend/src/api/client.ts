import axios from 'axios';
import type { AxiosError, InternalAxiosRequestConfig } from 'axios';

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000';

export const apiClient = axios.create({
  baseURL: API_BASE_URL,
  timeout: 15000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor to attach Bearer token
apiClient.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    const token = localStorage.getItem('signalrescue_token') || sessionStorage.getItem('signalrescue_token');
    if (token && config.headers) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error: AxiosError) => Promise.reject(error)
);

// Response interceptor to catch 401 Unauthorized
apiClient.interceptors.response.use(
  (response) => response,
  (error: AxiosError) => {
    if (error.response && error.response.status === 401) {
      // Clear credentials
      localStorage.removeItem('signalrescue_token');
      localStorage.removeItem('signalrescue_user');
      sessionStorage.removeItem('signalrescue_token');
      sessionStorage.removeItem('signalrescue_user');

      // Dispatch custom event for authStore to react without circular imports
      window.dispatchEvent(new CustomEvent('auth:unauthorized'));

      // Redirect to login if not already on login or landing page
      const currentPath = window.location.pathname;
      if (currentPath !== '/auth/login' && currentPath !== '/') {
        window.location.href = '/auth/login';
      }
    }
    return Promise.reject(error);
  }
);

export default apiClient;

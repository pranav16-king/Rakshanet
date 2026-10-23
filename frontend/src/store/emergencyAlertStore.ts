import { create } from 'zustand';

export interface EmergencyAlertItem {
  id: string;
  senderName: string;
  senderId?: string;
  coordinates: { lat: number; lng: number } | null;
  urgency: string;
  timestamp: number;
  hops?: number;
  payload?: string;
  fixType?: string;
}

interface EmergencyAlertState {
  alerts: EmergencyAlertItem[];
  latestSos: EmergencyAlertItem | null;
  addAlert: (alert: Omit<EmergencyAlertItem, 'id' | 'timestamp'> & { id?: string; timestamp?: number }) => void;
  dismissAlert: (id: string) => void;
  clearAlerts: () => void;
}

// Gentle audio alert synthesizer for emergency dispatch
function triggerEmergencyAudio() {
  try {
    if (typeof window === 'undefined') return;
    const AudioCtx = window.AudioContext || (window as any).webkitAudioContext;
    if (!AudioCtx) return;
    const ctx = new AudioCtx();
    if (ctx.state === 'suspended') {
      ctx.resume().catch(() => {});
    }

    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = 'triangle';
    osc.frequency.setValueAtTime(880, ctx.currentTime); // A5
    osc.frequency.exponentialRampToValueAtTime(440, ctx.currentTime + 0.3); // drop to A4

    gain.gain.setValueAtTime(0.2, ctx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.35);

    osc.connect(gain);
    gain.connect(ctx.destination);

    osc.start(ctx.currentTime);
    osc.stop(ctx.currentTime + 0.35);
  } catch {
    // AudioContext blocked or not supported - silent fallback
  }
}

export const useEmergencyAlertStore = create<EmergencyAlertState>((set) => ({
  alerts: [],
  latestSos: null,
  addAlert: (alertData) => {
    const alert: EmergencyAlertItem = {
      ...alertData,
      id: alertData.id || `sos-${Date.now()}-${Math.random().toString(36).substring(2, 7)}`,
      timestamp: alertData.timestamp || Date.now(),
    };

    triggerEmergencyAudio();

    set((state) => ({
      alerts: [alert, ...state.alerts.slice(0, 9)], // keep last 10 alerts
      latestSos: alert,
    }));
  },
  dismissAlert: (id) =>
    set((state) => ({
      alerts: state.alerts.filter((a) => a.id !== id),
      latestSos: state.latestSos?.id === id ? null : state.latestSos,
    })),
  clearAlerts: () => set({ alerts: [], latestSos: null }),
}));

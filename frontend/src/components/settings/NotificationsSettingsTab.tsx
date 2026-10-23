// src/components/settings/NotificationsSettingsTab.tsx
import React, { useState } from 'react';
import type { SystemSettings } from '../../types';
import { SettingsToggleRow } from './SettingsToggleRow';
import {
  Bell,
  Volume2,
  Flame,
  Smartphone,
  Radio,
  VolumeX,
  Play,
  ShieldAlert,
  Sparkles,
} from 'lucide-react';

interface NotificationsSettingsTabProps {
  settings: SystemSettings;
  onChange: (updated: Partial<SystemSettings>) => void;
}

export const NotificationsSettingsTab: React.FC<NotificationsSettingsTabProps> = ({
  settings,
  onChange,
}) => {
  const notif = settings.notifications || {
    criticalSosAudio: true,
    visualBeaconPulse: true,
    blackHoleSound: true,
    pushRelayHandoff: false,
  };

  const anomalies = settings.anomalies || {
    black_hole_detection: true,
    critical_drop_pct: 75.0,
    warning_drop_pct: 45.0,
  };

  const broadcast = settings.emergency_broadcast || {
    cap_auto_broadcast: true,
    sachet_ndma_integration: true,
  };

  const updateNotif = (updated: Partial<typeof notif>) => {
    onChange({
      notifications: { ...notif, ...updated },
    });
  };

  const updateBroadcast = (updated: Partial<typeof broadcast>) => {
    onChange({
      emergency_broadcast: { ...broadcast, ...updated },
    });
  };

  const updateAnomalies = (updated: Partial<typeof anomalies>) => {
    onChange({
      anomalies: { ...anomalies, ...updated },
    });
  };

  // Safe Web Audio API diagnostic tester
  const [isPlayingTestTone, setIsPlayingTestTone] = useState<boolean>(false);
  const [volume, setVolume] = useState<number>(0.6);
  const [isStrobing, setIsStrobing] = useState<boolean>(false);

  const playTestSiren = () => {
    try {
      const AudioCtx = window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
      if (!AudioCtx) return;
      const ctx = new AudioCtx();
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();

      osc.type = 'sawtooth';
      osc.frequency.setValueAtTime(880, ctx.currentTime);
      osc.frequency.exponentialRampToValueAtTime(440, ctx.currentTime + 0.6);
      osc.frequency.exponentialRampToValueAtTime(880, ctx.currentTime + 1.2);

      gain.gain.setValueAtTime(volume * 0.15, ctx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 1.25);

      osc.connect(gain);
      gain.connect(ctx.destination);

      setIsPlayingTestTone(true);
      osc.start();
      osc.stop(ctx.currentTime + 1.25);
      setTimeout(() => {
        setIsPlayingTestTone(false);
        ctx.close();
      }, 1300);
    } catch (e) {
      console.warn('Audio test tone could not be played:', e);
      setIsPlayingTestTone(false);
    }
  };

  const testVisualStrobe = () => {
    setIsStrobing(true);
    setTimeout(() => setIsStrobing(false), 2400);
  };

  return (
    <div className={`space-y-6 ${isStrobing ? 'ring-4 ring-[#D92D20] ring-inset animate-pulse rounded-2xl' : ''}`}>
      {/* 1. Emergency Audio-Visual Triggers */}
      <div className="p-5 sm:p-6 rounded-2xl border border-slate-200 dark:border-[#26344F] bg-white dark:bg-[#162036] shadow-sm space-y-4">
        <div className="flex items-center gap-2.5 pb-3 border-b border-slate-100 dark:border-slate-800">
          <div className="p-2 rounded-xl bg-red-400/15 text-red-600 dark:text-red-400">
            <Volume2 className="w-5 h-5" />
          </div>
          <div>
            <h3 className="text-sm sm:text-base font-bold text-slate-900 dark:text-white uppercase tracking-wider">
              Emergency Dispatch Notifications &amp; Alarms
            </h3>
            <p className="text-xs text-slate-500 dark:text-[#9FADC2]">
              Acoustic alarms, strobe beacons, and critical disaster alerts for active dispatch consoles.
            </p>
          </div>
        </div>

        <div className="space-y-1">
          <SettingsToggleRow
            label="Critical SOS Audible Alarm"
            description="Plays loud acoustic emergency beacon in Command Center upon receiving Life-Threatening SOS distress."
            checked={Boolean(notif.criticalSosAudio)}
            onChange={(checked) => updateNotif({ criticalSosAudio: checked })}
            icon={<Volume2 className="w-4 h-4 text-red-500" />}
            badge="P1 Alert"
          />

          <SettingsToggleRow
            label="Visual High-Visibility Beacon Strobe"
            description="Flashes console viewport perimeter in Signal Red (#D92D20) when unassigned critical tickets appear."
            checked={Boolean(notif.visualBeaconPulse)}
            onChange={(checked) => updateNotif({ visualBeaconPulse: checked })}
            icon={<Flame className="w-4 h-4 text-amber-500" />}
            badge="Hi-Vis Strobe"
          />

          <SettingsToggleRow
            label="Black Hole Sector Telemetry Drop Alarm"
            description="Audible alert whenever an active disaster sector drops >75% of incoming packet traffic."
            checked={Boolean(anomalies.black_hole_detection ?? notif.blackHoleSound)}
            onChange={(checked) => {
              updateAnomalies({ black_hole_detection: checked });
              updateNotif({ blackHoleSound: checked });
            }}
            icon={<Bell className="w-4 h-4 text-cyan-500" />}
            badge="DBSCAN Anomaly"
          />

          <SettingsToggleRow
            label="Relay Mules Push Notifications"
            description="Audible ping when moving pedestrian or vehicle data mules successfully offload buffered packets to gateway."
            checked={Boolean(notif.pushRelayHandoff)}
            onChange={(checked) => updateNotif({ pushRelayHandoff: checked })}
            icon={<Smartphone className="w-4 h-4 text-emerald-500" />}
          />
        </div>
      </div>

      {/* 2. Public Alert Interoperability (CAP 1.2 & NDMA Sachet) */}
      <div className="p-5 sm:p-6 rounded-2xl border border-slate-200 dark:border-[#26344F] bg-white dark:bg-[#162036] shadow-sm space-y-4">
        <div className="flex items-center gap-2.5 pb-3 border-b border-slate-100 dark:border-slate-800">
          <div className="p-2 rounded-xl bg-amber-400/15 text-amber-600 dark:text-amber-400">
            <Radio className="w-5 h-5" />
          </div>
          <div>
            <h3 className="text-sm sm:text-base font-bold text-slate-900 dark:text-white uppercase tracking-wider">
              National Emergency Alert Interoperability
            </h3>
            <p className="text-xs text-slate-500 dark:text-[#9FADC2]">
              Common Alerting Protocol (OASIS CAP 1.2) XML feeds and NDMA Sachet civil defense synchronization.
            </p>
          </div>
        </div>

        <div className="space-y-1">
          <SettingsToggleRow
            label="Auto-Broadcast OASIS CAP 1.2 XML Feed"
            description="Automatically generate and publish standard CAP v1.2 XML alert feeds on verified multi-node clusters."
            checked={Boolean(broadcast.cap_auto_broadcast)}
            onChange={(checked) => updateBroadcast({ cap_auto_broadcast: checked })}
            icon={<Radio className="w-4 h-4 text-amber-500" />}
            badge="CAP 1.2 XML"
          />

          <SettingsToggleRow
            label="NDMA Sachet National Disaster Gateway Sync"
            description="Stream verified disaster incidents to NDMA Sachet portal for national television, radio, and SMS broadcast."
            checked={Boolean(broadcast.sachet_ndma_integration)}
            onChange={(checked) => updateBroadcast({ sachet_ndma_integration: checked })}
            icon={<ShieldAlert className="w-4 h-4 text-red-500" />}
            badge="NDMA Sachet"
          />
        </div>
      </div>

      {/* 3. Diagnostic Sound & Strobe Tester */}
      <div className="p-5 sm:p-6 rounded-2xl border border-slate-200 dark:border-[#26344F] bg-white dark:bg-[#162036] shadow-sm space-y-4">
        <div className="flex items-center gap-2.5 pb-3 border-b border-slate-100 dark:border-slate-800">
          <div className="p-2 rounded-xl bg-emerald-400/15 text-emerald-600 dark:text-emerald-400">
            <Sparkles className="w-5 h-5" />
          </div>
          <div>
            <h3 className="text-sm sm:text-base font-bold text-slate-900 dark:text-white uppercase tracking-wider">
              Hardware &amp; Audio Alarm Diagnostic Check
            </h3>
            <p className="text-xs text-slate-500 dark:text-[#9FADC2]">
              Safely test console speakers and high-visibility perimeter strobe without generating fake distress events.
            </p>
          </div>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div className="p-4 rounded-xl bg-slate-50 dark:bg-[#0E1627] border border-slate-200/80 dark:border-slate-800 space-y-3">
            <div className="flex items-center justify-between">
              <span className="text-xs font-bold text-slate-900 dark:text-white flex items-center gap-1.5">
                <Volume2 className="w-4 h-4 text-red-500" />
                Console Acoustic Siren Test
              </span>
              <span className="text-xs font-mono font-bold text-slate-500 dark:text-slate-400">
                {Math.round(volume * 100)}% Vol
              </span>
            </div>
            <div className="flex items-center gap-2">
              <VolumeX className="w-3.5 h-3.5 text-slate-400" />
              <input
                type="range"
                min={0.1}
                max={1.0}
                step={0.05}
                value={volume}
                onChange={(e) => setVolume(parseFloat(e.target.value))}
                className="w-full accent-[#FFC400] dark:accent-[#FFD21F] cursor-pointer"
              />
              <Volume2 className="w-3.5 h-3.5 text-slate-400" />
            </div>
            <button
              type="button"
              onClick={playTestSiren}
              disabled={isPlayingTestTone}
              className={`w-full py-2 px-3 rounded-xl text-xs font-bold transition flex items-center justify-center gap-2 cursor-pointer ${
                isPlayingTestTone
                  ? 'bg-red-500 text-white animate-pulse'
                  : 'bg-[#FFC400] dark:bg-[#FFD21F] text-[#1A1400] hover:brightness-105'
              }`}
            >
              <Play className="w-3.5 h-3.5" />
              {isPlayingTestTone ? 'Playing 880Hz Siren Tone...' : 'Test SOS Acoustic Alarm'}
            </button>
          </div>

          <div className="p-4 rounded-xl bg-slate-50 dark:bg-[#0E1627] border border-slate-200/80 dark:border-slate-800 space-y-3 flex flex-col justify-between">
            <div>
              <span className="text-xs font-bold text-slate-900 dark:text-white flex items-center gap-1.5">
                <Flame className="w-4 h-4 text-amber-500" />
                Screen Perimeter Strobe Test
              </span>
              <p className="text-[11px] text-slate-500 dark:text-slate-400 mt-1 leading-relaxed">
                Previews the red high-vis border pulse that illuminates the command console on unassigned P1 tickets.
              </p>
            </div>
            <button
              type="button"
              onClick={testVisualStrobe}
              disabled={isStrobing}
              className="w-full py-2 px-3 rounded-xl text-xs font-bold border border-red-500/40 text-red-600 dark:text-red-400 bg-red-500/10 hover:bg-red-500/20 transition cursor-pointer text-center"
            >
              {isStrobing ? 'Strobe Pulse Active (3 Pulses)...' : 'Test Visual Strobe Pulse'}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

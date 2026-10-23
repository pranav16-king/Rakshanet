import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  X,
  Smartphone,
  Tablet,
  Radio,
  Share2,
  Battery,
  Wifi,
  MapPin,
  Clock,
  Layers,
  Activity,
  Send,
  Navigation,
  CheckCircle,
  Copy,
  Check,
} from 'lucide-react';
import type { Device } from '../../types/devices';
import { devicesApi } from '../../api/devices';

interface DeviceDetailDrawerProps {
  device: Device | null;
  onClose: () => void;
  onViewLogs?: (deviceId: string) => void;
}

export const DeviceDetailDrawer: React.FC<DeviceDetailDrawerProps> = ({
  device,
  onClose,
  onViewLogs,
}) => {
  const navigate = useNavigate();
  const [isPinging, setIsPinging] = useState(false);
  const [pingResult, setPingResult] = useState<number | null>(null);
  const [copied, setCopied] = useState(false);

  if (!device) return null;

  const handleCopyId = () => {
    navigator.clipboard.writeText(device.id);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const handlePing = async () => {
    setIsPinging(true);
    try {
      const res = await devicesApi.pingDevice(device.id);
      setPingResult(res.latencyMs);
    } finally {
      setIsPinging(false);
    }
  };

  const handleLocateOnMap = () => {
    navigate('/app/map');
  };

  const getHardwareIcon = (type: string) => {
    switch (type) {
      case 'Tablet':
        return <Tablet className="w-5 h-5 text-purple-500" />;
      case 'Satellite Uplink':
        return <Radio className="w-5 h-5 text-amber-500" />;
      case 'Relay Beacon':
        return <Share2 className="w-5 h-5 text-cyan-500" />;
      default:
        return <Smartphone className="w-5 h-5 text-blue-500" />;
    }
  };

  return (
    <div className="fixed inset-0 z-50 overflow-hidden flex justify-end animate-in fade-in duration-200">
      {/* Backdrop */}
      <div
        className="fixed inset-0 bg-slate-900/60 backdrop-blur-xs transition-opacity"
        onClick={onClose}
      />

      {/* Drawer Body */}
      <div className="relative w-full max-w-md bg-white dark:bg-[#0B1220] border-l border-slate-200 dark:border-[#26344F] shadow-2xl h-full flex flex-col z-10 overflow-y-auto scrollbar-tactical">
        {/* Header */}
        <div className="p-6 border-b border-slate-200 dark:border-[#162036] flex items-center justify-between sticky top-0 bg-white/95 dark:bg-[#0B1220]/95 backdrop-blur-sm z-20">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-slate-100 dark:bg-[#162036] border border-slate-200/80 dark:border-[#26344F] flex items-center justify-center shrink-0">
              {getHardwareIcon(device.type)}
            </div>
            <div>
              <div className="flex items-center gap-2">
                <span className="font-mono font-bold text-sm text-slate-900 dark:text-white">
                  {device.id}
                </span>
                <button
                  onClick={handleCopyId}
                  className="text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 cursor-pointer"
                  title="Copy Device ID"
                >
                  {copied ? <Check size={13} className="text-emerald-500" /> : <Copy size={13} />}
                </button>
              </div>
              <h3 className="text-base font-bold text-slate-900 dark:text-white leading-tight">
                {device.userName}
              </h3>
            </div>
          </div>

          <button
            onClick={onClose}
            className="p-2 rounded-xl text-slate-400 hover:text-slate-700 dark:hover:text-white hover:bg-slate-100 dark:hover:bg-[#162036] transition-colors cursor-pointer"
          >
            <X size={18} />
          </button>
        </div>

        {/* Status Pill Strip */}
        <div className="px-6 py-3.5 bg-slate-50 dark:bg-[#0E1627] border-b border-slate-200/80 dark:border-[#162036] flex items-center justify-between text-xs">
          <div className="flex items-center gap-2">
            <span
              className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full font-bold text-xs ${
                device.status === 'Online'
                  ? 'bg-emerald-50 dark:bg-emerald-950/40 text-emerald-700 dark:text-emerald-400 border border-emerald-500/30'
                  : device.status === 'Relay'
                  ? 'bg-cyan-50 dark:bg-cyan-950/40 text-cyan-700 dark:text-cyan-400 border border-cyan-500/30'
                  : 'bg-rose-50 dark:bg-rose-950/40 text-rose-700 dark:text-rose-400 border border-rose-500/30'
              }`}
            >
              <span
                className={`w-2 h-2 rounded-full ${
                  device.status === 'Online'
                    ? 'bg-emerald-500 animate-pulse'
                    : device.status === 'Relay'
                    ? 'bg-cyan-500 animate-pulse'
                    : 'bg-rose-500'
                }`}
              />
              <span>{device.status.toUpperCase()}</span>
            </span>
            <span className="text-slate-500 dark:text-[#9FADC2]">
              {device.hardwareModel || `${device.type} Node`}
            </span>
          </div>

          <span className="text-[11px] font-semibold text-slate-400 dark:text-[#9FADC2]">
            Heartbeat: {device.lastPing}
          </span>
        </div>

        {/* Content Body */}
        <div className="p-6 space-y-6 flex-1">
          {/* Battery & Health Gauge */}
          <div className="p-4 rounded-xl bg-slate-50/80 dark:bg-[#162036] border border-slate-200/80 dark:border-[#26344F]">
            <div className="flex items-center justify-between mb-2">
              <span className="text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-[#9FADC2] flex items-center gap-1.5">
                <Battery size={14} className="text-emerald-500" />
                <span>Battery Level & Power Health</span>
              </span>
              <span className="font-mono text-sm font-black text-slate-900 dark:text-white">
                {device.battery}%
              </span>
            </div>

            <div className="w-full h-3 rounded-full bg-slate-200 dark:bg-slate-700/60 overflow-hidden mb-2">
              <div
                className={`h-full transition-all duration-500 ${
                  device.battery > 50
                    ? 'bg-emerald-500'
                    : device.battery > 20
                    ? 'bg-amber-500'
                    : 'bg-rose-500'
                }`}
                style={{ width: `${device.battery}%` }}
              />
            </div>

            <div className="flex items-center justify-between text-[11px] text-slate-500 dark:text-[#9FADC2]">
              <span>Est. Runtime: ~{Math.round((device.battery / 100) * 18)} hrs remaining</span>
              <span>Drain Rate: 2.1%/hr</span>
            </div>
          </div>

          {/* Radio Mesh Telemetry */}
          <div className="p-4 rounded-xl bg-slate-50/80 dark:bg-[#162036] border border-slate-200/80 dark:border-[#26344F] space-y-3">
            <span className="text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-[#9FADC2] flex items-center gap-1.5">
              <Wifi size={14} className="text-amber-500" />
              <span>Mesh Radio & Signal Telemetry</span>
            </span>

            <div className="grid grid-cols-2 gap-3 text-xs">
              <div className="p-2.5 rounded-lg bg-white dark:bg-[#0E1627] border border-slate-200/60 dark:border-[#26344F]">
                <span className="text-slate-400 block text-[10px] uppercase font-semibold">
                  Signal Strength
                </span>
                <span className="font-mono text-sm font-bold text-slate-900 dark:text-white">
                  {device.signalStrengthDbm} dBm
                </span>
                <span className="text-[10px] text-emerald-600 dark:text-emerald-400 block mt-0.5">
                  {device.signalStrengthDbm > -60
                    ? 'Strong Radio Link'
                    : device.signalStrengthDbm > -85
                    ? 'Moderate RF Link'
                    : 'Fringe Attenuation'}
                </span>
              </div>

              <div className="p-2.5 rounded-lg bg-white dark:bg-[#0E1627] border border-slate-200/60 dark:border-[#26344F]">
                <span className="text-slate-400 block text-[10px] uppercase font-semibold">
                  Hops to Gateway
                </span>
                <span className="font-mono text-sm font-bold text-slate-900 dark:text-white">
                  {device.meshHops === 0 ? 'Direct Base Hop' : `${device.meshHops} Hops`}
                </span>
                <span className="text-[10px] text-slate-500 dark:text-[#9FADC2] block mt-0.5">
                  Protocol: BLE 5.3 / LoRa
                </span>
              </div>
            </div>

            <div className="grid grid-cols-2 gap-3 text-xs">
              <div className="p-2.5 rounded-lg bg-white dark:bg-[#0E1627] border border-slate-200/60 dark:border-[#26344F]">
                <span className="text-slate-400 block text-[10px] uppercase font-semibold">
                  Mule Packets Forwarded
                </span>
                <span className="font-mono text-sm font-bold text-slate-900 dark:text-white">
                  {device.packetsForwarded ?? (device.meshHops === 0 ? 120 : 18)} packets
                </span>
              </div>

              <div className="p-2.5 rounded-lg bg-white dark:bg-[#0E1627] border border-slate-200/60 dark:border-[#26344F]">
                <span className="text-slate-400 block text-[10px] uppercase font-semibold">
                  Relay Mode
                </span>
                <span className="text-xs font-bold text-cyan-600 dark:text-cyan-400">
                  {device.relayActive ? 'Active Store & Forward' : 'Edge Leaf Node'}
                </span>
              </div>
            </div>
          </div>

          {/* Spatiotemporal Location */}
          <div className="p-4 rounded-xl bg-slate-50/80 dark:bg-[#162036] border border-slate-200/80 dark:border-[#26344F] space-y-2.5">
            <span className="text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-[#9FADC2] flex items-center gap-1.5">
              <MapPin size={14} className="text-rose-500" />
              <span>Spatiotemporal Positioning</span>
            </span>

            <div className="text-xs space-y-1.5">
              <div className="flex items-center justify-between py-1 border-b border-slate-200/60 dark:border-[#26344F]/60">
                <span className="text-slate-500 dark:text-[#9FADC2]">Sector Description</span>
                <span className="font-medium text-slate-900 dark:text-white text-right">
                  {device.location}
                </span>
              </div>

              <div className="flex items-center justify-between py-1 border-b border-slate-200/60 dark:border-[#26344F]/60">
                <span className="text-slate-500 dark:text-[#9FADC2]">GPS Coordinates</span>
                <span className="font-mono text-slate-900 dark:text-white">
                  {device.lat && device.lng
                    ? `${device.lat.toFixed(4)}° N, ${device.lng.toFixed(4)}° E`
                    : '13.0425° N, 80.2285° E'}
                </span>
              </div>

              <div className="flex items-center justify-between py-1">
                <span className="text-slate-500 dark:text-[#9FADC2]">Horizontal Accuracy</span>
                <span className="font-mono text-emerald-600 dark:text-emerald-400">
                  ± 4.5 meters (Fused GPS)
                </span>
              </div>
            </div>
          </div>

          {/* Live Ping Test */}
          <div className="p-4 rounded-xl bg-slate-50/80 dark:bg-[#162036] border border-slate-200/80 dark:border-[#26344F] flex items-center justify-between">
            <div>
              <span className="text-xs font-bold text-slate-900 dark:text-white block">
                Mesh Link Round-Trip Ping
              </span>
              <span className="text-[11px] text-slate-500 dark:text-[#9FADC2]">
                {pingResult !== null
                  ? `ACK received in ${pingResult}ms (RTT)`
                  : 'Measure real-time packet latency'}
              </span>
            </div>

            <button
              onClick={handlePing}
              disabled={isPinging}
              className="px-3 py-1.5 rounded-lg bg-amber-400 dark:bg-[#FFD21F] text-[#1A1400] text-xs font-bold hover:brightness-105 transition-all cursor-pointer disabled:opacity-60 flex items-center gap-1.5 shadow-xs"
            >
              <Send size={12} className={isPinging ? 'animate-spin' : ''} />
              <span>{isPinging ? 'Pinging...' : 'Ping Link'}</span>
            </button>
          </div>
        </div>

        {/* Action Footer */}
        <div className="p-6 border-t border-slate-200 dark:border-[#162036] bg-white dark:bg-[#0B1220] sticky bottom-0 z-20 space-y-2.5">
          <button
            onClick={handleLocateOnMap}
            className="w-full py-2.5 px-4 rounded-xl bg-amber-400 dark:bg-[#FFD21F] text-[#1A1400] text-xs font-bold hover:brightness-105 transition-all cursor-pointer flex items-center justify-center gap-2 shadow-xs"
          >
            <Navigation size={14} />
            <span>Track on Live Disaster Map</span>
          </button>

          {onViewLogs && (
            <button
              onClick={() => {
                onViewLogs(device.id);
                onClose();
              }}
              className="w-full py-2 px-4 rounded-xl bg-slate-100 dark:bg-[#162036] text-slate-700 dark:text-[#EEF2F8] border border-slate-200 dark:border-[#26344F] text-xs font-bold hover:bg-slate-200 dark:hover:bg-[#1E2844] transition-colors cursor-pointer"
            >
              Inspect Telemetry Packets
            </button>
          )}
        </div>
      </div>
    </div>
  );
};

export default DeviceDetailDrawer;

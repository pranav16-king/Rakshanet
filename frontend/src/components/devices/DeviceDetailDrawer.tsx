import React, { useState } from 'react';
import { Copy, MapPin, Radio, X } from 'lucide-react';
import type { Device } from '../../types/devices';

interface DeviceDetailDrawerProps {
  device: Device | null;
  onClose: () => void;
  onViewLogs?: (deviceId: string) => void;
}

const telemetry = (value: React.ReactNode | undefined) => value === undefined || value === null || value === '' ? 'Not reported' : value;

/** Details intentionally render only telemetry that arrived from the gateway. */
export const DeviceDetailDrawer: React.FC<DeviceDetailDrawerProps> = ({ device, onClose, onViewLogs }) => {
  const [copied, setCopied] = useState(false);
  if (!device) return null;
  const coordinates = device.lat !== undefined && device.lng !== undefined ? `${device.lat.toFixed(4)}°, ${device.lng.toFixed(4)}°` : undefined;
  const copyId = async () => {
    await navigator.clipboard?.writeText(device.id);
    setCopied(true);
    window.setTimeout(() => setCopied(false), 1500);
  };
  const rows: Array<[string, React.ReactNode | undefined]> = [
    ['Status', device.status], ['Hardware', device.hardwareModel ?? device.type], ['Last reported', device.lastPing],
    ['Location', device.location], ['GPS coordinates', coordinates], ['Battery', device.battery === undefined ? undefined : `${device.battery}%`],
    ['Mesh hops', device.meshHops], ['Signal strength', device.signalStrengthDbm === undefined ? undefined : `${device.signalStrengthDbm} dBm`],
    ['Packets forwarded', device.packetsForwarded], ['Relay mode', device.relayActive === true ? 'Active store and forward' : undefined],
  ];

  return <div className="fixed inset-0 z-50 flex justify-end" role="dialog" aria-modal="true" aria-label="Device details">
    <button type="button" aria-label="Close device details" className="absolute inset-0 bg-slate-900/60" onClick={onClose} />
    <aside className="relative h-full w-full max-w-md overflow-y-auto border-l border-slate-200 bg-white shadow-xl dark:border-slate-700 dark:bg-slate-950">
      <header className="flex items-center justify-between border-b border-slate-200 p-5 dark:border-slate-800">
        <div><p className="text-xs text-slate-500">Device report</p><h2 className="font-mono font-bold text-slate-950 dark:text-white">{device.id}</h2><p className="text-sm text-slate-600 dark:text-slate-300">{device.userName}</p></div>
        <div className="flex gap-2"><button type="button" onClick={copyId} className="rounded-lg p-3 text-slate-600 hover:bg-slate-100 dark:text-slate-300 dark:hover:bg-slate-800" aria-label="Copy device ID"><Copy size={18} />{copied && <span className="sr-only">Copied</span>}</button><button type="button" onClick={onClose} className="rounded-lg p-3 text-slate-600 hover:bg-slate-100 dark:text-slate-300 dark:hover:bg-slate-800" aria-label="Close"><X size={18} /></button></div>
      </header>
      <section className="space-y-4 p-5">
        <div className="rounded-xl border border-slate-200 p-4 dark:border-slate-700"><div className="mb-3 flex items-center gap-2 text-sm font-semibold"><Radio size={16} /> Observed mesh telemetry</div><dl className="space-y-3 text-sm">{rows.map(([label, value]) => <div key={label} className="flex justify-between gap-4 border-b border-slate-100 pb-2 last:border-0 dark:border-slate-800"><dt className="text-slate-500">{label}</dt><dd className="text-right font-medium text-slate-900 dark:text-white">{telemetry(value)}</dd></div>)}</dl></div>
        {coordinates && <a href={`/app/map?device=${encodeURIComponent(device.id)}`} className="flex min-h-12 items-center justify-center gap-2 rounded-lg bg-amber-400 px-4 font-semibold text-slate-950 hover:bg-amber-300"><MapPin size={18} />View reported position</a>}
        {onViewLogs && <button type="button" onClick={() => { onViewLogs(device.id); onClose(); }} className="min-h-12 w-full rounded-lg border border-slate-300 px-4 font-semibold text-slate-700 hover:bg-slate-50 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-900">Inspect ingested packets</button>}
      </section>
    </aside>
  </div>;
};

export default DeviceDetailDrawer;

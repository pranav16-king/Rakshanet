import React, { useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { AlertTriangle, MapPin, Radio, X, ArrowRight, ShieldAlert } from 'lucide-react';
import { useEmergencyAlertStore, type EmergencyAlertItem } from '../../store/emergencyAlertStore';

interface ToastItemProps {
  alert: EmergencyAlertItem;
  onDismiss: (id: string) => void;
}

const ToastItem: React.FC<ToastItemProps> = ({ alert, onDismiss }) => {
  const navigate = useNavigate();

  useEffect(() => {
    const timer = setTimeout(() => {
      onDismiss(alert.id);
    }, 12000);
    return () => clearTimeout(timer);
  }, [alert.id, onDismiss]);

  const hasCoords = alert.coordinates && Number.isFinite(alert.coordinates.lat) && Number.isFinite(alert.coordinates.lng);
  const coordsFormatted = hasCoords
    ? `${alert.coordinates!.lat.toFixed(4)}° N, ${alert.coordinates!.lng.toFixed(4)}° E`
    : 'GPS Acquisition Pending';

  const handleOpenMap = () => {
    if (hasCoords) {
      navigate(`/app/map?lat=${alert.coordinates!.lat}&lng=${alert.coordinates!.lng}&focus=${encodeURIComponent(alert.id)}`);
    } else {
      navigate('/app/map');
    }
    onDismiss(alert.id);
  };

  return (
    <div
      role="alert"
      aria-live="assertive"
      className="w-full max-w-md pointer-events-auto rounded-2xl bg-[#0B1220]/95 backdrop-blur-md border-2 border-red-600 shadow-2xl p-4 text-white overflow-hidden relative animate-in fade-in slide-in-from-top-4 duration-300 ring-4 ring-red-600/20"
    >
      {/* Top emergency pulse banner */}
      <div className="flex items-center justify-between pb-2 mb-2 border-b border-red-900/60">
        <div className="flex items-center gap-2">
          <span className="relative flex h-3 w-3">
            <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-red-400 opacity-80" />
            <span className="relative inline-flex rounded-full h-3 w-3 bg-red-600" />
          </span>
          <span className="text-xs font-black tracking-wider text-red-400 uppercase flex items-center gap-1 font-mono">
            <ShieldAlert className="w-3.5 h-3.5 text-red-500" />
            CRITICAL SOS DISPATCH
          </span>
        </div>
        <div className="flex items-center gap-2">
          <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-red-600 text-white font-mono uppercase">
            {alert.urgency || 'CRITICAL'}
          </span>
          <button
            onClick={() => onDismiss(alert.id)}
            aria-label="Dismiss alert"
            className="text-slate-400 hover:text-white transition-colors p-1 rounded-md hover:bg-slate-800 cursor-pointer"
          >
            <X className="w-4 h-4" />
          </button>
        </div>
      </div>

      {/* Main Alert Content */}
      <div className="space-y-2">
        <div className="flex items-start justify-between gap-2">
          <div>
            <h4 className="text-sm font-black text-white flex items-center gap-1.5">
              <span>{alert.senderName}</span>
              {alert.senderId && (
                <span className="text-[11px] font-mono font-normal text-slate-400">
                  ({alert.senderId})
                </span>
              )}
            </h4>
            <p className="text-xs text-slate-300 mt-0.5 font-medium line-clamp-2">
              {alert.payload || 'SOS distress signal broadcast over disaster mesh spectrum.'}
            </p>
          </div>
        </div>

        {/* Location & Hops metadata */}
        <div className="flex flex-wrap items-center gap-3 text-[11px] font-mono text-slate-300 pt-1 border-t border-slate-800/80">
          <div className="flex items-center gap-1 text-amber-300">
            <MapPin className="w-3 h-3 text-amber-400 shrink-0" />
            <span>{coordsFormatted}</span>
          </div>

          <div className="flex items-center gap-1 text-cyan-300">
            <Radio className="w-3 h-3 text-cyan-400 shrink-0" />
            <span>{alert.hops !== undefined ? `${alert.hops} Hops away` : 'Direct Relay'}</span>
          </div>
        </div>

        {/* Action Button */}
        <div className="pt-2">
          <button
            onClick={handleOpenMap}
            type="button"
            className="w-full flex items-center justify-center gap-1.5 px-3 py-2 rounded-xl bg-gradient-to-r from-red-600 to-amber-600 hover:from-red-500 hover:to-amber-500 text-white font-bold text-xs shadow-md transition-all cursor-pointer"
          >
            <span>Track on Live Tactical Map & Response Vector</span>
            <ArrowRight className="w-3.5 h-3.5" />
          </button>
        </div>
      </div>
    </div>
  );
};

export const EmergencyToastContainer: React.FC = () => {
  const { alerts, dismissAlert } = useEmergencyAlertStore();

  if (alerts.length === 0) return null;

  return (
    <div
      aria-label="Emergency alerts"
      className="fixed top-4 right-4 z-[9999] flex flex-col gap-3 pointer-events-none max-w-md w-full px-4 sm:px-0"
    >
      {alerts.map((alert) => (
        <ToastItem key={alert.id} alert={alert} onDismiss={dismissAlert} />
      ))}
    </div>
  );
};

export default EmergencyToastContainer;

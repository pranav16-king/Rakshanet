import React, { useState, useEffect } from 'react';
import {
  X,
  Shield,
  LifeBuoy,
  Truck,
  HeartPulse,
  Send,
  Navigation,
  Clock,
  CheckCircle2,
  AlertCircle,
  Plane,
} from 'lucide-react';
import type { Incident, RescueUnit } from '../../types/incident.ts';
import { fetchAvailableRescueUnits, assignTeamToIncident } from '../../api/incidents.ts';
import { useTheme } from '../../theme/ThemeContext.tsx';

interface AssignTeamModalProps {
  isOpen: boolean;
  incident: Incident;
  onClose: () => void;
  onSuccess: (assignedTeamName: string) => void;
}

export const AssignTeamModal: React.FC<AssignTeamModalProps> = ({
  isOpen,
  incident,
  onClose,
  onSuccess,
}) => {
  const { isDark } = useTheme();
  const [units, setUnits] = useState<RescueUnit[]>([]);
  const [selectedUnitId, setSelectedUnitId] = useState<string>('');
  const [dispatchNotes, setDispatchNotes] = useState<string>('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (isOpen) {
      setError(null);
      fetchAvailableRescueUnits().then((fleet) => {
        setUnits(fleet);
        if (fleet.length > 0 && !selectedUnitId) {
          setSelectedUnitId(fleet[0].unit_id);
        }
      });
    }
  }, [isOpen]);

  if (!isOpen) return null;

  const handleDispatch = async () => {
    if (!selectedUnitId) {
      setError('Please select an operational rescue unit to dispatch.');
      return;
    }

    setLoading(true);
    setError(null);

    try {
      const res = await assignTeamToIncident(incident.id, selectedUnitId, dispatchNotes);
      if (res.success) {
        onSuccess(res.unitName);
        onClose();
      } else {
        setError('Dispatch failed. Please retry.');
      }
    } catch (err: any) {
      setError(err?.message || 'Failed to dispatch rescue unit.');
    } finally {
      setLoading(false);
    }
  };

  const getUnitIcon = (unitType: string) => {
    switch (unitType) {
      case 'BOAT':
        return <LifeBuoy size={18} className="text-[#3CC6D0]" />;
      case 'HIGH_CLEARANCE_4WD':
        return <Truck size={18} className="text-[#FFA033]" />;
      case 'AMBULANCE':
        return <HeartPulse size={18} className="text-[#FF5A4E]" />;
      case 'HELICOPTER':
        return <Plane size={18} className="text-[#4CD08A]" />;
      default:
        return <Shield size={18} className="text-[#FFC400]" />;
    }
  };

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm"
      role="dialog"
      aria-modal="true"
      aria-labelledby="modal-title"
    >
      <div
        className={`w-full max-w-2xl rounded-2xl border shadow-2xl overflow-hidden transition-colors flex flex-col max-h-[90vh] ${
          isDark ? 'bg-[#111A2C] border-[#26344F]' : 'bg-white border-[#E6DCA8]'
        }`}
      >
        {/* Modal Header */}
        <div
          className={`px-6 py-4 border-b flex items-center justify-between ${
            isDark ? 'border-[#26344F] bg-[#162036]' : 'border-[#E6DCA8] bg-[#FFF5C2]/50'
          }`}
        >
          <div>
            <h2
              id="modal-title"
              className={`font-display font-bold text-lg ${
                isDark ? 'text-[#EEF2F8]' : 'text-[#16202D]'
              }`}
            >
              Assign Rescue Response Team
            </h2>
            <div className="text-xs font-mono opacity-75 flex items-center gap-2 mt-0.5">
              <span className="font-bold text-[#FFC400]">{incident.id}</span>
              <span>•</span>
              <span>{incident.title}</span>
              <span>•</span>
              <span className="text-[#FF5A4E] font-bold">{incident.severity}</span>
            </div>
          </div>
          <button
            type="button"
            onClick={onClose}
            aria-label="Close modal"
            className={`p-2 rounded-lg border transition-colors ${
              isDark
                ? 'border-[#26344F] text-[#9FADC2] hover:text-white hover:bg-[#1f2d4d]'
                : 'border-[#E6DCA8] text-[#566070] hover:text-[#16202D] hover:bg-[#ebdca8]'
            }`}
          >
            <X size={18} />
          </button>
        </div>

        {/* Modal Body */}
        <div className="p-6 overflow-y-auto space-y-5">
          {error && (
            <div className="p-3 rounded-lg border border-[#D92D20]/40 bg-[#FDE2DF] text-[#D92D20] text-xs flex items-center gap-2">
              <AlertCircle size={16} className="shrink-0" />
              <span>{error}</span>
            </div>
          )}

          <div>
            <label className="block text-xs font-bold uppercase tracking-wider font-mono mb-2 opacity-80">
              Select Available NDRF / SDRF / Fleet Unit:
            </label>
            <div className="space-y-2.5">
              {units.map((unit) => {
                const isSelected = selectedUnitId === unit.unit_id;
                return (
                  <div
                    key={unit.unit_id}
                    onClick={() => setSelectedUnitId(unit.unit_id)}
                    className={`p-3.5 rounded-xl border cursor-pointer transition-all flex items-center justify-between gap-3 ${
                      isSelected
                        ? isDark
                          ? 'bg-[#162036] border-[#FFD21F] ring-2 ring-[#FFD21F]/20'
                          : 'bg-[#FFF5C2] border-[#8A5A00] ring-2 ring-[#FFC400]/30'
                        : isDark
                        ? 'bg-[#0E1627] border-[#26344F] hover:border-[#3A4C70]'
                        : 'bg-white border-[#E6DCA8] hover:border-[#C9BB6E]'
                    }`}
                  >
                    <div className="flex items-center gap-3">
                      <div className="p-2.5 rounded-lg bg-black/15 shrink-0">
                        {getUnitIcon(unit.unit_type)}
                      </div>
                      <div>
                        <div className="flex items-center gap-2">
                          <span
                            className={`text-sm font-bold ${
                              isDark ? 'text-white' : 'text-[#16202D]'
                            }`}
                          >
                            {unit.name}
                          </span>
                          <span className="text-[10px] font-mono font-bold px-1.5 py-0.5 rounded bg-black/20 text-[#FFC400]">
                            {unit.agency}
                          </span>
                        </div>
                        <div className="flex items-center gap-3 text-xs opacity-75 font-mono mt-1">
                          <span className="flex items-center gap-1">
                            <Navigation size={12} className="text-[#0E8A94]" />
                            {unit.distance_km} km away
                          </span>
                          <span>•</span>
                          <span className="flex items-center gap-1 text-[#1E8E4E] font-bold">
                            <Clock size={12} />
                            ETA: ~{unit.eta_minutes} min
                          </span>
                          <span>•</span>
                          <span>Cap: {unit.capacity} pers</span>
                        </div>
                      </div>
                    </div>

                    <div className="shrink-0 flex items-center">
                      <div
                        className={`w-5 h-5 rounded-full border-2 flex items-center justify-center transition-colors ${
                          isSelected
                            ? 'border-[#FFC400] bg-[#FFC400] text-[#1A1400]'
                            : 'border-gray-500'
                        }`}
                      >
                        {isSelected && <CheckCircle2 size={14} className="stroke-[3]" />}
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          {/* Operational Notes */}
          <div>
            <label className="block text-xs font-bold uppercase tracking-wider font-mono mb-1.5 opacity-80">
              Tactical Dispatch Orders / Channel Directives:
            </label>
            <textarea
              rows={3}
              value={dispatchNotes}
              onChange={(e) => setDispatchNotes(e.target.value)}
              placeholder="e.g. Approach via eastern bridge bend; deploy inflatable rafts to rooftop cluster; switch to VHF CH-16."
              className={`w-full p-3 text-xs rounded-xl border outline-none transition-colors ${
                isDark
                  ? 'bg-[#0E1627] border-[#26344F] text-[#EEF2F8] placeholder-[#5F6E86] focus:border-[#FFD21F]'
                  : 'bg-[#F6F0D4] border-[#E6DCA8] text-[#16202D] placeholder-[#9AA1AB] focus:border-[#FFC400]'
              }`}
            />
          </div>
        </div>

        {/* Modal Footer */}
        <div
          className={`px-6 py-4 border-t flex items-center justify-between gap-3 ${
            isDark ? 'border-[#26344F] bg-[#162036]' : 'border-[#E6DCA8] bg-[#FFF5C2]/40'
          }`}
        >
          <button
            type="button"
            onClick={onClose}
            disabled={loading}
            className={`px-4 py-2.5 rounded-xl border text-xs font-bold transition-all ${
              isDark
                ? 'border-[#26344F] text-[#9FADC2] hover:bg-[#1f2d4d]'
                : 'border-[#E6DCA8] text-[#566070] hover:bg-[#ebdca8]'
            }`}
          >
            Cancel
          </button>

          <button
            type="button"
            onClick={handleDispatch}
            disabled={loading || !selectedUnitId}
            className={`px-6 py-2.5 rounded-xl text-xs font-bold flex items-center gap-2 transition-all shadow-md ${
              loading || !selectedUnitId
                ? 'opacity-50 cursor-not-allowed bg-gray-500 text-white'
                : 'bg-[#FFC400] text-[#1A1400] hover:bg-[#E0AA00] active:scale-95'
            }`}
          >
            <Send size={15} />
            <span>{loading ? 'Transmitting Dispatch...' : 'Confirm & Dispatch Unit'}</span>
          </button>
        </div>
      </div>
    </div>
  );
};

// src/components/resources/ResourceAllocationModal.tsx
import React, { useState } from 'react';
import type { ResourceItem } from '../../types';
import { X, Layers, CheckCircle, Plus, Minus, RotateCcw } from 'lucide-react';

interface ResourceAllocationModalProps {
  resource: ResourceItem;
  isOpen: boolean;
  onClose: () => void;
  onSave: (resourceId: string, newAllocated: number) => void;
}

export const ResourceAllocationModal: React.FC<ResourceAllocationModalProps> = ({
  resource,
  isOpen,
  onClose,
  onSave,
}) => {
  const maxCap = Number(resource.totalCapacity ?? resource.quantity ?? 100);
  const [allocatedVal, setAllocatedVal] = useState<number>(resource.allocated ?? 0);
  const [saving, setSaving] = useState<boolean>(false);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    const safeVal = Math.max(0, Math.min(maxCap, allocatedVal));
    await onSave(resource.id, safeVal);
    setSaving(false);
    onClose();
  };

  const handleAdjust = (delta: number) => {
    setAllocatedVal((prev) => Math.max(0, Math.min(maxCap, prev + delta)));
  };

  const locationStr =
    typeof resource.location === 'object' && resource.location !== null
      ? resource.location.facilityName || `${resource.location.lat}, ${resource.location.lng}`
      : String(resource.location || 'Central Depot');

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-in fade-in duration-150">
      <div className="w-full max-w-md rounded-2xl bg-white dark:bg-[#162036] border border-[#E6DCA8] dark:border-[#26344F] shadow-2xl p-6 text-[#16202D] dark:text-[#EEF2F8]">
        {/* Header */}
        <div className="flex items-center justify-between border-b border-[#E6DCA8] dark:border-[#26344F] pb-3 mb-4">
          <div className="flex items-center gap-2">
            <Layers className="w-5 h-5 text-[#8A5A00] dark:text-[#FFD21F]" />
            <h3 className="text-lg font-bold text-[#16202D] dark:text-white">
              Adjust Asset Allocation
            </h3>
          </div>
          <button
            onClick={onClose}
            className="p-1 rounded-lg text-[#566070] dark:text-[#9FADC2] hover:text-[#16202D] dark:hover:text-white hover:bg-black/5 dark:hover:bg-white/10 transition cursor-pointer"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          {/* Asset Summary */}
          <div className="p-3.5 rounded-xl bg-[#FFFCEB] dark:bg-[#0E1627] border border-[#E6DCA8] dark:border-[#26344F]">
            <div className="text-[11px] font-bold uppercase tracking-wider text-[#566070] dark:text-[#9FADC2]">
              Asset Name
            </div>
            <div className="text-sm font-black text-[#16202D] dark:text-white mt-0.5">
              {resource.name}
            </div>
            <div className="text-xs text-[#566070] dark:text-[#9FADC2] mt-1 flex items-center justify-between">
              <span>{locationStr}</span>
              <span className="font-mono font-bold text-[#0E8A94] dark:text-[#3CC6D0]">
                Total: {maxCap} {resource.unit}
              </span>
            </div>
          </div>

          {/* Allocation Input with Quick Steppers */}
          <div className="space-y-2">
            <div className="flex items-center justify-between text-xs font-semibold text-[#16202D] dark:text-[#EEF2F8]">
              <label>Deployed / Allocated Count ({resource.unit})</label>
              <span className="font-mono text-emerald-600 dark:text-emerald-400">
                Available: {Math.max(0, maxCap - allocatedVal)} {resource.unit}
              </span>
            </div>

            <div className="flex items-center gap-2">
              <button
                type="button"
                onClick={() => handleAdjust(-1)}
                className="w-10 h-10 rounded-xl bg-gray-100 dark:bg-[#0E1627] border border-gray-300 dark:border-slate-700 flex items-center justify-center font-bold text-base hover:bg-gray-200 transition cursor-pointer"
              >
                <Minus className="w-4 h-4" />
              </button>

              <input
                type="number"
                min={0}
                max={maxCap}
                value={allocatedVal}
                onChange={(e) => setAllocatedVal(Number(e.target.value))}
                className="flex-1 h-10 bg-white dark:bg-[#0E1627] border border-[#E6DCA8] dark:border-slate-700 rounded-xl px-3.5 text-center font-mono font-bold text-base text-[#16202D] dark:text-white focus:outline-none focus:ring-2 focus:ring-[#FFC400]"
              />

              <button
                type="button"
                onClick={() => handleAdjust(1)}
                className="w-10 h-10 rounded-xl bg-gray-100 dark:bg-[#0E1627] border border-gray-300 dark:border-slate-700 flex items-center justify-center font-bold text-base hover:bg-gray-200 transition cursor-pointer"
              >
                <Plus className="w-4 h-4" />
              </button>
            </div>

            {/* Quick Presets */}
            <div className="flex items-center gap-1.5 pt-1">
              <button
                type="button"
                onClick={() => setAllocatedVal(0)}
                className="px-2.5 py-1 rounded-lg text-[11px] font-semibold bg-gray-100 dark:bg-[#0E1627] text-[#566070] dark:text-[#9FADC2] hover:bg-gray-200 transition"
              >
                Reset (0)
              </button>
              <button
                type="button"
                onClick={() => handleAdjust(maxCap > 50 ? 25 : 2)}
                className="px-2.5 py-1 rounded-lg text-[11px] font-semibold bg-gray-100 dark:bg-[#0E1627] text-[#566070] dark:text-[#9FADC2] hover:bg-gray-200 transition"
              >
                +{maxCap > 50 ? 25 : 2}
              </button>
              <button
                type="button"
                onClick={() => setAllocatedVal(Math.round(maxCap / 2))}
                className="px-2.5 py-1 rounded-lg text-[11px] font-semibold bg-gray-100 dark:bg-[#0E1627] text-[#566070] dark:text-[#9FADC2] hover:bg-gray-200 transition"
              >
                50% Capacity
              </button>
              <button
                type="button"
                onClick={() => setAllocatedVal(maxCap)}
                className="px-2.5 py-1 rounded-lg text-[11px] font-semibold bg-amber-50 dark:bg-amber-950/40 text-amber-700 dark:text-amber-300 border border-amber-300 dark:border-amber-800 hover:bg-amber-100 transition"
              >
                Max Deploy ({maxCap})
              </button>
            </div>
          </div>

          {/* Modal Action Buttons */}
          <div className="pt-4 border-t border-[#E6DCA8] dark:border-[#26344F] flex items-center justify-end gap-3">
            <button
              type="button"
              onClick={onClose}
              disabled={saving}
              className="px-4 py-2 text-xs rounded-xl bg-gray-100 dark:bg-[#0E1627] text-[#566070] dark:text-[#9FADC2] hover:bg-gray-200 transition cursor-pointer font-semibold"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={saving}
              className="flex items-center gap-2 px-5 py-2 text-xs rounded-xl bg-[#FFC400] dark:bg-[#FFD21F] hover:bg-[#E0AA00] text-[#1A1400] font-bold transition shadow-xs cursor-pointer"
            >
              <CheckCircle className="w-4 h-4" />
              {saving ? 'Updating...' : 'Save Allocation'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

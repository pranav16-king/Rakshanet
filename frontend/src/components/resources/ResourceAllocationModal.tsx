// src/components/resources/ResourceAllocationModal.tsx
import React, { useState } from 'react';
import type { ResourceItem } from '../../types';
import { X, Layers, CheckCircle } from 'lucide-react';

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
  const [allocatedVal, setAllocatedVal] = useState<number>(resource.allocated ?? 0);

  if (!isOpen) return null;

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const maxCap = resource.totalCapacity ?? resource.quantity ?? 100;
    onSave(resource.id, Math.max(0, Math.min(maxCap, allocatedVal)));
    onClose();
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm">
      <div className="w-full max-w-md rounded-2xl bg-[#162036] border border-slate-700 shadow-2xl p-6 text-slate-100">
        <div className="flex items-center justify-between border-b border-slate-700/80 pb-3 mb-4">
          <div className="flex items-center gap-2">
            <Layers className="w-5 h-5 text-amber-400" />
            <h3 className="text-lg font-bold text-white">Adjust Allocation</h3>
          </div>
          <button
            onClick={onClose}
            className="p-1 rounded-lg text-slate-400 hover:text-white hover:bg-slate-800 transition"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <div className="text-xs text-slate-400">Resource Asset</div>
            <div className="text-base font-semibold text-white mt-0.5">{resource.name}</div>
            <div className="text-xs text-slate-400">
              Location: {resource.location} • Total: {resource.totalCapacity} {resource.unit}
            </div>
          </div>

          <div className="space-y-1.5">
            <label className="text-xs font-medium text-slate-300">
              Allocated Amount ({resource.unit})
            </label>
            <input
              type="number"
              min={0}
              max={resource.totalCapacity ?? resource.quantity ?? 100}
              value={allocatedVal}
              onChange={(e) => setAllocatedVal(Number(e.target.value))}
              className="w-full bg-[#0E1627] border border-slate-700 rounded-lg px-3.5 py-2.5 text-sm text-white focus:outline-none focus:border-amber-400"
            />
            <div className="flex justify-between text-xs text-slate-400">
              <span>0 (All free)</span>
              <span>Remaining: {Math.max(0, (resource.totalCapacity ?? resource.quantity ?? 100) - allocatedVal)}</span>
              <span>{resource.totalCapacity ?? resource.quantity ?? 100} (Full)</span>
            </div>
          </div>

          <div className="pt-3 border-t border-slate-700/80 flex items-center justify-end gap-3">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 text-xs rounded-lg bg-slate-800 text-slate-300 hover:bg-slate-700 transition"
            >
              Cancel
            </button>
            <button
              type="submit"
              className="flex items-center gap-2 px-5 py-2 text-xs rounded-lg bg-amber-400 hover:bg-amber-300 text-slate-950 font-bold transition shadow-md"
            >
              <CheckCircle className="w-4 h-4" />
              Update Allocation
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

// src/components/resources/ResourceCard.tsx
import React from 'react';
import type { ResourceItem } from '../../types';
import { AllocationProgress } from './AllocationProgress';
import {
  Compass,
  Truck,
  HeartPulse,
  Home,
  Utensils,
  Cpu,
  MapPin,
  Clock,
  Layers,
} from 'lucide-react';

interface ResourceCardProps {
  resource: ResourceItem;
  onAllocate?: () => void;
}

export const ResourceCard: React.FC<ResourceCardProps> = ({ resource, onAllocate }) => {
  const getCategoryIcon = () => {
    switch (resource.category) {
      case 'BOATS':
        return <Compass className="w-5 h-5 text-cyan-400" />;
      case 'RESCUE_VEHICLES':
        return <Truck className="w-5 h-5 text-amber-400" />;
      case 'MEDICAL':
        return <HeartPulse className="w-5 h-5 text-red-400" />;
      case 'SHELTERS':
        return <Home className="w-5 h-5 text-emerald-400" />;
      case 'RATIONS':
        return <Utensils className="w-5 h-5 text-orange-400" />;
      case 'EQUIPMENT':
      default:
        return <Cpu className="w-5 h-5 text-purple-400" />;
    }
  };

  const getUrgencyBadge = () => {
    switch (resource.urgency) {
      case 'CRITICAL':
        return 'bg-red-500/20 text-red-400 border-red-500/30';
      case 'HIGH':
        return 'bg-amber-500/20 text-amber-400 border-amber-500/30';
      default:
        return 'bg-emerald-500/20 text-emerald-400 border-emerald-500/30';
    }
  };

  return (
    <div className="p-5 rounded-xl border border-slate-700/80 bg-[#162036] hover:border-amber-400/50 transition-all flex flex-col justify-between shadow-md">
      <div>
        {/* Card Header */}
        <div className="flex items-start justify-between gap-3 mb-3">
          <div className="flex items-center gap-3">
            <div className="p-2.5 rounded-lg bg-[#0E1627] border border-slate-700/80">
              {getCategoryIcon()}
            </div>
            <div>
              <h3 className="font-bold text-white text-base leading-snug">
                {resource.name}
              </h3>
              <div className="text-xs text-slate-400 mt-0.5">
                Category: <strong className="text-slate-300">{(resource.category || resource.type || '').replace(/_/g, ' ')}</strong>
              </div>
            </div>
          </div>

          <span className={`px-2.5 py-0.5 rounded-full text-xs font-semibold border ${getUrgencyBadge()}`}>
            {resource.urgency || resource.status}
          </span>
        </div>

        {/* Location & Time */}
        <div className="flex items-center justify-between text-xs text-slate-300 bg-[#0E1627] p-2.5 rounded-lg border border-slate-800 mb-4">
          <div className="flex items-center gap-1.5 truncate">
            <MapPin className="w-3.5 h-3.5 text-cyan-400 flex-shrink-0" />
            <span className="truncate">
              {typeof resource.location === 'object' && resource.location !== null
                ? (resource.location.facilityName || `${resource.location.lat}, ${resource.location.lng}`)
                : String(resource.location || 'Field Base')}
            </span>
          </div>
          <div className="flex items-center gap-1 text-slate-400 flex-shrink-0 ml-2">
            <Clock className="w-3.5 h-3.5" />
            <span>{resource.lastUpdated || resource.lastRestocked || 'Recently'}</span>
          </div>
        </div>

        {/* Capacity Bar */}
        <div className="mb-4">
          <AllocationProgress
            allocated={resource.allocated ?? (resource.quantity - resource.available)}
            total={resource.totalCapacity ?? resource.quantity}
            unit={resource.unit}
          />
        </div>
      </div>

      {/* Action Footer */}
      <div className="pt-3 border-t border-slate-700/60 flex items-center justify-between">
        <span className="text-xs font-medium text-slate-400 flex items-center gap-1.5">
          <Layers className="w-3.5 h-3.5 text-amber-400" />
          Status: <strong className="text-white">{resource.status}</strong>
        </span>

        <button
          onClick={onAllocate}
          className="px-3.5 py-1.5 rounded-lg bg-amber-400 hover:bg-amber-300 text-slate-950 font-bold text-xs shadow-md transition"
        >
          Manage Allocation
        </button>
      </div>
    </div>
  );
};

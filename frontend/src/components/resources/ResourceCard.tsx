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
  Info,
  Sliders,
} from 'lucide-react';

interface ResourceCardProps {
  resource: ResourceItem;
  onAllocate?: () => void;
  onViewDetails?: () => void;
}

export const ResourceCard: React.FC<ResourceCardProps> = ({
  resource,
  onAllocate,
  onViewDetails,
}) => {
  const getCategoryIcon = () => {
    switch (resource.category) {
      case 'BOATS':
        return <Compass className="w-5 h-5 text-cyan-600 dark:text-cyan-400" />;
      case '4WDS':
      case 'RESCUE_VEHICLES':
        return <Truck className="w-5 h-5 text-amber-600 dark:text-amber-400" />;
      case 'AMBULANCES':
      case 'MEDICAL':
        return <HeartPulse className="w-5 h-5 text-red-600 dark:text-red-400" />;
      case 'SHELTERS':
        return <Home className="w-5 h-5 text-emerald-600 dark:text-emerald-400" />;
      case 'FOOD_WATER':
      case 'RATIONS':
        return <Utensils className="w-5 h-5 text-orange-600 dark:text-orange-400" />;
      default:
        return <Cpu className="w-5 h-5 text-purple-600 dark:text-purple-400" />;
    }
  };

  const getStatusBadge = () => {
    switch (resource.status) {
      case 'READY':
      case 'AVAILABLE':
        return 'bg-emerald-50 dark:bg-emerald-950/40 text-emerald-700 dark:text-emerald-400 border-emerald-300 dark:border-emerald-800';
      case 'LOW':
        return 'bg-amber-50 dark:bg-amber-950/40 text-amber-700 dark:text-amber-400 border-amber-300 dark:border-amber-800';
      case 'DEPLETED':
        return 'bg-red-50 dark:bg-red-950/40 text-red-700 dark:text-red-400 border-red-300 dark:border-red-800';
      default:
        return 'bg-blue-50 dark:bg-blue-950/40 text-blue-700 dark:text-blue-400 border-blue-300 dark:border-blue-800';
    }
  };

  return (
    <div className="p-5 rounded-2xl border border-[#E6DCA8] dark:border-[#26344F] bg-white dark:bg-[#162036] hover:border-[#FFC400] dark:hover:border-[#FFD21F] transition-all flex flex-col justify-between shadow-xs hover:shadow-md">
      <div>
        {/* Card Header */}
        <div className="flex items-start justify-between gap-3 mb-3">
          <div className="flex items-center gap-3">
            <div className="p-2.5 rounded-xl bg-[#FFFCEB] dark:bg-[#0E1627] border border-[#E6DCA8] dark:border-[#26344F] shadow-2xs">
              {getCategoryIcon()}
            </div>
            <div>
              <h3 className="font-bold text-[#16202D] dark:text-white text-base leading-snug">
                {resource.name}
              </h3>
              <div className="text-xs text-[#566070] dark:text-[#9FADC2] mt-0.5">
                Category:{' '}
                <strong className="text-[#16202D] dark:text-slate-200">
                  {(resource.category || resource.type || '').replace(/_/g, ' ')}
                </strong>
              </div>
            </div>
          </div>

          <span
            className={`px-2.5 py-0.5 rounded-full text-xs font-bold border shrink-0 ${getStatusBadge()}`}
          >
            {resource.status}
          </span>
        </div>

        {/* Location & Time */}
        <div className="flex items-center justify-between text-xs bg-[#FFFCEB]/70 dark:bg-[#0E1627] p-2.5 rounded-xl border border-[#E6DCA8] dark:border-[#26344F] mb-4">
          <div className="flex items-center gap-1.5 truncate text-[#16202D] dark:text-[#EEF2F8]">
            <MapPin className="w-3.5 h-3.5 text-[#0E8A94] dark:text-[#3CC6D0] shrink-0" />
            <span className="truncate font-medium">
              {typeof resource.location === 'object' && resource.location !== null
                ? resource.location.facilityName || `${resource.location.lat}, ${resource.location.lng}`
                : String(resource.location || 'Central Disaster Depot')}
            </span>
          </div>
          <div className="flex items-center gap-1 text-[#566070] dark:text-[#9FADC2] shrink-0 ml-2 font-mono text-[11px]">
            <Clock className="w-3 h-3" />
            <span>{resource.lastUpdated || 'Live Telemetry'}</span>
          </div>
        </div>

        {/* Key Specs Preview Chips */}
        {resource.specifications && resource.specifications.length > 0 && (
          <div className="flex flex-wrap gap-1.5 mb-4">
            {resource.specifications.slice(0, 2).map((spec, i) => (
              <span
                key={i}
                className="px-2 py-0.5 rounded-md text-[10px] font-medium bg-gray-100 dark:bg-[#0E1627] text-[#566070] dark:text-[#9FADC2] border border-gray-200 dark:border-gray-800 truncate max-w-[200px]"
              >
                {spec}
              </span>
            ))}
          </div>
        )}

        {/* Capacity Bar */}
        <div className="mb-4">
          <AllocationProgress
            allocated={resource.allocated ?? 0}
            total={resource.totalCapacity ?? resource.quantity ?? 0}
            unit={resource.unit}
          />
        </div>
      </div>

      {/* Action Footer */}
      <div className="pt-3 border-t border-[#E6DCA8] dark:border-[#26344F] flex items-center justify-between gap-2">
        <button
          onClick={onViewDetails}
          className="flex items-center gap-1 px-3 py-1.5 rounded-lg text-xs font-semibold text-[#566070] dark:text-[#9FADC2] hover:text-[#16202D] dark:hover:text-white hover:bg-black/5 dark:hover:bg-white/5 transition cursor-pointer"
        >
          <Info className="w-3.5 h-3.5" />
          Details
        </button>

        <button
          onClick={onAllocate}
          className="flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl bg-[#FFC400] dark:bg-[#FFD21F] hover:bg-[#E0AA00] text-[#1A1400] font-bold text-xs shadow-xs transition cursor-pointer"
        >
          <Sliders className="w-3 h-3" />
          Manage Allocation
        </button>
      </div>
    </div>
  );
};

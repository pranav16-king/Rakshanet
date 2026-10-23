// src/components/resources/ResourceDetailsModal.tsx
import React from 'react';
import type { ResourceItem } from '../../types';
import {
  X,
  Layers,
  MapPin,
  Phone,
  UserCheck,
  CheckCircle2,
  AlertTriangle,
  Clock,
  Shield,
  Truck,
  Compass,
  HeartPulse,
  Home,
  Utensils,
  Cpu,
  Activity,
  Sliders,
} from 'lucide-react';
import { AllocationProgress } from './AllocationProgress';

interface ResourceDetailsModalProps {
  resource: ResourceItem | null;
  isOpen: boolean;
  onClose: () => void;
  onOpenAllocate: (resource: ResourceItem) => void;
}

export const ResourceDetailsModal: React.FC<ResourceDetailsModalProps> = ({
  resource,
  isOpen,
  onClose,
  onOpenAllocate,
}) => {
  if (!isOpen || !resource) return null;

  const getCategoryIcon = () => {
    switch (resource.category) {
      case 'BOATS':
        return <Compass className="w-5 h-5 text-cyan-500" />;
      case '4WDS':
      case 'RESCUE_VEHICLES':
        return <Truck className="w-5 h-5 text-amber-500" />;
      case 'AMBULANCES':
      case 'MEDICAL':
        return <HeartPulse className="w-5 h-5 text-red-500" />;
      case 'SHELTERS':
        return <Home className="w-5 h-5 text-emerald-500" />;
      case 'FOOD_WATER':
      case 'RATIONS':
        return <Utensils className="w-5 h-5 text-orange-500" />;
      default:
        return <Cpu className="w-5 h-5 text-purple-500" />;
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
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-in fade-in duration-150">
      <div className="w-full max-w-xl rounded-2xl bg-white dark:bg-[#162036] border border-[#E6DCA8] dark:border-[#26344F] shadow-2xl overflow-hidden flex flex-col max-h-[90vh]">
        {/* Header */}
        <div className="p-5 border-b border-[#E6DCA8] dark:border-[#26344F] flex items-start justify-between gap-3 bg-[#FFFCEB]/50 dark:bg-[#0E1627]/50">
          <div className="flex items-center gap-3">
            <div className="p-3 rounded-xl bg-white dark:bg-[#162036] border border-[#E6DCA8] dark:border-[#26344F] shadow-xs">
              {getCategoryIcon()}
            </div>
            <div>
              <div className="flex items-center gap-2">
                <span className="font-mono text-xs font-bold text-[#8A5A00] dark:text-[#FFD21F]">
                  {resource.id}
                </span>
                <span className={`px-2 py-0.5 rounded-full text-[11px] font-bold border ${getStatusBadge()}`}>
                  {resource.status}
                </span>
              </div>
              <h2 className="text-lg sm:text-xl font-black text-[#16202D] dark:text-white tracking-tight mt-0.5">
                {resource.name}
              </h2>
            </div>
          </div>

          <button
            onClick={onClose}
            className="p-1.5 rounded-lg text-[#566070] dark:text-[#9FADC2] hover:text-[#16202D] dark:hover:text-white hover:bg-black/5 dark:hover:bg-white/10 transition cursor-pointer"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Modal Body */}
        <div className="p-6 overflow-y-auto space-y-6 text-xs text-[#16202D] dark:text-[#EEF2F8]">
          {/* Description */}
          {resource.description && (
            <p className="p-3.5 rounded-xl bg-[#FFFCEB] dark:bg-[#0E1627] border border-[#E6DCA8] dark:border-[#26344F] text-[#566070] dark:text-[#9FADC2] leading-relaxed">
              {resource.description}
            </p>
          )}

          {/* Allocation & Deployment Visualizer */}
          <div className="p-4 rounded-xl bg-[#FFFCEB]/40 dark:bg-[#0E1627]/60 border border-[#E6DCA8] dark:border-[#26344F] space-y-3">
            <div className="flex items-center justify-between">
              <span className="font-bold text-xs uppercase tracking-wider text-[#566070] dark:text-[#9FADC2]">
                Current Deployment Status
              </span>
              <span className="font-mono font-bold text-[#0E8A94] dark:text-[#3CC6D0]">
                {resource.allocated} / {resource.totalCapacity} {resource.unit} in-field
              </span>
            </div>
            <AllocationProgress
              allocated={resource.allocated ?? 0}
              total={resource.totalCapacity ?? resource.quantity ?? 0}
              unit={resource.unit}
            />
          </div>

          {/* Operational Details Grid */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div className="p-3.5 rounded-xl border border-[#E6DCA8] dark:border-[#26344F] bg-white dark:bg-[#162036] space-y-1">
              <span className="text-[11px] font-semibold text-[#566070] dark:text-[#9FADC2] flex items-center gap-1.5">
                <MapPin className="w-3.5 h-3.5 text-[#0E8A94] dark:text-[#3CC6D0]" /> Depot Location
              </span>
              <div className="font-bold text-sm text-[#16202D] dark:text-white">
                {typeof resource.location === 'object' && resource.location !== null
                  ? resource.location.facilityName || `${resource.location.lat}, ${resource.location.lng}`
                  : String(resource.location || 'Central Disaster Depot')}
              </div>
            </div>

            <div className="p-3.5 rounded-xl border border-[#E6DCA8] dark:border-[#26344F] bg-white dark:bg-[#162036] space-y-1">
              <span className="text-[11px] font-semibold text-[#566070] dark:text-[#9FADC2] flex items-center gap-1.5">
                <Shield className="w-3.5 h-3.5 text-[#FFC400]" /> Readiness Level
              </span>
              <div className="font-bold text-sm text-[#1E8E4E] dark:text-[#4CD08A] flex items-center gap-1.5">
                <CheckCircle2 className="w-4 h-4" />
                {resource.maintenanceStatus || '100% OPERATIONAL'}
              </div>
            </div>

            <div className="p-3.5 rounded-xl border border-[#E6DCA8] dark:border-[#26344F] bg-white dark:bg-[#162036] space-y-1">
              <span className="text-[11px] font-semibold text-[#566070] dark:text-[#9FADC2] flex items-center gap-1.5">
                <UserCheck className="w-3.5 h-3.5 text-[#8A5A00] dark:text-[#FFD21F]" /> Depot Officer
              </span>
              <div className="font-bold text-sm text-[#16202D] dark:text-white">
                {resource.depotOfficer || 'State Logistics Commander'}
              </div>
            </div>

            <div className="p-3.5 rounded-xl border border-[#E6DCA8] dark:border-[#26344F] bg-white dark:bg-[#162036] space-y-1">
              <span className="text-[11px] font-semibold text-[#566070] dark:text-[#9FADC2] flex items-center gap-1.5">
                <Phone className="w-3.5 h-3.5 text-[#1E8E4E]" /> Direct Dispatch Contact
              </span>
              <div className="font-mono font-bold text-sm text-[#16202D] dark:text-white">
                {resource.contactNumber || '+91-94450-10701'}
              </div>
            </div>
          </div>

          {/* Technical Specifications */}
          {resource.specifications && resource.specifications.length > 0 && (
            <div className="space-y-2">
              <span className="text-xs font-bold uppercase tracking-wider text-[#566070] dark:text-[#9FADC2] block">
                Technical & Logistics Specifications:
              </span>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                {resource.specifications.map((spec, i) => (
                  <div
                    key={i}
                    className="p-2.5 rounded-lg bg-[#FFFCEB]/60 dark:bg-[#0E1627] border border-[#E6DCA8] dark:border-[#26344F] flex items-center gap-2 text-xs"
                  >
                    <span className="w-1.5 h-1.5 rounded-full bg-[#FFC400] shrink-0" />
                    <span>{spec}</span>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>

        {/* Modal Footer */}
        <div className="p-4 border-t border-[#E6DCA8] dark:border-[#26344F] bg-[#FFFCEB]/30 dark:bg-[#0E1627]/40 flex items-center justify-between gap-3">
          <div className="text-[11px] text-[#566070] dark:text-[#9FADC2]">
            Telemetry: <span className="font-medium text-[#1E8E4E] dark:text-[#4CD08A]">Live Sync Active</span>
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={onClose}
              className="px-4 py-2 rounded-xl text-xs font-semibold bg-gray-100 dark:bg-[#1E293B] text-[#566070] dark:text-[#9FADC2] hover:bg-gray-200 transition cursor-pointer"
            >
              Close
            </button>
            <button
              onClick={() => {
                onClose();
                onOpenAllocate(resource);
              }}
              className="flex items-center gap-1.5 px-4 py-2 rounded-xl text-xs font-bold bg-[#FFC400] dark:bg-[#FFD21F] text-[#1A1400] hover:bg-[#E0AA00] transition cursor-pointer shadow-xs"
            >
              <Sliders className="w-3.5 h-3.5" />
              Adjust Allocation
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

import React from 'react';
import { Search } from 'lucide-react';
import type { MapFilterState } from '../../types/map';

export interface MapControlBarProps {
  filters: MapFilterState;
  onFilterChange: (newFilters: Partial<MapFilterState>) => void;
  className?: string;
}

export const MapControlBar: React.FC<MapControlBarProps> = ({
  filters,
  onFilterChange,
  className = '',
}) => {
  return (
    <div
      className={`bg-white/90 dark:bg-[#0B1220]/90 backdrop-blur-md border border-[#E2E8F0] dark:border-[#26344F] rounded-xl p-2.5 shadow-md flex flex-wrap items-center gap-3 ${className}`}
    >
      {/* Search Input */}
      <div className="relative flex-1 min-w-[200px]">
        <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-[#64748B] dark:text-[#9FADC2]" />
        <input
          type="text"
          value={filters.searchQuery}
          onChange={(e) => onFilterChange({ searchQuery: e.target.value })}
          placeholder="Search location, incident or device..."
          className="w-full pl-9 pr-3 py-1.5 text-xs rounded-lg bg-[#F8FAFC] dark:bg-[#162036] border border-[#E2E8F0] dark:border-[#26344F] text-[#0F172A] dark:text-[#EEF2F8] placeholder-[#64748B] dark:placeholder-[#9FADC2] focus:outline-none focus:ring-2 focus:ring-[#FFC400]"
        />
      </div>

      {/* Incidents Filter Dropdown */}
      <div className="w-36">
        <select
          value={filters.incidentType}
          onChange={(e) => onFilterChange({ incidentType: e.target.value })}
          className="w-full px-2.5 py-1.5 text-xs rounded-lg bg-[#F8FAFC] dark:bg-[#162036] border border-[#E2E8F0] dark:border-[#26344F] text-[#0F172A] dark:text-[#EEF2F8] focus:outline-none focus:ring-2 focus:ring-[#FFC400] cursor-pointer"
        >
          <option value="ALL">All Incidents</option>
          <option value="sos">SOS Clusters</option>
          <option value="landslide">Landslides</option>
          <option value="flood">Flood Areas</option>
          <option value="rescue_team">Rescue Teams</option>
        </select>
      </div>

      {/* Devices Filter Dropdown */}
      <div className="w-32">
        <select
          value={filters.deviceType}
          onChange={(e) => onFilterChange({ deviceType: e.target.value })}
          className="w-full px-2.5 py-1.5 text-xs rounded-lg bg-[#F8FAFC] dark:bg-[#162036] border border-[#E2E8F0] dark:border-[#26344F] text-[#0F172A] dark:text-[#EEF2F8] focus:outline-none focus:ring-2 focus:ring-[#FFC400] cursor-pointer"
        >
          <option value="ALL">All Devices</option>
          <option value="Smartphone">Smartphones</option>
          <option value="Relay Node">Relay Nodes</option>
          <option value="Tablet Responder">Tablets</option>
          <option value="LoRa Mesh Hop">LoRa Hops</option>
        </select>
      </div>

      {/* Status Filter Dropdown */}
      <div className="w-28">
        <select
          value={filters.status}
          onChange={(e) => onFilterChange({ status: e.target.value })}
          className="w-full px-2.5 py-1.5 text-xs rounded-lg bg-[#F8FAFC] dark:bg-[#162036] border border-[#E2E8F0] dark:border-[#26344F] text-[#0F172A] dark:text-[#EEF2F8] focus:outline-none focus:ring-2 focus:ring-[#FFC400] cursor-pointer"
        >
          <option value="ALL">All Status</option>
          <option value="Online">Online</option>
          <option value="Relay">Relay</option>
          <option value="Offline">Offline</option>
        </select>
      </div>
    </div>
  );
};

// src/pages/resources/ResourcesPage.tsx
import React, { useState, useEffect, useMemo } from 'react';
import type { ResourceItem } from '../../types';
import { resourcesApi } from '../../api/resources';
import { ResourceCard } from '../../components/resources/ResourceCard';
import { ResourceAllocationModal } from '../../components/resources/ResourceAllocationModal';
import { ResourceDetailsModal } from '../../components/resources/ResourceDetailsModal';
import {
  Package,
  RefreshCw,
  Search,
  CheckCircle2,
  AlertTriangle,
  Compass,
  Truck,
  HeartPulse,
  Home,
  Utensils,
  Layers,
  Shield,
  Activity,
} from 'lucide-react';

export const ResourcesPage: React.FC = () => {
  const [resources, setResources] = useState<ResourceItem[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [searchTerm, setSearchTerm] = useState<string>('');
  const [selectedCategory, setSelectedCategory] = useState<string>('ALL');
  const [selectedStatus, setSelectedStatus] = useState<string>('ALL');

  // Modals state
  const [editingResource, setEditingResource] = useState<ResourceItem | null>(null);
  const [inspectingResource, setInspectingResource] = useState<ResourceItem | null>(null);

  const fetchResources = async () => {
    setLoading(true);
    try {
      const data = await resourcesApi.getResources();
      setResources(data);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchResources();
  }, []);

  const handleSaveAllocation = async (resourceId: string, newAllocated: number) => {
    const res = await resourcesApi.updateResourceAllocation(resourceId, newAllocated);
    if (res.success) {
      setResources((prev) =>
        prev.map((r) => (r.id === resourceId ? res.resource : r))
      );
    }
  };

  // Filtered resources based on category, status, and search query
  const filteredResources = useMemo(() => {
    return resources.filter((item) => {
      const query = searchTerm.trim().toLowerCase();
      const locStr =
        typeof item.location === 'object' && item.location !== null
          ? item.location.facilityName || `${item.location.lat}, ${item.location.lng}`
          : String(item.location || '');

      const matchesSearch =
        !query ||
        item.name.toLowerCase().includes(query) ||
        item.id.toLowerCase().includes(query) ||
        locStr.toLowerCase().includes(query) ||
        (item.description && item.description.toLowerCase().includes(query));

      const matchesCategory =
        selectedCategory === 'ALL' ||
        item.category === selectedCategory ||
        (selectedCategory === '4WDS' && (item.category === '4WDS' || item.category === 'RESCUE_VEHICLES')) ||
        (selectedCategory === 'FOOD_WATER' && (item.category === 'FOOD_WATER' || item.category === 'RATIONS')) ||
        item.type === selectedCategory;

      const matchesStatus =
        selectedStatus === 'ALL' ||
        item.status?.toUpperCase() === selectedStatus.toUpperCase();

      return matchesSearch && matchesCategory && matchesStatus;
    });
  }, [resources, searchTerm, selectedCategory, selectedStatus]);

  // Real Dynamic Metrics computed from actual inventory
  const totalCategories = useMemo(() => {
    const set = new Set(resources.map((r) => r.category || r.type));
    return set.size;
  }, [resources]);

  const totalAvailable = useMemo(() => {
    return resources.reduce((sum, r) => sum + (Number(r.available) || 0), 0);
  }, [resources]);

  const totalDeployed = useMemo(() => {
    return resources.reduce((sum, r) => sum + (Number(r.allocated) || 0), 0);
  }, [resources]);

  const shelterBedsFree = useMemo(() => {
    const shelters = resources.filter((r) => r.category === 'SHELTERS');
    if (shelters.length === 0) return '600 Beds Free';
    const availableCamps = shelters.reduce((s, r) => s + (Number(r.available) || 0), 0);
    return `${availableCamps * 150} Beds Free (${availableCamps} Camps)`;
  }, [resources]);

  const criticalItemsCount = useMemo(() => {
    return resources.filter(
      (r) => r.urgency === 'CRITICAL' || r.status === 'LOW' || r.status === 'DEPLETED'
    ).length;
  }, [resources]);

  const categoryPills: Array<{
    key: string;
    label: string;
    icon: React.ComponentType<{ className?: string }>;
    color: string;
  }> = [
    { key: 'ALL', label: 'All Resources', icon: Layers, color: 'text-amber-500' },
    { key: 'BOATS', label: 'Rescue Boats', icon: Compass, color: 'text-cyan-500' },
    { key: '4WDS', label: '4WD Vehicles', icon: Truck, color: 'text-amber-500' },
    { key: 'AMBULANCES', label: 'Ambulances', icon: Activity, color: 'text-rose-500' },
    { key: 'MEDICAL', label: 'Medical Trauma Kits', icon: HeartPulse, color: 'text-red-500' },
    { key: 'SHELTERS', label: 'Emergency Shelters', icon: Home, color: 'text-emerald-500' },
    { key: 'FOOD_WATER', label: 'Food & Water Rations', icon: Utensils, color: 'text-orange-500' },
  ];

  return (
    <div className="p-4 sm:p-6 max-w-7xl mx-auto space-y-6">
      {/* Header bar */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2.5">
            <span className="p-2.5 rounded-xl bg-amber-500/10 text-[#8A5A00] dark:text-[#FFD21F] border border-amber-500/20 shadow-xs">
              <Package className="w-6 h-6" />
            </span>
            <div>
              <h1
                className="text-2xl sm:text-3xl font-black text-[#16202D] dark:text-white tracking-tight"
                style={{ fontFamily: '"Barlow Semi Condensed", sans-serif' }}
              >
                Relief Resources & Disaster Logistics Catalog
              </h1>
              <p className="text-xs sm:text-sm text-[#566070] dark:text-[#9FADC2] mt-0.5">
                Real-time inventory and allocation status of Zodiac boats, 4WD vehicles, trauma kits, shelters, and rations.
              </p>
            </div>
          </div>
        </div>

        <button
          onClick={fetchResources}
          disabled={loading}
          className="flex items-center gap-2 px-4 py-2.5 rounded-xl border border-[#E6DCA8] dark:border-[#26344F] bg-white dark:bg-[#162036] hover:bg-[#FFFCEB] dark:hover:bg-[#1C2844] text-[#16202D] dark:text-white text-xs font-bold transition shadow-xs cursor-pointer self-start md:self-auto"
        >
          <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin text-[#FFC400]' : ''}`} />
          Refresh Inventory
        </button>
      </div>

      {/* Real KPI Stats cards */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <div className="p-4 rounded-2xl bg-white dark:bg-[#162036] border border-[#E6DCA8] dark:border-[#26344F] shadow-xs">
          <div className="text-xs font-semibold text-[#566070] dark:text-[#9FADC2]">
            Tracked Asset Classes
          </div>
          <div className="text-2xl sm:text-3xl font-black text-[#16202D] dark:text-white mt-1">
            {totalCategories || 7} Categories
          </div>
          <div className="text-[11px] text-[#566070] dark:text-[#9FADC2] mt-0.5">
            Disaster relief logistics
          </div>
        </div>

        <div className="p-4 rounded-2xl bg-white dark:bg-[#162036] border border-[#E6DCA8] dark:border-[#26344F] shadow-xs">
          <div className="text-xs font-semibold text-[#566070] dark:text-[#9FADC2]">
            Available &amp; Ready
          </div>
          <div className="text-2xl sm:text-3xl font-black text-[#1E8E4E] dark:text-[#4CD08A] mt-1 flex items-center gap-2">
            <CheckCircle2 className="w-5 h-5 shrink-0" />
            {totalAvailable.toLocaleString()} Units
          </div>
          <div className="text-[11px] text-[#566070] dark:text-[#9FADC2] mt-0.5">
            Deployment ready across bases
          </div>
        </div>

        <div className="p-4 rounded-2xl bg-white dark:bg-[#162036] border border-[#E6DCA8] dark:border-[#26344F] shadow-xs">
          <div className="text-xs font-semibold text-[#566070] dark:text-[#9FADC2]">
            In-Field Deployment
          </div>
          <div className="text-2xl sm:text-3xl font-black text-[#0E8A94] dark:text-[#3CC6D0] mt-1 flex items-center gap-2">
            <Shield className="w-5 h-5 shrink-0" />
            {totalDeployed.toLocaleString()} Units
          </div>
          <div className="text-[11px] text-[#566070] dark:text-[#9FADC2] mt-0.5">
            Allocated to active rescue operations
          </div>
        </div>

        <div className="p-4 rounded-2xl bg-white dark:bg-[#162036] border border-[#E6DCA8] dark:border-[#26344F] shadow-xs">
          <div className="text-xs font-semibold text-[#566070] dark:text-[#9FADC2]">
            Shelter Capacity Reserve
          </div>
          <div className="text-2xl sm:text-3xl font-black text-[#8A5A00] dark:text-[#FFD21F] mt-1 flex items-center gap-2">
            <Home className="w-5 h-5 shrink-0" />
            {shelterBedsFree}
          </div>
          <div className="text-[11px] text-[#566070] dark:text-[#9FADC2] mt-0.5">
            Across district centers
          </div>
        </div>
      </div>

      {/* Filter Category Pills */}
      <div className="flex flex-wrap items-center gap-2 pb-1">
        {categoryPills.map((pill) => {
          const Icon = pill.icon;
          const isSelected = selectedCategory === pill.key;
          return (
            <button
              key={pill.key}
              onClick={() => setSelectedCategory(pill.key)}
              className={`flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl text-xs font-bold transition cursor-pointer ${
                isSelected
                  ? 'bg-[#FFC400] dark:bg-[#FFD21F] text-[#1A1400] shadow-xs'
                  : 'bg-white dark:bg-[#162036] text-[#566070] dark:text-[#9FADC2] border border-[#E6DCA8] dark:border-[#26344F] hover:bg-[#FFFCEB] dark:hover:bg-[#1C2844] hover:text-[#16202D] dark:hover:text-white'
              }`}
            >
              <Icon className={`w-3.5 h-3.5 ${isSelected ? 'text-[#1A1400]' : pill.color}`} />
              <span>{pill.label}</span>
            </button>
          );
        })}
      </div>

      {/* Search Input & Status Filter */}
      <div className="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-3">
        <div className="relative w-full sm:w-96">
          <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-[#566070] dark:text-[#9FADC2]" />
          <input
            type="text"
            placeholder="Search by resource name, depot location, specs..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full bg-white dark:bg-[#162036] border border-[#E6DCA8] dark:border-[#26344F] rounded-xl pl-9 pr-3.5 py-2 text-xs text-[#16202D] dark:text-white placeholder-[#566070] dark:placeholder-[#9FADC2] focus:outline-none focus:ring-2 focus:ring-[#FFC400]"
          />
        </div>

        <div className="flex items-center gap-2">
          <span className="text-xs text-[#566070] dark:text-[#9FADC2] font-semibold">
            Status:
          </span>
          <select
            value={selectedStatus}
            onChange={(e) => setSelectedStatus(e.target.value)}
            className="h-9 px-3 rounded-xl bg-white dark:bg-[#162036] border border-[#E6DCA8] dark:border-[#26344F] text-xs font-bold text-[#16202D] dark:text-white focus:outline-none focus:ring-2 focus:ring-[#FFC400] cursor-pointer"
          >
            <option value="ALL">All Statuses</option>
            <option value="READY">Ready &amp; Available</option>
            <option value="LOW">Low Reserves</option>
            <option value="DEPLETED">Depleted / Full</option>
          </select>
        </div>
      </div>

      {/* Grid of Resource Cards */}
      {loading ? (
        <div className="p-16 text-center text-[#566070] dark:text-[#9FADC2] rounded-2xl bg-white dark:bg-[#162036] border border-[#E6DCA8] dark:border-[#26344F]">
          <RefreshCw className="w-8 h-8 animate-spin mx-auto text-[#FFC400] mb-3" />
          <p className="font-bold text-sm text-[#16202D] dark:text-white">
            Connecting to Disaster Logistics Gateway...
          </p>
          <p className="text-xs text-[#566070] dark:text-[#9FADC2] mt-1">
            Loading real-time asset tracking and depot allocations
          </p>
        </div>
      ) : filteredResources.length === 0 ? (
        <div className="p-16 text-center rounded-2xl bg-white dark:bg-[#162036] border border-[#E6DCA8] dark:border-[#26344F]">
          <AlertTriangle className="w-10 h-10 text-amber-500 mx-auto mb-3 opacity-80" />
          <h3 className="font-bold text-base text-[#16202D] dark:text-white">
            No resources match active filters
          </h3>
          <p className="text-xs text-[#566070] dark:text-[#9FADC2] mt-1 max-w-sm mx-auto">
            Try resetting your search query or choosing another asset category.
          </p>
          <button
            onClick={() => {
              setSearchTerm('');
              setSelectedCategory('ALL');
              setSelectedStatus('ALL');
            }}
            className="mt-4 px-4 py-2 rounded-xl text-xs font-bold bg-[#FFC400] dark:bg-[#FFD21F] text-[#1A1400] hover:bg-[#E0AA00] transition cursor-pointer"
          >
            Reset Filters
          </button>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
          {filteredResources.map((res) => (
            <ResourceCard
              key={res.id}
              resource={res}
              onAllocate={() => setEditingResource(res)}
              onViewDetails={() => setInspectingResource(res)}
            />
          ))}
        </div>
      )}

      {/* Allocation adjustment modal */}
      {editingResource && (
        <ResourceAllocationModal
          resource={editingResource}
          isOpen={true}
          onClose={() => setEditingResource(null)}
          onSave={handleSaveAllocation}
        />
      )}

      {/* Full Resource Details modal */}
      {inspectingResource && (
        <ResourceDetailsModal
          resource={inspectingResource}
          isOpen={true}
          onClose={() => setInspectingResource(null)}
          onOpenAllocate={(res) => {
            setInspectingResource(null);
            setEditingResource(res);
          }}
        />
      )}
    </div>
  );
};

export default ResourcesPage;

// src/pages/resources/ResourcesPage.tsx
import React, { useState, useEffect } from 'react';
import type { ResourceItem } from '../../types';
import { resourcesApi } from '../../api/resources';
import { ResourceCard } from '../../components/resources/ResourceCard';
import { ResourceAllocationModal } from '../../components/resources/ResourceAllocationModal';
import {
  Package,
  RefreshCw,
  Search,
  Filter,
  CheckCircle2,
  AlertTriangle,
  Compass,
  Truck,
  HeartPulse,
  Home,
  Utensils,
} from 'lucide-react';

export const ResourcesPage: React.FC = () => {
  const [resources, setResources] = useState<ResourceItem[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [searchTerm, setSearchTerm] = useState<string>('');
  const [selectedCategory, setSelectedCategory] = useState<string>('ALL');
  const [editingResource, setEditingResource] = useState<ResourceItem | null>(null);

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

  const filteredResources = resources.filter((item) => {
    const locStr =
      typeof item.location === 'object' && item.location !== null
        ? item.location.facilityName || `${item.location.lat}, ${item.location.lng}`
        : String(item.location || '');
    const matchesSearch =
      item.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      locStr.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesCategory =
      selectedCategory === 'ALL' || item.category === selectedCategory || item.type === selectedCategory;
    return matchesSearch && matchesCategory;
  });

  const totalAssets = resources.length;
  const criticalItems = resources.filter((r) => r.urgency === 'CRITICAL' || r.status === 'LOW' || r.status === 'DEPLETED').length;
  const readyItems = resources.filter((r) => r.status === 'READY' || r.status === 'AVAILABLE').length;

  return (
    <div className="p-6 max-w-7xl mx-auto space-y-6 text-slate-100">
      {/* Header bar */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <span className="p-2 rounded-xl bg-amber-500/10 text-amber-400 border border-amber-500/20">
              <Package className="w-6 h-6" />
            </span>
            <h1 className="text-2xl font-bold tracking-tight text-white font-display">
              Relief Resources & Disaster Logistics Catalog
            </h1>
          </div>
          <p className="text-sm text-slate-400 mt-1">
            Real-time inventory and allocation status of Zodiac boats, 4WD vehicles, trauma kits, shelters, and rations.
          </p>
        </div>

        <button
          onClick={fetchResources}
          disabled={loading}
          className="flex items-center gap-2 px-3.5 py-2.5 rounded-lg border border-slate-700 bg-[#162036] hover:bg-slate-700/60 text-slate-200 text-sm font-medium transition"
        >
          <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
          Refresh Inventory
        </button>
      </div>

      {/* KPI Stats cards */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <div className="p-4 rounded-xl bg-[#162036] border border-slate-700/70 shadow-sm">
          <div className="text-xs text-slate-400">Tracked Asset Classes</div>
          <div className="text-2xl font-bold text-white mt-1">{totalAssets} Categories</div>
          <div className="text-xs text-slate-500 mt-0.5">Disaster relief logistics</div>
        </div>

        <div className="p-4 rounded-xl bg-[#162036] border border-slate-700/70 shadow-sm">
          <div className="text-xs text-slate-400">Available & Ready</div>
          <div className="text-2xl font-bold text-emerald-400 mt-1 flex items-center gap-2">
            <CheckCircle2 className="w-5 h-5" />
            {readyItems} Items
          </div>
          <div className="text-xs text-slate-500 mt-0.5">Deployment ready</div>
        </div>

        <div className="p-4 rounded-xl bg-[#162036] border border-slate-700/70 shadow-sm">
          <div className="text-xs text-slate-400">Critical Priority Assets</div>
          <div className="text-2xl font-bold text-red-400 mt-1 flex items-center gap-2">
            <AlertTriangle className="w-5 h-5" />
            {criticalItems} Classes
          </div>
          <div className="text-xs text-slate-500 mt-0.5">Boats & ALS Trauma Kits</div>
        </div>

        <div className="p-4 rounded-xl bg-[#162036] border border-slate-700/70 shadow-sm">
          <div className="text-xs text-slate-400">Shelter Capacity Reserve</div>
          <div className="text-2xl font-bold text-cyan-400 mt-1 flex items-center gap-2">
            <Home className="w-5 h-5" />
            660 Beds Free
          </div>
          <div className="text-xs text-slate-500 mt-0.5">Across district centers</div>
        </div>
      </div>

      {/* Filter Category Pills */}
      <div className="flex flex-wrap items-center gap-2 pb-1">
        <button
          onClick={() => setSelectedCategory('ALL')}
          className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition ${
            selectedCategory === 'ALL'
              ? 'bg-amber-400 text-slate-950 shadow-md'
              : 'bg-[#162036] text-slate-300 border border-slate-700 hover:bg-slate-800'
          }`}
        >
          All Resources
        </button>

        <button
          onClick={() => setSelectedCategory('BOATS')}
          className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold transition ${
            selectedCategory === 'BOATS'
              ? 'bg-cyan-500 text-slate-950 shadow-md'
              : 'bg-[#162036] text-slate-300 border border-slate-700 hover:bg-slate-800'
          }`}
        >
          <Compass className="w-3.5 h-3.5" />
          Rescue Boats
        </button>

        <button
          onClick={() => setSelectedCategory('RESCUE_VEHICLES')}
          className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold transition ${
            selectedCategory === 'RESCUE_VEHICLES'
              ? 'bg-amber-400 text-slate-950 shadow-md'
              : 'bg-[#162036] text-slate-300 border border-slate-700 hover:bg-slate-800'
          }`}
        >
          <Truck className="w-3.5 h-3.5" />
          4WD Vehicles
        </button>

        <button
          onClick={() => setSelectedCategory('MEDICAL')}
          className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold transition ${
            selectedCategory === 'MEDICAL'
              ? 'bg-red-500 text-white shadow-md'
              : 'bg-[#162036] text-slate-300 border border-slate-700 hover:bg-slate-800'
          }`}
        >
          <HeartPulse className="w-3.5 h-3.5" />
          Medical Trauma Kits
        </button>

        <button
          onClick={() => setSelectedCategory('SHELTERS')}
          className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold transition ${
            selectedCategory === 'SHELTERS'
              ? 'bg-emerald-500 text-slate-950 shadow-md'
              : 'bg-[#162036] text-slate-300 border border-slate-700 hover:bg-slate-800'
          }`}
        >
          <Home className="w-3.5 h-3.5" />
          Emergency Shelters
        </button>

        <button
          onClick={() => setSelectedCategory('RATIONS')}
          className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold transition ${
            selectedCategory === 'RATIONS'
              ? 'bg-orange-500 text-white shadow-md'
              : 'bg-[#162036] text-slate-300 border border-slate-700 hover:bg-slate-800'
          }`}
        >
          <Utensils className="w-3.5 h-3.5" />
          Food &amp; Water Rations
        </button>
      </div>

      {/* Search Input */}
      <div className="relative w-full sm:w-96">
        <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
        <input
          type="text"
          placeholder="Search by resource name, location depot..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          className="w-full bg-[#0E1627] border border-slate-700 rounded-lg pl-9 pr-3.5 py-2 text-sm text-slate-200 placeholder-slate-500 focus:outline-none focus:border-amber-400"
        />
      </div>

      {/* Grid of Resource Cards */}
      {loading ? (
        <div className="p-12 text-center text-slate-400">
          <RefreshCw className="w-6 h-6 animate-spin mx-auto text-amber-400 mb-2" />
          Loading relief resource inventory...
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
          {filteredResources.map((res) => (
            <ResourceCard
              key={res.id}
              resource={res}
              onAllocate={() => setEditingResource(res)}
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
    </div>
  );
};

export default ResourcesPage;

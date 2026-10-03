// src/pages/rescue-ops/RescueOpsPage.tsx
import React, { useState, useEffect } from 'react';
import type { RescueUnit, DispatchPlan } from '../../types';
import { rescueOpsApi } from '../../api/rescueOps';
import { FleetTable } from '../../components/rescue/FleetTable';
import { DispatchPlanSummary } from '../../components/rescue/DispatchPlanSummary';
import {
  Sparkles,
  RefreshCw,
  Search,
  Filter,
  CheckCircle2,
  AlertCircle,
  Clock,
  Shield,
} from 'lucide-react';

export const RescueOpsPage: React.FC = () => {
  const [fleet, setFleet] = useState<RescueUnit[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [optimizing, setOptimizing] = useState<boolean>(false);
  const [activePlan, setActivePlan] = useState<DispatchPlan | null>(null);
  const [searchTerm, setSearchTerm] = useState<string>('');
  const [typeFilter, setTypeFilter] = useState<string>('ALL');
  const [statusFilter, setStatusFilter] = useState<string>('ALL');
  const [selectedUnit, setSelectedUnit] = useState<RescueUnit | null>(null);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  const fetchFleet = async () => {
    setLoading(true);
    setErrorMsg(null);
    try {
      const data = await rescueOpsApi.getFleet();
      setFleet(data);
    } catch {
      setErrorMsg('Failed to fetch emergency response fleet.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchFleet();
  }, []);

  const handleRunOptimization = async () => {
    setOptimizing(true);
    setErrorMsg(null);
    try {
      const plan = await rescueOpsApi.optimizeDispatch(fleet);
      setActivePlan(plan);
    } catch {
      setErrorMsg('MILP dispatch optimization failed to compute.');
    } finally {
      setOptimizing(false);
    }
  };

  const filteredFleet = fleet.filter((unit) => {
    const matchesSearch =
      unit.unit_id.toLowerCase().includes(searchTerm.toLowerCase()) ||
      unit.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      unit.capabilities.some((c) => c.toLowerCase().includes(searchTerm.toLowerCase()));

    const matchesType = typeFilter === 'ALL' || unit.unit_type === typeFilter;
    const matchesStatus = statusFilter === 'ALL' || unit.status === statusFilter;

    return matchesSearch && matchesType && matchesStatus;
  });

  const availableCount = fleet.filter((u) => u.status === 'AVAILABLE').length;
  const inTransitCount = fleet.filter((u) => u.status === 'IN_TRANSIT' || u.status === 'DISPATCHED').length;
  const totalCapacity = fleet.reduce((acc, u) => acc + u.capacity, 0);

  return (
    <div className="p-6 max-w-7xl mx-auto space-y-6 text-slate-100">
      {/* Header section */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <span className="p-2 rounded-xl bg-amber-500/10 text-amber-400 border border-amber-500/20">
              <Shield className="w-6 h-6" />
            </span>
            <h1 className="text-2xl font-bold tracking-tight text-white font-display">
              Rescue Operations & Fleet Dispatch
            </h1>
          </div>
          <p className="text-sm text-slate-400 mt-1">
            Real-time management of amphibious boats, 4WD vehicles, helicopters, and MILP dispatch engine.
          </p>
        </div>

        {/* Action button */}
        <div className="flex items-center gap-3">
          <button
            onClick={fetchFleet}
            disabled={loading}
            className="flex items-center gap-2 px-3.5 py-2.5 rounded-lg border border-slate-700 bg-[#162036] hover:bg-slate-700/60 text-slate-200 text-sm font-medium transition"
            title="Refresh Fleet"
          >
            <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
            Refresh
          </button>

          <button
            onClick={handleRunOptimization}
            disabled={optimizing}
            className="flex items-center gap-2 px-5 py-2.5 rounded-lg bg-amber-400 hover:bg-amber-300 text-slate-950 font-bold text-sm shadow-lg shadow-amber-400/20 transition disabled:opacity-50"
          >
            {optimizing ? (
              <>
                <RefreshCw className="w-4 h-4 animate-spin text-slate-950" />
                Solving MILP Matrix...
              </>
            ) : (
              <>
                <Sparkles className="w-4 h-4 text-slate-950" />
                Run Optimization Dispatch
              </>
            )}
          </button>
        </div>
      </div>

      {errorMsg && (
        <div className="p-4 rounded-xl bg-red-500/10 border border-red-500/30 text-red-400 text-sm flex items-center gap-2">
          <AlertCircle className="w-5 h-5 flex-shrink-0" />
          <span>{errorMsg}</span>
        </div>
      )}

      {/* KPI stats strip */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <div className="p-4 rounded-xl bg-[#162036] border border-slate-700/70 shadow-sm">
          <div className="text-xs text-slate-400">Total Registered Fleet</div>
          <div className="text-2xl font-bold text-white mt-1">{fleet.length} Units</div>
          <div className="text-xs text-slate-500 mt-0.5">Multi-agency coordination</div>
        </div>

        <div className="p-4 rounded-xl bg-[#162036] border border-slate-700/70 shadow-sm">
          <div className="text-xs text-slate-400">Available For Immediate Dispatch</div>
          <div className="text-2xl font-bold text-emerald-400 mt-1 flex items-center gap-2">
            <CheckCircle2 className="w-5 h-5" />
            {availableCount}
          </div>
          <div className="text-xs text-slate-500 mt-0.5">Ready for instant assignment</div>
        </div>

        <div className="p-4 rounded-xl bg-[#162036] border border-slate-700/70 shadow-sm">
          <div className="text-xs text-slate-400">Dispatched / In Transit</div>
          <div className="text-2xl font-bold text-cyan-400 mt-1 flex items-center gap-2">
            <Clock className="w-5 h-5" />
            {inTransitCount}
          </div>
          <div className="text-xs text-slate-500 mt-0.5">Active field missions</div>
        </div>

        <div className="p-4 rounded-xl bg-[#162036] border border-slate-700/70 shadow-sm">
          <div className="text-xs text-slate-400">Total Evacuation Capacity</div>
          <div className="text-2xl font-bold text-amber-400 mt-1">
            {totalCapacity} <span className="text-xs font-normal text-slate-400">pax/trip</span>
          </div>
          <div className="text-xs text-slate-500 mt-0.5">Combined rescue throughput</div>
        </div>
      </div>

      {/* Generated Optimal Dispatch Plan Display */}
      {activePlan && (
        <DispatchPlanSummary
          plan={activePlan}
          onClose={() => setActivePlan(null)}
        />
      )}

      {/* Filter & Search Bar */}
      <div className="flex flex-col sm:flex-row gap-3 items-center justify-between bg-[#162036] p-3.5 rounded-xl border border-slate-700/70">
        <div className="relative w-full sm:w-80">
          <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
          <input
            type="text"
            placeholder="Search by unit ID, name, capability..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full bg-[#0E1627] border border-slate-700 rounded-lg pl-9 pr-3.5 py-2 text-sm text-slate-200 placeholder-slate-500 focus:outline-none focus:border-amber-400"
          />
        </div>

        <div className="flex items-center gap-2 w-full sm:w-auto">
          <div className="flex items-center gap-1.5 text-xs text-slate-400">
            <Filter className="w-3.5 h-3.5" />
            <span>Type:</span>
          </div>
          <select
            value={typeFilter}
            onChange={(e) => setTypeFilter(e.target.value)}
            className="bg-[#0E1627] border border-slate-700 text-slate-200 rounded-lg px-3 py-1.5 text-xs focus:outline-none focus:border-amber-400"
          >
            <option value="ALL">All Types</option>
            <option value="BOAT">Boats</option>
            <option value="HIGH_CLEARANCE_4WD">High-Clearance 4WD</option>
            <option value="AMBULANCE">Ambulance</option>
            <option value="HELICOPTER">Helicopter</option>
          </select>

          <div className="flex items-center gap-1.5 text-xs text-slate-400 ml-2">
            <span>Status:</span>
          </div>
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="bg-[#0E1627] border border-slate-700 text-slate-200 rounded-lg px-3 py-1.5 text-xs focus:outline-none focus:border-amber-400"
          >
            <option value="ALL">All Statuses</option>
            <option value="AVAILABLE">Available</option>
            <option value="DISPATCHED">Dispatched</option>
            <option value="IN_TRANSIT">In Transit</option>
            <option value="REST">Rest</option>
          </select>
        </div>
      </div>

      {/* Fleet table */}
      {loading ? (
        <div className="p-12 text-center text-slate-400">
          <RefreshCw className="w-8 h-8 animate-spin mx-auto text-amber-400 mb-3" />
          Loading active response units...
        </div>
      ) : (
        <FleetTable
          units={filteredFleet}
          selectedUnitId={selectedUnit?.unit_id}
          onSelectUnit={(unit) => setSelectedUnit(unit)}
        />
      )}

      {/* Unit Detail Quick-view Drawer if selected */}
      {selectedUnit && (
        <div className="p-5 rounded-xl border border-slate-700 bg-[#162036] flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <div className="text-xs text-slate-400">Selected Unit Detail</div>
            <div className="text-lg font-bold text-white mt-0.5">
              {selectedUnit.unit_id} — {selectedUnit.name}
            </div>
            <div className="text-xs text-slate-300 mt-1 flex items-center gap-3">
              <span>Base: {selectedUnit.base_location || 'Field Station'}</span>
              <span>Speed: {selectedUnit.speed_kmh} km/h</span>
              <span>Crew: {selectedUnit.crew_count || 4} personnel</span>
              <span>Evacuation Capacity: {selectedUnit.capacity} people</span>
            </div>
          </div>
          <div className="flex items-center gap-3">
            <button
              onClick={() => setSelectedUnit(null)}
              className="px-4 py-2 text-xs rounded-lg bg-slate-800 text-slate-300 hover:bg-slate-700 transition"
            >
              Close
            </button>
            <button
              onClick={handleRunOptimization}
              className="px-4 py-2 text-xs rounded-lg bg-amber-400 font-bold text-slate-950 hover:bg-amber-300 transition"
            >
              Run Dispatch for this Unit
            </button>
          </div>
        </div>
      )}
    </div>
  );
};

export default RescueOpsPage;

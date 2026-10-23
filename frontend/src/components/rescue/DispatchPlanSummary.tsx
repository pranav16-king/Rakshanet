// src/components/rescue/DispatchPlanSummary.tsx
import React from 'react';
import type { DispatchPlan } from '../../types';
import {
  ShieldCheck,
  Clock,
  Compass,
  CheckCircle2,
  Users,
  MapPin,
  ArrowRight,
} from 'lucide-react';

interface DispatchPlanSummaryProps {
  plan: DispatchPlan;
  onClose?: () => void;
}

export const DispatchPlanSummary: React.FC<DispatchPlanSummaryProps> = ({ plan, onClose }) => {
  return (
    <div className="rounded-xl border border-amber-500/30 bg-white dark:bg-[#111A2C] p-6 shadow-xl space-y-6">
      {/* Header bar */}
      <div className="flex flex-wrap items-center justify-between gap-4 border-b border-slate-200 dark:border-slate-700/80 pb-4">
        <div>
          <div className="flex items-center gap-2">
            <span className="p-1.5 rounded-lg bg-amber-500/10 text-amber-500 dark:text-amber-400">
              <ShieldCheck className="w-5 h-5" />
            </span>
            <h3 className="text-lg font-bold text-slate-900 dark:text-white tracking-wide">
              Optimal MILP Dispatch Plan Generated
            </h3>
            <span className="px-2.5 py-0.5 rounded-full text-xs font-semibold bg-emerald-500/10 dark:bg-emerald-500/20 text-emerald-600 dark:text-emerald-400 border border-emerald-500/30">
              {plan.solver_status}
            </span>
          </div>
          <p className="text-xs text-slate-500 dark:text-slate-400 mt-1 font-mono">
            Plan ID: {plan.plan_id} • Calculated at {new Date(plan.generated_at).toLocaleTimeString()}
          </p>
        </div>

        {onClose && (
          <button
            onClick={onClose}
            className="text-xs px-3 py-1.5 rounded-lg bg-slate-100 hover:bg-slate-200 dark:bg-slate-800 text-slate-700 dark:text-slate-300 dark:hover:bg-slate-700 transition"
          >
            Dismiss
          </button>
        )}
      </div>

      {/* KPI stats metrics */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
        <div className="p-3.5 rounded-lg bg-slate-50 dark:bg-[#162036] border border-slate-200 dark:border-slate-800">
          <div className="text-xs text-slate-500 dark:text-slate-400">Assigned Units</div>
          <div className="text-2xl font-bold text-slate-900 dark:text-white mt-1">
            {plan.assigned_count}{' '}
            <span className="text-xs font-normal text-slate-500 dark:text-slate-400">
              / {plan.total_units_evaluated} units
            </span>
          </div>
        </div>

        <div className="p-3.5 rounded-lg bg-slate-50 dark:bg-[#162036] border border-slate-200 dark:border-slate-800">
          <div className="text-xs text-slate-500 dark:text-slate-400">Casualties Addressed</div>
          <div className="text-2xl font-bold text-emerald-600 dark:text-emerald-400 mt-1 flex items-center gap-1.5">
            <Users className="w-5 h-5" />
            {plan.total_casualties_addressed}
          </div>
        </div>

        <div className="p-3.5 rounded-lg bg-slate-50 dark:bg-[#162036] border border-slate-200 dark:border-slate-800">
          <div className="text-xs text-slate-500 dark:text-slate-400">Cumulative Transit</div>
          <div className="text-2xl font-bold text-cyan-600 dark:text-cyan-400 mt-1">
            {plan.cumulative_transit_distance_km.toFixed(1)}{' '}
            <span className="text-xs font-normal text-slate-500 dark:text-slate-400">km</span>
          </div>
        </div>

        <div className="p-3.5 rounded-lg bg-slate-50 dark:bg-[#162036] border border-slate-200 dark:border-slate-800">
          <div className="text-xs text-slate-500 dark:text-slate-400">Unassigned Incidents</div>
          <div className="text-2xl font-bold text-slate-900 dark:text-slate-200 mt-1">
            {plan.unassigned_incident_ids.length === 0 ? (
              <span className="text-emerald-600 dark:text-emerald-400 text-lg flex items-center gap-1">
                <CheckCircle2 className="w-4 h-4" /> 0 (All covered)
              </span>
            ) : (
              plan.unassigned_incident_ids.length
            )}
          </div>
        </div>
      </div>

      {/* Assignment cards */}
      <div className="space-y-3">
        <h4 className="text-xs font-semibold text-slate-600 dark:text-slate-300 uppercase tracking-wider">
          Unit Assignments & Routing Logic
        </h4>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
          {plan.assignments.map((asgn) => (
            <div
              key={asgn.unit_id}
              className="p-4 rounded-xl bg-slate-50 dark:bg-[#162036] border border-slate-200 dark:border-slate-700/80 hover:border-amber-400/50 transition-all flex flex-col justify-between"
            >
              <div>
                <div className="flex items-center justify-between gap-2 mb-2">
                  <span className="font-mono text-xs font-bold text-amber-600 dark:text-amber-400 bg-amber-500/10 px-2 py-0.5 rounded border border-amber-500/20">
                    {asgn.unit_id}
                  </span>
                  <span
                    className={`text-[11px] font-bold px-2 py-0.5 rounded ${
                      asgn.incident_urgency === 'CRITICAL'
                        ? 'bg-red-500/10 dark:bg-red-500/20 text-red-600 dark:text-red-400 border border-red-500/30'
                        : 'bg-amber-500/10 dark:bg-amber-500/20 text-amber-600 dark:text-amber-400 border border-amber-500/30'
                    }`}
                  >
                    {asgn.incident_urgency}
                  </span>
                </div>

                <div className="text-sm font-semibold text-slate-900 dark:text-white mb-1">
                  {asgn.unit_name}
                </div>

                <div className="flex items-center gap-1.5 text-xs text-slate-600 dark:text-slate-300 mb-2">
                  <ArrowRight className="w-3.5 h-3.5 text-cyan-500 dark:text-cyan-400" />
                  <span className="font-medium text-cyan-600 dark:text-cyan-300">{asgn.incident_id}</span>
                  <span className="text-slate-400 dark:text-slate-500">({asgn.incident_category})</span>
                </div>

                <p className="text-xs text-slate-600 dark:text-slate-400 bg-white dark:bg-[#0E1627] p-2.5 rounded-lg border border-slate-200 dark:border-slate-800 mb-3">
                  {asgn.match_reason}
                </p>
              </div>

              <div className="pt-2 border-t border-slate-200 dark:border-slate-800 flex items-center justify-between text-xs text-slate-600 dark:text-slate-300">
                <div className="flex items-center gap-1">
                  <Clock className="w-3.5 h-3.5 text-amber-500 dark:text-amber-400" />
                  <span>ETA: <strong className="text-slate-900 dark:text-white">{asgn.eta_minutes.toFixed(1)}m</strong></span>
                </div>
                <div className="flex items-center gap-1">
                  <Compass className="w-3.5 h-3.5 text-cyan-500 dark:text-cyan-400" />
                  <span>{asgn.transit_distance_km.toFixed(1)} km</span>
                </div>
                <div className="flex items-center gap-1">
                  <MapPin className="w-3.5 h-3.5 text-emerald-500 dark:text-emerald-400" />
                  <span className="text-emerald-600 dark:text-emerald-400 font-medium">+{asgn.casualties_addressed} pax</span>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

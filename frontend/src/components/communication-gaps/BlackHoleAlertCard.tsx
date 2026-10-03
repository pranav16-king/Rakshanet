// src/components/communication-gaps/BlackHoleAlertCard.tsx
import React from 'react';
import type { BlackHoleAnomaly } from '../../types';
import { DecayChartMini } from './DecayChartMini';
import {
  Radio,
  Clock,
  Users,
  Compass,
  TrendingDown,
  Navigation,
} from 'lucide-react';

interface BlackHoleAlertCardProps {
  anomaly: BlackHoleAnomaly;
  isSelected?: boolean;
  onSelect?: () => void;
}

export const BlackHoleAlertCard: React.FC<BlackHoleAlertCardProps> = ({
  anomaly,
  isSelected,
  onSelect,
}) => {
  const isCritical = anomaly.severity === 'CRITICAL' || anomaly.drop_percentage >= 75;

  return (
    <div
      onClick={onSelect}
      className={`p-5 rounded-xl border transition-all cursor-pointer ${
        isCritical
          ? 'bg-[#161327] border-purple-500/40 hover:border-purple-400'
          : 'bg-[#162036] border-slate-700/80 hover:border-amber-400/50'
      } ${isSelected ? 'ring-2 ring-purple-400 shadow-lg shadow-purple-500/10' : ''}`}
    >
      {/* Top Header */}
      <div className="flex items-start justify-between gap-3 mb-3">
        <div className="flex items-center gap-2.5">
          <span
            className={`p-2 rounded-lg ${
              isCritical
                ? 'bg-purple-500/20 text-purple-400 border border-purple-500/30 animate-pulse'
                : 'bg-amber-500/20 text-amber-400 border border-amber-500/30'
            }`}
          >
            <Radio className="w-5 h-5" />
          </span>
          <div>
            <div className="font-mono font-bold text-white text-sm tracking-wide">
              {anomaly.sector_id}
            </div>
            <div className="text-xs text-slate-400">
              Center: {anomaly.center_lat.toFixed(4)}°N, {anomaly.center_lng.toFixed(4)}°E
            </div>
          </div>
        </div>

        <div className="flex flex-col items-end">
          <span
            className={`px-2.5 py-0.5 rounded-full text-xs font-bold ${
              isCritical
                ? 'bg-red-500/20 text-red-400 border border-red-500/30'
                : 'bg-amber-500/20 text-amber-400 border border-amber-500/30'
            }`}
          >
            {anomaly.drop_percentage.toFixed(1)}% Telemetry Drop
          </span>
          <span className="text-[11px] text-slate-400 mt-1 flex items-center gap-1">
            <Clock className="w-3 h-3" />
            {anomaly.silence_duration_minutes.toFixed(0)}m silence
          </span>
        </div>
      </div>

      {/* Metrics Row */}
      <div className="grid grid-cols-3 gap-2 p-3 rounded-lg bg-[#0B101E] border border-slate-800/80 mb-3">
        <div>
          <div className="text-[11px] text-slate-400">Silenced Nodes</div>
          <div className="text-sm font-semibold text-white mt-0.5 flex items-center gap-1">
            <TrendingDown className="w-3.5 h-3.5 text-red-400" />
            {anomaly.baseline_nodes} ➔ {anomaly.current_nodes}
          </div>
        </div>

        <div>
          <div className="text-[11px] text-slate-400">Silenced Population</div>
          <div className="text-sm font-semibold text-purple-300 mt-0.5 flex items-center gap-1">
            <Users className="w-3.5 h-3.5 text-purple-400" />
            ~{anomaly.estimated_silenced_people}
          </div>
        </div>

        <div>
          <div className="text-[11px] text-slate-400">Decay Velocity</div>
          <div className="text-sm font-semibold text-amber-300 mt-0.5 flex items-center gap-1">
            <Compass className="w-3.5 h-3.5 text-amber-400" />
            {anomaly.decay_rate_per_hour.toFixed(0)}/hr
          </div>
        </div>
      </div>

      {/* Mini time-series sparkline */}
      {anomaly.time_series && (
        <div className="flex items-center justify-between mb-3 px-1">
          <span className="text-[11px] text-slate-400">Spatiotemporal Decay Curve:</span>
          <DecayChartMini
            data={anomaly.time_series}
            criticalDrop={isCritical}
          />
        </div>
      )}

      {/* Last seen ping */}
      {anomaly.last_signal_seen && (
        <div className="text-xs text-slate-400 mb-3 flex items-center gap-1.5">
          <Navigation className="w-3 h-3 text-cyan-400" />
          <span>Last signal seen: <strong className="text-slate-200">{anomaly.last_signal_seen}</strong></span>
        </div>
      )}

      {/* Tactical action banner */}
      <div className="p-2.5 rounded-lg bg-purple-900/30 border border-purple-500/30 flex items-center justify-between">
        <span className="text-[11px] font-mono text-purple-300 font-semibold tracking-wide">
          ACTION: {anomaly.recommended_action.replace(/_/g, ' ')}
        </span>
      </div>
    </div>
  );
};

// src/components/rescue/UnitStatusBadge.tsx
import React from 'react';
import type { UnitStatus } from '../../types';

interface UnitStatusBadgeProps {
  status: UnitStatus;
}

export const UnitStatusBadge: React.FC<UnitStatusBadgeProps> = ({ status }) => {
  const getBadgeStyle = () => {
    switch (status) {
      case 'AVAILABLE':
        return 'bg-emerald-500/10 text-emerald-400 border-emerald-500/30';
      case 'DISPATCHED':
        return 'bg-amber-500/10 text-amber-400 border-amber-500/30';
      case 'IN_TRANSIT':
        return 'bg-cyan-500/10 text-cyan-400 border-cyan-500/30';
      case 'REST':
      case 'MAINTENANCE':
        return 'bg-slate-500/10 text-slate-400 border-slate-500/30';
      default:
        return 'bg-slate-500/10 text-slate-400 border-slate-500/30';
    }
  };

  const getDotStyle = () => {
    switch (status) {
      case 'AVAILABLE':
        return 'bg-emerald-400';
      case 'DISPATCHED':
        return 'bg-amber-400 animate-pulse';
      case 'IN_TRANSIT':
        return 'bg-cyan-400 animate-pulse';
      default:
        return 'bg-slate-400';
    }
  };

  return (
    <span
      className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium border ${getBadgeStyle()}`}
    >
      <span className={`w-1.5 h-1.5 rounded-full ${getDotStyle()}`} />
      {status.replace('_', ' ')}
    </span>
  );
};

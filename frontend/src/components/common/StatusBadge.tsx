import React from 'react';
import type { MessageBadgeType } from '../../types/messages';

interface StatusBadgeProps {
  label?: string;
  status?: string;
  type?: MessageBadgeType | 'online' | 'relay' | 'offline' | string;
  size?: 'sm' | 'md' | 'lg' | string;
  className?: string;
  dot?: boolean;
}

export const StatusBadge: React.FC<StatusBadgeProps> = ({
  label,
  status,
  type = 'report',
  size = 'md',
  className = '',
  dot = false,
}) => {
  const displayLabel = label || status || 'Active';
  let badgeStyles = 'bg-slate-100 text-slate-700 border-slate-200 dark:bg-slate-800 dark:text-slate-300 dark:border-slate-700';
  let dotStyles = 'bg-slate-400';

  switch (type) {
    case 'sos':
      badgeStyles =
        'bg-red-50 text-red-700 border-red-200 font-semibold dark:bg-red-950/60 dark:text-red-300 dark:border-red-900';
      dotStyles = 'bg-red-500 animate-pulse';
      break;
    case 'medical':
      badgeStyles =
        'bg-rose-50 text-rose-700 border-rose-200 font-medium dark:bg-rose-950/50 dark:text-rose-300 dark:border-rose-900';
      dotStyles = 'bg-rose-500';
      break;
    case 'report':
      badgeStyles =
        'bg-blue-50 text-blue-700 border-blue-200 font-medium dark:bg-blue-950/50 dark:text-blue-300 dark:border-blue-900';
      dotStyles = 'bg-blue-500';
      break;
    case 'team':
      badgeStyles =
        'bg-emerald-50 text-emerald-700 border-emerald-200 font-medium dark:bg-emerald-950/50 dark:text-emerald-300 dark:border-emerald-900';
      dotStyles = 'bg-emerald-500';
      break;
    case 'system':
      badgeStyles =
        'bg-indigo-50 text-indigo-700 border-indigo-200 font-medium dark:bg-indigo-950/50 dark:text-indigo-300 dark:border-indigo-900';
      dotStyles = 'bg-indigo-500';
      break;
    case 'online':
      badgeStyles =
        'bg-emerald-50 text-emerald-700 border-emerald-200 dark:bg-emerald-950/40 dark:text-emerald-300 dark:border-emerald-900';
      dotStyles = 'bg-emerald-500';
      break;
    case 'relay':
      badgeStyles =
        'bg-amber-50 text-amber-700 border-amber-200 dark:bg-amber-950/40 dark:text-amber-300 dark:border-amber-900';
      dotStyles = 'bg-amber-500';
      break;
    case 'offline':
      badgeStyles =
        'bg-slate-100 text-slate-600 border-slate-200 dark:bg-slate-800 dark:text-slate-400 dark:border-slate-700';
      dotStyles = 'bg-slate-400';
      break;
  }

  return (
    <span
      className={`inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs border tracking-tight ${badgeStyles} ${className}`}
    >
      {dot && <span className={`w-1.5 h-1.5 rounded-full ${dotStyles}`} />}
      <span>{displayLabel}</span>
    </span>
  );
};

export default StatusBadge;

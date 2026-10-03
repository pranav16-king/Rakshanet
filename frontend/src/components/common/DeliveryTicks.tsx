import React from 'react';
import { Check, CheckCheck, Clock } from 'lucide-react';
import type { DeliveryStatus } from '../../types/messages';

interface DeliveryTicksProps {
  status: DeliveryStatus;
  className?: string;
  showLabel?: boolean;
}

export const DeliveryTicks: React.FC<DeliveryTicksProps> = ({
  status,
  className = '',
  showLabel = false,
}) => {
  if (status === 'queued') {
    return (
      <div
        className={`inline-flex items-center gap-1 text-slate-400 ${className}`}
        title="Queued (1 tick: queued on local device / mesh buffer)"
        aria-label="Message status: queued"
      >
        <Check className="w-4 h-4" strokeWidth={2.5} />
        {showLabel && <span className="text-xs font-medium">Queued</span>}
      </div>
    );
  }

  if (status === 'relayed') {
    return (
      <div
        className={`inline-flex items-center gap-1 text-sky-600 dark:text-sky-400 ${className}`}
        title="Mesh Relayed (2 ticks: propagated via mesh hops)"
        aria-label="Message status: mesh relayed"
      >
        <CheckCheck className="w-4 h-4" strokeWidth={2.5} />
        {showLabel && <span className="text-xs font-medium">Mesh Relayed</span>}
      </div>
    );
  }

  // delivered: double green
  return (
    <div
      className={`inline-flex items-center gap-1 text-emerald-600 dark:text-emerald-400 ${className}`}
      title="Delivered (Double green ticks: delivered and acknowledged)"
      aria-label="Message status: delivered"
    >
      <CheckCheck className="w-4 h-4 text-emerald-600 dark:text-emerald-400" strokeWidth={2.5} />
      {showLabel && <span className="text-xs font-semibold text-emerald-700 dark:text-emerald-400">Delivered</span>}
    </div>
  );
};

export default DeliveryTicks;

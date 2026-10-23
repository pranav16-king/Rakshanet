// src/components/reports/ExportActionCard.tsx
import React from 'react';
import { Download, Eye, Layers } from 'lucide-react';

interface ExportActionCardProps {
  title: string;
  description: string;
  formatBadge: string;
  badgeColor?: string;
  icon: React.ReactNode;
  recordCount?: number;
  payloadSize?: string;
  liveStatus?: string;
  onPreview: () => void;
  onDownload: () => void;
  downloadLabel?: string;
}

export const ExportActionCard: React.FC<ExportActionCardProps> = ({
  title,
  description,
  formatBadge,
  badgeColor = 'bg-cyan-500/15 text-cyan-700 dark:text-cyan-400 border-cyan-500/30',
  icon,
  recordCount,
  payloadSize,
  liveStatus = 'Live Feed Synced',
  onPreview,
  onDownload,
  downloadLabel = 'Download Feed',
}) => {
  return (
    <div className="p-5 rounded-2xl border border-slate-200 dark:border-[#26344F] bg-white dark:bg-[#162036] hover:border-slate-300 dark:hover:border-slate-500 transition-all flex flex-col justify-between shadow-xs hover:shadow-md">
      <div>
        {/* Top Badges & Icon */}
        <div className="flex items-start justify-between gap-3 mb-3">
          <div className="p-2.5 rounded-xl bg-slate-100 dark:bg-[#0E1627] border border-slate-200 dark:border-slate-700/80 shadow-xs">
            {icon}
          </div>
          <div className="flex flex-col items-end gap-1">
            <span className={`px-2.5 py-0.5 rounded-full text-xs font-mono font-bold border ${badgeColor}`}>
              {formatBadge}
            </span>
            {payloadSize && (
              <span className="text-[11px] font-mono text-slate-500 dark:text-slate-400">
                Payload: {payloadSize}
              </span>
            )}
          </div>
        </div>

        {/* Title & Live Status */}
        <div className="flex items-center gap-2 mb-1">
          <h3 className="text-base font-bold text-slate-900 dark:text-white">{title}</h3>
        </div>

        <div className="flex items-center gap-2 mb-2">
          <span className="inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full bg-emerald-500/15 text-emerald-700 dark:text-emerald-400 border border-emerald-500/30 text-[10px] font-semibold">
            <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
            <span>{liveStatus}</span>
          </span>
          {recordCount !== undefined && (
            <span className="inline-flex items-center gap-1 text-[11px] font-semibold text-slate-600 dark:text-slate-400">
              <Layers className="w-3 h-3" />
              <span>{recordCount} {recordCount === 1 ? 'incident' : 'incidents'} packaged</span>
            </span>
          )}
        </div>

        <p className="text-xs text-slate-600 dark:text-slate-400 leading-relaxed mb-4">
          {description}
        </p>
      </div>

      {/* Action Buttons */}
      <div className="pt-3 border-t border-slate-100 dark:border-slate-700/60 flex items-center justify-between gap-2">
        <button
          onClick={onPreview}
          className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 dark:bg-slate-800 dark:hover:bg-slate-700 dark:text-slate-200 text-xs font-semibold border border-slate-200 dark:border-slate-700 transition cursor-pointer"
        >
          <Eye className="w-3.5 h-3.5" />
          Preview
        </button>

        <button
          onClick={onDownload}
          className="flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl bg-[#FFD21F] hover:bg-[#FACC15] text-[#0B1220] font-bold text-xs shadow-xs hover:shadow-md transition cursor-pointer"
        >
          <Download className="w-3.5 h-3.5" />
          {downloadLabel}
        </button>
      </div>
    </div>
  );
};

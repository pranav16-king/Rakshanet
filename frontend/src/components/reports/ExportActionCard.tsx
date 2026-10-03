// src/components/reports/ExportActionCard.tsx
import React from 'react';
import { Download, Eye } from 'lucide-react';

interface ExportActionCardProps {
  title: string;
  description: string;
  formatBadge: string;
  badgeColor?: string;
  icon: React.ReactNode;
  onPreview: () => void;
  onDownload: () => void;
  downloadLabel?: string;
}

export const ExportActionCard: React.FC<ExportActionCardProps> = ({
  title,
  description,
  formatBadge,
  badgeColor = 'bg-cyan-500/20 text-cyan-400 border-cyan-500/30',
  icon,
  onPreview,
  onDownload,
  downloadLabel = 'Download Feed',
}) => {
  return (
    <div className="p-5 rounded-xl border border-slate-700/80 bg-[#162036] hover:border-slate-600 transition flex flex-col justify-between shadow-md">
      <div>
        <div className="flex items-start justify-between gap-3 mb-3">
          <div className="p-2.5 rounded-lg bg-[#0E1627] border border-slate-700">
            {icon}
          </div>
          <span className={`px-2.5 py-0.5 rounded-full text-xs font-mono font-semibold border ${badgeColor}`}>
            {formatBadge}
          </span>
        </div>

        <h3 className="text-base font-bold text-white mb-1.5">{title}</h3>
        <p className="text-xs text-slate-400 leading-relaxed mb-4">{description}</p>
      </div>

      <div className="pt-3 border-t border-slate-700/60 flex items-center justify-between gap-2">
        <button
          onClick={onPreview}
          className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-xs text-slate-200 transition"
        >
          <Eye className="w-3.5 h-3.5" />
          Preview
        </button>

        <button
          onClick={onDownload}
          className="flex items-center gap-1.5 px-3.5 py-1.5 rounded-lg bg-amber-400 hover:bg-amber-300 text-slate-950 font-bold text-xs shadow-md transition"
        >
          <Download className="w-3.5 h-3.5" />
          {downloadLabel}
        </button>
      </div>
    </div>
  );
};

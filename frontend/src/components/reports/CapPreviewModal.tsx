// src/components/reports/CapPreviewModal.tsx
import React from 'react';
import { X, Copy, Check, FileCode } from 'lucide-react';

interface CapPreviewModalProps {
  isOpen: boolean;
  onClose: () => void;
  xmlContent: string;
}

export const CapPreviewModal: React.FC<CapPreviewModalProps> = ({
  isOpen,
  onClose,
  xmlContent,
}) => {
  const [copied, setCopied] = React.useState(false);

  if (!isOpen) return null;

  const handleCopy = () => {
    navigator.clipboard.writeText(xmlContent);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/75 backdrop-blur-sm">
      <div className="w-full max-w-3xl rounded-2xl bg-white dark:bg-[#162036] border border-slate-200 dark:border-slate-700 shadow-2xl flex flex-col max-h-[85vh] text-slate-900 dark:text-slate-100">
        <div className="flex items-center justify-between p-4 border-b border-slate-200 dark:border-slate-700/80">
          <div className="flex items-center gap-2.5">
            <div className="p-1.5 rounded-lg bg-orange-500/10 text-orange-600 dark:text-orange-400">
              <FileCode className="w-5 h-5" />
            </div>
            <div>
              <h3 className="text-base font-bold text-slate-900 dark:text-white">
                OASIS Common Alerting Protocol (CAP v1.2) XML Feed
              </h3>
              <p className="text-xs text-slate-500 dark:text-slate-400">
                Standard interoperability payload for NDMA, SACHET, and State Disaster Authorities.
              </p>
            </div>
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={handleCopy}
              className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-slate-100 hover:bg-slate-200 dark:bg-slate-800 dark:hover:bg-slate-700 text-xs font-semibold text-slate-700 dark:text-slate-200 transition cursor-pointer"
            >
              {copied ? <Check className="w-3.5 h-3.5 text-emerald-500" /> : <Copy className="w-3.5 h-3.5" />}
              {copied ? 'Copied' : 'Copy XML'}
            </button>
            <button
              onClick={onClose}
              className="p-1 rounded-lg text-slate-400 hover:text-slate-700 dark:hover:text-white hover:bg-slate-100 dark:hover:bg-slate-800 transition cursor-pointer"
            >
              <X className="w-5 h-5" />
            </button>
          </div>
        </div>

        <div className="p-4 overflow-y-auto flex-1 font-mono text-xs bg-[#0A0F1D] text-emerald-300 whitespace-pre leading-relaxed select-all">
          {xmlContent}
        </div>
      </div>
    </div>
  );
};

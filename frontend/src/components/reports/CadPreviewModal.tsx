// src/components/reports/CadPreviewModal.tsx
import React, { useState } from 'react';
import { X, Copy, Check, Terminal } from 'lucide-react';

interface CadPreviewModalProps {
  isOpen: boolean;
  onClose: () => void;
  jsonData: unknown;
}

export const CadPreviewModal: React.FC<CadPreviewModalProps> = ({
  isOpen,
  onClose,
  jsonData,
}) => {
  const [copied, setCopied] = useState(false);

  if (!isOpen) return null;

  const jsonString = JSON.stringify(jsonData, null, 2);

  const handleCopy = () => {
    navigator.clipboard.writeText(jsonString);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/75 backdrop-blur-sm">
      <div className="w-full max-w-3xl rounded-2xl bg-[#162036] border border-slate-700 shadow-2xl flex flex-col max-h-[85vh] text-slate-100">
        <div className="flex items-center justify-between p-4 border-b border-slate-700/80">
          <div className="flex items-center gap-2.5">
            <div className="p-1.5 rounded-lg bg-cyan-500/10 text-cyan-400">
              <Terminal className="w-5 h-5" />
            </div>
            <div>
              <h3 className="text-base font-bold text-white">
                Computer-Aided Dispatch (CAD 112/911) JSON Feed
              </h3>
              <p className="text-xs text-slate-400">
                Legacy 112/911 emergency dispatch console schema export.
              </p>
            </div>
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={handleCopy}
              className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-xs text-slate-200 transition"
            >
              {copied ? <Check className="w-3.5 h-3.5 text-emerald-400" /> : <Copy className="w-3.5 h-3.5" />}
              {copied ? 'Copied' : 'Copy JSON'}
            </button>
            <button
              onClick={onClose}
              className="p-1 rounded-lg text-slate-400 hover:text-white hover:bg-slate-800 transition"
            >
              <X className="w-5 h-5" />
            </button>
          </div>
        </div>

        <div className="p-4 overflow-y-auto flex-1 font-mono text-xs bg-[#0A0F1D] text-cyan-300 whitespace-pre leading-relaxed select-all">
          {jsonString}
        </div>
      </div>
    </div>
  );
};

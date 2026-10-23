// src/components/reports/CsvPreviewModal.tsx
import React, { useState, useMemo } from 'react';
import { X, Copy, Check, FileSpreadsheet, Search, Download } from 'lucide-react';

interface CsvPreviewModalProps {
  isOpen: boolean;
  onClose: () => void;
  csvContent: string;
  filename?: string;
  onDownload: () => void;
}

export const CsvPreviewModal: React.FC<CsvPreviewModalProps> = ({
  isOpen,
  onClose,
  csvContent,
  filename = 'RakshaNet-Incident-Summary.csv',
  onDownload,
}) => {
  const [copied, setCopied] = useState(false);
  const [search, setSearch] = useState('');

  const parsedData = useMemo(() => {
    if (!csvContent) return { headers: [], rows: [] };
    const lines = csvContent.trim().split('\n');
    if (lines.length === 0) return { headers: [], rows: [] };

    const parseCsvLine = (line: string): string[] => {
      const result: string[] = [];
      let current = '';
      let inQuotes = false;

      for (let i = 0; i < line.length; i++) {
        const char = line[i];
        if (char === '"') {
          if (inQuotes && line[i + 1] === '"') {
            current += '"';
            i++;
          } else {
            inQuotes = !inQuotes;
          }
        } else if (char === ',' && !inQuotes) {
          result.push(current.trim());
          current = '';
        } else {
          current += char;
        }
      }
      result.push(current.trim());
      return result;
    };

    const headers = parseCsvLine(lines[0]);
    const rows = lines.slice(1).map(parseCsvLine);
    return { headers, rows };
  }, [csvContent]);

  const filteredRows = useMemo(() => {
    if (!search.trim()) return parsedData.rows;
    const q = search.toLowerCase();
    return parsedData.rows.filter((row) =>
      row.some((cell) => cell.toLowerCase().includes(q))
    );
  }, [parsedData.rows, search]);

  if (!isOpen) return null;

  const handleCopy = () => {
    navigator.clipboard.writeText(csvContent);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/75 backdrop-blur-sm animate-in fade-in duration-200">
      <div className="w-full max-w-5xl rounded-2xl bg-white dark:bg-[#162036] border border-slate-200 dark:border-slate-700 shadow-2xl flex flex-col max-h-[88vh] text-slate-900 dark:text-slate-100 overflow-hidden">
        {/* Header */}
        <div className="flex items-center justify-between p-4 sm:p-5 border-b border-slate-200 dark:border-slate-700/80 bg-slate-50 dark:bg-[#0E1627]/60">
          <div className="flex items-center gap-3">
            <div className="p-2.5 rounded-xl bg-emerald-500/15 text-emerald-600 dark:text-emerald-400 border border-emerald-500/30">
              <FileSpreadsheet className="w-6 h-6" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h3 className="text-base sm:text-lg font-bold text-slate-900 dark:text-white">
                  Real Incident Summary Table Preview
                </h3>
                <span className="px-2 py-0.5 rounded-full text-xs font-mono font-semibold bg-emerald-500/15 text-emerald-600 dark:text-emerald-400 border border-emerald-500/30">
                  {parsedData.rows.length} Real Records
                </span>
              </div>
              <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
                Standard RFC 4180 format • Master incidents with GPS, casualties, device ratios, and fleet assignments.
              </p>
            </div>
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={handleCopy}
              className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-700 dark:bg-slate-800 dark:hover:bg-slate-700 dark:text-slate-200 text-xs font-semibold border border-slate-200 dark:border-slate-700 transition"
              title="Copy Raw CSV"
            >
              {copied ? <Check className="w-3.5 h-3.5 text-emerald-500" /> : <Copy className="w-3.5 h-3.5" />}
              {copied ? 'Copied' : 'Copy CSV'}
            </button>

            <button
              onClick={onDownload}
              className="flex items-center gap-1.5 px-3.5 py-1.5 rounded-lg bg-[#FFD21F] hover:bg-[#FACC15] text-[#0B1220] font-bold text-xs shadow-sm transition"
            >
              <Download className="w-3.5 h-3.5" />
              Download CSV
            </button>

            <button
              onClick={onClose}
              className="p-1.5 rounded-lg text-slate-400 hover:text-slate-700 dark:hover:text-white hover:bg-slate-100 dark:hover:bg-slate-800 transition"
              aria-label="Close dialog"
            >
              <X className="w-5 h-5" />
            </button>
          </div>
        </div>

        {/* Search & Metadata Bar */}
        <div className="px-5 py-3 border-b border-slate-200 dark:border-slate-800 bg-white dark:bg-[#162036] flex flex-col sm:flex-row sm:items-center justify-between gap-3">
          <div className="relative flex-1 max-w-md">
            <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
            <input
              type="text"
              placeholder="Filter columns (ID, Category, Location, Fleet)..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-full pl-9 pr-4 py-1.5 rounded-lg text-xs bg-slate-50 dark:bg-[#0E1627] border border-slate-200 dark:border-slate-700 text-slate-900 dark:text-white placeholder:text-slate-400 focus:outline-none focus:ring-1 focus:ring-emerald-500"
            />
          </div>
          <div className="text-xs text-slate-500 dark:text-slate-400 font-mono flex items-center gap-2">
            <span>Showing {filteredRows.length} of {parsedData.rows.length} incidents</span>
            <span>•</span>
            <span>{parsedData.headers.length} columns</span>
          </div>
        </div>

        {/* Scrollable Table Content */}
        <div className="flex-1 overflow-auto p-4 bg-slate-50/50 dark:bg-[#0E1627]/40">
          {filteredRows.length === 0 ? (
            <div className="p-8 text-center text-slate-500 dark:text-slate-400 text-sm">
              No matching records found in CSV preview.
            </div>
          ) : (
            <div className="border border-slate-200 dark:border-slate-800 rounded-xl overflow-hidden shadow-xs bg-white dark:bg-[#162036]">
              <table className="w-full text-left text-xs border-collapse">
                <thead className="bg-slate-100 dark:bg-[#0E1627] text-slate-700 dark:text-slate-300 font-bold uppercase tracking-wider sticky top-0 z-10 border-b border-slate-200 dark:border-slate-700">
                  <tr>
                    {parsedData.headers.map((header, idx) => (
                      <th key={idx} scope="col" className="px-3.5 py-2.5 whitespace-nowrap">
                        {header}
                      </th>
                    ))}
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 dark:divide-slate-800">
                  {filteredRows.map((row, rowIdx) => (
                    <tr
                      key={rowIdx}
                      className="hover:bg-slate-50/80 dark:hover:bg-slate-800/40 transition-colors"
                    >
                      {row.map((cell, colIdx) => {
                        const isSeverity = colIdx === 3;
                        const isId = colIdx === 0;
                        const isCasualty = colIdx === 8;

                        return (
                          <td
                            key={colIdx}
                            className={`px-3.5 py-2 whitespace-nowrap ${
                              isId ? 'font-mono font-bold text-slate-900 dark:text-white' : ''
                            } ${
                              isSeverity
                                ? cell === 'CRITICAL'
                                  ? 'text-rose-600 dark:text-rose-400 font-bold'
                                  : 'text-amber-600 dark:text-amber-400 font-bold'
                                : 'text-slate-600 dark:text-slate-300'
                            }`}
                          >
                            {isCasualty ? (
                              <span className="font-bold text-rose-600 dark:text-rose-400">
                                👥 {cell}
                              </span>
                            ) : (
                              cell
                            )}
                          </td>
                        );
                      })}
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="p-3.5 border-t border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-[#0E1627]/60 flex items-center justify-between text-xs text-slate-500 dark:text-slate-400">
          <div className="font-mono">Export File: {filename}</div>
          <button
            onClick={onClose}
            className="px-4 py-1.5 rounded-lg bg-slate-200 hover:bg-slate-300 text-slate-800 dark:bg-slate-800 dark:hover:bg-slate-700 dark:text-slate-200 font-medium transition"
          >
            Close
          </button>
        </div>
      </div>
    </div>
  );
};

import React from 'react';
import { ChevronLeft, ChevronRight } from 'lucide-react';
import { useTheme } from '../../theme/ThemeContext.tsx';

interface IncidentPaginationProps {
  currentPage: number;
  totalPages: number;
  totalCount: number;
  pageSize: number;
  onPageChange: (newPage: number) => void;
  onPageSizeChange: (newSize: number) => void;
}

export const IncidentPagination: React.FC<IncidentPaginationProps> = ({
  currentPage,
  totalPages,
  totalCount,
  pageSize,
  onPageChange,
  onPageSizeChange,
}) => {
  const { isDark } = useTheme();

  const startItem = totalCount === 0 ? 0 : (currentPage - 1) * pageSize + 1;
  const endItem = Math.min(currentPage * pageSize, totalCount);

  return (
    <div
      className={`px-4 py-3.5 border-t flex flex-col sm:flex-row items-center justify-between gap-3 text-xs transition-colors ${
        isDark ? 'border-[#26344F] text-[#9FADC2]' : 'border-[#E2E8F0] text-[#64748B]'
      }`}
    >
      {/* Total count and page size selector */}
      <div className="flex items-center gap-3">
        <span>
          Showing <strong className={isDark ? 'text-white' : 'text-[#0F172A]'}>{startItem}</strong> to{' '}
          <strong className={isDark ? 'text-white' : 'text-[#0F172A]'}>{endItem}</strong> of{' '}
          <strong className={isDark ? 'text-white' : 'text-[#0F172A]'}>{totalCount}</strong> incidents
        </span>
        <div className="flex items-center gap-1.5 pl-2 border-l border-inherit">
          <span>Rows:</span>
          <select
            value={pageSize}
            onChange={(e) => onPageSizeChange(Number(e.target.value))}
            aria-label="Rows per page"
            className={`px-2 py-1 rounded border font-semibold outline-none cursor-pointer ${
              isDark
                ? 'bg-[#162036] border-[#26344F] text-[#EEF2F8]'
                : 'bg-white border-[#E2E8F0] text-[#0F172A]'
            }`}
          >
            <option value={5}>5</option>
            <option value={10}>10</option>
            <option value={20}>20</option>
            <option value={50}>50</option>
          </select>
        </div>
      </div>

      {/* Pagination controls */}
      <div className="flex items-center gap-1.5">
        <button
          type="button"
          onClick={() => onPageChange(currentPage - 1)}
          disabled={currentPage <= 1}
          aria-label="Previous page"
          className={`p-1.5 rounded-lg border transition-all ${
            currentPage <= 1
              ? 'opacity-40 cursor-not-allowed border-transparent'
              : isDark
              ? 'bg-[#162036] border-[#26344F] text-[#EEF2F8] hover:bg-[#1f2d4d]'
              : 'bg-white border-[#E2E8F0] text-[#0F172A] hover:bg-[#F1F5F9]'
          }`}
        >
          <ChevronLeft size={16} />
        </button>

        <span className="px-2 font-mono font-semibold">
          Page {currentPage} of {Math.max(1, totalPages)}
        </span>

        <button
          type="button"
          onClick={() => onPageChange(currentPage + 1)}
          disabled={currentPage >= totalPages}
          aria-label="Next page"
          className={`p-1.5 rounded-lg border transition-all ${
            currentPage >= totalPages
              ? 'opacity-40 cursor-not-allowed border-transparent'
              : isDark
              ? 'bg-[#162036] border-[#26344F] text-[#EEF2F8] hover:bg-[#1f2d4d]'
              : 'bg-white border-[#E2E8F0] text-[#0F172A] hover:bg-[#F1F5F9]'
          }`}
        >
          <ChevronRight size={16} />
        </button>
      </div>
    </div>
  );
};

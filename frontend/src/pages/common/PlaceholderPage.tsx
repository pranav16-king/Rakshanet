import React from 'react';
import { useLocation, Link } from 'react-router-dom';
import { Construction, ArrowLeft } from 'lucide-react';

export const PlaceholderPage: React.FC = () => {
  const location = useLocation();
  const title = location.pathname.replace('/', '').toUpperCase() || 'SECTION';

  return (
    <div className="flex flex-col items-center justify-center min-h-[60vh] p-8 text-center">
      <div className="w-16 h-16 rounded-2xl bg-[#F8FAFC] dark:bg-[#162036] border border-[#E2E8F0] dark:border-[#26344F] flex items-center justify-center text-[#FFC400] mb-4 shadow-sm">
        <Construction className="w-8 h-8" />
      </div>
      <h2 className="text-xl font-bold font-display text-[#0F172A] dark:text-[#EEF2F8] mb-1">
        {title} Command Module
      </h2>
      <p className="text-sm text-[#64748B] dark:text-[#9FADC2] max-w-md mb-6">
        This view is part of the RakshaNet command subsystem. Switch to the Overview Dashboard or Live Map for active operations.
      </p>
      <div className="flex gap-3">
        <Link
          to="/app/dashboard"
          className="inline-flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold bg-[#FFC400] text-[#1A1400] hover:bg-[#E0AA00] transition-colors shadow-xs"
        >
          <ArrowLeft className="w-3.5 h-3.5" />
          Return to Overview
        </Link>
        <Link
          to="/app/map"
          className="inline-flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold bg-white dark:bg-[#162036] border border-[#E2E8F0] dark:border-[#26344F] text-[#0F172A] dark:text-[#EEF2F8] hover:bg-[#F8FAFC] dark:hover:bg-[#1C2844] transition-colors shadow-xs"
        >
          Open Live Map
        </Link>
      </div>
    </div>
  );
};

export default PlaceholderPage;

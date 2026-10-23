import React from 'react';
import { Outlet } from 'react-router-dom';
import { CommandSidebar } from './CommandSidebar';
import { CommandHeader } from './CommandHeader';

export const CommandLayout: React.FC = () => {
  return (
    <div className="flex h-screen w-screen overflow-hidden bg-[#F8FAFC] dark:bg-[#0B1220] text-[#0F172A] dark:text-[#EEF2F8] transition-colors">
      {/* Zone 1: Left Navigation Sidebar */}
      <CommandSidebar />

      {/* Main Workspace Area */}
      <div className="flex-1 flex flex-col min-w-0 h-full overflow-hidden">
        {/* Top Header */}
        <CommandHeader />

        {/* Dynamic Page Outlet */}
        <main className="flex-1 min-h-0 overflow-y-auto">
          <Outlet />
        </main>
      </div>
    </div>
  );
};

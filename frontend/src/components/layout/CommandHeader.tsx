import React, { useState, useEffect } from 'react';
import { Search, Bell, HelpCircle, Sun, Moon } from 'lucide-react';

export const CommandHeader: React.FC = () => {
  const [isDark, setIsDark] = useState<boolean>(() => {
    return document.documentElement.classList.contains('dark') || true;
  });

  useEffect(() => {
    if (isDark) {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
  }, [isDark]);

  const toggleTheme = () => {
    setIsDark((prev) => !prev);
  };

  return (
    <header className="h-16 px-6 bg-white dark:bg-[#0B1220] border-b border-[#E2E8F0] dark:border-[#26344F] flex items-center justify-between shrink-0 transition-colors z-20">
      {/* Search Input */}
      <div className="relative w-80 max-w-sm">
        <Search className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-[#64748B] dark:text-[#9FADC2]" />
        <input
          type="text"
          placeholder="Search anything..."
          className="w-full pl-10 pr-4 py-2 text-sm rounded-xl bg-[#F8FAFC] dark:bg-[#162036] border border-[#E2E8F0] dark:border-[#26344F] text-[#0F172A] dark:text-[#EEF2F8] placeholder-[#64748B] dark:placeholder-[#9FADC2] focus:outline-none focus:ring-2 focus:ring-[#FFC400] transition-all"
        />
      </div>

      {/* Action Icons and User Profile */}
      <div className="flex items-center gap-4">
        {/* Theme Toggle */}
        <button
          type="button"
          onClick={toggleTheme}
          title={isDark ? 'Switch to Light Theme' : 'Switch to Dark Theme'}
          className="p-2 rounded-xl text-[#64748B] dark:text-[#9FADC2] hover:bg-[#F8FAFC] dark:hover:bg-[#162036] transition-colors cursor-pointer"
        >
          {isDark ? <Sun className="w-4 h-4 text-[#FFD21F]" /> : <Moon className="w-4 h-4" />}
        </button>

        {/* Notifications */}
        <button
          type="button"
          aria-label="View notifications"
          className="relative p-2 rounded-xl text-[#64748B] dark:text-[#9FADC2] hover:bg-[#F8FAFC] dark:hover:bg-[#162036] transition-colors cursor-pointer"
        >
          <Bell className="w-4 h-4" />
          <span className="absolute top-1.5 right-1.5 w-2 h-2 rounded-full bg-[#D92D20] ring-2 ring-white dark:ring-[#0B1220]" />
        </button>

        {/* Help Circle */}
        <button
          type="button"
          aria-label="Help and documentation"
          className="p-2 rounded-xl text-[#64748B] dark:text-[#9FADC2] hover:bg-[#F8FAFC] dark:hover:bg-[#162036] transition-colors cursor-pointer"
        >
          <HelpCircle className="w-4 h-4" />
        </button>

        <div className="h-6 w-px bg-[#E2E8F0] dark:bg-[#26344F]" />

        {/* User Profile */}
        <div className="flex items-center gap-3 pl-1">
          <div className="w-9 h-9 rounded-full bg-[#0F172A] dark:bg-[#FFC400] text-[#FFC400] dark:text-[#1A1400] font-bold text-sm flex items-center justify-center ring-2 ring-[#FFC400]/40">
            A
          </div>
          <div className="flex flex-col text-left leading-tight">
            <span className="text-xs font-bold text-[#0F172A] dark:text-[#EEF2F8]">
              Admin
            </span>
            <span className="text-[11px] text-[#64748B] dark:text-[#9FADC2]">
              Government
            </span>
          </div>
        </div>
      </div>
    </header>
  );
};

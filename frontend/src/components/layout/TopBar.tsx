import React from 'react';
import {
  Search,
  Bell,
  Sun,
  Moon,
  Zap,
} from 'lucide-react';
import { useAuthStore } from '../../store/authStore';
import { useThemeStore } from '../../store/themeStore';
import { StatusDot } from '../common/StatusDot';

interface TopBarProps {
  isSidebarCollapsed: boolean;
}

export const TopBar: React.FC<TopBarProps> = ({ isSidebarCollapsed }) => {
  const { user } = useAuthStore();
  const { theme, setTheme } = useThemeStore();

  const handleCycleTheme = () => {
    if (theme === 'dark') setTheme('light');
    else if (theme === 'light') setTheme('oled');
    else setTheme('dark');
  };

  const getThemeIcon = () => {
    if (theme === 'light') return <Sun size={18} className="text-[#FFC400]" />;
    if (theme === 'oled') return <Zap size={18} className="text-[#3CC6D0]" />;
    return <Moon size={18} className="text-[#FFD21F]" />;
  };

  return (
    <header
      className={`fixed top-0 right-0 h-16 z-20 flex items-center justify-between px-6 bg-white dark:bg-[#0B1220] border-b border-slate-200 dark:border-[#162036] transition-all duration-300 ease-in-out select-none ${
        isSidebarCollapsed ? 'left-[72px]' : 'left-[260px]'
      }`}
    >
      {/* Left: Global Search Input */}
      <div className="flex items-center gap-4 flex-1 max-w-md">
        <div className="relative w-full">
          <Search
            size={18}
            className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400 dark:text-[#9FADC2]"
          />
          <input
            type="text"
            placeholder="Search anything (incidents, devices, personnel)..."
            className="w-full h-10 pl-10 pr-4 text-sm rounded-xl bg-slate-100/80 dark:bg-[#162036] border border-slate-200 dark:border-[#26344F] text-slate-900 dark:text-[#EEF2F8] placeholder-slate-400 dark:placeholder-[#9FADC2]/70 focus:outline-none focus:ring-2 focus:ring-[#FFC400] dark:focus:ring-[#FFD21F] transition-all"
          />
        </div>
      </div>

      {/* Right Controls */}
      <div className="flex items-center gap-4">
        {/* Live Updates Badge */}
        <div className="hidden sm:flex items-center gap-2 px-3 py-1.5 rounded-full bg-emerald-50 dark:bg-[#0F3322] border border-emerald-500/30 text-xs font-semibold text-emerald-700 dark:text-[#4CD08A]">
          <StatusDot color="green" pulse size="sm" />
          <span>Live Mesh Ingestion</span>
        </div>

        {/* Theme Mode Toggle Button */}
        <button
          onClick={handleCycleTheme}
          className="p-2 rounded-xl text-slate-500 dark:text-[#9FADC2] hover:bg-slate-100 dark:hover:bg-[#162036] border border-transparent hover:border-slate-200 dark:hover:border-[#26344F] transition-all cursor-pointer"
          title={`Current Theme: ${theme.toUpperCase()} (Click to toggle)`}
        >
          {getThemeIcon()}
        </button>

        {/* Notification Bell */}
        <button
          className="relative p-2 rounded-xl text-slate-500 dark:text-[#9FADC2] hover:bg-slate-100 dark:hover:bg-[#162036] border border-transparent hover:border-slate-200 dark:hover:border-[#26344F] transition-all cursor-pointer"
          title="Incident Alerts"
        >
          <Bell size={19} />
          <span className="absolute top-1.5 right-1.5 w-2.5 h-2.5 rounded-full bg-[#D92D20] dark:bg-[#FF5A4E] ring-2 ring-white dark:ring-[#0B1220]" />
        </button>

        {/* User Profile & Role Chip */}
        <div className="flex items-center gap-3 pl-3 border-l border-slate-200 dark:border-[#26344F]">
          <div className="w-9 h-9 rounded-full bg-[#FFC400] dark:bg-[#FFD21F] text-[#1A1400] font-bold text-sm flex items-center justify-center shadow-sm">
            {user?.name ? user.name.charAt(0).toUpperCase() : 'A'}
          </div>
          <div className="hidden md:flex flex-col text-left">
            <span className="text-sm font-semibold text-slate-900 dark:text-[#EEF2F8] leading-tight">
              {user?.name || 'Administrator'}
            </span>
            <div className="flex items-center gap-1.5 mt-0.5">
              <span className="text-[10px] font-bold px-1.5 py-0.2 rounded bg-amber-500/10 text-amber-700 dark:text-[#FFD21F] border border-amber-500/20 uppercase tracking-wider">
                {user?.role || 'Admin'}
              </span>
              <span className="text-[11px] text-slate-500 dark:text-[#9FADC2]">
                Government HQ
              </span>
            </div>
          </div>
        </div>
      </div>
    </header>
  );
};

export default TopBar;

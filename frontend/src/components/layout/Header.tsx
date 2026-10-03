import React from 'react';
import {
  Radio,
  Wifi,
  MapPin,
  Bell,
  Sun,
  Moon,
  Zap,
} from 'lucide-react';
import { useTheme } from '../../theme/ThemeContext.tsx';

interface HeaderProps {
  breadcrumbs?: React.ReactNode;
}

export const Header: React.FC<HeaderProps> = ({ breadcrumbs }) => {
  const { theme, cycleTheme, isDark } = useTheme();

  return (
    <header
      className={`h-16 px-6 border-b flex items-center justify-between transition-colors sticky top-0 z-30 ${
        theme === 'oled'
          ? 'bg-black/90 backdrop-blur border-[#26344F]'
          : isDark
          ? 'bg-[#0B1220]/90 backdrop-blur border-[#26344F]'
          : 'bg-[#FFFCEB]/90 backdrop-blur border-[#E6DCA8]'
      }`}
    >
      {/* Left side: Breadcrumbs or dynamic path */}
      <div className="flex items-center gap-3">{breadcrumbs}</div>

      {/* Right side: System status + Theme toggle + Notifications + User profile */}
      <div className="flex items-center gap-4">
        {/* Status Strip per design.md Section 1 & 2.5 */}
        <div
          className={`hidden md:flex items-center gap-3 px-3 py-1.5 rounded-full text-xs font-mono font-medium border ${
            isDark
              ? 'bg-[#162036] border-[#26344F] text-[#9FADC2]'
              : 'bg-[#FFF5C2] border-[#E6DCA8] text-[#566070]'
          }`}
        >
          <div className="flex items-center gap-1.5 text-[#1E8E4E]">
            <Radio size={13} className="shrink-0" />
            <span className="font-semibold">Mesh 28</span>
          </div>
          <span className="opacity-40">|</span>
          <div className="flex items-center gap-1.5 text-[#1E8E4E]">
            <Wifi size={13} className="shrink-0" />
            <span>Online</span>
          </div>
          <span className="opacity-40">|</span>
          <div className="flex items-center gap-1.5 text-[#1E8E4E]">
            <MapPin size={13} className="shrink-0" />
            <span>GPS Fix</span>
          </div>
        </div>

        {/* Theme Switcher (Light / Dark / OLED) */}
        <button
          type="button"
          onClick={cycleTheme}
          title={`Theme: ${theme.toUpperCase()} (Click to toggle)`}
          aria-label={`Current theme is ${theme}. Click to switch theme`}
          className={`p-2 rounded-lg border transition-all flex items-center gap-1.5 text-xs font-bold ${
            isDark
              ? 'bg-[#162036] border-[#26344F] text-[#FFD21F] hover:bg-[#1f2d4d]'
              : 'bg-[#FFF5C2] border-[#E6DCA8] text-[#8A5A00] hover:bg-[#ffeaa0]'
          }`}
        >
          {theme === 'light' && <Sun size={16} />}
          {theme === 'dark' && <Moon size={16} />}
          {theme === 'oled' && <Zap size={16} />}
          <span className="uppercase text-[11px] tracking-wider">{theme}</span>
        </button>

        {/* Alerts Bell */}
        <button
          type="button"
          aria-label="Disaster notifications"
          className={`p-2 rounded-lg border relative transition-colors ${
            isDark
              ? 'bg-[#162036] border-[#26344F] text-[#EEF2F8] hover:bg-[#1f2d4d]'
              : 'bg-[#FFFFFF] border-[#E6DCA8] text-[#16202D] hover:bg-[#FFF5C2]'
          }`}
        >
          <Bell size={18} />
          <span className="absolute top-1.5 right-1.5 w-2 h-2 rounded-full bg-[#D92D20] ring-2 ring-inherit animate-pulse"></span>
        </button>

        {/* User Profile */}
        <div className="flex items-center gap-2.5 pl-2 border-l border-inherit">
          <div className="w-8 h-8 rounded-full bg-[#FFC400] text-[#1A1400] font-bold text-xs flex items-center justify-center font-display shadow-sm">
            AG
          </div>
          <div className="hidden lg:block text-left">
            <div
              className={`text-xs font-bold leading-tight ${
                isDark ? 'text-[#EEF2F8]' : 'text-[#16202D]'
              }`}
            >
              Admin
            </div>
            <div className="text-[10px] text-muted opacity-75 font-mono">Government</div>
          </div>
        </div>
      </div>
    </header>
  );
};

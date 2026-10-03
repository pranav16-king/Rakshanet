import React from 'react';
import { NavLink, useLocation } from 'react-router-dom';
import {
  LayoutDashboard,
  MapPin,
  AlertTriangle,
  Users,
  MessageSquare,
  Cpu,
  BarChart2,
  Box,
  FileText,
  Settings,
  Radio,
  Wifi,
  BatteryCharging,
} from 'lucide-react';

export const NAV_ITEMS = [
  { path: '/', label: 'Dashboard', icon: LayoutDashboard },
  { path: '/map', label: 'Live Map', icon: MapPin },
  { path: '/incidents', label: 'Incidents', icon: AlertTriangle },
  { path: '/people', label: 'People', icon: Users },
  { path: '/messages', label: 'Messages', icon: MessageSquare },
  { path: '/devices', label: 'Devices', icon: Cpu },
  { path: '/analytics', label: 'Analytics', icon: BarChart2 },
  { path: '/resources', label: 'Resources', icon: Box },
  { path: '/reports', label: 'Reports', icon: FileText },
  { path: '/settings', label: 'Settings', icon: Settings },
];

export const CommandSidebar: React.FC = () => {
  const location = useLocation();

  return (
    <aside className="w-64 bg-[#0B1220] text-[#EEF2F8] flex flex-col shrink-0 border-r border-[#26344F] z-30 select-none">
      {/* Brand Header */}
      <div className="h-16 px-5 flex items-center gap-3 border-b border-[#26344F]">
        <div className="w-9 h-9 rounded-lg bg-[#FFC400] flex items-center justify-center text-[#1A1400] shadow-sm">
          <svg className="w-5 h-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
            <path d="M12 2L2 22h20L12 2z" />
            <path d="M12 9v5" />
            <circle cx="12" cy="18" r="0.5" fill="currentColor" />
          </svg>
        </div>
        <div className="flex flex-col">
          <span className="font-bold font-display text-base tracking-wide text-white">
            SignalRescue AI
          </span>
          <span className="text-[10px] text-[#9FADC2] tracking-wider uppercase font-semibold">
            Command Center
          </span>
        </div>
      </div>

      {/* Navigation Links */}
      <nav className="flex-1 px-3 py-4 space-y-1.5 overflow-y-auto">
        {NAV_ITEMS.map((item) => {
          const isActive =
            item.path === '/'
              ? location.pathname === '/' || location.pathname === '/dashboard' || location.pathname === '/overview'
              : location.pathname.startsWith(item.path);

          const IconComponent = item.icon;

          return (
            <NavLink
              key={item.path}
              to={item.path}
              className={`flex items-center gap-3.5 px-3.5 py-2.5 rounded-xl text-sm font-semibold transition-all duration-150 ${
                isActive
                  ? 'bg-[#FFC400] text-[#1A1400] font-bold shadow-sm'
                  : 'text-[#9FADC2] hover:bg-[#162036] hover:text-[#EEF2F8]'
              }`}
            >
              <IconComponent className={`w-4 h-4 ${isActive ? 'text-[#1A1400]' : 'text-[#9FADC2]'}`} />
              <span>{item.label}</span>
            </NavLink>
          );
        })}
      </nav>

      {/* Network & Device Status Footer */}
      <div className="p-3 m-3 rounded-xl bg-[#0E1627] border border-[#26344F] text-xs space-y-2">
        <div className="flex items-center justify-between text-[#9FADC2]">
          <span className="flex items-center gap-1.5">
            <Radio className="w-3.5 h-3.5 text-[#3CC6D0] animate-pulse" />
            Mesh Net
          </span>
          <span className="text-[#3CC6D0] font-mono text-[11px] font-bold">ACTIVE (8 Hops)</span>
        </div>

        <div className="flex items-center justify-between text-[#9FADC2]">
          <span className="flex items-center gap-1.5">
            <Wifi className="w-3.5 h-3.5 text-[#4CD08A]" />
            Satellite Uplink
          </span>
          <span className="text-[#4CD08A] font-mono text-[11px] font-bold">ONLINE</span>
        </div>

        <div className="flex items-center justify-between text-[#9FADC2]">
          <span className="flex items-center gap-1.5">
            <BatteryCharging className="w-3.5 h-3.5 text-[#FFD21F]" />
            Gateway Power
          </span>
          <span className="text-[#EEF2F8] font-mono text-[11px] font-bold">94%</span>
        </div>
      </div>
    </aside>
  );
};

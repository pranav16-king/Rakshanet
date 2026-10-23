import React from 'react';
import { NavLink } from 'react-router-dom';
import {
  LayoutDashboard,
  Map,
  AlertTriangle,
  Users,
  MessageSquare,
  Radio,
  BarChart3,
  Package,
  FileText,
  Settings,
  Shield,
  WifiOff,
  UserSearch,
  LogOut,
  ChevronLeft,
  ChevronRight,
} from 'lucide-react';
import { useAuthStore } from '../../store/authStore';
import { StatusDot } from '../common/StatusDot';
import type { WebSocketStatus } from '../../hooks/useWebSocket';

interface SidebarProps {
  isCollapsed?: boolean;
  onToggleCollapse?: () => void;
  connectionStatus?: WebSocketStatus;
}

interface NavItem {
  name: string;
  path: string;
  icon: React.ElementType;
  badge?: string | number;
}

const navItems: NavItem[] = [
  { name: 'Dashboard', path: '/app/dashboard', icon: LayoutDashboard },
  { name: 'Live Map', path: '/app/map', icon: Map },
  { name: 'Incidents', path: '/app/incidents', icon: AlertTriangle, badge: '18' },
  { name: 'Rescue Ops', path: '/app/rescue-ops', icon: Shield },
  { name: 'Comms Gaps', path: '/app/communication-gaps', icon: WifiOff },
  { name: 'People', path: '/app/people', icon: Users },
  { name: 'Missing Persons', path: '/app/missing-persons', icon: UserSearch },
  { name: 'Messages', path: '/app/messages', icon: MessageSquare },
  { name: 'Devices', path: '/app/devices', icon: Radio },
  { name: 'Analytics', path: '/app/analytics', icon: BarChart3 },
  { name: 'Resources', path: '/app/resources', icon: Package },
  { name: 'Reports', path: '/app/reports', icon: FileText },
  { name: 'Settings', path: '/app/settings', icon: Settings },
];

export const Sidebar: React.FC<SidebarProps> = ({
  isCollapsed = false,
  onToggleCollapse = () => {},
  connectionStatus = 'connected',
}) => {
  const { user, logout } = useAuthStore();

  const getStatusColor = () => {
    switch (connectionStatus) {
      case 'connected':
        return 'green';
      case 'connecting':
      case 'reconnecting':
        return 'yellow';
      default:
        return 'red';
    }
  };

  const getStatusLabel = () => {
    switch (connectionStatus) {
      case 'connected':
        return 'Mesh Online';
      case 'connecting':
        return 'Connecting...';
      case 'reconnecting':
        return 'Reconnecting...';
      default:
        return 'Mesh Offline';
    }
  };

  return (
    <aside
      className={`fixed top-0 left-0 h-screen z-30 flex flex-col bg-[#0B1220] border-r border-[#162036] transition-all duration-300 ease-in-out select-none ${
        isCollapsed ? 'w-[72px]' : 'w-[260px]'
      }`}
    >
      {/* Brand Header */}
      <div className="h-16 flex items-center justify-between px-4 border-b border-[#162036]">
        <div className="flex items-center gap-3 overflow-hidden">
          {/* Beacon Yellow Logo */}
          <div className="w-9 h-9 min-w-[36px] bg-[#FFD21F] rounded-xl flex items-center justify-center shadow-lg shadow-yellow-500/20">
            <svg viewBox="0 0 24 24" fill="none" className="w-5 h-5">
              <path d="M12 3L2 20h20L12 3z" fill="#0B1220" />
              <path d="M12 8v5" stroke="#FFD21F" strokeWidth="2.5" strokeLinecap="round" />
              <circle cx="12" cy="16.5" r="1.2" fill="#FFD21F" />
            </svg>
          </div>

          {!isCollapsed && (
            <div className="flex flex-col whitespace-nowrap">
              <span className="font-bold text-white text-base tracking-tight" style={{ fontFamily: '"Barlow Semi Condensed", sans-serif' }}>
                RakshaNet <span className="text-[#FFD21F]">AI</span>
              </span>
              <span className="text-[10px] text-[#9FADC2] font-semibold tracking-wider uppercase">
                Command Center
              </span>
            </div>
          )}
        </div>

        {/* Collapse toggle */}
        <button
          onClick={onToggleCollapse}
          className="p-1.5 rounded-lg text-[#9FADC2] hover:text-white hover:bg-[#162036] transition-colors"
          title={isCollapsed ? 'Expand sidebar' : 'Collapse sidebar'}
        >
          {isCollapsed ? <ChevronRight size={18} /> : <ChevronLeft size={18} />}
        </button>
      </div>

      {/* Navigation List */}
      <nav className="flex-1 overflow-y-auto px-3 py-4 space-y-1.5 scrollbar-thin">
        {navItems.map((item) => {
          const Icon = item.icon;
          return (
            <NavLink
              key={item.path}
              to={item.path}
              className={({ isActive }) =>
                `flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-sm font-semibold transition-all group ${
                  isActive
                    ? 'bg-[#FFD21F] text-[#0B1220] shadow-md shadow-yellow-500/10 font-bold'
                    : 'text-[#9FADC2] hover:text-white hover:bg-[#162036]'
                }`
              }
              title={isCollapsed ? item.name : undefined}
            >
              {({ isActive }) => (
                <>
                  <Icon
                    size={20}
                    className={`flex-shrink-0 transition-transform group-hover:scale-105 ${
                      isActive ? 'text-[#0B1220]' : 'text-[#9FADC2] group-hover:text-white'
                    }`}
                  />
                  {!isCollapsed && (
                    <span className="truncate flex-1 tracking-wide">{item.name}</span>
                  )}
                  {!isCollapsed && item.badge && (
                    <span
                      className={`text-[11px] px-1.5 py-0.5 rounded-full font-bold ${
                        isActive
                          ? 'bg-[#0B1220] text-[#FFD21F]'
                          : 'bg-[#FF5A4E]/20 text-[#FF5A4E]'
                      }`}
                    >
                      {item.badge}
                    </span>
                  )}
                </>
              )}
            </NavLink>
          );
        })}
      </nav>

      {/* Backend Mesh Connection Status Indicator */}
      <div className="px-4 py-3 mx-2 mb-2 rounded-xl bg-[#0E1627] border border-[#162036]">
        <div className="flex items-center gap-2.5">
          <StatusDot color={getStatusColor()} pulse={connectionStatus === 'connected'} size="sm" />
          {!isCollapsed && (
            <div className="flex flex-col">
              <span className="text-xs font-semibold text-white tracking-wide">
                {getStatusLabel()}
              </span>
              <span className="text-[10px] text-[#9FADC2]">
                {connectionStatus === 'connected' ? 'ws://localhost:8000' : 'Reconnecting mesh'}
              </span>
            </div>
          )}
        </div>
      </div>

      {/* User Profile Card & Logout */}
      <div className="p-3 border-t border-[#162036]">
        <div className="flex items-center justify-between p-2 rounded-xl hover:bg-[#162036] transition-colors">
          <div className="flex items-center gap-3 overflow-hidden">
            <div className="w-9 h-9 min-w-[36px] rounded-full bg-[#162036] border border-[#26344F] flex items-center justify-center text-sm font-bold text-[#FFD21F]">
              {user?.name ? user.name.charAt(0).toUpperCase() : 'A'}
            </div>
            {!isCollapsed && (
              <div className="flex flex-col overflow-hidden">
                <span className="text-sm font-semibold text-white truncate">
                  {user?.name || 'Commander'}
                </span>
                <span className="text-[11px] text-[#9FADC2] truncate">
                  {user?.role || 'Admin'} · Govt
                </span>
              </div>
            )}
          </div>

          <button
            onClick={logout}
            className="p-1.5 rounded-lg text-[#9FADC2] hover:text-[#FF5A4E] hover:bg-[#FF5A4E]/10 transition-colors"
            title="Log out"
          >
            <LogOut size={18} />
          </button>
        </div>
      </div>
    </aside>
  );
};

export default Sidebar;

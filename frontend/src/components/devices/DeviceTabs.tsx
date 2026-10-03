import React from 'react';
import type { DeviceTab } from '../../types/devices';
import { List, Network, FileText } from 'lucide-react';

interface DeviceTabsProps {
  activeTab: DeviceTab;
  onTabChange: (tab: DeviceTab) => void;
}

export const DeviceTabs: React.FC<DeviceTabsProps> = ({
  activeTab,
  onTabChange,
}) => {
  const tabs: { id: DeviceTab; label: string; icon: React.ReactNode }[] = [
    { id: 'list', label: 'Device List', icon: <List className="w-4 h-4" /> },
    {
      id: 'topology',
      label: 'Network Topology',
      icon: <Network className="w-4 h-4" />,
    },
    {
      id: 'logs',
      label: 'Connection Logs',
      icon: <FileText className="w-4 h-4" />,
    },
  ];

  return (
    <div
      role="tablist"
      aria-label="Devices views"
      className="flex items-center gap-2 border-b border-slate-200 dark:border-slate-800 pb-2 overflow-x-auto"
    >
      {tabs.map((tab) => {
        const isActive = activeTab === tab.id;
        return (
          <button
            key={tab.id}
            role="tab"
            aria-selected={isActive}
            onClick={() => onTabChange(tab.id)}
            className={`flex items-center gap-2 px-4 py-2 rounded-lg text-sm transition-all focus:outline-none focus:ring-2 focus:ring-[#FFC400]/50 ${
              isActive
                ? 'bg-[#FFC400] text-slate-950 font-bold shadow-xs'
                : 'bg-white dark:bg-slate-800 text-slate-700 dark:text-slate-300 border border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-750 font-medium'
            }`}
          >
            {tab.icon}
            <span>{tab.label}</span>
          </button>
        );
      })}
    </div>
  );
};

export default DeviceTabs;

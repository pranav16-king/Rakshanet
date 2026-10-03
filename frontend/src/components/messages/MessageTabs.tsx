import React from 'react';
import type { MessageFilterTab } from '../../types/messages';

interface TabItem {
  id: MessageFilterTab;
  label: string;
  count?: number;
}

interface MessageTabsProps {
  activeTab: MessageFilterTab;
  onTabChange: (tab: MessageFilterTab) => void;
  counts?: Partial<Record<MessageFilterTab, number>>;
}

export const MessageTabs: React.FC<MessageTabsProps> = ({
  activeTab,
  onTabChange,
  counts,
}) => {
  const tabs: TabItem[] = [
    { id: 'all', label: 'All Messages', count: counts?.all },
    { id: 'sos', label: 'SOS Alerts', count: counts?.sos },
    { id: 'report', label: 'Incident Reports', count: counts?.report },
    { id: 'team', label: 'Team Messages', count: counts?.team },
    { id: 'system', label: 'System Logs', count: counts?.system },
  ];

  return (
    <div
      role="tablist"
      aria-label="Message filter categories"
      className="flex flex-wrap items-center gap-2 overflow-x-auto pb-1"
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
                ? 'bg-[#FFC400] text-slate-950 font-bold shadow-sm'
                : 'bg-white dark:bg-slate-800 text-slate-700 dark:text-slate-300 border border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-700 font-medium'
            }`}
          >
            <span>{tab.label}</span>
            {tab.count !== undefined && (
              <span
                className={`text-xs px-1.5 py-0.5 rounded-full ${
                  isActive
                    ? 'bg-black/15 text-slate-950 font-bold'
                    : 'bg-slate-100 dark:bg-slate-700 text-slate-600 dark:text-slate-400'
                }`}
              >
                {tab.count}
              </span>
            )}
          </button>
        );
      })}
    </div>
  );
};

export default MessageTabs;

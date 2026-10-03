import React from 'react';
import { Battery, Radio } from 'lucide-react';
import type { LiveDevice } from '../../types/map';

export interface LiveDeviceItemProps {
  device: LiveDevice;
  isSelected?: boolean;
  onSelect?: (device: LiveDevice) => void;
}

export const LiveDeviceItem: React.FC<LiveDeviceItemProps> = ({
  device,
  isSelected = false,
  onSelect,
}) => {
  const getStatusBadge = () => {
    switch (device.status) {
      case 'Online':
        return (
          <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[11px] font-bold bg-[#D9F2E3] dark:bg-[#0F3322] text-[#1E8E4E] dark:text-[#4CD08A] border border-[#1E8E4E]/25">
            <span className="w-1.5 h-1.5 rounded-full bg-[#1E8E4E] dark:bg-[#4CD08A] animate-pulse" />
            Online
          </span>
        );
      case 'Relay':
        return (
          <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[11px] font-bold bg-[#D6F1F3] dark:bg-[#0F3037] text-[#0E8A94] dark:text-[#3CC6D0] border border-[#0E8A94]/25">
            <Radio className="w-2.5 h-2.5 text-[#0E8A94] dark:text-[#3CC6D0]" />
            Relay
          </span>
        );
      case 'Offline':
      default:
        return (
          <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[11px] font-bold bg-[#F0F2F5] dark:bg-[#1E293B] text-[#566070] dark:text-[#9FADC2] border border-[#566070]/25">
            Offline
          </span>
        );
    }
  };

  return (
    <div
      onClick={() => onSelect?.(device)}
      className={`p-3 rounded-xl border transition-all duration-150 cursor-pointer flex items-center justify-between gap-3 ${
        isSelected
          ? 'bg-[#FFC400]/10 dark:bg-[#FFD21F]/15 border-[#FFC400] dark:border-[#FFD21F] shadow-xs'
          : 'bg-white dark:bg-[#162036] border-[#E6DCA8] dark:border-[#26344F] hover:border-[#FFC400]/70 dark:hover:border-[#FFD21F]/70 hover:bg-[#FFFCEB]/50 dark:hover:bg-[#1C2844]'
      }`}
    >
      <div className="flex flex-col min-w-0">
        <div className="flex items-center gap-2">
          <span className="font-mono text-xs font-bold text-[#16202D] dark:text-[#EEF2F8]">
            {device.id}
          </span>
          {device.battery !== undefined && (
            <span className="text-[10px] text-[#566070] dark:text-[#9FADC2] inline-flex items-center gap-0.5">
              <Battery className="w-3 h-3" />
              {device.battery}%
            </span>
          )}
        </div>
        <span className="text-xs text-[#566070] dark:text-[#9FADC2] truncate mt-0.5">
          {device.location} · {device.relativeTime}
        </span>
      </div>

      <div className="shrink-0">
        {getStatusBadge()}
      </div>
    </div>
  );
};

import React from 'react';
import { LifeBuoy, HeartPulse, Utensils, Tent, Plus } from 'lucide-react';
import type { ResourceNeed } from '../../types/incident.ts';
import { useTheme } from '../../theme/ThemeContext.tsx';

interface ResourcesNeededCardProps {
  resources: ResourceNeed[];
  onManageResources?: () => void;
}

export const ResourcesNeededCard: React.FC<ResourcesNeededCardProps> = ({
  resources,
  onManageResources,
}) => {
  const { isDark } = useTheme();

  const getResourceIcon = (iconType: ResourceNeed['iconType']) => {
    switch (iconType) {
      case 'boat':
        return <LifeBuoy size={20} className="text-[#3CC6D0]" />;
      case 'medical':
        return <HeartPulse size={20} className="text-[#FF5A4E]" />;
      case 'food':
        return <Utensils size={20} className="text-[#FFA033]" />;
      case 'shelter':
        return <Tent size={20} className="text-[#A98BFF]" />;
      default:
        return <LifeBuoy size={20} className="text-[#3CC6D0]" />;
    }
  };

  const getCardBg = (iconType: ResourceNeed['iconType']) => {
    if (isDark) {
      switch (iconType) {
        case 'boat':
          return 'bg-[#0F3037]/70 border-[#3CC6D0]/30';
        case 'medical':
          return 'bg-[#3A1512]/70 border-[#FF5A4E]/30';
        case 'food':
          return 'bg-[#3A2508]/70 border-[#FFA033]/30';
        case 'shelter':
          return 'bg-[#271F40]/70 border-[#A98BFF]/30';
        default:
          return 'bg-[#162036] border-[#26344F]';
      }
    } else {
      switch (iconType) {
        case 'boat':
          return 'bg-[#D6F1F3]/80 border-[#0E8A94]/30';
        case 'medical':
          return 'bg-[#FDE2DF]/80 border-[#D92D20]/30';
        case 'food':
          return 'bg-[#FFE6C7]/80 border-[#E07B00]/30';
        case 'shelter':
          return 'bg-[#F0EBFF]/80 border-[#7A4DD8]/30';
        default:
          return 'bg-[#FFFFFF] border-[#E6DCA8]';
      }
    }
  };

  return (
    <div
      className={`p-5 rounded-xl border transition-colors shadow-sm ${
        isDark ? 'bg-[#162036] border-[#26344F]' : 'bg-white border-[#E6DCA8]'
      }`}
    >
      <div className="flex items-center justify-between mb-4">
        <h3
          className={`font-display font-bold text-base tracking-tight ${
            isDark ? 'text-[#EEF2F8]' : 'text-[#16202D]'
          }`}
        >
          Resources Needed
        </h3>
        <span className="text-[11px] font-mono opacity-60">AI Logistics Optimisation</span>
      </div>

      {/* 2x2 Resource Units Grid matching media_1791015140209.jpg */}
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
        {resources.map((res) => (
          <div
            key={res.id}
            className={`p-3.5 rounded-xl border flex items-center gap-3 transition-transform hover:-translate-y-0.5 ${getCardBg(
              res.iconType
            )}`}
          >
            <div className="p-2 rounded-lg bg-black/10 shrink-0">
              {getResourceIcon(res.iconType)}
            </div>
            <div className="min-w-0 flex-1">
              <div
                className={`text-xs font-semibold truncate ${
                  isDark ? 'text-[#EEF2F8]' : 'text-[#16202D]'
                }`}
              >
                {res.title}
              </div>
              <div className="text-xs font-mono font-bold text-[#FFC400]">
                {res.quantityDisplay}
              </div>
            </div>
          </div>
        ))}
      </div>

      {onManageResources && (
        <div className="mt-4 pt-3 border-t border-inherit flex justify-end">
          <button
            type="button"
            onClick={onManageResources}
            className={`text-xs font-semibold flex items-center gap-1.5 transition-colors ${
              isDark ? 'text-[#FFD21F] hover:text-white' : 'text-[#8A5A00] hover:text-[#16202D]'
            }`}
          >
            <Plus size={14} />
            <span>Request Additional Mutual Aid</span>
          </button>
        </div>
      )}
    </div>
  );
};

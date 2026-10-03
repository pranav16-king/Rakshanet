import React from 'react';
import type { IncidentSeverity } from '../../types';

interface BadgeProps {
  variant?: 'severity' | 'status' | 'outline' | 'pill';
  severity?: IncidentSeverity;
  label: string;
  icon?: React.ReactNode;
  className?: string;
}

export const Badge: React.FC<BadgeProps> = ({
  variant = 'severity',
  severity: level = 'UNKNOWN',
  label,
  icon,
  className = '',
}) => {
  const getSeverityStyle = (s: IncidentSeverity) => {
    switch (s) {
      case 'CRITICAL':
        return 'bg-[#FDE2DF] dark:bg-[#3A1512] text-[#D92D20] dark:text-[#FF5A4E] border-[#D92D20]/30';
      case 'HIGH':
        return 'bg-[#FFE6C7] dark:bg-[#3A2508] text-[#E07B00] dark:text-[#FFA033] border-[#E07B00]/30';
      case 'MEDIUM':
        return 'bg-[#FFEFA6] dark:bg-[#3A3010] text-[#8A5A00] dark:text-[#FFD21F] border-[#FFC400]/30';
      case 'LOW':
        return 'bg-[#D9F2E3] dark:bg-[#0F3322] text-[#1E8E4E] dark:text-[#4CD08A] border-[#1E8E4E]/30';
      default:
        return 'bg-gray-100 dark:bg-gray-800 text-[#566070] dark:text-[#9FADC2] border-gray-400/30';
    }
  };

  const baseStyle =
    'inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-semibold tracking-wide border';
  const customStyle = variant === 'severity' ? getSeverityStyle(level) : 'bg-gray-100 dark:bg-[#162036] text-gray-700 dark:text-gray-300 border-gray-300 dark:border-gray-700';

  return (
    <span className={`${baseStyle} ${customStyle} ${className}`}>
      {icon && <span className="flex-shrink-0">{icon}</span>}
      <span>{label}</span>
    </span>
  );
};

export default Badge;

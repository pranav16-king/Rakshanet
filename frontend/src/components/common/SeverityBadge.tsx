import React from 'react';
import { AlertOctagon, AlertTriangle, AlertCircle, CheckCircle, HelpCircle } from 'lucide-react';
import type { SeverityLevel } from '../../types/incident.ts';
import { useTheme } from '../../theme/ThemeContext.tsx';

interface SeverityBadgeProps {
  severity: SeverityLevel | string;
  size?: 'sm' | 'md' | 'lg';
  showIcon?: boolean;
  className?: string;
}

export const SeverityBadge: React.FC<SeverityBadgeProps> = ({
  severity,
  size = 'md',
  showIcon = true,
  className = '',
}) => {
  const { isDark } = useTheme();
  const normalized = (severity || 'UNKNOWN').toUpperCase() as SeverityLevel;

  // Icon mapping strictly per design.md Section 2.4
  const getIcon = () => {
    const iconSize = size === 'sm' ? 12 : size === 'lg' ? 18 : 14;
    switch (normalized) {
      case 'CRITICAL':
        return <AlertOctagon size={iconSize} className="shrink-0" />;
      case 'HIGH':
        return <AlertTriangle size={iconSize} className="shrink-0" />;
      case 'MEDIUM':
        return <AlertCircle size={iconSize} className="shrink-0" />;
      case 'LOW':
        return <CheckCircle size={iconSize} className="shrink-0" />;
      default:
        return <HelpCircle size={iconSize} className="shrink-0" />;
    }
  };

  // Color & tint styles strictly adhering to light vs dark contrast rules
  const getStyles = () => {
    switch (normalized) {
      case 'CRITICAL':
        return isDark
          ? 'bg-[#3A1512] text-[#FF5A4E] border-[#FF5A4E]/30'
          : 'bg-[#FDE2DF] text-[#D92D20] border-[#D92D20]/30';
      case 'HIGH':
        return isDark
          ? 'bg-[#3A2508] text-[#FFA033] border-[#FFA033]/30'
          : 'bg-[#FFE6C7] text-[#E07B00] border-[#E07B00]/30';
      case 'MEDIUM':
        return isDark
          ? 'bg-[#3A3010] text-[#FFD21F] border-[#FFD21F]/30'
          : 'bg-[#F1F5F9] text-[#8A5A00] border-[#CBD5E1]/40';
      case 'LOW':
        return isDark
          ? 'bg-[#0F3322] text-[#4CD08A] border-[#4CD08A]/30'
          : 'bg-[#D9F2E3] text-[#1E8E4E] border-[#1E8E4E]/30';
      default:
        return isDark
          ? 'bg-[#162036] text-[#9FADC2] border-[#26344F]'
          : 'bg-[#F8FAFC] text-[#64748B] border-[#E2E8F0]';
    }
  };

  const getLabel = () => {
    switch (normalized) {
      case 'CRITICAL':
        return 'Critical';
      case 'HIGH':
        return 'High';
      case 'MEDIUM':
        return 'Medium';
      case 'LOW':
        return 'Low';
      default:
        return 'Unknown';
    }
  };

  const sizeClasses =
    size === 'sm'
      ? 'px-2 py-0.5 text-xs font-semibold gap-1'
      : size === 'lg'
      ? 'px-3.5 py-1.5 text-sm font-bold gap-2'
      : 'px-2.5 py-1 text-xs font-bold gap-1.5';

  return (
    <span
      className={`inline-flex items-center rounded-full border transition-colors ${sizeClasses} ${getStyles()} ${className}`}
      role="status"
      aria-label={`Severity: ${getLabel()}`}
    >
      {showIcon && getIcon()}
      <span>{getLabel()}</span>
    </span>
  );
};

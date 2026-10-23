import React from 'react';

interface LogoProps {
  size?: 'sm' | 'md' | 'lg';
  showSubtitle?: boolean;
  subtitle?: string;
  className?: string;
}

export const Logo: React.FC<LogoProps> = ({
  size = 'md',
  showSubtitle = false,
  subtitle = 'Command Center',
  className = '',
}) => {
  const iconSizes = {
    sm: 'w-7 h-7',
    md: 'w-9 h-9',
    lg: 'w-12 h-12',
  };

  const textSizes = {
    sm: 'text-base',
    md: 'text-lg',
    lg: 'text-2xl',
  };

  return (
    <div className={`flex items-center gap-3 select-none ${className}`}>
      {/* Hi-Vis Beacon Triangle Emblem */}
      <div
        className={`${iconSizes[size]} bg-[#FFC400] dark:bg-[#FFD21F] rounded-xl flex items-center justify-center shadow-md relative overflow-hidden flex-shrink-0`}
        style={{
          boxShadow: '0 0 16px rgba(255, 196, 0, 0.35)',
        }}
      >
        <svg
          viewBox="0 0 24 24"
          fill="none"
          stroke="#0F172A"
          strokeWidth="2.5"
          strokeLinecap="round"
          strokeLinejoin="round"
          className="w-5/6 h-5/6"
        >
          {/* Signal wave triangle beacon */}
          <path d="M12 3L2 20h20L12 3z" fill="#0F172A" stroke="none" />
          <path d="M12 8v5" stroke="#FFC400" strokeWidth="2.5" />
          <circle cx="12" cy="16.5" r="1.2" fill="#FFC400" />
        </svg>
      </div>

      <div className="flex flex-col leading-tight">
        <span
          className={`font-bold tracking-tight text-[#0F172A] dark:text-[#EEF2F8] ${textSizes[size]}`}
          style={{ fontFamily: '"Barlow Semi Condensed", sans-serif' }}
        >
          RakshaNet <span className="text-[#8A5A00] dark:text-[#FFD21F]">AI</span>
        </span>
        {showSubtitle && (
          <span className="text-xs font-medium text-[#64748B] dark:text-[#9FADC2] tracking-wider uppercase">
            {subtitle}
          </span>
        )}
      </div>
    </div>
  );
};

export default Logo;

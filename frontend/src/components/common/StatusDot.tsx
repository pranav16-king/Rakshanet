import React from 'react';

export type StatusColor = 'green' | 'yellow' | 'red' | 'teal' | 'gray';

interface StatusDotProps {
  color?: StatusColor;
  pulse?: boolean;
  label?: string;
  size?: 'sm' | 'md' | 'lg';
  className?: string;
}

export const StatusDot: React.FC<StatusDotProps> = ({
  color = 'green',
  pulse = true,
  label,
  size = 'md',
  className = '',
}) => {
  const dotSizes = {
    sm: 'w-2 h-2',
    md: 'w-2.5 h-2.5',
    lg: 'w-3 h-3',
  };

  const colorStyles = {
    green: {
      bg: 'bg-[#1E8E4E] dark:bg-[#4CD08A]',
      ping: 'bg-[#4CD08A]',
      glow: 'shadow-[0_0_8px_rgba(76,208,138,0.6)]',
    },
    yellow: {
      bg: 'bg-[#FFC400] dark:bg-[#FFD21F]',
      ping: 'bg-[#FFD21F]',
      glow: 'shadow-[0_0_8px_rgba(255,210,31,0.6)]',
    },
    red: {
      bg: 'bg-[#D92D20] dark:bg-[#FF5A4E]',
      ping: 'bg-[#FF5A4E]',
      glow: 'shadow-[0_0_8px_rgba(255,90,78,0.6)]',
    },
    teal: {
      bg: 'bg-[#0E8A94] dark:bg-[#3CC6D0]',
      ping: 'bg-[#3CC6D0]',
      glow: 'shadow-[0_0_8px_rgba(60,198,208,0.6)]',
    },
    gray: {
      bg: 'bg-[#566070] dark:bg-[#9FADC2]',
      ping: 'bg-[#9FADC2]',
      glow: 'shadow-none',
    },
  };

  const current = colorStyles[color];

  return (
    <div className={`inline-flex items-center gap-2 ${className}`}>
      <span className="relative flex items-center justify-center">
        {pulse && color !== 'gray' && (
          <span
            className={`animate-ping absolute inline-flex h-full w-full rounded-full opacity-75 ${current.ping}`}
          />
        )}
        <span
          className={`relative inline-flex rounded-full ${dotSizes[size]} ${current.bg} ${current.glow}`}
        />
      </span>
      {label && (
        <span className="text-xs font-medium text-[#566070] dark:text-[#9FADC2]">
          {label}
        </span>
      )}
    </div>
  );
};

export default StatusDot;

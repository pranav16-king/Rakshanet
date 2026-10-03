import React from 'react';

interface SignalRescueLogoProps {
  size?: number;
  className?: string;
  showText?: boolean;
  textClassName?: string;
  subtitle?: string;
}

export const SignalRescueLogo: React.FC<SignalRescueLogoProps> = ({
  size = 40,
  className = '',
  showText = false,
  textClassName = 'text-slate-900 dark:text-white',
  subtitle,
}) => {
  return (
    <div className={`inline-flex items-center gap-3 ${className}`}>
      {/* Precision Hi-Vis Beacon Triangle Emblem matching Screen 1 & Screen 2 */}
      <div
        className="relative shrink-0 flex items-center justify-center rounded-xl overflow-hidden shadow-sm transition-transform hover:scale-105"
        style={{ width: size, height: size }}
      >
        <svg
          viewBox="0 0 100 100"
          width={size}
          height={size}
          className="w-full h-full drop-shadow-sm"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          {/* Rounded Yellow Triangle Base */}
          <polygon
            points="50,6 94,86 6,86"
            fill="#FFC400"
            stroke="#E0AA00"
            strokeWidth="3"
            strokeLinejoin="round"
          />
          {/* Inner Dark Geometric Beacon / Rescue Flame Emblem */}
          <path
            d="M50 26L74 76H26L50 26Z"
            fill="#0B1220"
          />
          {/* Inner Glowing Signal Beacon Wave */}
          <path
            d="M50 42L63 70H37L50 42Z"
            fill="#FFC400"
          />
          {/* Central High-Intensity Pulse Dot */}
          <circle cx="50" cy="62" r="4.5" fill="#0B1220" />
        </svg>
      </div>

      {showText && (
        <div className="flex flex-col">
          <span className={`font-display font-extrabold tracking-tight text-xl leading-none ${textClassName}`}>
            SignalRescue AI
          </span>
          {subtitle && (
            <span className="text-[11px] font-bold tracking-widest uppercase text-slate-500 dark:text-slate-400 mt-1">
              {subtitle}
            </span>
          )}
        </div>
      )}
    </div>
  );
};

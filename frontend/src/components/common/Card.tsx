import React from 'react';

interface CardProps extends React.HTMLAttributes<HTMLDivElement> {
  variant?: 'default' | 'raised' | 'sunken' | 'alert';
  alertColor?: 'red' | 'yellow' | 'teal' | 'green';
  className?: string;
}

export const Card: React.FC<CardProps> = ({
  children,
  variant = 'default',
  alertColor = 'red',
  className = '',
  ...props
}) => {
  const variantStyles = {
    default:
      'bg-white dark:bg-[#162036] border border-slate-200 dark:border-[#26344F] text-slate-900 dark:text-[#EEF2F8]',
    raised:
      'bg-slate-50 dark:bg-[#111A2C] border border-slate-200 dark:border-[#3A4C70] shadow-md',
    sunken:
      'bg-slate-50 dark:bg-[#0E1627] border border-slate-200/80 dark:border-[#26344F]/50',
    alert:
      'bg-white dark:bg-[#162036] border-l-4 border-y border-r border-slate-200 dark:border-[#26344F]',
  };

  const alertBorders = {
    red: 'border-l-[#D92D20] dark:border-l-[#FF5A4E]',
    yellow: 'border-l-[#FFC400] dark:border-l-[#FFD21F]',
    teal: 'border-l-[#0E8A94] dark:border-l-[#3CC6D0]',
    green: 'border-l-[#1E8E4E] dark:border-l-[#4CD08A]',
  };

  const alertClass = variant === 'alert' ? alertBorders[alertColor] : '';

  return (
    <div
      className={`rounded-xl p-4 transition-colors ${variantStyles[variant]} ${alertClass} ${className}`}
      {...props}
    >
      {children}
    </div>
  );
};

export default Card;

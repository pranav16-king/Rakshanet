import React from 'react';

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'danger' | 'ghost' | 'outline';
  size?: 'sm' | 'md' | 'lg';
  isLoading?: boolean;
  leftIcon?: React.ReactNode;
  rightIcon?: React.ReactNode;
}

export const Button: React.FC<ButtonProps> = ({
  children,
  variant = 'primary',
  size = 'md',
  isLoading = false,
  leftIcon,
  rightIcon,
  className = '',
  disabled,
  ...props
}) => {
  const sizeStyles = {
    sm: 'h-9 px-3 text-xs rounded-lg gap-1.5',
    md: 'h-11 px-4 text-sm rounded-xl gap-2',
    lg: 'h-13 px-6 text-base rounded-xl gap-2.5 min-h-[48px]',
  };

  const variantStyles = {
    primary:
      'bg-[#FFC400] dark:bg-[#FFD21F] text-[#1A1400] font-semibold hover:brightness-105 active:scale-[0.98] shadow-sm',
    secondary:
      'bg-[#162036] text-[#EEF2F8] border border-[#26344F] hover:bg-[#1E2B48] active:scale-[0.98]',
    danger:
      'bg-[#D92D20] dark:bg-[#FF5A4E] text-white font-semibold hover:brightness-110 active:scale-[0.98] shadow-sm',
    ghost:
      'bg-transparent text-[#566070] dark:text-[#9FADC2] hover:bg-black/5 dark:hover:bg-white/5 active:scale-[0.98]',
    outline:
      'bg-transparent border border-white/30 text-white hover:bg-white/10 active:scale-[0.98]',
  };

  return (
    <button
      className={`inline-flex items-center justify-center font-medium transition-all select-none disabled:opacity-50 disabled:pointer-events-none cursor-pointer ${sizeStyles[size]} ${variantStyles[variant]} ${className}`}
      disabled={disabled || isLoading}
      {...props}
    >
      {isLoading ? (
        <span className="w-4 h-4 border-2 border-current border-t-transparent rounded-full animate-spin" />
      ) : (
        leftIcon && <span className="flex-shrink-0">{leftIcon}</span>
      )}
      <span>{children}</span>
      {!isLoading && rightIcon && <span className="flex-shrink-0">{rightIcon}</span>}
    </button>
  );
};

export default Button;

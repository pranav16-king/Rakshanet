import React from 'react';

export interface LoadingSkeletonProps {
  variant?: 'text' | 'rectangular' | 'circular' | 'card';
  width?: string | number;
  height?: string | number;
  className?: string;
  count?: number;
}

export const LoadingSkeleton: React.FC<LoadingSkeletonProps> = ({
  variant = 'text',
  width,
  height,
  className = '',
  count = 1,
}) => {
  const getVariantStyles = () => {
    switch (variant) {
      case 'circular':
        return 'rounded-full';
      case 'rectangular':
        return 'rounded-lg';
      case 'card':
        return 'rounded-xl h-28 w-full';
      case 'text':
      default:
        return 'rounded h-4 w-full';
    }
  };

  const elements = Array.from({ length: count }, (_, i) => (
    <div
      key={i}
      style={{
        width: width !== undefined ? width : undefined,
        height: height !== undefined ? height : undefined,
      }}
      className={`bg-[#E6DCA8]/50 dark:bg-[#26344F]/80 animate-pulse ${getVariantStyles()} ${className}`}
      aria-hidden="true"
    />
  ));

  return count === 1 ? elements[0] : <div className="space-y-2">{elements}</div>;
};

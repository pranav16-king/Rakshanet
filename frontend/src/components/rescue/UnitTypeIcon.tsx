// src/components/rescue/UnitTypeIcon.tsx
import React from 'react';
import { Truck, Ambulance, Compass, Plane } from 'lucide-react';
import type { UnitType } from '../../types';

interface UnitTypeIconProps {
  type: UnitType;
  className?: string;
}

export const UnitTypeIcon: React.FC<UnitTypeIconProps> = ({ type, className = 'w-5 h-5' }) => {
  switch (type) {
    case 'BOAT':
      return <Compass className={className} />;
    case 'HIGH_CLEARANCE_4WD':
      return <Truck className={className} />;
    case 'AMBULANCE':
      return <Ambulance className={className} />;
    case 'HELICOPTER':
      return <Plane className={className} />;
    default:
      return <Truck className={className} />;
  }
};

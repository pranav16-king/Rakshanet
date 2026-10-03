// src/components/rescue/FleetTable.tsx
import React from 'react';
import type { RescueUnit } from '../../types';
import { UnitTypeIcon } from './UnitTypeIcon';
import { UnitStatusBadge } from './UnitStatusBadge';
import { MapPin, Users, Gauge, Fuel } from 'lucide-react';

interface FleetTableProps {
  units: RescueUnit[];
  onSelectUnit?: (unit: RescueUnit) => void;
  selectedUnitId?: string;
}

export const FleetTable: React.FC<FleetTableProps> = ({
  units,
  onSelectUnit,
  selectedUnitId,
}) => {
  return (
    <div className="w-full overflow-x-auto rounded-xl border border-slate-700/60 bg-[#162036] shadow-md">
      <table className="w-full text-left text-sm text-slate-200">
        <thead className="bg-[#0E1627] text-xs uppercase tracking-wider text-slate-400 border-b border-slate-700">
          <tr>
            <th scope="col" className="px-5 py-3.5 font-semibold">Unit ID & Name</th>
            <th scope="col" className="px-4 py-3.5 font-semibold">Type</th>
            <th scope="col" className="px-4 py-3.5 font-semibold">Status</th>
            <th scope="col" className="px-4 py-3.5 font-semibold">Base Location</th>
            <th scope="col" className="px-4 py-3.5 font-semibold">Capacity</th>
            <th scope="col" className="px-4 py-3.5 font-semibold">Speed / Readiness</th>
            <th scope="col" className="px-5 py-3.5 font-semibold">Capabilities</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-slate-800">
          {units.map((unit) => {
            const isSelected = selectedUnitId === unit.unit_id;
            return (
              <tr
                key={unit.unit_id}
                onClick={() => onSelectUnit?.(unit)}
                className={`transition-colors cursor-pointer hover:bg-slate-800/40 ${
                  isSelected ? 'bg-amber-500/10 border-l-4 border-amber-400' : ''
                }`}
              >
                <td className="px-5 py-4 whitespace-nowrap">
                  <div className="flex items-center gap-3">
                    <div className="p-2 rounded-lg bg-slate-800 text-amber-400 border border-slate-700">
                      <UnitTypeIcon type={unit.unit_type} className="w-5 h-5" />
                    </div>
                    <div>
                      <div className="font-mono font-semibold text-white tracking-wide">
                        {unit.unit_id}
                      </div>
                      <div className="text-xs text-slate-400 max-w-[200px] truncate">
                        {unit.name}
                      </div>
                    </div>
                  </div>
                </td>

                <td className="px-4 py-4 whitespace-nowrap">
                  <span className="text-xs font-medium text-slate-300">
                    {unit.unit_type.replace(/_/g, ' ')}
                  </span>
                </td>

                <td className="px-4 py-4 whitespace-nowrap">
                  <UnitStatusBadge status={unit.status} />
                </td>

                <td className="px-4 py-4 whitespace-nowrap text-xs text-slate-300">
                  <div className="flex items-center gap-1.5">
                    <MapPin className="w-3.5 h-3.5 text-cyan-400 flex-shrink-0" />
                    <span>{unit.base_location || `${unit.lat.toFixed(4)}, ${unit.lng.toFixed(4)}`}</span>
                  </div>
                </td>

                <td className="px-4 py-4 whitespace-nowrap">
                  <div className="flex items-center gap-2">
                    <Users className="w-3.5 h-3.5 text-slate-400" />
                    <span className="font-medium text-slate-100">{unit.capacity}</span>
                    <span className="text-xs text-slate-400">pax/trip</span>
                  </div>
                </td>

                <td className="px-4 py-4 whitespace-nowrap text-xs">
                  <div className="space-y-1">
                    <div className="flex items-center gap-1 text-slate-300">
                      <Gauge className="w-3 h-3 text-cyan-400" />
                      <span>{unit.speed_kmh} km/h avg</span>
                    </div>
                    {unit.fuel_percent !== undefined && (
                      <div className="flex items-center gap-1 text-slate-400">
                        <Fuel className="w-3 h-3 text-emerald-400" />
                        <span>Fuel {unit.fuel_percent}%</span>
                      </div>
                    )}
                  </div>
                </td>

                <td className="px-5 py-4">
                  <div className="flex flex-wrap gap-1.5 max-w-[280px]">
                    {unit.capabilities.map((cap) => (
                      <span
                        key={cap}
                        className="px-2 py-0.5 rounded text-[11px] font-medium bg-slate-800 text-cyan-300 border border-slate-700/80"
                      >
                        {cap.replace(/_/g, ' ')}
                      </span>
                    ))}
                  </div>
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
};

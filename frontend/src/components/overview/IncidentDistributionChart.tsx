import React from 'react';
import { PieChart, Pie, Cell, ResponsiveContainer, Tooltip } from 'recharts';
import { IncidentCategoryDistribution } from '../../types/dashboard';
import { EmptyState } from '../common/EmptyState';
import { LoadingSkeleton } from '../common/LoadingSkeleton';
import { PieChart as PieChartIcon } from 'lucide-react';

export interface IncidentDistributionChartProps {
  categories: IncidentCategoryDistribution[];
  total: number;
  isLoading?: boolean;
  className?: string;
}

export const IncidentDistributionChart: React.FC<IncidentDistributionChartProps> = ({
  categories,
  total,
  isLoading = false,
  className = '',
}) => {
  if (isLoading) {
    return (
      <div className={`bg-white dark:bg-[#162036] border border-[#E6DCA8] dark:border-[#26344F] rounded-xl p-5 shadow-sm ${className}`}>
        <LoadingSkeleton variant="text" width="40%" className="mb-4" />
        <div className="flex items-center justify-center h-56">
          <LoadingSkeleton variant="circular" width="160px" height="160px" />
        </div>
      </div>
    );
  }

  const isEmpty = total === 0 || categories.length === 0;

  return (
    <div
      className={`bg-white dark:bg-[#162036] border border-[#E6DCA8] dark:border-[#26344F] rounded-xl p-5 shadow-sm flex flex-col justify-between ${className}`}
    >
      {/* Header */}
      <div className="flex items-center justify-between mb-2">
        <h2 className="text-base font-bold text-[#16202D] dark:text-[#EEF2F8] font-display">
          Incident Distribution
        </h2>
        <span className="text-xs font-semibold px-2 py-0.5 rounded-full bg-[#FFFCEB] dark:bg-[#0E1627] text-[#566070] dark:text-[#9FADC2] border border-[#E6DCA8] dark:border-[#26344F]">
          Live telemetry
        </span>
      </div>

      {isEmpty ? (
        <div className="py-6">
          <EmptyState
            icon={PieChartIcon}
            title="No Incidents Reported"
            description="The disaster telemetry network reports zero active hazards across monitored sectors."
          />
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-12 gap-4 items-center">
          {/* Donut Chart with Center Total */}
          <div className="md:col-span-7 relative h-60 w-full flex items-center justify-center">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Tooltip
                  formatter={(val: any) => [`${val ?? 0} incidents`, 'Count']}
                  contentStyle={{
                    backgroundColor: '#0B1220',
                    borderColor: '#26344F',
                    borderRadius: '8px',
                    color: '#EEF2F8',
                    fontSize: '12px',
                    boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.3)',
                  }}
                  itemStyle={{ color: '#FFD21F' }}
                />
                <Pie
                  data={categories}
                  cx="50%"
                  cy="50%"
                  innerRadius={68}
                  outerRadius={92}
                  paddingAngle={3}
                  dataKey="count"
                  strokeWidth={0}
                >
                  {categories.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
                  ))}
                </Pie>
              </PieChart>
            </ResponsiveContainer>

            {/* Centered Total Overlay */}
            <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none select-none">
              <span className="text-3xl font-extrabold tracking-tight text-[#16202D] dark:text-[#EEF2F8] font-display">
                {total}
              </span>
              <span className="text-xs font-medium text-[#566070] dark:text-[#9FADC2]">
                Total
              </span>
            </div>
          </div>

          {/* Colored Legend on the right */}
          <div className="md:col-span-5 flex flex-col space-y-2.5 pr-2">
            {categories.map((cat) => (
              <div
                key={cat.name}
                className="flex items-center justify-between text-xs py-0.5 border-b border-dashed border-gray-100 dark:border-gray-800/60 last:border-0"
              >
                <div className="flex items-center gap-2.5">
                  <span
                    className="w-2.5 h-2.5 rounded-full shrink-0 shadow-2xs"
                    style={{ backgroundColor: cat.color }}
                  />
                  <span className="text-[#16202D] dark:text-[#EEF2F8] font-medium">
                    {cat.name}
                  </span>
                </div>
                <span className="font-bold font-mono text-[#16202D] dark:text-[#EEF2F8]">
                  {cat.count}
                </span>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
};

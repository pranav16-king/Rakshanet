import React from 'react';
import { useNavigate } from 'react-router-dom';
import { PieChart, Pie, Cell, ResponsiveContainer, Tooltip } from 'recharts';
import { PieChart as PieChartIcon, Activity, MapPin, ArrowRight } from 'lucide-react';
import { IncidentCategoryDistribution } from '../../types/dashboard';
import { EmptyState } from '../common/EmptyState';
import { LoadingSkeleton } from '../common/LoadingSkeleton';

export interface IncidentDistributionChartProps {
  categories: IncidentCategoryDistribution[];
  total: number;
  isLoading?: boolean;
  className?: string;
}

const CATEGORY_COLOR_MAP: Record<string, string> = {
  Flood: '#0E8A94',
  Earthquake: '#E11D48',
  Landslide: '#D97706',
  Cyclone: '#8B5CF6',
  Fire: '#EF4444',
  'Building Collapse': '#A855F7',
  Others: '#64748B',
};

export const IncidentDistributionChart: React.FC<IncidentDistributionChartProps> = ({
  categories,
  total,
  isLoading = false,
  className = '',
}) => {
  const navigate = useNavigate();

  if (isLoading) {
    return (
      <div
        className={`bg-white dark:bg-[#162036] border border-slate-200 dark:border-[#26344F] rounded-2xl p-6 shadow-xs flex flex-col justify-between ${className}`}
      >
        <div className="flex justify-between items-center mb-4">
          <LoadingSkeleton variant="text" width="45%" />
          <LoadingSkeleton variant="text" width="20%" />
        </div>
        <div className="flex items-center justify-center h-64">
          <LoadingSkeleton variant="circular" width="180px" height="180px" />
        </div>
        <div className="space-y-2 mt-4">
          <LoadingSkeleton variant="text" count={3} />
        </div>
      </div>
    );
  }

  const isEmpty = total === 0 || categories.length === 0;

  // Enhance categories with fallback colors and compute percentages
  const enrichedCategories = categories.map((cat) => ({
    ...cat,
    color: cat.color || CATEGORY_COLOR_MAP[cat.name] || '#64748B',
    pct: total > 0 ? Math.round((cat.count / total) * 100) : 0,
  }));

  // Find dominant disaster
  const dominant = enrichedCategories.reduce(
    (max, cat) => (cat.count > max.count ? cat : max),
    enrichedCategories[0] || { name: 'None', count: 0 }
  );

  return (
    <div
      className={`bg-white dark:bg-[#162036] border border-slate-200 dark:border-[#26344F] rounded-2xl p-6 shadow-xs flex flex-col justify-between min-h-[500px] ${className}`}
    >
      {/* Card Header */}
      <div>
        <div className="flex items-center justify-between mb-1">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 rounded-lg bg-teal-50 dark:bg-teal-950/40 text-teal-600 dark:text-teal-400 border border-teal-200/60 dark:border-teal-900/40 flex items-center justify-center">
              <PieChartIcon size={16} />
            </div>
            <div>
              <h2
                className="text-base font-bold text-slate-900 dark:text-[#EEF2F8] tracking-tight"
                style={{ fontFamily: '"Barlow Semi Condensed", sans-serif' }}
              >
                Incident Distribution
              </h2>
              <p className="text-xs text-slate-500 dark:text-[#9FADC2]">
                Active alerts categorized by disaster taxonomy
              </p>
            </div>
          </div>

          <div className="flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-slate-50 dark:bg-[#0E1627] border border-slate-200/80 dark:border-[#26344F] text-[11px] font-semibold text-slate-600 dark:text-[#9FADC2]">
            <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
            <span>Live Telemetry</span>
          </div>
        </div>
      </div>

      {isEmpty ? (
        <div className="py-12 flex-1 flex items-center justify-center">
          <EmptyState
            icon={PieChartIcon}
            title="Zero Active Hazards"
            description="The disaster telemetry network reports all sectors operational and clear of distress clusters."
          />
        </div>
      ) : (
        <div className="flex-1 flex flex-col justify-center my-3">
          {/* Main Visual: Segmented Donut & Center Total */}
          <div className="grid grid-cols-1 md:grid-cols-12 gap-4 items-center">
            {/* Recharts Pie Donut */}
            <div className="md:col-span-6 relative h-56 w-full flex items-center justify-center">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Tooltip
                    formatter={(val: any, name: any) => [
                      `${val} incidents (${total > 0 ? Math.round(((val as number) / total) * 100) : 0}%)`,
                      name,
                    ]}
                    contentStyle={{
                      backgroundColor: '#0B1220',
                      borderColor: '#26344F',
                      borderRadius: '10px',
                      color: '#EEF2F8',
                      fontSize: '12px',
                      boxShadow: '0 10px 15px -3px rgba(0, 0, 0, 0.4)',
                    }}
                    itemStyle={{ color: '#FFD21F' }}
                  />
                  <Pie
                    data={enrichedCategories}
                    cx="50%"
                    cy="50%"
                    innerRadius={68}
                    outerRadius={92}
                    paddingAngle={3}
                    dataKey="count"
                    strokeWidth={0}
                  >
                    {enrichedCategories.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={entry.color} />
                    ))}
                  </Pie>
                </PieChart>
              </ResponsiveContainer>

              {/* Centered Total Overlay */}
              <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none select-none">
                <span
                  className="text-4xl font-black text-slate-900 dark:text-white tracking-tight"
                  style={{ fontFamily: '"Barlow Semi Condensed", sans-serif' }}
                >
                  {total}
                </span>
                <span className="text-[11px] font-semibold uppercase tracking-wider text-slate-500 dark:text-[#9FADC2]">
                  Total Active
                </span>
              </div>
            </div>

            {/* Categorical Breakdown Legend with Counts and Percentages */}
            <div className="md:col-span-6 flex flex-col space-y-2 pr-1">
              {enrichedCategories.map((cat) => (
                <div
                  key={cat.name}
                  className="flex items-center justify-between text-xs py-1 px-2 rounded-lg hover:bg-slate-50 dark:hover:bg-[#0E1627] transition-colors"
                >
                  <div className="flex items-center gap-2.5 min-w-0">
                    <span
                      className="w-2.5 h-2.5 rounded-full shrink-0 shadow-2xs"
                      style={{ backgroundColor: cat.color }}
                    />
                    <span className="text-slate-700 dark:text-[#CBD5E1] font-medium truncate">
                      {cat.name}
                    </span>
                  </div>
                  <div className="flex items-center gap-2 shrink-0">
                    <span className="font-bold text-slate-900 dark:text-white font-mono">
                      {cat.count}
                    </span>
                    <span className="text-[10px] font-mono font-semibold px-1.5 py-0.2 rounded bg-slate-100 dark:bg-[#0E1627] text-slate-600 dark:text-[#9FADC2] border border-slate-200/80 dark:border-[#26344F]">
                      {cat.pct}%
                    </span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Bottom Telemetry & Quick Action Strip */}
      <div className="pt-4 border-t border-slate-200 dark:border-[#26344F] flex flex-col sm:flex-row sm:items-center justify-between gap-3 text-xs">
        <div className="flex items-center gap-2 text-slate-500 dark:text-[#9FADC2]">
          <Activity size={14} className="text-amber-500 shrink-0" />
          <span>
            Primary threat: <strong className="text-slate-800 dark:text-[#EEF2F8]">{dominant?.name}</strong> ({dominant?.count} active)
          </span>
        </div>

        <button
          onClick={() => navigate('/app/map')}
          className="inline-flex items-center gap-1.5 font-bold text-amber-600 dark:text-[#FFD21F] hover:underline cursor-pointer group"
        >
          <MapPin size={13} />
          <span>Sector Geographic View</span>
          <ArrowRight size={13} className="group-hover:translate-x-0.5 transition-transform" />
        </button>
      </div>
    </div>
  );
};

export default IncidentDistributionChart;

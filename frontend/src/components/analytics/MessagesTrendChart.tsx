// src/components/analytics/MessagesTrendChart.tsx
import React from 'react';
import {
  ResponsiveContainer,
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
} from 'recharts';
import type { MessageTrendPoint } from '../../types';

interface MessagesTrendChartProps {
  data: MessageTrendPoint[];
}

export const MessagesTrendChart: React.FC<MessagesTrendChartProps> = ({ data }) => {
  return (
    <div className="p-6 rounded-xl border border-slate-700/80 bg-[#162036] shadow-md space-y-4">
      {/* Chart Title and Legend Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div>
          <h3 className="text-base font-bold text-white">Messages Over Time</h3>
          <p className="text-xs text-slate-400 mt-0.5">
            Breakdown of emergency SOS distress beacons, field reports, and total telemetry traffic.
          </p>
        </div>

        {/* Legend pills */}
        <div className="flex items-center gap-4 text-xs font-medium">
          <div className="flex items-center gap-1.5">
            <span className="w-3 h-3 rounded-full bg-[#3B82F6]" />
            <span className="text-slate-300">Total</span>
          </div>
          <div className="flex items-center gap-1.5">
            <span className="w-3 h-3 rounded-full bg-[#EF4444]" />
            <span className="text-slate-300">SOS</span>
          </div>
          <div className="flex items-center gap-1.5">
            <span className="w-3 h-3 rounded-full bg-[#10B981]" />
            <span className="text-slate-300">Reports</span>
          </div>
        </div>
      </div>

      {/* Recharts Multi-line chart */}
      <div className="w-full h-72 sm:h-80 pt-2">
        <ResponsiveContainer width="100%" height="100%">
          <LineChart data={data} margin={{ top: 10, right: 20, left: -10, bottom: 0 }}>
            <CartesianGrid strokeDasharray="3 3" stroke="#26344F" vertical={false} />
            <XAxis
              dataKey="date"
              stroke="#9FADC2"
              fontSize={12}
              tickLine={false}
              axisLine={{ stroke: '#26344F' }}
            />
            <YAxis
              stroke="#9FADC2"
              fontSize={12}
              tickLine={false}
              axisLine={{ stroke: '#26344F' }}
              tickFormatter={(v) => v.toLocaleString()}
            />
            <Tooltip
              contentStyle={{
                backgroundColor: '#0E1627',
                borderColor: '#3A4C70',
                borderRadius: '8px',
                color: '#EEF2F8',
                fontSize: '12px',
              }}
              formatter={(val: any, name: any) => {
                const label = name === 'total' ? 'Total Messages' : name === 'sos' ? 'Distress SOS' : 'Field Reports';
                return [Number(val || 0).toLocaleString(), label];
              }}
            />
            <Line
              type="monotone"
              dataKey="total"
              stroke="#3B82F6"
              strokeWidth={2.5}
              dot={{ r: 4, fill: '#3B82F6', stroke: '#162036', strokeWidth: 2 }}
              activeDot={{ r: 6 }}
            />
            <Line
              type="monotone"
              dataKey="sos"
              stroke="#EF4444"
              strokeWidth={2.5}
              dot={{ r: 4, fill: '#EF4444', stroke: '#162036', strokeWidth: 2 }}
              activeDot={{ r: 6 }}
            />
            <Line
              type="monotone"
              dataKey="reports"
              stroke="#10B981"
              strokeWidth={2.5}
              dot={{ r: 4, fill: '#10B981', stroke: '#162036', strokeWidth: 2 }}
              activeDot={{ r: 6 }}
            />
          </LineChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
};

import React from 'react';
import {
  TrendingUp,
  Users,
  MessageSquare,
  ShieldCheck,
  CheckCircle,
} from 'lucide-react';
import { Card } from '../../components/common/Card';

export const AnalyticsPage: React.FC = () => {
  const stats = [
    { label: 'Total Messages', value: '85,421', change: '+32%', icon: MessageSquare },
    { label: 'Unique Users', value: '4,238', change: '+12%', icon: Users },
    { label: 'Incidents Handled', value: '56', change: '+48%', icon: ShieldCheck },
    { label: 'People Helped', value: '1,842', change: '+65%', icon: CheckCircle },
  ];

  const timeSeries = [
    { date: 'Sep 16', text: 250, sos: 100, reports: 40 },
    { date: 'Sep 17', text: 450, sos: 220, reports: 90 },
    { date: 'Sep 18', text: 980, sos: 510, reports: 180 },
    { date: 'Sep 19', text: 1540, sos: 740, reports: 290 },
    { date: 'Sep 20', text: 1350, sos: 680, reports: 310 },
    { date: 'Sep 21', text: 1820, sos: 890, reports: 420 },
  ];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1
            className="text-2xl sm:text-3xl font-black text-[#16202D] dark:text-white tracking-tight"
            style={{ fontFamily: '"Barlow Semi Condensed", sans-serif' }}
          >
            Analytics & Reports
          </h1>
          <p className="text-xs sm:text-sm text-[#566070] dark:text-[#9FADC2]">
            Telemetry ingestion statistics, DTN hop throughput, and casualty preservation metrics
          </p>
        </div>

        <select className="h-9 px-3 rounded-xl bg-white dark:bg-[#162036] border border-[#E6DCA8] dark:border-[#26344F] text-xs font-semibold text-[#16202D] dark:text-white focus:outline-none focus:ring-2 focus:ring-[#FFC400]">
          <option>Last 7 days</option>
          <option>Last 30 days</option>
          <option>Entire Disaster Cycle</option>
        </select>
      </div>

      {/* 4 Stat Cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {stats.map((s, idx) => (
          <Card key={idx} className="flex flex-col justify-between">
            <span className="text-xs font-semibold text-[#566070] dark:text-[#9FADC2]">
              {s.label}
            </span>
            <span
              className="text-3xl font-black text-[#16202D] dark:text-white my-1"
              style={{ fontFamily: '"Barlow Semi Condensed", sans-serif' }}
            >
              {s.value}
            </span>
            <span className="text-xs font-bold text-[#1E8E4E] dark:text-[#4CD08A] flex items-center gap-1">
              <TrendingUp size={12} /> {s.change}
            </span>
          </Card>
        ))}
      </div>

      {/* Messages Over Time Graph Canvas */}
      <Card>
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
          <div>
            <h3
              className="text-base font-bold text-[#16202D] dark:text-white"
              style={{ fontFamily: '"Barlow Semi Condensed", sans-serif' }}
            >
              Messages Over Time
            </h3>
            <p className="text-xs text-[#566070] dark:text-[#9FADC2]">
              Categorized telemetry rate received across cellular fringes and data mules
            </p>
          </div>

          <div className="flex items-center gap-4 text-xs font-semibold">
            <div className="flex items-center gap-1.5">
              <span className="w-2.5 h-2.5 rounded-full bg-[#0E8A94]" />
              <span className="text-[#566070] dark:text-[#9FADC2]">Text</span>
            </div>
            <div className="flex items-center gap-1.5">
              <span className="w-2.5 h-2.5 rounded-full bg-[#D92D20]" />
              <span className="text-[#566070] dark:text-[#9FADC2]">SOS</span>
            </div>
            <div className="flex items-center gap-1.5">
              <span className="w-2.5 h-2.5 rounded-full bg-[#FFC400]" />
              <span className="text-[#566070] dark:text-[#9FADC2]">Reports</span>
            </div>
          </div>
        </div>

        {/* Visual Line Chart SVG */}
        <div className="relative h-64 w-full bg-[#FFFCEB]/40 dark:bg-[#0E1627] rounded-xl p-4 border border-[#E6DCA8]/50 dark:border-[#26344F]/50 flex flex-col justify-end">
          <div className="grid grid-cols-6 gap-2 h-48 items-end">
            {timeSeries.map((point, i) => (
              <div key={i} className="flex flex-col items-center gap-1 h-full justify-end group">
                <div className="w-full max-w-[40px] flex items-end gap-1 h-full">
                  <div
                    className="w-1/3 bg-[#0E8A94] rounded-t-sm transition-all group-hover:brightness-125"
                    style={{ height: `${(point.text / 2000) * 100}%` }}
                    title={`Text: ${point.text}`}
                  />
                  <div
                    className="w-1/3 bg-[#D92D20] rounded-t-sm transition-all group-hover:brightness-125"
                    style={{ height: `${(point.sos / 2000) * 100}%` }}
                    title={`SOS: ${point.sos}`}
                  />
                  <div
                    className="w-1/3 bg-[#FFC400] rounded-t-sm transition-all group-hover:brightness-125"
                    style={{ height: `${(point.reports / 2000) * 100}%` }}
                    title={`Reports: ${point.reports}`}
                  />
                </div>
                <span className="text-[11px] font-semibold text-[#566070] dark:text-[#9FADC2] mt-2">
                  {point.date}
                </span>
              </div>
            ))}
          </div>
        </div>
      </Card>
    </div>
  );
};

export default AnalyticsPage;

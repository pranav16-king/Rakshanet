import React from 'react';
import {
  Sparkles,
  ShieldAlert,
  Clock,
  AlertTriangle,
  Users,
  Compass,
  Radio,
  Info,
  CheckCircle,
} from 'lucide-react';
import type { AIExplainability } from '../../types/incident.ts';
import { useTheme } from '../../theme/ThemeContext.tsx';

interface IncidentAIExplanationProps {
  explainability: AIExplainability;
}

export const IncidentAIExplanation: React.FC<IncidentAIExplanationProps> = ({ explainability }) => {
  const { isDark } = useTheme();
  const { factors, priorityScore, confidencePct, confidenceGrade, modelVersion, synthesis, disclaimer } =
    explainability;

  const factorList = [
    {
      ...factors.lastContactTime,
      icon: Clock,
    },
    {
      ...factors.incidentSeverity,
      icon: AlertTriangle,
    },
    {
      ...factors.affectedPopulation,
      icon: Users,
    },
    {
      ...factors.hazardBoundaryProximity,
      icon: Compass,
    },
    {
      ...factors.communicationStatus,
      icon: Radio,
    },
  ];

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'critical':
        return isDark
          ? 'bg-[#3A1512] text-[#FF5A4E] border-[#FF5A4E]/30'
          : 'bg-[#FDE2DF] text-[#D92D20] border-[#D92D20]/30';
      case 'warning':
        return isDark
          ? 'bg-[#3A2508] text-[#FFA033] border-[#FFA033]/30'
          : 'bg-[#FFE6C7] text-[#E07B00] border-[#E07B00]/30';
      case 'normal':
      default:
        return isDark
          ? 'bg-[#0F3322] text-[#4CD08A] border-[#4CD08A]/30'
          : 'bg-[#D9F2E3] text-[#1E8E4E] border-[#1E8E4E]/30';
    }
  };

  return (
    <div
      className={`p-6 rounded-xl border transition-colors shadow-sm ${
        isDark ? 'bg-[#162036] border-[#26344F]' : 'bg-white border-[#E6DCA8]'
      }`}
    >
      {/* Header with Title and Model Version */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between pb-4 border-b border-inherit gap-2">
        <div className="flex items-center gap-2.5">
          <div className="w-8 h-8 rounded-lg bg-[#FFC400]/20 flex items-center justify-center text-[#FFC400]">
            <Sparkles size={18} />
          </div>
          <div>
            <h3
              className={`font-display font-bold text-base tracking-tight ${
                isDark ? 'text-[#EEF2F8]' : 'text-[#16202D]'
              }`}
            >
              AI Analysis & Deep Explainability
            </h3>
            <p className="text-[11px] opacity-70">
              Deterministic factor breakdown per SignalRescue Design Rule 5 & 11
            </p>
          </div>
        </div>
        <div
          className={`px-2.5 py-1 rounded-md text-[11px] font-mono border self-start sm:self-auto ${
            isDark ? 'bg-[#0E1627] border-[#26344F] text-[#9FADC2]' : 'bg-[#F6F0D4] border-[#E6DCA8] text-[#566070]'
          }`}
        >
          {modelVersion}
        </div>
      </div>

      {/* Priority Score & Confidence Meter Row */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4 my-5">
        {/* Priority Score Card */}
        <div
          className={`p-4 rounded-xl border flex items-center justify-between ${
            isDark ? 'bg-[#0E1627] border-[#26344F]' : 'bg-[#FFF5C2]/40 border-[#E6DCA8]'
          }`}
        >
          <div>
            <span className="text-xs font-semibold uppercase tracking-wider opacity-70 block mb-1">
              Priority Triage Score
            </span>
            <div className="flex items-baseline gap-2">
              <span className="font-display font-bold text-3xl text-[#FF5A4E]">
                {priorityScore}
              </span>
              <span className="text-xs opacity-50 font-mono">/ 100</span>
              <span
                className={`ml-2 px-2 py-0.5 rounded text-[11px] font-bold uppercase ${
                  isDark ? 'bg-[#3A1512] text-[#FF5A4E]' : 'bg-[#FDE2DF] text-[#D92D20]'
                }`}
              >
                CRITICAL
              </span>
            </div>
            <div className="text-[11px] opacity-75 mt-1">
              Calculated from casualty risk & telemetry decay
            </div>
          </div>
          <div className="w-12 h-12 rounded-full border-4 border-[#FF5A4E] flex items-center justify-center text-[#FF5A4E]">
            <ShieldAlert size={22} />
          </div>
        </div>

        {/* Confidence Meter Card */}
        <div
          className={`p-4 rounded-xl border flex flex-col justify-between ${
            isDark ? 'bg-[#0E1627] border-[#26344F]' : 'bg-[#FFF5C2]/40 border-[#E6DCA8]'
          }`}
        >
          <div className="flex items-center justify-between mb-2">
            <span className="text-xs font-semibold uppercase tracking-wider opacity-70">
              Model Confidence Meter
            </span>
            <span className="text-xs font-mono font-bold text-[#1E8E4E] flex items-center gap-1">
              <CheckCircle size={13} />
              {confidenceGrade}
            </span>
          </div>

          <div className="space-y-2">
            <div className="flex items-center justify-between text-xs font-mono">
              <span>Statistical Accuracy</span>
              <span className="font-bold text-base text-[#1E8E4E]">{confidencePct}%</span>
            </div>

            {/* Confidence Bar Meter */}
            <div
              className={`w-full h-2.5 rounded-full overflow-hidden ${
                isDark ? 'bg-[#162036]' : 'bg-[#E6DCA8]'
              }`}
            >
              <div
                className="h-full bg-gradient-to-r from-[#FFC400] via-[#0E8A94] to-[#1E8E4E] rounded-full transition-all duration-500"
                style={{ width: `${confidencePct}%` }}
              />
            </div>

            <div className="flex items-center justify-between text-[10px] opacity-70 italic font-mono pt-0.5">
              <span>{disclaimer}</span>
            </div>
          </div>
        </div>
      </div>

      {/* Factor Contribution Proportions Visualizer */}
      <div className="mb-5">
        <div className="flex items-center justify-between text-xs mb-1.5 font-mono">
          <span className="font-semibold">Factor Contribution Weights:</span>
          <span className="opacity-70">Total: 100% Deterministic Sum</span>
        </div>
        <div className="w-full h-2 rounded-full overflow-hidden flex bg-black/10">
          <div
            style={{ width: `${factors.incidentSeverity.weightPct}%` }}
            className="bg-[#D92D20]"
            title={`Severity: ${factors.incidentSeverity.weightPct}%`}
          />
          <div
            style={{ width: `${factors.lastContactTime.weightPct}%` }}
            className="bg-[#E07B00]"
            title={`Last Contact: ${factors.lastContactTime.weightPct}%`}
          />
          <div
            style={{ width: `${factors.affectedPopulation.weightPct}%` }}
            className="bg-[#FFC400]"
            title={`Population: ${factors.affectedPopulation.weightPct}%`}
          />
          <div
            style={{ width: `${factors.hazardBoundaryProximity.weightPct}%` }}
            className="bg-[#0E8A94]"
            title={`Hazard Proximity: ${factors.hazardBoundaryProximity.weightPct}%`}
          />
          <div
            style={{ width: `${factors.communicationStatus.weightPct}%` }}
            className="bg-[#7A4DD8]"
            title={`Comm Status: ${factors.communicationStatus.weightPct}%`}
          />
        </div>
      </div>

      {/* Detailed Factors List (Strictly adhering to design.md rule 5) */}
      <div className="space-y-3">
        <span className="text-xs font-bold uppercase tracking-wider opacity-80 block font-mono">
          5 Core Explainability Factors:
        </span>

        {factorList.map((factor) => {
          const Icon = factor.icon;
          return (
            <div
              key={factor.factorKey}
              className={`p-3.5 rounded-lg border transition-all flex flex-col sm:flex-row sm:items-center justify-between gap-3 ${
                isDark
                  ? 'bg-[#0E1627] border-[#26344F] hover:border-[#3A4C70]'
                  : 'bg-white border-[#E6DCA8] hover:border-[#C9BB6E]'
              }`}
            >
              <div className="flex items-start gap-3">
                <div
                  className={`p-2 rounded-md mt-0.5 shrink-0 ${
                    isDark ? 'bg-[#162036] text-[#FFC400]' : 'bg-[#FFF5C2] text-[#8A5A00]'
                  }`}
                >
                  <Icon size={16} />
                </div>
                <div>
                  <div className="flex items-center gap-2 flex-wrap">
                    <span
                      className={`text-xs font-bold ${
                        isDark ? 'text-[#EEF2F8]' : 'text-[#16202D]'
                      }`}
                    >
                      {factor.name}
                    </span>
                    <span
                      className={`px-2 py-0.5 rounded text-[10px] font-mono font-bold border ${getStatusBadge(
                        factor.status
                      )}`}
                    >
                      {factor.valueDisplay}
                    </span>
                  </div>
                  <p
                    className={`text-xs mt-1 leading-snug ${
                      isDark ? 'text-[#9FADC2]' : 'text-[#566070]'
                    }`}
                  >
                    {factor.details}
                  </p>
                </div>
              </div>

              <div className="flex sm:flex-col items-center sm:items-end justify-between shrink-0 font-mono text-xs pl-11 sm:pl-0 border-t sm:border-t-0 pt-2 sm:pt-0 border-inherit">
                <span className="opacity-60 text-[11px]">Weight</span>
                <span className="font-bold text-[#FFC400] text-sm">{factor.weightPct}%</span>
              </div>
            </div>
          );
        })}
      </div>

      {/* AI Synthesis Summary */}
      <div
        className={`mt-5 p-3.5 rounded-lg border text-xs flex items-start gap-2.5 ${
          isDark
            ? 'bg-[#0F3037]/60 border-[#3CC6D0]/30 text-[#3CC6D0]'
            : 'bg-[#D6F1F3]/60 border-[#0E8A94]/30 text-[#0E8A94]'
        }`}
      >
        <Info size={16} className="shrink-0 mt-0.5" />
        <div className="leading-relaxed">
          <strong className="block mb-0.5 font-bold uppercase tracking-wide">
            Operational Recommendation:
          </strong>
          <span className={isDark ? 'text-white' : 'text-[#16202D]'}>{synthesis}</span>
        </div>
      </div>
    </div>
  );
};

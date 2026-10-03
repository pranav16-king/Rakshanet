// src/components/communication-gaps/DecayChartMini.tsx
import React from 'react';

interface DecayChartMiniProps {
  data: Array<{ timestamp: number; active_nodes: number }>;
  criticalDrop: boolean;
}

export const DecayChartMini: React.FC<DecayChartMiniProps> = ({ data, criticalDrop }) => {
  if (!data || data.length < 2) return null;

  const width = 140;
  const height = 40;
  const padding = 4;

  const maxNodes = Math.max(...data.map(d => d.active_nodes), 1);
  const minNodes = Math.min(...data.map(d => d.active_nodes), 0);
  const range = maxNodes - minNodes || 1;

  const points = data
    .map((d, index) => {
      const x = padding + (index / (data.length - 1)) * (width - 2 * padding);
      const y = height - padding - ((d.active_nodes - minNodes) / range) * (height - 2 * padding);
      return `${x},${y}`;
    })
    .join(' ');

  const strokeColor = criticalDrop ? '#FF5A4E' : '#FFA033';
  const fillColor = criticalDrop ? 'rgba(255, 90, 78, 0.15)' : 'rgba(255, 160, 51, 0.15)';

  const firstY = height - padding - ((data[0].active_nodes - minNodes) / range) * (height - 2 * padding);
  const lastY = height - padding - ((data[data.length - 1].active_nodes - minNodes) / range) * (height - 2 * padding);
  const areaPoints = `${padding},${height} ${padding},${firstY} ${points} ${width - padding},${lastY} ${width - padding},${height}`;

  return (
    <div className="flex flex-col items-end">
      <svg width={width} height={height} className="overflow-visible">
        <polygon points={areaPoints} fill={fillColor} />
        <polyline
          fill="none"
          stroke={strokeColor}
          strokeWidth="2"
          strokeLinecap="round"
          strokeLinejoin="round"
          points={points}
        />
        {/* Start point */}
        <circle
          cx={padding}
          cy={firstY}
          r="2.5"
          fill="#3CC6D0"
        />
        {/* Collapse end point */}
        <circle
          cx={width - padding}
          cy={lastY}
          r="3"
          fill={strokeColor}
          className="animate-pulse"
        />
      </svg>
      <div className="text-[10px] text-slate-400 font-mono mt-0.5">
        {data[0].active_nodes} ➔ {data[data.length - 1].active_nodes} nodes
      </div>
    </div>
  );
};

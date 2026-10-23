import React from 'react';
import { AlertOctagon, Clock, Map, MapPin, Users } from 'lucide-react';
import type { Incident } from '../../types/incident.ts';
import { useTheme } from '../../theme/ThemeContext.tsx';
import { SeverityBadge } from '../common/SeverityBadge.tsx';

interface IncidentKeyInfoCardProps {
  incident: Incident;
}

const reported = (value: unknown): string =>
  typeof value === 'string' && value.trim()
    ? value
    : typeof value === 'number' && Number.isFinite(value)
      ? String(value)
      : 'Not reported';

const formatReportedTime = (value: unknown): string => {
  if (!value) return 'Not reported';
  let epoch: number | null = null;
  if (typeof value === 'number' && Number.isFinite(value) && value > 1000000000) {
    epoch = value;
  } else if (typeof value === 'string') {
    const trimmed = value.trim();
    if (!trimmed || trimmed === 'Not reported') return 'Not reported';
    const num = Number(trimmed);
    if (!isNaN(num) && num > 1000000000) {
      epoch = num;
    } else {
      return trimmed;
    }
  }
  if (epoch) {
    try {
      return new Date(epoch).toLocaleString(undefined, {
        day: '2-digit',
        month: 'short',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit',
      });
    } catch {
      return String(value);
    }
  }
  return 'Not reported';
};

export const IncidentKeyInfoCard: React.FC<IncidentKeyInfoCardProps> = ({ incident }) => {
  const { isDark } = useTheme();
  const hasCoordinates =
    typeof incident.coordinates?.lat === 'number' && Number.isFinite(incident.coordinates.lat) &&
    typeof incident.coordinates?.lng === 'number' && Number.isFinite(incident.coordinates.lng);

  const area = typeof incident.affectedAreaKm2 === 'number' && Number.isFinite(incident.affectedAreaKm2) && incident.affectedAreaKm2 > 0
    ? `${incident.affectedAreaKm2} km²`
    : hasCoordinates
      ? `Sector ±${incident.clusterRadiusMeters || 250} m radius`
      : (typeof incident.affected_area === 'string' && incident.affected_area.trim() ? incident.affected_area : 'Not reported');

  const peopleCount = incident.affectedPeople ?? incident.people_count;
  const peopleDisplay = typeof peopleCount === 'number' && peopleCount > 0
    ? `${peopleCount} soul${peopleCount === 1 ? '' : 's'} reported`
    : 'Not reported';

  const locationDisplay = hasCoordinates
    ? `${incident.coordinates!.lat.toFixed(4)}° N, ${incident.coordinates!.lng.toFixed(4)}° E`
    : (typeof incident.location === 'string' && incident.location !== 'Location unavailable' && incident.location.trim()
        ? incident.location
        : 'Not reported');

  const rows = [
    { label: 'Incident ID', value: incident.id || 'Not reported', icon: AlertOctagon },
    { label: 'Affected area', value: area, icon: Map },
    { label: 'People reported', value: peopleDisplay, icon: Users },
    { label: 'Reported location', value: locationDisplay, icon: MapPin },
    { label: 'First reported', value: formatReportedTime(incident.firstReported ?? incident.firstReportedTimestamp), icon: Clock },
    { label: 'Last updated', value: formatReportedTime(incident.lastUpdate ?? incident.lastUpdateTimestamp), icon: Clock },
  ];

  return (
    <section className={`rounded-xl border p-5 shadow-sm ${isDark ? 'border-[#26344F] bg-[#162036]' : 'border-[#E2E8F0] bg-white'}`}>
      <div className="mb-4 flex items-center justify-between gap-3">
        <h3 className={`font-display text-base font-bold tracking-tight ${isDark ? 'text-[#EEF2F8]' : 'text-[#0F172A]'}`}>
          Reported incident information
        </h3>
        <SeverityBadge severity={incident.severity} size="sm" />
      </div>
      <dl className="space-y-3 text-xs">
        {rows.map(({ label, value, icon: Icon }) => (
          <div key={label} className="flex items-start justify-between gap-4 border-b border-inherit/40 pb-3 last:border-0 last:pb-0">
            <dt className={`flex shrink-0 items-center gap-1.5 ${isDark ? 'text-[#9FADC2]' : 'text-[#64748B]'}`}>
              <Icon size={13} aria-hidden="true" />
              {label}
            </dt>
            <dd className={`break-all text-right font-mono font-medium ${isDark ? 'text-white' : 'text-[#0F172A]'}`}>{value}</dd>
          </div>
        ))}
      </dl>
    </section>
  );
};

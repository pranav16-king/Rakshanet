import React, { useState } from 'react';
import { Search, Users, HeartPulse, Clock, Smartphone, AlertTriangle } from 'lucide-react';
import type { IncidentPerson } from '../../types/incident.ts';
import { useTheme } from '../../theme/ThemeContext.tsx';

interface IncidentPeopleTabProps {
  people: IncidentPerson[];
}

export const IncidentPeopleTab: React.FC<IncidentPeopleTabProps> = ({ people }) => {
  const { isDark } = useTheme();
  const [search, setSearch] = useState('');

  const filtered = people.filter(
    (p) =>
      p.name.toLowerCase().includes(search.toLowerCase()) ||
      p.devicePseudonym.toLowerCase().includes(search.toLowerCase()) ||
      p.location.toLowerCase().includes(search.toLowerCase())
  );

  const getStatusBadge = (status: IncidentPerson['status']) => {
    switch (status) {
      case 'Critical Triage':
        return isDark
          ? 'bg-[#3A1512] text-[#FF5A4E] border-[#FF5A4E]/30'
          : 'bg-[#FDE2DF] text-[#D92D20] border-[#D92D20]/30';
      case 'Trapped':
        return isDark
          ? 'bg-[#3A2508] text-[#FFA033] border-[#FFA033]/30'
          : 'bg-[#FFE6C7] text-[#E07B00] border-[#E07B00]/30';
      case 'Safe Haven':
        return isDark
          ? 'bg-[#0F3322] text-[#4CD08A] border-[#4CD08A]/30'
          : 'bg-[#D9F2E3] text-[#1E8E4E] border-[#1E8E4E]/30';
      default:
        return 'bg-gray-700 text-gray-200 border-gray-600';
    }
  };

  return (
    <div
      className={`p-6 rounded-xl border transition-colors shadow-sm ${
        isDark ? 'bg-[#162036] border-[#26344F]' : 'bg-white border-[#E2E8F0]'
      }`}
    >
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
        <div>
          <h3
            className={`font-display font-bold text-lg ${
              isDark ? 'text-[#EEF2F8]' : 'text-[#0F172A]'
            }`}
          >
            Affected Individuals & Families ({people.length} Estimated)
          </h3>
          <p className="text-xs opacity-70">
            Triage census aggregated from mobile mesh beacon headers
          </p>
        </div>

        {/* Search */}
        <div className="relative min-w-[240px]">
          <Search
            size={14}
            className="absolute left-3 top-1/2 -translate-y-1/2 opacity-60 pointer-events-none"
          />
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search survivor or handset ID..."
            className={`w-full pl-9 pr-3 py-1.5 text-xs rounded-lg border outline-none ${
              isDark
                ? 'bg-[#0E1627] border-[#26344F] text-white focus:border-[#FFD21F]'
                : 'bg-[#F8FAFC] border-[#E2E8F0] text-black focus:border-[#FFC400]'
            }`}
          />
        </div>
      </div>

      {/* People Table */}
      <div className="overflow-x-auto">
        <table className="w-full text-left text-xs border-collapse">
          <thead>
            <tr
              className={`border-b font-mono font-bold uppercase opacity-75 ${
                isDark ? 'border-[#26344F] bg-[#0E1627]' : 'border-[#E2E8F0] bg-[#F1F5F9]/40'
              }`}
            >
              <th className="py-2.5 px-3">Name / Entity</th>
              <th className="py-2.5 px-3">Triage Status</th>
              <th className="py-2.5 px-3">Family Size</th>
              <th className="py-2.5 px-3">Handset ID</th>
              <th className="py-2.5 px-3">Location Details</th>
              <th className="py-2.5 px-3">Last Ping</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-inherit">
            {filtered.map((person) => (
              <tr
                key={person.id}
                className={isDark ? 'hover:bg-[#0E1627]/60' : 'hover:bg-[#F1F5F9]/30'}
              >
                <td className="py-3 px-3 font-semibold">
                  <div>{person.name}</div>
                  {person.medicalNotes && (
                    <div className="text-[11px] text-amber-500 flex items-center gap-1 mt-0.5">
                      <HeartPulse size={11} />
                      <span>{person.medicalNotes}</span>
                    </div>
                  )}
                </td>
                <td className="py-3 px-3">
                  <span
                    className={`inline-block px-2 py-0.5 rounded text-[11px] font-bold border ${getStatusBadge(
                      person.status
                    )}`}
                  >
                    {person.status}
                  </span>
                </td>
                <td className="py-3 px-3 font-mono font-semibold">
                  <div className="flex items-center gap-1">
                    <Users size={12} className="opacity-70" />
                    <span>{person.familyMembersCount} pers</span>
                  </div>
                </td>
                <td className="py-3 px-3 font-mono font-bold text-[#3CC6D0]">
                  <div className="flex items-center gap-1">
                    <Smartphone size={12} />
                    <span>{person.devicePseudonym}</span>
                  </div>
                </td>
                <td className="py-3 px-3 opacity-80">{person.location}</td>
                <td className="py-3 px-3 font-mono opacity-70">
                  <div className="flex items-center gap-1">
                    <Clock size={11} />
                    <span>{person.lastContact}</span>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};

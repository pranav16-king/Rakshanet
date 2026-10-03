import React from 'react';
import { MoreVertical, ShieldCheck, Eye, Phone, Radio } from 'lucide-react';
import type { Person, UserRole } from '../../types/people';
import { StatusBadge } from '../common/StatusBadge';

interface PeopleTableProps {
  people: Person[];
  onSelectPerson: (person: Person) => void;
  onOpenActionsMenu?: (person: Person) => void;
}

export const PeopleTable: React.FC<PeopleTableProps> = ({
  people,
  onSelectPerson,
}) => {
  const getRoleBadge = (role: UserRole) => {
    switch (role) {
      case 'Rescue Team':
        return (
          <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold bg-teal-50 text-teal-700 border border-teal-200 dark:bg-teal-950/50 dark:text-teal-300 dark:border-teal-800">
            Rescue Team
          </span>
        );
      case 'Volunteer':
        return (
          <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold bg-purple-50 text-purple-700 border border-purple-200 dark:bg-purple-950/50 dark:text-purple-300 dark:border-purple-800">
            Volunteer
          </span>
        );
      case 'Organizer':
        return (
          <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold bg-amber-50 text-amber-700 border border-amber-200 dark:bg-amber-950/50 dark:text-amber-300 dark:border-amber-800">
            Organizer
          </span>
        );
      case 'Field User':
      default:
        return (
          <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold bg-sky-50 text-sky-700 border border-sky-200 dark:bg-sky-950/50 dark:text-sky-300 dark:border-sky-800">
            Field User
          </span>
        );
    }
  };

  const getAvatarBg = (color: string) => {
    switch (color) {
      case 'blue':
        return 'bg-blue-100 text-blue-700 dark:bg-blue-950 dark:text-blue-300';
      case 'purple':
        return 'bg-purple-100 text-purple-700 dark:bg-purple-950 dark:text-purple-300';
      case 'teal':
        return 'bg-teal-100 text-teal-700 dark:bg-teal-950 dark:text-teal-300';
      case 'rose':
        return 'bg-rose-100 text-rose-700 dark:bg-rose-950 dark:text-rose-300';
      case 'emerald':
        return 'bg-emerald-100 text-emerald-700 dark:bg-emerald-950 dark:text-emerald-300';
      case 'amber':
        return 'bg-amber-100 text-amber-700 dark:bg-amber-950 dark:text-amber-300';
      default:
        return 'bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-300';
    }
  };

  return (
    <div className="overflow-x-auto rounded-xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 shadow-xs">
      <table className="w-full text-left text-sm text-slate-700 dark:text-slate-200">
        <thead className="bg-slate-50 dark:bg-slate-800/60 border-b border-slate-200 dark:border-slate-800 text-xs font-semibold text-slate-500 dark:text-slate-400 uppercase tracking-wider">
          <tr>
            <th scope="col" className="px-5 py-3.5">Name</th>
            <th scope="col" className="px-5 py-3.5">Role</th>
            <th scope="col" className="px-5 py-3.5">Location</th>
            <th scope="col" className="px-5 py-3.5">Last Active</th>
            <th scope="col" className="px-5 py-3.5">Status</th>
            <th scope="col" className="px-5 py-3.5 text-right">Actions</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-slate-100 dark:divide-slate-800/80 font-normal">
          {people.map((person) => (
            <tr
              key={person.id}
              onClick={() => onSelectPerson(person)}
              className="hover:bg-slate-50/80 dark:hover:bg-slate-800/40 transition-colors cursor-pointer group"
            >
              {/* Name & Avatar */}
              <td className="px-5 py-3.5 whitespace-nowrap">
                <div className="flex items-center gap-3">
                  <div
                    className={`w-9 h-9 rounded-full flex items-center justify-center font-bold text-xs shrink-0 ${getAvatarBg(
                      person.avatarColor
                    )}`}
                  >
                    {person.avatarInitial}
                  </div>
                  <div>
                    <div className="font-semibold text-slate-900 dark:text-slate-100 group-hover:text-[#8A5A00] dark:group-hover:text-[#FFC400] transition-colors">
                      {person.name}
                    </div>
                    {person.deviceId && (
                      <div className="font-mono text-[11px] text-slate-400 flex items-center gap-1">
                        <Radio className="w-3 h-3 text-slate-400" />
                        {person.deviceId}
                      </div>
                    )}
                  </div>
                </div>
              </td>

              {/* Role */}
              <td className="px-5 py-3.5 whitespace-nowrap">
                {getRoleBadge(person.role)}
              </td>

              {/* Location */}
              <td className="px-5 py-3.5 whitespace-nowrap text-slate-600 dark:text-slate-300">
                {person.location}
              </td>

              {/* Last Active */}
              <td className="px-5 py-3.5 whitespace-nowrap text-slate-500 dark:text-slate-400 text-xs">
                {person.lastActive}
              </td>

              {/* Status */}
              <td className="px-5 py-3.5 whitespace-nowrap">
                <StatusBadge
                  label={person.status}
                  type={person.status === 'Online' ? 'online' : 'offline'}
                  dot
                />
              </td>

              {/* Actions */}
              <td className="px-5 py-3.5 whitespace-nowrap text-right">
                <div className="flex items-center justify-end gap-1">
                  <button
                    type="button"
                    onClick={(e) => {
                      e.stopPropagation();
                      onSelectPerson(person);
                    }}
                    className="p-1.5 text-slate-400 hover:text-slate-700 dark:hover:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg transition-colors"
                    title="View user details & privacy logs"
                  >
                    <Eye className="w-4 h-4" />
                  </button>
                  <button
                    type="button"
                    onClick={(e) => {
                      e.stopPropagation();
                      onSelectPerson(person);
                    }}
                    className="p-1.5 text-slate-400 hover:text-slate-700 dark:hover:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg transition-colors"
                    title="Actions menu"
                  >
                    <MoreVertical className="w-4 h-4" />
                  </button>
                </div>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

export default PeopleTable;

// src/components/settings/UsersSettingsTab.tsx
import React, { useState, useEffect } from 'react';
import type { SystemSettings } from '../../types';
import { SettingsToggleRow } from './SettingsToggleRow';
import { settingsApi } from '../../api/settings';
import {
  Users,
  Key,
  Shield,
  Search,
  CheckCircle2,
  Clock,
  MapPin,
  RefreshCw,
  UserCheck,
} from 'lucide-react';

interface UsersSettingsTabProps {
  settings: SystemSettings;
  onChange: (updated: Partial<SystemSettings>) => void;
}

export const UsersSettingsTab: React.FC<UsersSettingsTabProps> = ({
  settings,
  onChange,
}) => {
  const access = settings.access_control || {
    requireMfaForCommanders: false,
    sessionTimeoutHours: 24,
    permitAnonymousSos: true,
  };

  const updateAccess = (updated: Partial<typeof access>) => {
    onChange({
      access_control: { ...access, ...updated },
    });
  };

  // Real backend users state
  const [users, setUsers] = useState<any[]>([]);
  const [loadingUsers, setLoadingUsers] = useState<boolean>(true);
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [selectedRole, setSelectedRole] = useState<string>('ALL');

  const fetchUsers = async () => {
    setLoadingUsers(true);
    try {
      const data = await settingsApi.getRegisteredUsers();
      setUsers(data);
    } finally {
      setLoadingUsers(false);
    }
  };

  useEffect(() => {
    fetchUsers();
  }, []);

  const roles = ['ALL', 'Administrator', 'Field Commander', 'Rescue Specialist', 'Medical Officer', 'Community Volunteer'];

  const filteredUsers = users.filter((u) => {
    const matchesSearch =
      !searchQuery ||
      u.name?.toLowerCase().includes(searchQuery.toLowerCase()) ||
      u.email?.toLowerCase().includes(searchQuery.toLowerCase()) ||
      u.agency?.toLowerCase().includes(searchQuery.toLowerCase()) ||
      u.location?.toLowerCase().includes(searchQuery.toLowerCase());

    const matchesRole = selectedRole === 'ALL' || u.role === selectedRole;
    return matchesSearch && matchesRole;
  });

  const getRoleBadge = (role: string) => {
    switch (role) {
      case 'Administrator':
        return 'bg-amber-500/10 text-amber-600 dark:text-amber-400 border-amber-500/30';
      case 'Field Commander':
        return 'bg-red-500/10 text-red-600 dark:text-red-400 border-red-500/30';
      case 'Rescue Specialist':
        return 'bg-cyan-500/10 text-cyan-600 dark:text-cyan-400 border-cyan-500/30';
      case 'Medical Officer':
        return 'bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border-emerald-500/30';
      default:
        return 'bg-slate-500/10 text-slate-600 dark:text-slate-400 border-slate-500/30';
    }
  };

  return (
    <div className="space-y-6">
      {/* 1. Identity & Access Policies */}
      <div className="p-5 sm:p-6 rounded-2xl border border-slate-200 dark:border-[#26344F] bg-white dark:bg-[#162036] shadow-sm space-y-4">
        <div className="flex items-center gap-2.5 pb-3 border-b border-slate-100 dark:border-slate-800">
          <div className="p-2 rounded-xl bg-amber-400/15 text-amber-600 dark:text-amber-400">
            <Key className="w-5 h-5" />
          </div>
          <div>
            <h3 className="text-sm sm:text-base font-bold text-slate-900 dark:text-white uppercase tracking-wider">
              Identity &amp; Access Controls
            </h3>
            <p className="text-xs text-slate-500 dark:text-[#9FADC2]">
              Manage dispatcher authentication, authorization roles, and mesh node pseudonym policies.
            </p>
          </div>
        </div>

        <div className="space-y-1">
          <SettingsToggleRow
            label="Require Multi-Factor Authentication (MFA)"
            description="Mandatory for Field Commanders and Command Center Administrators during crisis activation."
            checked={Boolean(access.requireMfaForCommanders)}
            onChange={(checked) => updateAccess({ requireMfaForCommanders: checked })}
            icon={<Key className="w-4 h-4 text-amber-500" />}
            badge="Security"
          />

          <SettingsToggleRow
            label="Permit Anonymous Survivor SOS Pings"
            description="Allow citizen handsets to broadcast distress packets without prior account registration."
            checked={Boolean(access.permitAnonymousSos ?? settings.allowNewUserRegistration)}
            onChange={(checked) => {
              updateAccess({ permitAnonymousSos: checked });
              onChange({ allowNewUserRegistration: checked });
            }}
            icon={<Shield className="w-4 h-4 text-emerald-500" />}
            badge="Survivor Ingress"
          />
        </div>

        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pt-3 border-t border-slate-100 dark:border-slate-800 p-3.5 rounded-xl bg-slate-50 dark:bg-[#0E1627] border border-slate-200/80 dark:border-slate-800">
          <div>
            <div className="text-xs sm:text-sm font-bold text-slate-900 dark:text-slate-100">
              Command Center Session Expiry
            </div>
            <div className="text-[11px] text-slate-500 dark:text-slate-400">
              Duration in hours before an idle dispatcher session must re-authenticate.
            </div>
          </div>
          <div className="flex items-center gap-1.5">
            {[8, 12, 24, 48].map((hours) => (
              <button
                key={hours}
                type="button"
                onClick={() => updateAccess({ sessionTimeoutHours: hours })}
                className={`px-3 py-1.5 rounded-lg text-xs font-mono font-bold transition cursor-pointer ${
                  (access.sessionTimeoutHours ?? 24) === hours
                    ? 'bg-[#FFC400] dark:bg-[#FFD21F] text-[#1A1400]'
                    : 'bg-white dark:bg-[#162036] border border-slate-200 dark:border-slate-700 text-slate-600 dark:text-slate-300 hover:border-amber-400'
                }`}
              >
                {hours}h
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* 2. Real Authorized Personnel & Field Units (REAL DATA from /api/v1/users) */}
      <div className="p-5 sm:p-6 rounded-2xl border border-slate-200 dark:border-[#26344F] bg-white dark:bg-[#162036] shadow-sm space-y-4">
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 pb-3 border-b border-slate-100 dark:border-slate-800">
          <div className="flex items-center gap-2.5">
            <div className="p-2 rounded-xl bg-cyan-400/15 text-cyan-600 dark:text-cyan-400">
              <Users className="w-5 h-5" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h3 className="text-sm sm:text-base font-bold text-slate-900 dark:text-white uppercase tracking-wider">
                  Authorized Personnel &amp; Field Units
                </h3>
                <span className="px-2 py-0.5 rounded-full text-[10px] font-mono font-bold bg-cyan-500/10 text-cyan-600 dark:text-cyan-400 border border-cyan-500/20">
                  {users.length} Verified in DB
                </span>
              </div>
              <p className="text-xs text-slate-500 dark:text-[#9FADC2]">
                Real-time synchronized dispatcher and responder registry from FastAPI SQLite backend.
              </p>
            </div>
          </div>

          <button
            type="button"
            onClick={fetchUsers}
            disabled={loadingUsers}
            className="self-start sm:self-auto flex items-center gap-1.5 px-3 py-1.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-xs font-semibold text-slate-700 dark:text-slate-200 hover:border-amber-400 transition cursor-pointer"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${loadingUsers ? 'animate-spin' : ''}`} />
            Refresh Personnel
          </button>
        </div>

        {/* Search & Role Filters */}
        <div className="flex flex-col sm:flex-row gap-3 pt-1">
          <div className="relative flex-1">
            <Search className="w-4 h-4 absolute left-3 top-3 text-slate-400" />
            <input
              type="text"
              placeholder="Search by name, agency, sector, or email..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-9 pr-3 py-2 rounded-xl bg-slate-50 dark:bg-[#0E1627] border border-slate-200 dark:border-slate-700 text-xs sm:text-sm text-slate-900 dark:text-white focus:outline-none focus:border-amber-400"
            />
          </div>

          <div className="flex items-center gap-1.5 overflow-x-auto pb-1 sm:pb-0">
            {roles.map((r) => (
              <button
                key={r}
                type="button"
                onClick={() => setSelectedRole(r)}
                className={`px-2.5 py-1.5 rounded-xl text-[11px] font-bold whitespace-nowrap transition cursor-pointer ${
                  selectedRole === r
                    ? 'bg-[#FFC400] dark:bg-[#FFD21F] text-[#1A1400]'
                    : 'bg-slate-50 dark:bg-[#0E1627] border border-slate-200 dark:border-slate-700 text-slate-600 dark:text-slate-300 hover:border-slate-400'
                }`}
              >
                {r}
              </button>
            ))}
          </div>
        </div>

        {/* Real Users Table */}
        <div className="overflow-x-auto rounded-xl border border-slate-200 dark:border-slate-800">
          <table className="w-full text-left text-xs">
            <thead className="bg-slate-50 dark:bg-[#0E1627] border-b border-slate-200 dark:border-slate-800 text-slate-500 dark:text-slate-400 uppercase tracking-wider text-[11px]">
              <tr>
                <th className="py-2.5 px-3 font-bold">Operator Name</th>
                <th className="py-2.5 px-3 font-bold">Role</th>
                <th className="py-2.5 px-3 font-bold">Agency</th>
                <th className="py-2.5 px-3 font-bold">Assigned Sector</th>
                <th className="py-2.5 px-3 font-bold">Contact</th>
                <th className="py-2.5 px-3 font-bold">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 dark:divide-slate-800/80 bg-white dark:bg-[#162036]">
              {loadingUsers ? (
                <tr>
                  <td colSpan={6} className="py-8 text-center text-slate-400">
                    <RefreshCw className="w-5 h-5 animate-spin mx-auto mb-2 text-amber-500" />
                    Querying live SQLite personnel registry...
                  </td>
                </tr>
              ) : filteredUsers.length === 0 ? (
                <tr>
                  <td colSpan={6} className="py-8 text-center text-slate-400">
                    No authorized personnel matching search criteria.
                  </td>
                </tr>
              ) : (
                filteredUsers.map((user) => (
                  <tr key={user.id} className="hover:bg-slate-50/60 dark:hover:bg-[#111A2C]/60 transition">
                    <td className="py-3 px-3">
                      <div className="flex items-center gap-2.5">
                        <div className="w-7 h-7 rounded-full bg-amber-400/20 text-amber-600 dark:text-amber-400 font-bold flex items-center justify-center text-xs">
                          {user.name?.charAt(0) || 'U'}
                        </div>
                        <div>
                          <div className="font-bold text-slate-900 dark:text-white">
                            {user.name}
                          </div>
                          <div className="text-[10px] font-mono text-slate-400">
                            ID: {user.id}
                          </div>
                        </div>
                      </div>
                    </td>

                    <td className="py-3 px-3">
                      <span className={`inline-block px-2 py-0.5 rounded-md border text-[10px] font-bold ${getRoleBadge(user.role)}`}>
                        {user.role}
                      </span>
                    </td>

                    <td className="py-3 px-3 text-slate-700 dark:text-slate-300 font-medium">
                      {user.agency || 'Disaster Response Command'}
                    </td>

                    <td className="py-3 px-3 text-slate-600 dark:text-slate-400">
                      <span className="flex items-center gap-1">
                        <MapPin className="w-3 h-3 text-cyan-500 flex-shrink-0" />
                        {user.location || 'Base Station'}
                      </span>
                    </td>

                    <td className="py-3 px-3 text-slate-500 dark:text-slate-400 text-[11px] font-mono">
                      <div>{user.phone || 'N/A'}</div>
                      <div className="text-[10px] text-slate-400 truncate max-w-[160px]">{user.email}</div>
                    </td>

                    <td className="py-3 px-3">
                      <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-md text-[10px] font-bold bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20">
                        <span className="w-1.5 h-1.5 rounded-full bg-emerald-500" />
                        {user.status || 'Active'}
                      </span>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

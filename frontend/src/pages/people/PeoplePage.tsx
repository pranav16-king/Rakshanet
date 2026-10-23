import React, { useState, useEffect, useCallback } from 'react';
import {
  UserPlus,
  Search,
  MoreVertical,
  RefreshCw,
} from 'lucide-react';
import { Card } from '../../components/common/Card';
import { Button } from '../../components/common/Button';
import { AddUserModal } from '../../components/people/AddUserModal';
import { UserDetailsModal } from '../../components/people/UserDetailsModal';
import { peopleApi } from '../../api/people';
import type { Person, PeopleFilterTab, NewUserPayload } from '../../types/people';

export const PeoplePage: React.FC = () => {
  const [activeTab, setActiveTab] = useState<string>('All Users');
  const [search, setSearch] = useState<string>('');
  const [people, setPeople] = useState<Person[]>([]);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [selectedPerson, setSelectedPerson] = useState<Person | null>(null);
  const [isAddModalOpen, setIsAddModalOpen] = useState<boolean>(false);

  const tabs = ['All Users', 'Field Users', 'Rescue Teams', 'Volunteers', 'Organizers'];

  const getFilterTabKey = (tab: string): PeopleFilterTab => {
    switch (tab) {
      case 'Field Users':
        return 'field_users';
      case 'Rescue Teams':
        return 'rescue_teams';
      case 'Volunteers':
        return 'volunteers';
      case 'Organizers':
        return 'organizers';
      case 'All Users':
      default:
        return 'all';
    }
  };

  const fetchPeople = useCallback(async () => {
    setIsLoading(true);
    try {
      const data = await peopleApi.getPeople(getFilterTabKey(activeTab), search);
      setPeople(data);
    } catch {
      // Handled in api
    } finally {
      setIsLoading(false);
    }
  }, [activeTab, search]);

  useEffect(() => {
    fetchPeople();
  }, [fetchPeople]);

  const handleAddUser = async (payload: NewUserPayload) => {
    await peopleApi.addPerson(payload);
    await fetchPeople();
  };

  const handleToggleAuthorization = (personId: string, authorize: boolean) => {
    const updated = peopleApi.toggleAuthorization(personId, authorize);
    if (updated) {
      setPeople((prev) => prev.map((p) => (p.id === personId ? { ...p, isAuthorized: authorize } : p)));
      if (selectedPerson && selectedPerson.id === personId) {
        setSelectedPerson({ ...selectedPerson, isAuthorized: authorize });
      }
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1
            className="text-2xl sm:text-3xl font-black text-[#0F172A] dark:text-white tracking-tight"
            style={{ fontFamily: '"Barlow Semi Condensed", sans-serif' }}
          >
            People & Users
          </h1>
          <p className="text-xs sm:text-sm text-[#64748B] dark:text-[#9FADC2]">
            Registered survivors, coordinators, and active field emergency personnel
          </p>
        </div>

        <div className="flex items-center gap-2">
          <Button
            variant="secondary"
            size="md"
            leftIcon={<RefreshCw size={15} className={isLoading ? 'animate-spin' : ''} />}
            onClick={() => fetchPeople()}
          >
            Refresh
          </Button>
          <Button
            variant="primary"
            size="md"
            leftIcon={<UserPlus size={16} />}
            onClick={() => setIsAddModalOpen(true)}
          >
            Add User
          </Button>
        </div>
      </div>

      {/* Tabs and Search */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div className="flex items-center gap-2 overflow-x-auto pb-1">
          {tabs.map((tab) => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`px-3.5 py-1.5 rounded-xl text-xs font-bold transition-all whitespace-nowrap cursor-pointer ${
                activeTab === tab
                  ? 'bg-[#FFC400] dark:bg-[#FFD21F] text-[#1A1400]'
                  : 'bg-white dark:bg-[#162036] border border-slate-200 dark:border-[#26344F] text-slate-600 dark:text-[#9FADC2] hover:bg-slate-50 dark:hover:bg-[#1C2844]'
              }`}
            >
              {tab}
            </button>
          ))}
        </div>

        <div className="relative w-full sm:w-64">
          <Search
            size={15}
            className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 dark:text-[#9FADC2]"
          />
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search users..."
            className="w-full h-9 pl-9 pr-3 rounded-xl bg-white dark:bg-[#162036] border border-slate-200 dark:border-[#26344F] text-xs text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-[#FFC400]"
          />
        </div>
      </div>

      {/* Table */}
      <Card className="p-0 overflow-hidden border border-slate-200 dark:border-[#26344F]">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-slate-50 dark:bg-[#0E1627] text-slate-500 dark:text-[#9FADC2] uppercase tracking-wider font-semibold border-b border-slate-200 dark:border-[#26344F]">
              <tr>
                <th className="py-3.5 px-4">Name</th>
                <th className="py-3.5 px-4">Role</th>
                <th className="py-3.5 px-4">Location</th>
                <th className="py-3.5 px-4">Last Active</th>
                <th className="py-3.5 px-4">Status</th>
                <th className="py-3.5 px-4 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200/80 dark:divide-[#26344F]/50">
              {isLoading && people.length === 0 ? (
                <tr>
                  <td colSpan={6} className="py-8 text-center text-slate-400">
                    <RefreshCw className="w-5 h-5 mx-auto mb-2 animate-spin text-[#FFC400]" />
                    Loading emergency personnel directory...
                  </td>
                </tr>
              ) : people.length === 0 ? (
                <tr>
                  <td colSpan={6} className="py-8 text-center text-slate-400">
                    No personnel found matching current filter or search criteria.
                  </td>
                </tr>
              ) : (
                people.map((u) => (
                  <tr
                    key={u.id}
                    onClick={() => setSelectedPerson(u)}
                    className="hover:bg-slate-50 dark:hover:bg-[#0E1627]/40 transition-colors cursor-pointer group"
                  >
                    <td className="py-3.5 px-4 font-bold text-slate-900 dark:text-white flex items-center gap-2.5">
                      <div
                        className={`w-7 h-7 rounded-full flex items-center justify-center text-[11px] font-bold shrink-0 ${
                          u.avatarColor === 'purple'
                            ? 'bg-purple-100 text-purple-700 dark:bg-purple-950 dark:text-purple-300'
                            : u.avatarColor === 'teal'
                            ? 'bg-teal-100 text-teal-700 dark:bg-teal-950 dark:text-teal-300'
                            : u.avatarColor === 'emerald'
                            ? 'bg-emerald-100 text-emerald-700 dark:bg-emerald-950 dark:text-emerald-300'
                            : u.avatarColor === 'rose'
                            ? 'bg-rose-100 text-rose-700 dark:bg-rose-950 dark:text-rose-300'
                            : u.avatarColor === 'amber'
                            ? 'bg-amber-100 text-amber-700 dark:bg-amber-950 dark:text-amber-300'
                            : 'bg-blue-100 text-blue-700 dark:bg-blue-950 dark:text-blue-300'
                        }`}
                      >
                        {u.avatarInitial || u.name.charAt(0)}
                      </div>
                      <div>
                        <div className="font-bold text-slate-900 dark:text-white group-hover:text-[#FFC400] transition-colors">
                          {u.name}
                        </div>
                        {u.deviceId && (
                          <div className="font-mono text-[10px] text-slate-400">{u.deviceId}</div>
                        )}
                      </div>
                    </td>
                    <td className="py-3.5 px-4 text-slate-600 dark:text-[#9FADC2]">
                      <span className="px-2 py-0.5 rounded-md bg-gray-100 dark:bg-[#111A2C] border border-gray-200 dark:border-gray-800 font-medium">
                        {u.role}
                      </span>
                    </td>
                    <td className="py-3.5 px-4 font-medium text-slate-700 dark:text-[#CBD5E1]">
                      {u.location}
                    </td>
                    <td className="py-3.5 px-4 text-slate-500 dark:text-[#9FADC2]">
                      {u.lastActive}
                    </td>
                    <td className="py-3.5 px-4">
                      <span
                        className={`inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full font-bold ${
                          u.status === 'Online'
                            ? 'bg-emerald-50 dark:bg-emerald-950/40 text-emerald-600 dark:text-emerald-400 border border-emerald-500/30'
                            : 'bg-gray-100 dark:bg-gray-800 text-gray-500 border border-gray-400/30'
                        }`}
                      >
                        <span
                          className={`w-1.5 h-1.5 rounded-full ${
                            u.status === 'Online' ? 'bg-emerald-500 animate-pulse' : 'bg-gray-400'
                          }`}
                        />
                        {u.status}
                      </span>
                    </td>
                    <td className="py-3.5 px-4 text-right">
                      <button
                        onClick={(e) => {
                          e.stopPropagation();
                          setSelectedPerson(u);
                        }}
                        className="p-1 rounded text-slate-400 hover:text-slate-800 dark:hover:text-white cursor-pointer"
                        title="View details & medical record"
                      >
                        <MoreVertical size={16} />
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </Card>

      {/* Add User Modal */}
      <AddUserModal
        isOpen={isAddModalOpen}
        onClose={() => setIsAddModalOpen(false)}
        onAddUser={handleAddUser}
      />

      {/* User Details & Medical Triage Modal */}
      <UserDetailsModal
        isOpen={Boolean(selectedPerson)}
        person={selectedPerson}
        onClose={() => setSelectedPerson(null)}
        onToggleAuthorization={handleToggleAuthorization}
      />
    </div>
  );
};

export default PeoplePage;

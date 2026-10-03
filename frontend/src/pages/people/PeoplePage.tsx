import React, { useState } from 'react';
import {
  Users,
  UserPlus,
  Search,
  MoreVertical,
  CheckCircle,
  XCircle,
} from 'lucide-react';
import { Card } from '../../components/common/Card';
import { Button } from '../../components/common/Button';

export const PeoplePage: React.FC = () => {
  const [activeTab, setActiveTab] = useState('All Users');
  const [search, setSearch] = useState('');

  const users = [
    {
      name: 'Amit Kumar',
      role: 'Field User',
      location: 'Uttarakhand',
      lastActive: '2 min ago',
      status: 'Online',
    },
    {
      name: 'Priya Sharma',
      role: 'Field User',
      location: 'Uttarakhand',
      lastActive: '5 min ago',
      status: 'Online',
    },
    {
      name: 'Rahul Mehta',
      role: 'Volunteer',
      location: 'Himachal Pradesh',
      lastActive: '10 min ago',
      status: 'Online',
    },
    {
      name: 'Sneha Patel',
      role: 'Field User',
      location: 'Delhi',
      lastActive: '15 min ago',
      status: 'Offline',
    },
    {
      name: 'Vikram Singh',
      role: 'Rescue Team',
      location: 'Uttarakhand',
      lastActive: '18 min ago',
      status: 'Online',
    },
    {
      name: 'Ananya Gupta',
      role: 'Organizer',
      location: 'Delhi',
      lastActive: '25 min ago',
      status: 'Online',
    },
  ];

  const tabs = ['All Users', 'Field Users', 'Rescue Teams', 'Volunteers', 'Organizers'];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1
            className="text-2xl sm:text-3xl font-black text-[#16202D] dark:text-white tracking-tight"
            style={{ fontFamily: '"Barlow Semi Condensed", sans-serif' }}
          >
            People & Users
          </h1>
          <p className="text-xs sm:text-sm text-[#566070] dark:text-[#9FADC2]">
            Registered survivors, coordinators, and active field emergency personnel
          </p>
        </div>

        <Button
          variant="primary"
          size="md"
          leftIcon={<UserPlus size={16} />}
          onClick={() => alert('Add Responder modal opened.')}
        >
          Add User
        </Button>
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
                  : 'bg-white dark:bg-[#162036] border border-[#E6DCA8] dark:border-[#26344F] text-[#566070] dark:text-[#9FADC2]'
              }`}
            >
              {tab}
            </button>
          ))}
        </div>

        <div className="relative w-full sm:w-64">
          <Search
            size={15}
            className="absolute left-3 top-1/2 -translate-y-1/2 text-[#566070] dark:text-[#9FADC2]"
          />
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search users..."
            className="w-full h-9 pl-9 pr-3 rounded-xl bg-white dark:bg-[#162036] border border-[#E6DCA8] dark:border-[#26344F] text-xs text-[#16202D] dark:text-white focus:outline-none focus:ring-2 focus:ring-[#FFC400]"
          />
        </div>
      </div>

      {/* Table */}
      <Card className="p-0 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-[#FFFCEB] dark:bg-[#0E1627] text-[#566070] dark:text-[#9FADC2] uppercase tracking-wider font-semibold border-b border-[#E6DCA8] dark:border-[#26344F]">
              <tr>
                <th className="py-3.5 px-4">Name</th>
                <th className="py-3.5 px-4">Role</th>
                <th className="py-3.5 px-4">Location</th>
                <th className="py-3.5 px-4">Last Active</th>
                <th className="py-3.5 px-4">Status</th>
                <th className="py-3.5 px-4 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#E6DCA8]/50 dark:divide-[#26344F]/50">
              {users.map((u, i) => (
                <tr
                  key={i}
                  className="hover:bg-[#FFFCEB]/40 dark:hover:bg-[#0E1627]/40 transition-colors"
                >
                  <td className="py-3.5 px-4 font-bold text-[#16202D] dark:text-white">
                    {u.name}
                  </td>
                  <td className="py-3.5 px-4 text-[#566070] dark:text-[#9FADC2]">
                    <span className="px-2 py-0.5 rounded-md bg-gray-100 dark:bg-[#111A2C] border border-gray-200 dark:border-gray-800 font-medium">
                      {u.role}
                    </span>
                  </td>
                  <td className="py-3.5 px-4 text-[#566070] dark:text-[#9FADC2]">{u.location}</td>
                  <td className="py-3.5 px-4 text-[#566070] dark:text-[#9FADC2]">{u.lastActive}</td>
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
                    <button className="p-1 rounded text-[#566070] hover:text-[#16202D] dark:hover:text-white cursor-pointer">
                      <MoreVertical size={16} />
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Card>
    </div>
  );
};

export default PeoplePage;

import React, { useState } from 'react';
import {
  MessageSquare,
  Search,
  Filter,
  Radio,
  Send,
  AlertOctagon,
  Clock,
  MapPin,
  Share2,
} from 'lucide-react';
import { Card } from '../../components/common/Card';
import { Badge } from '../../components/common/Badge';

export const MessagesPage: React.FC = () => {
  const [activeCategory, setActiveCategory] = useState('All Messages');
  const [searchTerm, setSearchTerm] = useState('');

  const messages = [
    {
      id: 'MSG-001',
      sender: 'Amit Kumar',
      role: 'Survivor',
      location: 'Uttarakhand',
      time: '2 min ago',
      text: 'Flood in river area, water level rising fast. 5 people trapped.',
      type: 'SOS',
      hops: 2,
    },
    {
      id: 'MSG-002',
      sender: 'Priya Sharma',
      role: 'Survivor',
      location: 'Delhi',
      time: '5 min ago',
      text: 'We are safe at school building. Need rescue supplies.',
      type: 'SOS',
      hops: 1,
    },
    {
      id: 'MSG-003',
      sender: 'Rahul Mehta',
      role: 'Field Responder',
      location: 'Himachal Pradesh',
      time: '10 min ago',
      text: 'Road blocked due to landslide. Alternative route needed on NH-7.',
      type: 'Report',
      hops: 3,
    },
    {
      id: 'MSG-004',
      sender: 'Sneha Patel',
      role: 'Medical Staff',
      location: 'Delhi',
      time: '15 min ago',
      text: 'Medical help required. One person injured with fractured arm.',
      type: 'Medical',
      hops: 2,
    },
    {
      id: 'MSG-005',
      sender: 'Volunteer Team',
      role: 'SDRF Crew',
      location: 'Uttarakhand',
      time: '18 min ago',
      text: 'Reaching the location in 30 minutes with high-clearance 4WD.',
      type: 'Team',
      hops: 1,
    },
    {
      id: 'MSG-006',
      sender: 'Organizer',
      role: 'Command Node',
      location: 'Uttarakhand',
      time: '25 min ago',
      text: 'Set up temporary shelter at community center. 80 capacity ready.',
      type: 'System',
      hops: 0,
    },
  ];

  const categories = [
    'All Messages',
    'SOS Alerts',
    'Incident Reports',
    'Team Messages',
    'System Logs',
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
            Messages & Communications
          </h1>
          <p className="text-xs sm:text-sm text-[#566070] dark:text-[#9FADC2]">
            Real-time messages and opportunistic DTN packets from field users
          </p>
        </div>

        <div className="flex items-center gap-2">
          <div className="relative">
            <Search
              size={15}
              className="absolute left-3 top-1/2 -translate-y-1/2 text-[#566070] dark:text-[#9FADC2]"
            />
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder="Search messages..."
              className="h-9 pl-9 pr-3 rounded-xl bg-white dark:bg-[#162036] border border-[#E6DCA8] dark:border-[#26344F] text-xs text-[#16202D] dark:text-white focus:outline-none focus:ring-2 focus:ring-[#FFC400]"
            />
          </div>
        </div>
      </div>

      {/* Category Pills */}
      <div className="flex items-center gap-2 overflow-x-auto pb-1">
        {categories.map((cat) => (
          <button
            key={cat}
            onClick={() => setActiveCategory(cat)}
            className={`px-4 py-2 rounded-xl text-xs font-bold transition-all whitespace-nowrap cursor-pointer ${
              activeCategory === cat
                ? 'bg-[#FFC400] dark:bg-[#FFD21F] text-[#1A1400] shadow-sm'
                : 'bg-white dark:bg-[#162036] border border-[#E6DCA8] dark:border-[#26344F] text-[#566070] dark:text-[#9FADC2] hover:text-[#16202D] dark:hover:text-white'
            }`}
          >
            {cat}
          </button>
        ))}
      </div>

      {/* Message Feed Card */}
      <Card className="p-0 overflow-hidden">
        <div className="divide-y divide-[#E6DCA8]/50 dark:divide-[#26344F]/50">
          {messages.map((msg) => (
            <div
              key={msg.id}
              className="p-4 hover:bg-[#FFFCEB]/40 dark:hover:bg-[#0E1627]/40 transition-colors flex items-start justify-between gap-4"
            >
              <div className="flex items-start gap-3.5">
                {/* Avatar */}
                <div className="w-10 h-10 rounded-full bg-[#162036] text-[#FFD21F] border border-[#26344F] flex items-center justify-center font-bold text-sm flex-shrink-0">
                  {msg.sender.charAt(0)}
                </div>

                <div>
                  <div className="flex items-center gap-2 mb-1">
                    <span className="text-sm font-bold text-[#16202D] dark:text-white">
                      {msg.sender}
                    </span>
                    <span className="text-[11px] text-[#566070] dark:text-[#9FADC2]">
                      ({msg.role})
                    </span>
                  </div>

                  <p className="text-xs text-[#16202D] dark:text-[#EEF2F8] leading-relaxed mb-2 font-medium">
                    {msg.text}
                  </p>

                  <div className="flex items-center gap-3 text-[11px] text-[#566070] dark:text-[#9FADC2]">
                    <span className="flex items-center gap-1">
                      <MapPin size={12} className="text-[#0E8A94]" /> {msg.location}
                    </span>
                    <span>•</span>
                    <span className="flex items-center gap-1">
                      <Clock size={12} /> {msg.time}
                    </span>
                    <span>•</span>
                    <span className="flex items-center gap-1 font-mono">
                      <Share2 size={12} /> {msg.hops} mesh hops
                    </span>
                  </div>
                </div>
              </div>

              {/* Tag / Badge */}
              <div className="flex-shrink-0">
                <span
                  className={`text-[10px] font-bold px-2 py-0.5 rounded-full uppercase tracking-wider ${
                    msg.type === 'SOS'
                      ? 'bg-[#D92D20]/15 text-[#D92D20] dark:text-[#FF5A4E] border border-[#D92D20]/30'
                      : msg.type === 'Report'
                      ? 'bg-[#0E8A94]/15 text-[#0E8A94] dark:text-[#3CC6D0] border border-[#0E8A94]/30'
                      : msg.type === 'Medical'
                      ? 'bg-rose-500/15 text-rose-600 dark:text-rose-400 border border-rose-500/30'
                      : 'bg-amber-500/15 text-amber-600 dark:text-amber-400 border border-amber-500/30'
                  }`}
                >
                  {msg.type}
                </span>
              </div>
            </div>
          ))}
        </div>
      </Card>
    </div>
  );
};

export default MessagesPage;

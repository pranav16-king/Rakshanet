import React, { useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import {
  ArrowLeft,
  Share2,
  Users,
  Clock,
  MapPin,
  LifeBuoy,
  HeartPulse,
  Package,
  Home,
  CheckCircle,
} from 'lucide-react';
import { Card } from '../../components/common/Card';
import { Badge } from '../../components/common/Badge';
import { Button } from '../../components/common/Button';

export const IncidentDetailPage: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [activeTab, setActiveTab] = useState('Overview');
  const [isAssigned, setIsAssigned] = useState(false);

  const incidentId = id || 'INC-2026-001';

  return (
    <div className="space-y-6">
      {/* Top Breadcrumb & Actions */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div className="flex items-center gap-3">
          <button
            onClick={() => navigate('/app/incidents')}
            className="p-2 rounded-xl bg-white dark:bg-[#162036] border border-[#E6DCA8] dark:border-[#26344F] text-[#566070] dark:text-[#9FADC2] hover:text-[#16202D] dark:hover:text-white transition-colors cursor-pointer"
          >
            <ArrowLeft size={18} />
          </button>
          <div>
            <div className="flex items-center gap-2 text-xs font-mono text-[#8A5A00] dark:text-[#FFD21F]">
              <span>Incidents</span>
              <span>/</span>
              <span>{incidentId}</span>
            </div>
            <div className="flex items-center gap-3 mt-1">
              <h1
                className="text-2xl sm:text-3xl font-black text-[#16202D] dark:text-white tracking-tight"
                style={{ fontFamily: '"Barlow Semi Condensed", sans-serif' }}
              >
                Flood in River Area
              </h1>
              <Badge severity="CRITICAL" label="Critical" />
            </div>
          </div>
        </div>

        {/* Action Buttons */}
        <div className="flex items-center gap-3">
          <Button
            variant={isAssigned ? 'secondary' : 'primary'}
            size="md"
            leftIcon={isAssigned ? <CheckCircle size={16} /> : undefined}
            onClick={() => setIsAssigned(!isAssigned)}
          >
            {isAssigned ? 'Assigned to NDRF-01' : 'Assign Team'}
          </Button>
          <Button
            variant="secondary"
            size="md"
            leftIcon={<Share2 size={16} />}
            onClick={() => alert('CAP v1.2 alert feed link copied to clipboard.')}
          >
            Share
          </Button>
        </div>
      </div>

      {/* Meta sub-ribbon */}
      <div className="flex flex-wrap items-center gap-4 text-xs text-[#566070] dark:text-[#9FADC2] px-4 py-2.5 rounded-xl bg-white dark:bg-[#162036] border border-[#E6DCA8] dark:border-[#26344F]">
        <span className="flex items-center gap-1.5 font-medium">
          <MapPin size={14} className="text-[#0E8A94]" /> Uttarakhand, India
        </span>
        <span>•</span>
        <span className="flex items-center gap-1.5 font-medium">
          <Clock size={14} /> 12 min ago
        </span>
        <span>•</span>
        <span className="flex items-center gap-1.5 font-bold text-[#D92D20] dark:text-[#FF5A4E]">
          <Users size={14} /> 142 affected users
        </span>
      </div>

      {/* Navigation Tabs */}
      <div className="flex items-center gap-2 border-b border-[#E6DCA8] dark:border-[#26344F] pb-1 overflow-x-auto">
        {['Overview', 'People (142)', 'Messages (320)', 'Devices (28)', 'Resources', 'Timeline'].map(
          (tab) => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`px-4 py-2 text-xs font-bold rounded-xl transition-all cursor-pointer whitespace-nowrap ${
                activeTab === tab
                  ? 'bg-[#FFC400] dark:bg-[#FFD21F] text-[#1A1400] shadow-sm'
                  : 'text-[#566070] dark:text-[#9FADC2] hover:text-[#16202D] dark:hover:text-white'
              }`}
            >
              {tab}
            </button>
          )
        )}
      </div>

      {/* Tab Content: Grid Layout matching media_1791015140209.jpg */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        {/* Left Column: Map Boundary & Narrative */}
        <div className="lg:col-span-7 space-y-6">
          {/* Incident Area Map Canvas */}
          <div className="relative h-72 rounded-2xl bg-[#0E1627] border border-[#E6DCA8] dark:border-[#26344F] overflow-hidden flex items-center justify-center">
            {/* Synthetic Aerial Texture */}
            <div
              className="absolute inset-0 opacity-40"
              style={{
                backgroundImage:
                  'radial-gradient(ellipse at center, #162036 0%, #0B1220 100%)',
              }}
            />

            {/* Polygon perimeter visualization */}
            <div className="relative z-10 w-44 h-44 rounded-full border-2 border-dashed border-[#D92D20] bg-[#D92D20]/20 flex items-center justify-center animate-pulse">
              <span className="text-xs font-bold text-white bg-[#0B1220]/80 px-2 py-1 rounded">
                DBSCAN Zone (r ≈ 180m)
              </span>
            </div>

            <div className="absolute bottom-3 left-3 text-[11px] text-[#9FADC2] bg-[#0B1220]/90 px-3 py-1 rounded-lg">
              Centroid: 30.1245° N, 79.2311° E
            </div>
          </div>

          {/* Description Card */}
          <Card>
            <h3 className="text-sm font-bold text-[#16202D] dark:text-white mb-2">
              Description
            </h3>
            <p className="text-xs text-[#566070] dark:text-[#9FADC2] leading-relaxed">
              Heavy flooding reported in the river area. Multiple users have reported houses submerged and people stranded on rooftops. Communication networks are down. Distress packets relaying through volunteer handsets with 3 hops to nearest satellite node.
            </p>
            <div className="mt-4 pt-3 border-t border-[#E6DCA8]/50 dark:border-[#26344F]/50 flex justify-end">
              <span className="text-xs font-bold text-[#8A5A00] dark:text-[#FFD21F] cursor-pointer hover:underline">
                View all raw distress reports →
              </span>
            </div>
          </Card>
        </div>

        {/* Right Column: Key Information & Resources Needed */}
        <div className="lg:col-span-5 space-y-6">
          {/* Key Information Card */}
          <Card>
            <h3 className="text-sm font-bold text-[#16202D] dark:text-white mb-4 pb-2 border-b border-[#E6DCA8] dark:border-[#26344F]">
              Key Information
            </h3>

            <div className="space-y-3 text-xs">
              <div className="flex items-center justify-between">
                <span className="text-[#566070] dark:text-[#9FADC2]">Incident Type</span>
                <span className="font-bold text-[#16202D] dark:text-white">Flood</span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-[#566070] dark:text-[#9FADC2]">Severity</span>
                <span className="font-bold text-[#D92D20] dark:text-[#FF5A4E]">Critical</span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-[#566070] dark:text-[#9FADC2]">Affected Area</span>
                <span className="font-bold text-[#16202D] dark:text-white">~ 12 km²</span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-[#566070] dark:text-[#9FADC2]">Reported By</span>
                <span className="font-bold text-[#16202D] dark:text-white">Multiple users</span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-[#566070] dark:text-[#9FADC2]">First Reported</span>
                <span className="font-bold text-[#16202D] dark:text-white">12 min ago</span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-[#566070] dark:text-[#9FADC2]">Last Updated</span>
                <span className="font-bold text-[#16202D] dark:text-white">2 min ago</span>
              </div>
            </div>
          </Card>

          {/* Resources Needed Card */}
          <Card>
            <h3 className="text-sm font-bold text-[#16202D] dark:text-white mb-4 pb-2 border-b border-[#E6DCA8] dark:border-[#26344F]">
              Resources Needed
            </h3>

            <div className="grid grid-cols-2 gap-3 text-xs">
              <div className="p-3 rounded-xl bg-[#FFFCEB]/50 dark:bg-[#0E1627] border border-[#E6DCA8]/50 dark:border-[#26344F]/50 flex items-center gap-2.5">
                <LifeBuoy size={20} className="text-[#0E8A94] dark:text-[#3CC6D0] flex-shrink-0" />
                <div>
                  <span className="block font-bold text-[#16202D] dark:text-white">Rescue Boats</span>
                  <span className="text-[11px] text-[#566070] dark:text-[#9FADC2]">3 units</span>
                </div>
              </div>

              <div className="p-3 rounded-xl bg-[#FFFCEB]/50 dark:bg-[#0E1627] border border-[#E6DCA8]/50 dark:border-[#26344F]/50 flex items-center gap-2.5">
                <HeartPulse size={20} className="text-[#D92D20] dark:text-[#FF5A4E] flex-shrink-0" />
                <div>
                  <span className="block font-bold text-[#16202D] dark:text-white">Medical Teams</span>
                  <span className="text-[11px] text-[#566070] dark:text-[#9FADC2]">2 units</span>
                </div>
              </div>

              <div className="p-3 rounded-xl bg-[#FFFCEB]/50 dark:bg-[#0E1627] border border-[#E6DCA8]/50 dark:border-[#26344F]/50 flex items-center gap-2.5">
                <Package size={20} className="text-[#E07B00] dark:text-[#FFA033] flex-shrink-0" />
                <div>
                  <span className="block font-bold text-[#16202D] dark:text-white">Food & Water</span>
                  <span className="text-[11px] text-[#E07B00] font-semibold">High priority</span>
                </div>
              </div>

              <div className="p-3 rounded-xl bg-[#FFFCEB]/50 dark:bg-[#0E1627] border border-[#E6DCA8]/50 dark:border-[#26344F]/50 flex items-center gap-2.5">
                <Home size={20} className="text-[#8A5A00] dark:text-[#FFD21F] flex-shrink-0" />
                <div>
                  <span className="block font-bold text-[#16202D] dark:text-white">Temp Shelter</span>
                  <span className="text-[11px] text-[#566070] dark:text-[#9FADC2]">Required</span>
                </div>
              </div>
            </div>
          </Card>
        </div>
      </div>
    </div>
  );
};

export default IncidentDetailPage;

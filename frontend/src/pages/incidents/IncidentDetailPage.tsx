import React, { useState, useMemo } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import {
  ArrowLeft,
  Share2,
  Users,
  Clock,
  MapPin,
  CheckCircle,
  Radio,
  RefreshCw,
  Loader2,
  ShieldAlert,
} from 'lucide-react';
import { Badge } from '../../components/common/Badge';
import { Button } from '../../components/common/Button';
import {
  fetchIncidentById,
  getIncidentPeople,
  getIncidentMessages,
  getIncidentDevices,
  getIncidentTimeline,
} from '../../api/incidents.ts';
import { IncidentOverviewTab } from '../../components/incidents/IncidentOverviewTab.tsx';
import { IncidentPeopleTab } from '../../components/incidents/IncidentPeopleTab.tsx';
import { IncidentMessagesTab } from '../../components/incidents/IncidentMessagesTab.tsx';
import { IncidentDevicesTab } from '../../components/incidents/IncidentDevicesTab.tsx';
import { IncidentResourcesTab } from '../../components/incidents/IncidentResourcesTab.tsx';
import { IncidentTimelineTab } from '../../components/incidents/IncidentTimelineTab.tsx';
import { AssignTeamModal } from '../../components/incidents/AssignTeamModal.tsx';

export const IncidentDetailPage: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [activeTab, setActiveTab] = useState('Overview');
  const [isAssignModalOpen, setIsAssignModalOpen] = useState(false);
  const [assignedTeamName, setAssignedTeamName] = useState<string | null>(null);
  const [copied, setCopied] = useState(false);

  const incidentId = id || 'INC-2026-001';

  // Real backend query with 15s live polling
  const {
    data: incident,
    isLoading,
    isRefetching,
    refetch,
  } = useQuery({
    queryKey: ['incident', incidentId],
    queryFn: () => fetchIncidentById(incidentId),
    refetchInterval: 15000,
  });

  const people = useMemo(
    () => getIncidentPeople(incident?.affectedPeople || 142),
    [incident?.affectedPeople]
  );
  const messages = useMemo(() => getIncidentMessages(), []);
  const devices = useMemo(() => getIncidentDevices(), []);
  const timeline = useMemo(() => getIncidentTimeline(), []);

  const handleShare = () => {
    const url = `${window.location.origin}/api/v1/interop/cap/feed.xml?incident_id=${incidentId}`;
    navigator.clipboard?.writeText(url);
    setCopied(true);
    setTimeout(() => setCopied(false), 2500);
  };

  if (isLoading) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[450px] space-y-4">
        <Loader2 className="w-10 h-10 animate-spin text-[#FFC400]" />
        <p className="text-sm font-semibold text-[#566070] dark:text-[#9FADC2]">
          Loading Incident {incidentId} live telemetry from Command Center...
        </p>
      </div>
    );
  }

  if (!incident) {
    return (
      <div className="p-8 rounded-2xl bg-white dark:bg-[#162036] border border-[#E6DCA8] dark:border-[#26344F] text-center space-y-4">
        <ShieldAlert className="w-12 h-12 text-[#D92D20] mx-auto" />
        <h2 className="text-xl font-bold text-[#16202D] dark:text-white">
          Incident Not Found
        </h2>
        <p className="text-sm text-[#566070] dark:text-[#9FADC2]">
          Could not find active incident record for identifier: {incidentId}
        </p>
        <Button variant="primary" onClick={() => navigate('/app/incidents')}>
          Back to Incidents List
        </Button>
      </div>
    );
  }

  const effectiveAssignedTeam =
    assignedTeamName || incident.assignedTeam;

  const tabs = [
    'Overview',
    `People (${incident.affectedPeople})`,
    `Messages (${messages.length})`,
    `Devices (${incident.devicesCount})`,
    'Resources',
    'Timeline',
  ];

  const locationString =
    typeof incident.location === 'string'
      ? incident.location
      : incident.location.address ||
        `${incident.coordinates.lat.toFixed(4)}° N, ${incident.coordinates.lng.toFixed(4)}° E`;

  return (
    <div className="space-y-6">
      {/* Top Breadcrumb & Actions */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div className="flex items-center gap-3">
          <button
            onClick={() => navigate('/app/incidents')}
            className="p-2 rounded-xl bg-white dark:bg-[#162036] border border-[#E6DCA8] dark:border-[#26344F] text-[#566070] dark:text-[#9FADC2] hover:text-[#16202D] dark:hover:text-white transition-colors cursor-pointer"
            title="Back to Incidents"
          >
            <ArrowLeft size={18} />
          </button>
          <div>
            <div className="flex items-center gap-2 text-xs font-mono text-[#8A5A00] dark:text-[#FFD21F]">
              <span>Incidents</span>
              <span>/</span>
              <span>{incident.id || incidentId}</span>
            </div>
            <div className="flex items-center gap-3 mt-1 flex-wrap">
              <h1
                className="text-2xl sm:text-3xl font-black text-[#16202D] dark:text-white tracking-tight"
                style={{ fontFamily: '"Barlow Semi Condensed", sans-serif' }}
              >
                {incident.title}
              </h1>
              <Badge severity={incident.severity} label={String(incident.severity)} />
              {incident.status && (
                <span className="text-xs px-2.5 py-0.5 rounded-full font-bold uppercase tracking-wider bg-[#0E8A94]/15 text-[#0E8A94] border border-[#0E8A94]/30">
                  {incident.status}
                </span>
              )}
            </div>
          </div>
        </div>

        {/* Action Buttons */}
        <div className="flex items-center gap-2 sm:gap-3 flex-wrap">
          <Button
            variant="secondary"
            size="sm"
            onClick={() => refetch()}
            leftIcon={<RefreshCw size={14} className={isRefetching ? 'animate-spin' : ''} />}
          >
            Refresh
          </Button>

          <Button
            variant={effectiveAssignedTeam ? 'secondary' : 'primary'}
            size="md"
            leftIcon={effectiveAssignedTeam ? <CheckCircle size={16} className="text-[#10B981]" /> : undefined}
            onClick={() => setIsAssignModalOpen(true)}
          >
            {effectiveAssignedTeam ? `Assigned to ${effectiveAssignedTeam}` : 'Assign Team'}
          </Button>

          <Button
            variant="secondary"
            size="md"
            leftIcon={<Share2 size={16} />}
            onClick={handleShare}
          >
            {copied ? 'Link Copied!' : 'Share CAP Feed'}
          </Button>
        </div>
      </div>

      {/* Meta sub-ribbon */}
      <div className="flex flex-wrap items-center gap-4 text-xs text-[#566070] dark:text-[#9FADC2] px-4 py-2.5 rounded-xl bg-white dark:bg-[#162036] border border-[#E6DCA8] dark:border-[#26344F]">
        <span className="flex items-center gap-1.5 font-medium">
          <MapPin size={14} className="text-[#0E8A94]" /> {locationString}
        </span>
        <span>•</span>
        <span className="flex items-center gap-1.5 font-medium">
          <Clock size={14} /> {incident.firstReported}
        </span>
        <span>•</span>
        <span className="flex items-center gap-1.5 font-bold text-[#D92D20] dark:text-[#FF5A4E]">
          <Users size={14} /> {incident.affectedPeople} affected users
        </span>
        <span>•</span>
        <span className="flex items-center gap-1.5 font-medium text-[#0E8A94] dark:text-[#3CC6D0]">
          <Radio size={14} /> {incident.devicesCount} active mesh devices
        </span>
      </div>

      {/* Navigation Tabs */}
      <div className="flex items-center gap-2 border-b border-[#E6DCA8] dark:border-[#26344F] pb-1 overflow-x-auto">
        {tabs.map((tab) => (
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
        ))}
      </div>

      {/* Tab Content Display */}
      <div>
        {activeTab === 'Overview' && (
          <IncidentOverviewTab
            incident={incident}
            onOpenAssignModal={() => setIsAssignModalOpen(true)}
          />
        )}

        {activeTab.startsWith('People') && (
          <IncidentPeopleTab people={people} />
        )}

        {activeTab.startsWith('Messages') && (
          <IncidentMessagesTab messages={messages} />
        )}

        {activeTab.startsWith('Devices') && (
          <IncidentDevicesTab devices={devices} />
        )}

        {activeTab === 'Resources' && (
          <IncidentResourcesTab
            resources={incident.resourcesNeeded}
            assignedTeam={effectiveAssignedTeam}
            onOpenAssignModal={() => setIsAssignModalOpen(true)}
          />
        )}

        {activeTab === 'Timeline' && (
          <IncidentTimelineTab timeline={timeline} />
        )}
      </div>

      {/* Assign Team Modal */}
      <AssignTeamModal
        isOpen={isAssignModalOpen}
        incident={incident}
        onClose={() => setIsAssignModalOpen(false)}
        onSuccess={(team) => {
          setAssignedTeamName(team);
          setIsAssignModalOpen(false);
          refetch();
        }}
      />
    </div>
  );
};

export default IncidentDetailPage;

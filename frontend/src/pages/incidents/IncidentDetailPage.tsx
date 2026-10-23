import React, { useState, useMemo, useEffect, useCallback } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useQuery, useQueryClient } from '@tanstack/react-query';
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
  Layers,
  FileText,
  Activity,
  Check,
  ChevronDown,
} from 'lucide-react';
import { Badge } from '../../components/common/Badge';
import { Button } from '../../components/common/Button';
import type { IncidentPerson, IncidentDevice, IncidentTimelineEvent } from '../../types/incident.ts';
import {
  fetchIncidentById,
  getIncidentPeople,
  getIncidentDevices,
  getIncidentTimeline,
  fetchIncidentCommunications,
  fetchIncidentMeshTopology,
  updateIncidentStatus,
} from '../../api/incidents.ts';
import { useWebSocket } from '../../hooks/useWebSocket';
import { IncidentOverviewTab } from '../../components/incidents/IncidentOverviewTab.tsx';
import { IncidentAreaMeshMap } from '../../components/incidents/IncidentAreaMeshMap.tsx';
import { IncidentCommunicationsCenter } from '../../components/incidents/IncidentCommunicationsCenter.tsx';
import { IncidentPeopleTab } from '../../components/incidents/IncidentPeopleTab.tsx';
import { IncidentDevicesTab } from '../../components/incidents/IncidentDevicesTab.tsx';
import { IncidentResourcesTab } from '../../components/incidents/IncidentResourcesTab.tsx';
import { IncidentTimelineTab } from '../../components/incidents/IncidentTimelineTab.tsx';
import { AssignTeamModal } from '../../components/incidents/AssignTeamModal.tsx';

const STATUS_OPTIONS = [
  'ACTIVE',
  'INVESTIGATING',
  'DISPATCHED',
  'CONTAINED',
  'RESOLVED',
];

export const IncidentDetailPage: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const queryClient = useQueryClient();

  const [activeTab, setActiveTab] = useState('Overview');
  const [isAssignModalOpen, setIsAssignModalOpen] = useState(false);
  const [assignedTeamName, setAssignedTeamName] = useState<string | null>(null);
  const [copied, setCopied] = useState(false);
  const [currentStatus, setCurrentStatus] = useState<string>('ACTIVE');
  const [isStatusMenuOpen, setIsStatusMenuOpen] = useState(false);

  const incidentId = id || '';

  // 1. Fetch Master Incident Details with 12s live polling
  const {
    data: incident,
    isLoading: isIncidentLoading,
    isRefetching,
    refetch: refetchIncident,
  } = useQuery({
    queryKey: ['incident', incidentId],
    queryFn: () => fetchIncidentById(incidentId),
    refetchInterval: 12000,
  });

  // 2. Fetch Incident-specific Segregated Communications
  const {
    data: communications,
    isLoading: isCommsLoading,
    refetch: refetchComms,
  } = useQuery({
    queryKey: ['incidentComms', incidentId],
    queryFn: () => fetchIncidentCommunications(incidentId),
    refetchInterval: 12000,
  });

  // 3. Fetch Incident-specific Mesh Topology & GPS Fixes
  const {
    data: topology,
    refetch: refetchTopology,
  } = useQuery({
    queryKey: ['incidentTopology', incidentId],
    queryFn: () => fetchIncidentMeshTopology(incidentId),
    refetchInterval: 15000,
  });

  // Sync incident status when loaded
  useEffect(() => {
    if (incident?.status) {
      setCurrentStatus(incident.status.toUpperCase());
    }
  }, [incident?.status]);

  // Real-time WebSocket Gateway reaction: auto-refresh on new telemetry packets
  const { status: wsStatus, lastMessage } = useWebSocket();
  useEffect(() => {
    if (!lastMessage) return;
    const ev = String((lastMessage as any).event);
    if (
      ev === 'NEW_PACKET_INGESTED' ||
      ev === 'INCIDENTS_UPDATED' ||
      ev === 'INCIDENT_ASSIGNED'
    ) {
      refetchIncident();
      refetchComms();
      refetchTopology();
    }
  }, [lastMessage, refetchIncident, refetchComms, refetchTopology]);


  const handleStatusChange = async (newStatus: string) => {
    setIsStatusMenuOpen(false);
    const prev = currentStatus;
    setCurrentStatus(newStatus);

    try {
      await updateIncidentStatus(incidentId, newStatus);
      queryClient.invalidateQueries({ queryKey: ['incidents'] });
      refetchIncident();
    } catch (err) {
      console.error('Failed to update incident status:', err);
      setCurrentStatus(prev);
    }
  };

  const people: IncidentPerson[] = useMemo(() => getIncidentPeople(), []); /* Legacy derived profiles deliberately disabled.
    if (communications?.sos_alerts && communications.sos_alerts.length > 0) {
      return communications.sos_alerts.map((s, idx) => ({
        id: s.id || `person-${idx}`,
        name: s.sender_name || s.sender_id || `Survivor ${idx + 1}`,
        role: 'Civic Survivor',
        status: s.priority === 'CRITICAL' ? 'Critical Triage' : 'Trapped',
        familyMembersCount: s.casualties || 1,
        devicePseudonym: s.sender_id,
        location: `${s.lat.toFixed(4)}° N, ${s.lng.toFixed(4)}° E`,
        lastContact: s.timestamp_display,
        medicalNotes: s.payload,
      }));
    }
    if (incident?.associatedDevices && incident.associatedDevices.length > 0) {
      return (incident.associatedDevices as string[]).map((devId: string, idx: number) => ({
        id: `dev-person-${idx}`,
        name: `Distress Handset (${devId})`,
        role: 'Civic Survivor',
        status: 'Trapped',
        familyMembersCount: incident.affectedPeople ? Math.max(1, Math.round(incident.affectedPeople / incident.associatedDevices.length)) : 1,
        devicePseudonym: devId,
        location: typeof incident.location === 'string' ? incident.location : `${incident.coordinates.lat.toFixed(4)}° N, ${incident.coordinates.lng.toFixed(4)}° E`,
        lastContact: 'Active Uplink',
        medicalNotes: 'Disaster mesh distress telemetry',
      }));
    }
    return [];
  }, [communications?.sos_alerts, incident?.associatedDevices, incident?.affectedPeople, incident?.location, incident?.coordinates]);

  */
  const devices: IncidentDevice[] = useMemo(() => getIncidentDevices(), []); /* Legacy derived device telemetry deliberately disabled.
    if (incident?.associatedDevices && incident.associatedDevices.length > 0) {
      return (incident.associatedDevices as string[]).map((devId: string) => ({
        deviceId: devId,
        ownerName: `Mesh Handset (${devId})`,
        deviceType: 'Phone',
        batteryPct: 85,
        hops: 0,
        lastSeen: 'Active Uplink',
        status: 'Relay',
        rssi: -58,
      }));
    }
    return [];
  }, [incident?.associatedDevices]);

  */
  const timeline: IncidentTimelineEvent[] = useMemo(() => getIncidentTimeline(), []); /* Legacy inferred timeline deliberately disabled.
    const events: IncidentTimelineEvent[] = [];
    if (incident?.firstReported) {
      events.push({
        id: 'ev-report',
        timestamp: incident.firstReported,
        title: 'Incident Distress Beacon Ingested',
        description: `Initial spatiotemporal cluster formed from distress beacons. Severity assessed as ${incident.severity}.`,
        category: 'DISTRESS',
        actor: 'RakshaNet Gateway Engine',
        severity: incident.severity as any,
      });
    }
    if (incident?.assignedTeam) {
      events.push({
        id: 'ev-assigned',
        timestamp: incident.lastUpdate || 'Recent',
        title: 'Rescue Team Dispatched',
        description: `Tactical assignment given to ${incident.assignedTeam}.`,
        category: 'DISPATCH',
        actor: 'Command Center Commander',
      });
    }
    if (communications?.sos_alerts && communications.sos_alerts.length > 0) {
      communications.sos_alerts.forEach((s) => {
        events.push({
          id: `ev-sos-${s.id}`,
          timestamp: s.timestamp_display,
          title: `SOS Alert: ${s.sender_name}`,
          description: s.payload,
          category: 'DISTRESS',
          actor: s.sender_id,
        });
      });
    }
    if (communications?.team_comms && communications.team_comms.length > 0) {
      communications.team_comms.forEach((tc) => {
        events.push({
          id: `ev-tc-${tc.id}`,
          timestamp: tc.timestamp_display,
          title: `Tactical Command: ${tc.sender}`,
          description: tc.message,
          category: 'DISPATCH',
          actor: tc.sender,
        });
      });
    }
    return events;
  }, [incident?.firstReported, incident?.lastUpdate, incident?.severity, incident?.assignedTeam, communications?.sos_alerts, communications?.team_comms]);

  */
  const handleShare = () => {
    const url = `${window.location.origin}/api/v1/interop/cap/${incidentId}.xml`;
    navigator.clipboard?.writeText(url);
    setCopied(true);
    setTimeout(() => setCopied(false), 2500);
  };

  if (isIncidentLoading) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[450px] space-y-4">
        <Loader2 className="w-10 h-10 animate-spin text-[#FFC400]" />
        <p className="text-sm font-semibold text-[#64748B] dark:text-[#9FADC2]">
          Loading Incident {incidentId} live telemetry from Command Center...
        </p>
      </div>
    );
  }

  if (!incident) {
    return (
      <div className="p-8 rounded-2xl bg-white dark:bg-[#162036] border border-[#E2E8F0] dark:border-[#26344F] text-center space-y-4">
        <ShieldAlert className="w-12 h-12 text-[#D92D20] mx-auto" />
        <h2 className="text-xl font-bold text-[#0F172A] dark:text-white">
          Incident Not Found
        </h2>
        <p className="text-sm text-[#64748B] dark:text-[#9FADC2]">
          Could not find active incident record for identifier: {incidentId}
        </p>
        <Button variant="primary" onClick={() => navigate('/app/incidents')}>
          Back to Incidents List
        </Button>
      </div>
    );
  }

  const effectiveAssignedTeam = assignedTeamName || incident.assignedTeam;

  const tabs = [
    'Overview',
    `Mesh Communications (${communications?.summary?.total ?? 0})`,
    'Incident Area Map',
    `People (${incident.affectedPeople ?? 'Not reported'})`,
    `Devices (${incident.devicesCount ?? 'Not reported'})`,
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
      {/* Top Breadcrumb, Title & Global Actions */}
      <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
        <div className="flex items-start sm:items-center gap-3">
          <button
            onClick={() => navigate('/app/incidents')}
            className="p-2.5 rounded-xl bg-white dark:bg-[#162036] border border-[#E2E8F0] dark:border-[#26344F] text-[#64748B] dark:text-[#9FADC2] hover:text-[#0F172A] dark:hover:text-white transition-colors cursor-pointer shrink-0 mt-1 sm:mt-0"
            title="Back to Incidents"
          >
            <ArrowLeft size={18} />
          </button>
          <div>
            <div className="flex items-center gap-2 text-xs font-mono text-[#8A5A00] dark:text-[#FFD21F]">
              <span>Incidents</span>
              <span>/</span>
              <span>{incident.id || incidentId}</span>
              <span>•</span>
              <span className="flex items-center gap-1 text-emerald-600 dark:text-emerald-400">
                <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
                <span>{wsStatus === 'connected' ? 'Mesh Uplink Active' : 'Gateway Polling'}</span>
              </span>
            </div>

            <div className="flex items-center gap-3 mt-1 flex-wrap">
              <h1
                className="text-2xl sm:text-3xl font-black text-[#0F172A] dark:text-white tracking-tight"
                style={{ fontFamily: '"Barlow Semi Condensed", sans-serif' }}
              >
                {incident.title}
              </h1>
              <Badge severity={incident.severity} label={String(incident.severity)} />

              {/* Interactive Status Selector Dropdown */}
              <div className="relative">
                <button
                  type="button"
                  onClick={() => setIsStatusMenuOpen(!isStatusMenuOpen)}
                  className={`text-xs px-3 py-1 rounded-full font-bold uppercase tracking-wider border flex items-center gap-1.5 transition-all cursor-pointer ${
                    currentStatus === 'ACTIVE' || currentStatus === 'OPEN'
                      ? 'bg-red-500/15 text-red-600 dark:text-red-400 border-red-500/30'
                      : currentStatus === 'INVESTIGATING'
                      ? 'bg-amber-500/15 text-amber-600 dark:text-amber-400 border-amber-500/30'
                      : currentStatus === 'DISPATCHED' || currentStatus === 'ASSIGNED'
                      ? 'bg-cyan-500/15 text-cyan-600 dark:text-cyan-400 border-cyan-500/30'
                      : currentStatus === 'CONTAINED'
                      ? 'bg-purple-500/15 text-purple-600 dark:text-purple-400 border-purple-500/30'
                      : 'bg-emerald-500/15 text-emerald-600 dark:text-emerald-400 border-emerald-500/30'
                  }`}
                >
                  <span>{currentStatus}</span>
                  <ChevronDown className="w-3.5 h-3.5 opacity-70" />
                </button>

                {isStatusMenuOpen && (
                  <div className="absolute left-0 mt-1 w-44 rounded-xl bg-white dark:bg-[#111A2E] border border-[#CBD5E1] dark:border-[#1E293B] shadow-2xl z-50 py-1 animate-in fade-in zoom-in-95">
                    <div className="px-3 py-1 text-[10px] font-bold uppercase tracking-wider text-[#94A3B8]">
                      Set Operational Status
                    </div>
                    {STATUS_OPTIONS.map((st) => (
                      <button
                        key={st}
                        onClick={() => handleStatusChange(st)}
                        className={`w-full text-left px-3 py-1.5 text-xs font-semibold flex items-center justify-between hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors ${
                          currentStatus === st
                            ? 'text-[#0891B2] dark:text-[#06B6D4] font-bold'
                            : 'text-[#334155] dark:text-[#CBD5E1]'
                        }`}
                      >
                        <span>{st}</span>
                        {currentStatus === st && <Check className="w-3.5 h-3.5" />}
                      </button>
                    ))}
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>

        {/* Action Buttons */}
        <div className="flex items-center gap-2 sm:gap-2.5 flex-wrap">
          <Button
            variant="secondary"
            size="sm"
            onClick={() => {
              refetchIncident();
              refetchComms();
              refetchTopology();
            }}
            leftIcon={
              <RefreshCw
                size={14}
                className={isRefetching ? 'animate-spin text-[#0891B2]' : ''}
              />
            }
          >
            Refresh
          </Button>

          <Button
            variant={effectiveAssignedTeam ? 'secondary' : 'primary'}
            size="md"
            leftIcon={
              effectiveAssignedTeam ? (
                <CheckCircle size={16} className="text-[#10B981]" />
              ) : undefined
            }
            onClick={() => setIsAssignModalOpen(true)}
          >
            {effectiveAssignedTeam
              ? `Assigned: ${effectiveAssignedTeam}`
              : 'Assign Rescue Team'}
          </Button>

          <Button
            variant="secondary"
            size="md"
            leftIcon={<Share2 size={16} />}
            onClick={handleShare}
            title="Copy OASIS CAP XML feed for CAD / 112 consoles"
          >
            {copied ? 'CAP Copied!' : 'Export CAP XML'}
          </Button>
        </div>
      </div>

      {/* Meta sub-ribbon */}
      <div className="flex flex-wrap items-center gap-4 text-xs text-[#64748B] dark:text-[#9FADC2] px-4 py-2.5 rounded-xl bg-white dark:bg-[#162036] border border-[#E2E8F0] dark:border-[#26344F] shadow-sm">
        <span className="flex items-center gap-1.5 font-medium">
          <MapPin size={14} className="text-[#0E8A94]" /> {locationString}
        </span>
        <span>•</span>
        <span className="flex items-center gap-1.5 font-medium">
          <Clock size={14} /> Reported: {incident.firstReported}
        </span>
        <span>•</span>
        <span className="flex items-center gap-1.5 font-bold text-[#D92D20] dark:text-[#FF5A4E]">
          <Users size={14} /> ~{incident.affectedPeople} estimated casualties
        </span>
        <span>•</span>
        <span className="flex items-center gap-1.5 font-medium text-[#0E8A94] dark:text-[#3CC6D0]">
          <Radio size={14} /> {incident.devicesCount} active mesh handsets
        </span>
      </div>

      {/* Navigation Tabs */}
      <div className="flex items-center gap-2 border-b border-[#E2E8F0] dark:border-[#26344F] pb-1 overflow-x-auto">
        {tabs.map((tab) => {
          const isSelected =
            (activeTab === 'Overview' && tab === 'Overview') ||
            (activeTab === 'Mesh Communications' && tab.startsWith('Mesh Communications')) ||
            (activeTab === 'Incident Area Map' && tab === 'Incident Area Map') ||
            (activeTab === 'People' && tab.startsWith('People')) ||
            (activeTab === 'Devices' && tab.startsWith('Devices')) ||
            (activeTab === 'Resources' && tab === 'Resources') ||
            (activeTab === 'Timeline' && tab.startsWith('Timeline'));

          return (
            <button
              key={tab}
              onClick={() => {
                if (tab.startsWith('Mesh Communications')) {
                  setActiveTab('Mesh Communications');
                } else if (tab.startsWith('People')) {
                  setActiveTab('People');
                } else if (tab.startsWith('Devices')) {
                  setActiveTab('Devices');
                } else if (tab.startsWith('Timeline')) {
                  setActiveTab('Timeline');
                } else {
                  setActiveTab(tab);
                }
              }}
              className={`px-4 py-2 text-xs font-bold rounded-xl transition-all cursor-pointer whitespace-nowrap ${
                isSelected
                  ? 'bg-[#FFC400] dark:bg-[#FFD21F] text-[#1A1400] shadow-sm'
                  : 'text-[#64748B] dark:text-[#9FADC2] hover:text-[#0F172A] dark:hover:text-white'
              }`}
            >
              {tab}
            </button>
          );
        })}
      </div>

      {/* Tab Content Display */}
      <div>
        {/* 1. OVERVIEW TAB: Integrated Area Mesh Map + Description + AI Analysis */}
        {activeTab === 'Overview' && (
          <IncidentOverviewTab
            incident={incident}
            topology={topology}
            onOpenAssignModal={() => setIsAssignModalOpen(true)}
            onSelectNode={(_type, _id) => {
              setActiveTab('Mesh Communications');
            }}
          />
        )}

        {/* 2. DEDICATED MESH COMMUNICATIONS CENTER */}
        {activeTab === 'Mesh Communications' && (
          <IncidentCommunicationsCenter
            incidentId={incidentId}
            communications={communications}
            isLoading={isCommsLoading}
            onRefresh={() => refetchComms()}
          />
        )}

        {/* 3. DEDICATED INCIDENT AREA MESH MAP */}
        {activeTab === 'Incident Area Map' && (
          <div className="space-y-4">
            <div className="p-4 rounded-xl bg-white dark:bg-[#111A2E] border border-[#E2E8F0] dark:border-[#1E293B]">
              <div className="flex items-center justify-between mb-2">
                <div>
                  <h3 className="text-base font-bold text-[#0F172A] dark:text-[#F8FAFC]">
                    Full Tactical Mesh Map: {incident.title}
                  </h3>
                  <p className="text-xs text-[#64748B] dark:text-[#94A3B8]">
                    Real-time geofence showing all active SOS pins, store-and-forward relay nodes, and extraction units
                  </p>
                </div>
              </div>
              <IncidentAreaMeshMap
                incident={incident}
                topology={topology}
                height="620px"
              />
            </div>
          </div>
        )}

        {/* 4. PEOPLE TAB */}
        {activeTab.startsWith('People') && (
          <IncidentPeopleTab people={people} />
        )}

        {/* 5. DEVICES TAB */}
        {activeTab.startsWith('Devices') && (
          <IncidentDevicesTab devices={devices} />
        )}

        {/* 6. RESOURCES TAB */}
        {activeTab === 'Resources' && (
          <IncidentResourcesTab
            resources={incident.resourcesNeeded}
            assignedTeam={effectiveAssignedTeam}
            onOpenAssignModal={() => setIsAssignModalOpen(true)}
          />
        )}

        {/* 7. TIMELINE TAB */}
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
          refetchIncident();
        }}
      />
    </div>
  );
};

export default IncidentDetailPage;

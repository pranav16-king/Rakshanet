import React, { useState, useEffect, useRef, useCallback } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import {
  UserSearch,
  Plus,
  Search,
  MapPin,
  Phone,
  Clock,
  Eye,
  CheckCircle2,
  AlertCircle,
  Users,
  Compass,
  X,
  Camera,
  Upload,
  UploadCloud,
  Sparkles,
  Check,
  RefreshCw,
  Radio,
  ExternalLink,
  Copy,
  User,
  ArrowRight,
  Activity,
  Scan,
  ShieldAlert,
  Filter,
  Layers,
  HeartPulse,
  Tag,
  Shirt,
  Ruler,
  Stethoscope,
  Maximize2,
  Navigation,
  Flame,
  Waves,
  Building2,
  Mountain,
  AlertTriangle,
  ChevronRight,
} from 'lucide-react';
import { Card } from '../../components/common/Card';
import { Button } from '../../components/common/Button';
import {
  getMissingPersons,
  createMissingPerson,
  updateMissingPersonStatus,
  addMissingPersonSighting,
  searchMissingPersonByPhoto,
} from '../../api/missingPersons';
import { incidentsApi } from '../../api/incidents';
import { API_BASE_URL } from '../../api/client';
import { useWebSocket } from '../../hooks/useWebSocket';
import type {
  MissingPerson,
  MissingPersonStatusFilter,
  CreateMissingPersonPayload,
  CreateSightingPayload,
  VisualMatch,
  VisualSearchResult,
} from '../../types/missingPerson';

// =============================================================================
// PHOTO URL RESOLUTION & AVATAR COMPONENT
// =============================================================================

export function resolvePhotoUrl(url?: string | null): string | undefined {
  if (!url || typeof url !== 'string') return undefined;
  const trimmed = url.trim();
  if (!trimmed) return undefined;
  if (trimmed.startsWith('data:') || trimmed.startsWith('blob:')) {
    return trimmed;
  }
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  if (trimmed.startsWith('/')) {
    return `${API_BASE_URL}${trimmed}`;
  }
  return `${API_BASE_URL}/${trimmed}`;
}

interface PersonAvatarProps {
  photoUrl?: string | null;
  name: string;
  isFound?: boolean;
  size?: 'sm' | 'md' | 'lg' | 'xl';
  className?: string;
  onClick?: () => void;
}

export const PersonAvatar: React.FC<PersonAvatarProps> = ({
  photoUrl,
  name,
  isFound = false,
  size = 'md',
  className = '',
  onClick,
}) => {
  const [hasError, setHasError] = useState(false);
  const resolvedUrl = resolvePhotoUrl(photoUrl);
  const initial = (name || '?').trim().charAt(0).toUpperCase();

  const sizeClasses = {
    sm: 'w-10 h-10 text-sm',
    md: 'w-14 h-14 text-base',
    lg: 'w-20 h-20 text-2xl',
    xl: 'w-28 h-28 text-3xl',
  }[size];

  useEffect(() => {
    setHasError(false);
  }, [photoUrl]);

  if (resolvedUrl && !hasError) {
    return (
      <div
        onClick={onClick}
        className={`relative shrink-0 rounded-xl overflow-hidden border shadow-sm transition-transform hover:scale-105 duration-200 ${
          onClick ? 'cursor-pointer' : ''
        } ${
          isFound
            ? 'border-emerald-500/50 ring-2 ring-emerald-500/20'
            : 'border-amber-500/50 ring-2 ring-amber-500/20'
        } ${sizeClasses} ${className}`}
      >
        <img
          src={resolvedUrl}
          alt={name}
          onError={() => setHasError(true)}
          className="w-full h-full object-cover object-center"
          loading="lazy"
        />
      </div>
    );
  }

  return (
    <div
      onClick={onClick}
      className={`relative shrink-0 rounded-xl flex flex-col items-center justify-center font-bold border transition-colors ${
        onClick ? 'cursor-pointer' : ''
      } ${
        isFound
          ? 'bg-emerald-500/15 border-emerald-500/30 text-emerald-600 dark:text-emerald-400'
          : 'bg-[#FFD21F]/20 border-amber-500/30 text-amber-700 dark:text-[#FFD21F]'
      } ${sizeClasses} ${className}`}
      title={name}
    >
      <span>{initial}</span>
      <User className="w-3.5 h-3.5 opacity-60 absolute bottom-1 right-1" />
    </div>
  );
};

// Disaster Type Icon Helper
function getDisasterIcon(type?: string) {
  const lower = (type || '').toLowerCase();
  if (lower.includes('flood') || lower.includes('water')) {
    return <Waves className="w-3.5 h-3.5 text-blue-500" />;
  }
  if (lower.includes('earthquake') || lower.includes('collapse') || lower.includes('struct')) {
    return <Building2 className="w-3.5 h-3.5 text-amber-500" />;
  }
  if (lower.includes('landslide') || lower.includes('hill') || lower.includes('mountain')) {
    return <Mountain className="w-3.5 h-3.5 text-orange-500" />;
  }
  if (lower.includes('cyclone') || lower.includes('storm') || lower.includes('wind')) {
    return <Compass className="w-3.5 h-3.5 text-cyan-500" />;
  }
  if (lower.includes('fire') || lower.includes('substation')) {
    return <Flame className="w-3.5 h-3.5 text-red-500" />;
  }
  return <AlertTriangle className="w-3.5 h-3.5 text-amber-500" />;
}

// =============================================================================
// MAIN MISSING PERSONS COMPONENT
// =============================================================================

export const MissingPersonsPage: React.FC = () => {
  const navigate = useNavigate();
  const [persons, setPersons] = useState<MissingPerson[]>([]);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [isRefreshing, setIsRefreshing] = useState<boolean>(false);
  const [selectedStatus, setSelectedStatus] = useState<MissingPersonStatusFilter>('ALL');
  const [selectedIncident, setSelectedIncident] = useState<string>('ALL');
  const [selectedPriority, setSelectedPriority] = useState<string>('ALL');
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [activeTab, setActiveTab] = useState<'DIRECTORY' | 'VISUAL_SEARCH'>('DIRECTORY');

  // Available Incidents for dropdown
  const [availableIncidents, setAvailableIncidents] = useState<
    { id: string; title: string; disaster_type?: string }[]
  >([]);

  // Modals state
  const [isReportModalOpen, setIsReportModalOpen] = useState<boolean>(false);
  const [isVisualSearchModalOpen, setIsVisualSearchModalOpen] = useState<boolean>(false);
  const [sightingModalPerson, setSightingModalPerson] = useState<MissingPerson | null>(null);
  const [detailModalPerson, setDetailModalPerson] = useState<MissingPerson | null>(null);
  const [lightboxPerson, setLightboxPerson] = useState<MissingPerson | null>(null);
  const [prefilledMatchPerson, setPrefilledMatchPerson] = useState<MissingPerson | null>(null);

  // Status update indicator
  const [optimisticAlert, setOptimisticAlert] = useState<{
    message: string;
    type: 'success' | 'info';
  } | null>(null);

  // Real-time Gateway WebSocket uplink
  const { status: wsStatus, lastMessage } = useWebSocket();
  const [lastSyncTime, setLastSyncTime] = useState<number>(Date.now());

  // Load available disaster incidents
  useEffect(() => {
    const loadIncidents = async () => {
      try {
        const data = await incidentsApi.getIncidents();
        if (data && data.length > 0) {
          setAvailableIncidents(
            data.map((inc: any) => ({
              id: inc.incident_id || inc.id || 'INC-UNKNOWN',
              title: inc.title || `${inc.category || 'Incident'} ${inc.incident_id || inc.id || ''}`,
              disaster_type: inc.disaster_type || inc.category,
            }))
          );
        }
      } catch (err) {
        console.error('Failed to load incidents for missing persons dropdown:', err);
      }
    };
    loadIncidents();
  }, []);

  const fetchPersons = useCallback(
    async (isBackground = false) => {
      if (!isBackground) setIsLoading(true);
      else setIsRefreshing(true);

      try {
        const data = await getMissingPersons(
          selectedStatus === 'ALL' ? undefined : selectedStatus,
          searchQuery,
          selectedIncident === 'ALL' ? undefined : selectedIncident
        );
        setPersons(data);
        setLastSyncTime(Date.now());

        // Keep active detail modal updated with fresh data
        setDetailModalPerson((currentDetail) => {
          if (!currentDetail) return null;
          const fresh = data.find((p) => p.id === currentDetail.id);
          return fresh || currentDetail;
        });
      } catch (err) {
        console.error('Failed to load missing persons:', err);
      } finally {
        setIsLoading(false);
        setIsRefreshing(false);
      }
    },
    [selectedStatus, searchQuery, selectedIncident]
  );

  useEffect(() => {
    fetchPersons();
  }, [fetchPersons]);

  // Real-time WebSocket event reaction
  useEffect(() => {
    if (!lastMessage) return;

    const relevantEvents = [
      'NEW_PACKET_INGESTED',
      'MISSING_PERSON_CREATED',
      'MISSING_PERSON_STATUS_UPDATED',
      'MISSING_PERSON_SIGHTING_ADDED',
      'CONNECTED',
    ];

    if (relevantEvents.includes(lastMessage.event)) {
      fetchPersons(true);
    }
  }, [lastMessage, fetchPersons]);

  // Periodic resilient polling every 15 seconds
  useEffect(() => {
    const timer = setInterval(() => {
      fetchPersons(true);
    }, 15000);
    return () => clearInterval(timer);
  }, [fetchPersons]);

  // Clear optimistic alert toast after 4s
  useEffect(() => {
    if (optimisticAlert) {
      const t = setTimeout(() => setOptimisticAlert(null), 4000);
      return () => clearTimeout(t);
    }
  }, [optimisticAlert]);

  // Computed metrics
  const totalCount = persons.length;
  const missingCount = persons.filter((p) => p.status.toUpperCase() !== 'FOUND').length;
  const foundCount = persons.filter((p) => p.status.toUpperCase() === 'FOUND').length;
  const criticalCount = persons.filter(
    (p) =>
      p.priority === 'CRITICAL' ||
      p.age < 12 ||
      p.age > 65 ||
      (p.medical_needs && p.medical_needs.toLowerCase() !== 'none')
  ).length;
  const totalSightings = persons.reduce((acc, p) => acc + (p.sightings?.length || 0), 0);

  // Filter persons by priority locally
  const filteredPersons = persons.filter((p) => {
    if (selectedPriority === 'ALL') return true;
    if (selectedPriority === 'CRITICAL') {
      return (
        p.priority === 'CRITICAL' ||
        p.age < 12 ||
        p.age > 65 ||
        (p.medical_needs && p.medical_needs.toLowerCase() !== 'none')
      );
    }
    if (selectedPriority === 'HIGH') return p.priority === 'HIGH';
    return true;
  });

  // Status toggle handler with optimistic update
  const handleToggleStatus = async (
    person: MissingPerson,
    targetStatus: 'MISSING' | 'FOUND'
  ) => {
    const prevPersons = [...persons];

    setPersons((prev) =>
      prev.map((p) =>
        p.id === person.id
          ? {
              ...p,
              status: targetStatus,
            }
          : p
      )
    );

    if (detailModalPerson && detailModalPerson.id === person.id) {
      setDetailModalPerson((prev) => (prev ? { ...prev, status: targetStatus } : null));
    }

    setOptimisticAlert({
      message: `${person.name} marked as ${
        targetStatus === 'FOUND' ? 'FOUND & REUNITED' : 'ACTIVE MISSING'
      }`,
      type: 'success',
    });

    try {
      await updateMissingPersonStatus(person.id, targetStatus);
      fetchPersons(true);
    } catch (err) {
      console.error('Failed to update person status:', err);
      setPersons(prevPersons);
      setOptimisticAlert({
        message: `Failed to update status for ${person.name}. Reverting change.`,
        type: 'info',
      });
    }
  };

  const formatTimeAgo = (ts: number) => {
    if (!ts) return 'Unknown';
    const diffMs = Date.now() - ts;
    const mins = Math.floor(diffMs / 60000);
    if (mins < 1) return 'Just now';
    if (mins < 60) return `${mins}m ago`;
    const hours = Math.floor(mins / 60);
    if (hours < 24) return `${hours}h ago`;
    const days = Math.floor(hours / 24);
    return `${days}d ago`;
  };

  return (
    <div className="space-y-6">
      {/* Toast Notification */}
      {optimisticAlert && (
        <div className="fixed top-5 right-5 z-50 animate-in fade-in slide-in-from-top-4 duration-300">
          <div className="flex items-center gap-2 px-4 py-3 rounded-xl bg-emerald-600 text-white shadow-xl border border-emerald-500 font-medium text-sm">
            <CheckCircle2 className="w-5 h-5 shrink-0" />
            <span>{optimisticAlert.message}</span>
            <button
              onClick={() => setOptimisticAlert(null)}
              className="ml-2 hover:opacity-80"
              aria-label="Dismiss alert"
            >
              <X className="w-4 h-4" />
            </button>
          </div>
        </div>
      )}

      {/* Page Header */}
      <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
        <div>
          <div className="flex items-center gap-3">
            <div className="p-2.5 bg-[#FFD21F]/15 dark:bg-[#FFD21F]/20 text-[#D97706] dark:text-[#FFD21F] rounded-xl border border-[#FFD21F]/30 shadow-sm">
              <UserSearch className="w-6 h-6" />
            </div>
            <div>
              <div className="flex items-center gap-2.5">
                <h1 className="text-2xl font-bold tracking-tight text-[#16202D] dark:text-[#EEF2F8]">
                  Missing Persons Registry
                </h1>
                {/* Live Real-Time Gateway Uplink Beacon */}
                <div
                  className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold border ${
                    wsStatus === 'connected'
                      ? 'bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border-emerald-500/30'
                      : 'bg-amber-500/10 text-amber-600 dark:text-amber-400 border-amber-500/30'
                  }`}
                  title={`WebSocket Status: ${wsStatus}. Auto-syncs field mesh uploads instantly.`}
                >
                  <span
                    className={`w-2 h-2 rounded-full ${
                      wsStatus === 'connected'
                        ? 'bg-emerald-500 animate-pulse'
                        : 'bg-amber-500'
                    }`}
                  />
                  <span>
                    {wsStatus === 'connected'
                      ? 'Gateway Uplink Live'
                      : 'Gateway Polling'}
                  </span>
                </div>
              </div>
              <p className="text-sm text-[#4E6178] dark:text-[#8E9EB5] mt-0.5">
                Disaster reunification directory, incident correlation, physical identification & Qdrant AI biometric search
              </p>
            </div>
          </div>
        </div>

        {/* Action Buttons */}
        <div className="flex flex-wrap items-center gap-2.5">
          <Button
            variant="outline"
            size="sm"
            onClick={() => fetchPersons(true)}
            className="text-xs flex items-center gap-1.5 border-[#CBD5E1] dark:border-[#334155] text-[#475569] dark:text-[#CBD5E1]"
            title="Force refresh registry records"
          >
            <RefreshCw
              className={`w-3.5 h-3.5 ${isRefreshing ? 'animate-spin text-[#0891B2]' : ''}`}
            />
            <span>{isRefreshing ? 'Syncing...' : 'Sync Gateway'}</span>
          </Button>

          <Button
            onClick={() => {
              setPrefilledMatchPerson(null);
              setIsVisualSearchModalOpen(true);
            }}
            className="bg-[#0891B2] hover:bg-[#0e7490] text-white font-semibold flex items-center gap-2 shadow-sm text-sm"
          >
            <Camera className="w-4 h-4" />
            <span>Match Found Person (Qdrant AI)</span>
          </Button>

          <Button
            onClick={() => setIsReportModalOpen(true)}
            className="bg-[#FFD21F] text-[#0B1220] hover:bg-[#FACC15] font-semibold flex items-center gap-2 shadow-sm text-sm"
          >
            <Plus className="w-4 h-4" />
            <span>Report Missing Person</span>
          </Button>
        </div>
      </div>

      {/* KPI Metrics Strip */}
      <div className="grid grid-cols-2 lg:grid-cols-5 gap-3.5">
        <Card className="p-4 bg-white dark:bg-[#111A2E] border-[#E2E8F0] dark:border-[#1E293B] shadow-sm">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-[#64748B] dark:text-[#94A3B8] uppercase tracking-wider">
              Total Bulletins
            </span>
            <Users className="w-4 h-4 text-[#3B82F6]" />
          </div>
          <div className="mt-2 text-2xl font-bold text-[#0F172A] dark:text-[#F8FAFC]">
            {totalCount}
          </div>
          <span className="text-[11px] text-[#64748B] dark:text-[#94A3B8] block mt-1">
            Registered disaster bulletins
          </span>
        </Card>

        <Card className="p-4 bg-white dark:bg-[#111A2E] border-[#E2E8F0] dark:border-[#1E293B] shadow-sm">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-[#F59E0B] uppercase tracking-wider">
              Active Missing
            </span>
            <AlertCircle className="w-4 h-4 text-[#F59E0B]" />
          </div>
          <div className="mt-2 text-2xl font-bold text-[#F59E0B]">
            {missingCount}
          </div>
          <span className="text-[11px] text-[#64748B] dark:text-[#94A3B8] block mt-1">
            Search parties actively looking
          </span>
        </Card>

        <Card className="p-4 bg-white dark:bg-[#111A2E] border-[#E2E8F0] dark:border-[#1E293B] shadow-sm">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-[#EF4444] uppercase tracking-wider">
              Critical Alerts
            </span>
            <HeartPulse className="w-4 h-4 text-[#EF4444]" />
          </div>
          <div className="mt-2 text-2xl font-bold text-[#EF4444]">
            {criticalCount}
          </div>
          <span className="text-[11px] text-[#64748B] dark:text-[#94A3B8] block mt-1">
            Children, elderly & medical needs
          </span>
        </Card>

        <Card className="p-4 bg-white dark:bg-[#111A2E] border-[#E2E8F0] dark:border-[#1E293B] shadow-sm">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-[#10B981] uppercase tracking-wider">
              Reunited / Found
            </span>
            <CheckCircle2 className="w-4 h-4 text-[#10B981]" />
          </div>
          <div className="mt-2 text-2xl font-bold text-[#10B981]">
            {foundCount}
          </div>
          <span className="text-[11px] text-[#10B981] block mt-1 font-medium">
            {totalCount > 0 ? `${Math.round((foundCount / totalCount) * 100)}% resolution rate` : '0%'}
          </span>
        </Card>

        <Card className="p-4 bg-white dark:bg-[#111A2E] border-[#E2E8F0] dark:border-[#1E293B] shadow-sm col-span-2 lg:col-span-1">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-[#06B6D4] uppercase tracking-wider">
              Sightings Logged
            </span>
            <Eye className="w-4 h-4 text-[#06B6D4]" />
          </div>
          <div className="mt-2 text-2xl font-bold text-[#06B6D4]">
            {totalSightings}
          </div>
          <span className="text-[11px] text-[#64748B] dark:text-[#94A3B8] block mt-1">
            GPS citizen & drone fixes
          </span>
        </Card>
      </div>

      {/* Main Tabs Header */}
      <div className="flex items-center justify-between border-b border-[#E2E8F0] dark:border-[#1E293B]">
        <div className="flex items-center gap-2">
          <button
            onClick={() => setActiveTab('DIRECTORY')}
            className={`flex items-center gap-2 px-4 py-2.5 text-sm font-semibold border-b-2 transition-colors ${
              activeTab === 'DIRECTORY'
                ? 'border-[#FFD21F] text-[#D97706] dark:text-[#FFD21F]'
                : 'border-transparent text-[#64748B] dark:text-[#94A3B8] hover:text-[#0F172A] dark:hover:text-[#F8FAFC]'
            }`}
          >
            <Users className="w-4 h-4" />
            <span>Bulletins Directory ({totalCount})</span>
          </button>

          <button
            onClick={() => setActiveTab('VISUAL_SEARCH')}
            className={`flex items-center gap-2 px-4 py-2.5 text-sm font-semibold border-b-2 transition-colors ${
              activeTab === 'VISUAL_SEARCH'
                ? 'border-[#0891B2] text-[#0891B2] dark:text-[#06B6D4]'
                : 'border-transparent text-[#64748B] dark:text-[#94A3B8] hover:text-[#0F172A] dark:hover:text-[#F8FAFC]'
            }`}
          >
            <Sparkles className="w-4 h-4" />
            <span>Visual Biometric Matcher (Qdrant AI)</span>
          </button>
        </div>

        <div className="text-xs text-[#64748B] dark:text-[#94A3B8] hidden sm:block">
          Uplink synced: {formatTimeAgo(lastSyncTime)}
        </div>
      </div>

      {/* ===================================================================== */}
      {/* TAB 1: BULLETINS DIRECTORY */}
      {/* ===================================================================== */}
      {activeTab === 'DIRECTORY' && (
        <div className="space-y-5">
          {/* Advanced Search & Incident Filter Controls */}
          <Card className="p-4 bg-white dark:bg-[#111A2E] border-[#E2E8F0] dark:border-[#1E293B] shadow-sm">
            <div className="flex flex-col lg:flex-row gap-3 items-stretch lg:items-center justify-between">
              {/* Search Box */}
              <div className="relative flex-1">
                <Search className="w-4 h-4 absolute left-3 top-1/2 transform -translate-y-1/2 text-[#94A3B8]" />
                <input
                  type="text"
                  placeholder="Search by name, clothing, marks, medical needs, location..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="w-full pl-9 pr-4 py-2 text-sm rounded-lg bg-[#F8FAFC] dark:bg-[#0B1220] border border-[#CBD5E1] dark:border-[#1E293B] text-[#0F172A] dark:text-[#F8FAFC] placeholder-[#94A3B8] focus:outline-none focus:ring-2 focus:ring-[#FFD21F]"
                />
              </div>

              {/* Incident Dropdown Filter */}
              <div className="flex items-center gap-2">
                <select
                  value={selectedIncident}
                  onChange={(e) => setSelectedIncident(e.target.value)}
                  className="px-3 py-2 text-xs font-semibold rounded-lg bg-[#F8FAFC] dark:bg-[#0B1220] border border-[#CBD5E1] dark:border-[#1E293B] text-[#0F172A] dark:text-[#F8FAFC] focus:outline-none focus:ring-2 focus:ring-[#FFD21F]"
                >
                  <option value="ALL">All Disaster Incidents</option>
                  {availableIncidents.map((inc) => {
                    const rawTitle = inc.title || inc.id || 'Incident';
                    const displayTitle = rawTitle.length > 32 ? `${rawTitle.slice(0, 32)}...` : rawTitle;
                    return (
                      <option key={inc.id} value={inc.id}>
                        {inc.id}: {displayTitle}
                      </option>
                    );
                  })}
                </select>

                {/* Priority Filter */}
                <select
                  value={selectedPriority}
                  onChange={(e) => setSelectedPriority(e.target.value)}
                  className="px-3 py-2 text-xs font-semibold rounded-lg bg-[#F8FAFC] dark:bg-[#0B1220] border border-[#CBD5E1] dark:border-[#1E293B] text-[#0F172A] dark:text-[#F8FAFC] focus:outline-none focus:ring-2 focus:ring-[#FFD21F]"
                >
                  <option value="ALL">All Priorities</option>
                  <option value="CRITICAL">🚨 Critical (Urgent / Medical)</option>
                  <option value="HIGH">High Priority</option>
                </select>
              </div>

              {/* Status Filter Pills */}
              <div className="flex items-center gap-1.5 shrink-0">
                {(['ALL', 'MISSING', 'FOUND'] as MissingPersonStatusFilter[]).map((st) => (
                  <button
                    key={st}
                    onClick={() => setSelectedStatus(st)}
                    className={`px-3 py-1.5 rounded-full text-xs font-semibold transition-colors ${
                      selectedStatus === st
                        ? 'bg-[#FFD21F] text-[#0B1220] shadow-sm'
                        : 'bg-[#F1F5F9] dark:bg-[#1E293B] text-[#64748B] dark:text-[#94A3B8] hover:bg-[#E2E8F0] dark:hover:bg-[#334155]'
                    }`}
                  >
                    {st === 'ALL'
                      ? `All (${totalCount})`
                      : st === 'MISSING'
                      ? `Active (${missingCount})`
                      : `Found (${foundCount})`}
                  </button>
                ))}
              </div>
            </div>
          </Card>

          {/* Cards Grid */}
          {isLoading ? (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
              {[1, 2, 3, 4, 5, 6].map((i) => (
                <div
                  key={i}
                  className="h-80 rounded-2xl bg-gray-200 dark:bg-gray-800 animate-pulse"
                />
              ))}
            </div>
          ) : filteredPersons.length === 0 ? (
            <Card className="p-12 text-center bg-white dark:bg-[#111A2E] border-[#E2E8F0] dark:border-[#1E293B]">
              <div className="mx-auto w-12 h-12 rounded-full bg-[#FFD21F]/15 flex items-center justify-center text-[#D97706] mb-4">
                <UserSearch className="w-6 h-6" />
              </div>
              <h3 className="text-lg font-semibold text-[#0F172A] dark:text-[#F8FAFC]">
                No Matching Missing Persons
              </h3>
              <p className="text-sm text-[#64748B] dark:text-[#94A3B8] max-w-sm mx-auto mt-1 mb-4">
                No reports found matching the selected filters. Reports submitted from field
                mobiles over mesh or cloud will appear here automatically.
              </p>
              <div className="flex items-center justify-center gap-3">
                <Button
                  onClick={() => setIsReportModalOpen(true)}
                  className="bg-[#FFD21F] text-[#0B1220] hover:bg-[#FACC15] font-semibold"
                >
                  Create New Report
                </Button>
                <Button
                  variant="outline"
                  onClick={() => setIsVisualSearchModalOpen(true)}
                  className="text-[#0891B2] border-[#0891B2]/40"
                >
                  Scan Photo with AI
                </Button>
              </div>
            </Card>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
              {filteredPersons.map((person) => {
                const isFound = person.status.toUpperCase() === 'FOUND';
                const isCritical =
                  person.priority === 'CRITICAL' ||
                  person.age < 12 ||
                  person.age > 65 ||
                  (person.medical_needs && person.medical_needs.toLowerCase() !== 'none');
                const resolvedUrl = resolvePhotoUrl(person.photo_url);

                return (
                  <Card
                    key={person.id}
                    className={`overflow-hidden transition-all duration-200 hover:shadow-lg flex flex-col bg-white dark:bg-[#111A2E] border ${
                      isFound
                        ? 'border-emerald-500/40 dark:border-emerald-500/40'
                        : isCritical
                        ? 'border-rose-500/40 dark:border-rose-500/40 ring-1 ring-rose-500/20'
                        : 'border-[#E2E8F0] dark:border-[#1E293B]'
                    }`}
                  >
                    {/* 1. TOP INCIDENT & STATUS BAR */}
                    <div className="px-4 py-2.5 bg-slate-50 dark:bg-[#0B1220]/80 border-b border-slate-100 dark:border-[#1E293B] flex items-center justify-between gap-2">
                      {/* Linked Incident Badge */}
                      {person.incident_id ? (
                        <Link
                          to={`/app/incidents`}
                          className="flex items-center gap-1.5 text-xs font-semibold text-slate-700 dark:text-slate-300 hover:text-amber-600 dark:hover:text-amber-400 truncate max-w-[200px]"
                          title={`Linked to Incident ${person.incident_id}: ${person.incident_title || 'Disaster Zone'}`}
                        >
                          {getDisasterIcon(person.incident_title || '')}
                          <span className="truncate">{person.incident_title || person.incident_id}</span>
                        </Link>
                      ) : (
                        <span className="flex items-center gap-1 text-[11px] font-medium text-slate-500 dark:text-slate-400">
                          <MapPin className="w-3 h-3 text-amber-500" />
                          <span>Sector Disaster Zone</span>
                        </span>
                      )}

                      {/* Status & Priority Badges */}
                      <div className="flex items-center gap-1.5 shrink-0">
                        {isCritical && !isFound && (
                          <span className="px-2 py-0.5 rounded text-[10px] font-bold bg-rose-500/15 text-rose-600 dark:text-rose-400 border border-rose-500/30">
                            CRITICAL
                          </span>
                        )}
                        <span
                          className={`text-[11px] px-2.5 py-0.5 rounded-full uppercase tracking-wider font-bold border ${
                            isFound
                              ? 'bg-emerald-500/15 text-emerald-600 dark:text-emerald-400 border-emerald-500/30'
                              : 'bg-amber-500/15 text-amber-600 dark:text-amber-400 border-amber-500/30'
                          }`}
                        >
                          {isFound ? 'FOUND' : 'MISSING'}
                        </span>
                      </div>
                    </div>

                    {/* 2. PHOTO & HERO IDENTIFICATION SHOWCASE */}
                    <div className="relative w-full h-48 bg-slate-900 overflow-hidden group">
                      {resolvedUrl ? (
                        <>
                          <img
                            src={resolvedUrl}
                            alt={person.name}
                            className="w-full h-full object-cover object-center group-hover:scale-105 transition-transform duration-300"
                            loading="lazy"
                          />
                          {/* Dark bottom gradient overlay */}
                          <div className="absolute inset-0 bg-gradient-to-t from-black/85 via-black/30 to-transparent pointer-events-none" />

                          {/* Top-Right Inspect Button */}
                          <button
                            type="button"
                            onClick={() => setLightboxPerson(person)}
                            className="absolute top-2.5 right-2.5 p-1.5 rounded-lg bg-black/60 text-white hover:bg-black/80 transition-colors shadow-sm"
                            title="Inspect Photo & Biometrics"
                          >
                            <Maximize2 className="w-3.5 h-3.5" />
                          </button>

                          {/* Bottom-Left Vector Status */}
                          <div className="absolute bottom-2.5 left-3 flex items-center gap-1.5 px-2 py-1 rounded-md bg-black/70 backdrop-blur-sm border border-white/20 text-[10px] font-mono text-cyan-300">
                            <Sparkles className="w-3 h-3 text-cyan-400" />
                            <span>Qdrant 512-D Indexed</span>
                          </div>
                        </>
                      ) : (
                        <div className="w-full h-full flex flex-col items-center justify-center p-4 bg-gradient-to-br from-slate-800 to-slate-900 text-slate-400">
                          <User className="w-12 h-12 text-slate-500 mb-2" />
                          <span className="text-xs font-semibold text-slate-300">No Photo Registered</span>
                          <button
                            onClick={() => {
                              setPrefilledMatchPerson(person);
                              setIsVisualSearchModalOpen(true);
                            }}
                            className="mt-2 text-[11px] px-3 py-1 rounded bg-[#0891B2]/30 hover:bg-[#0891B2]/50 text-cyan-300 border border-cyan-500/30 font-medium transition-colors"
                          >
                            + Attach Photo to Index
                          </button>
                        </div>
                      )}
                    </div>

                    {/* 3. CORE IDENTITY & PHYSICAL ATTRIBUTES (FOR EXACT DETECTION) */}
                    <div className="p-4 flex-1 flex flex-col justify-between space-y-3.5">
                      <div>
                        {/* Name, Age, Gender & Blood Group */}
                        <div className="flex items-start justify-between gap-2">
                          <div>
                            <h3 className="font-bold text-lg text-slate-900 dark:text-white leading-tight">
                              {person.name}
                            </h3>
                            <div className="flex flex-wrap items-center gap-1.5 text-xs text-slate-500 dark:text-slate-400 mt-1">
                              <span className="font-semibold text-slate-700 dark:text-slate-300">
                                {person.age} yrs
                              </span>
                              <span>•</span>
                              <span>{person.gender}</span>
                              {person.blood_group && (
                                <>
                                  <span>•</span>
                                  <span className="font-mono text-rose-600 dark:text-rose-400 font-bold">
                                    {person.blood_group}
                                  </span>
                                </>
                              )}
                              {person.height_cm ? (
                                <>
                                  <span>•</span>
                                  <span>{person.height_cm} cm</span>
                                </>
                              ) : null}
                            </div>
                          </div>

                          {/* Fast Status Toggle Link */}
                          <button
                            onClick={() =>
                              handleToggleStatus(
                                person,
                                isFound ? 'MISSING' : 'FOUND'
                              )
                            }
                            className={`text-xs font-semibold underline shrink-0 transition-colors ${
                              isFound
                                ? 'text-amber-600 dark:text-amber-400 hover:text-amber-700'
                                : 'text-emerald-600 dark:text-emerald-400 hover:text-emerald-700'
                            }`}
                          >
                            {isFound ? 'Set Missing' : 'Set Found'}
                          </button>
                        </div>

                        {/* PHYSICAL PROFILE GRID (CRUCIAL RELEVANT DATA FOR IDENTIFICATION) */}
                        <div className="mt-3 p-2.5 rounded-xl bg-slate-50 dark:bg-[#0B1220] border border-slate-200/80 dark:border-[#1E293B] space-y-2 text-xs">
                          {/* Clothing Last Seen */}
                          {person.clothing_last_seen && (
                            <div className="flex items-start gap-2">
                              <Shirt className="w-3.5 h-3.5 text-amber-500 shrink-0 mt-0.5" />
                              <span className="text-slate-700 dark:text-slate-300 leading-snug">
                                <strong className="text-slate-900 dark:text-white font-semibold">Wearing: </strong>
                                {person.clothing_last_seen}
                              </span>
                            </div>
                          )}

                          {/* Identifying Marks */}
                          {person.identifying_marks && (
                            <div className="flex items-start gap-2">
                              <Tag className="w-3.5 h-3.5 text-cyan-500 shrink-0 mt-0.5" />
                              <span className="text-slate-700 dark:text-slate-300 leading-snug">
                                <strong className="text-slate-900 dark:text-white font-semibold">Features: </strong>
                                {person.identifying_marks}
                              </span>
                            </div>
                          )}

                          {/* Medical Alerts */}
                          {person.medical_needs && person.medical_needs.toLowerCase() !== 'none' && (
                            <div className="flex items-start gap-2 p-1.5 rounded-lg bg-rose-50 dark:bg-rose-950/30 border border-rose-200 dark:border-rose-900/40 text-rose-700 dark:text-rose-300 font-medium">
                              <Stethoscope className="w-3.5 h-3.5 text-rose-500 shrink-0 mt-0.5" />
                              <span>
                                <strong>Medical: </strong>
                                {person.medical_needs}
                              </span>
                            </div>
                          )}
                        </div>

                        {/* Last Seen Location */}
                        <div className="mt-3 flex items-start gap-2 text-xs text-slate-700 dark:text-slate-300">
                          <MapPin className="w-4 h-4 text-amber-500 shrink-0 mt-0.5" />
                          <div>
                            <span className="font-semibold text-slate-900 dark:text-white">
                              {person.last_seen_location}
                            </span>
                            {person.lat && person.lng && (
                              <div className="flex items-center gap-1.5 mt-0.5 font-mono text-[11px] text-cyan-600 dark:text-cyan-400">
                                <span>[{person.lat.toFixed(4)}, {person.lng.toFixed(4)}]</span>
                                <a
                                  href={`https://www.google.com/maps/search/?api=1&query=${person.lat},${person.lng}`}
                                  target="_blank"
                                  rel="noreferrer"
                                  className="text-slate-400 hover:text-cyan-500 inline-flex items-center ml-1"
                                  title="View on Google Maps"
                                >
                                  <ExternalLink className="w-3 h-3" />
                                </a>
                              </div>
                            )}
                          </div>
                        </div>

                        {/* Assigned Search Team */}
                        {person.assigned_team && (
                          <div className="mt-2.5 flex items-center gap-1.5 text-xs text-slate-600 dark:text-slate-400">
                            <Navigation className="w-3.5 h-3.5 text-blue-500 shrink-0" />
                            <span>Assigned: <strong className="text-slate-800 dark:text-slate-200 font-semibold">{person.assigned_team}</strong></span>
                          </div>
                        )}

                        {/* Citizen Sightings Badge */}
                        <div className="mt-3">
                          {person.sightings && person.sightings.length > 0 ? (
                            <div className="p-2 rounded-lg bg-cyan-50 dark:bg-cyan-950/30 border border-cyan-200 dark:border-cyan-900/40 flex items-center justify-between text-xs">
                              <div className="flex items-center gap-1.5 text-cyan-700 dark:text-cyan-300 font-semibold">
                                <Eye className="w-3.5 h-3.5 text-cyan-600 dark:text-cyan-400" />
                                <span>{person.sightings.length} Field Sighting{person.sightings.length > 1 ? 's' : ''} logged</span>
                              </div>
                              <button
                                onClick={() => setDetailModalPerson(person)}
                                className="text-[11px] font-bold text-cyan-600 dark:text-cyan-400 hover:underline"
                              >
                                View Clues →
                              </button>
                            </div>
                          ) : (
                            <div className="p-1.5 rounded-lg bg-slate-50 dark:bg-[#0B1220] border border-slate-200 dark:border-[#1E293B] text-[11px] text-slate-400 text-center">
                              No citizen sightings recorded yet
                            </div>
                          )}
                        </div>
                      </div>

                      {/* 4. ACTIONS FOOTER */}
                      <div className="pt-3 border-t border-slate-100 dark:border-[#1E293B] flex items-center gap-2">
                        {/* 1-Click Biometric Match Button */}
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => {
                            setPrefilledMatchPerson(person);
                            setIsVisualSearchModalOpen(true);
                          }}
                          className="text-xs flex items-center gap-1 border-cyan-500/40 text-cyan-600 dark:text-cyan-400 hover:bg-cyan-500/10"
                          title="Match facial features with field found persons in Qdrant AI"
                        >
                          <Camera className="w-3.5 h-3.5" />
                          <span>Match AI</span>
                        </Button>

                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => setSightingModalPerson(person)}
                          className="text-xs text-amber-600 dark:text-amber-400 border-amber-500/40 hover:bg-amber-500/10"
                          title="Record new sighting coordinates"
                        >
                          + Sighting
                        </Button>

                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => setDetailModalPerson(person)}
                          className="text-xs flex-1 text-slate-700 dark:text-slate-300"
                        >
                          Dossier
                        </Button>

                        {!isFound ? (
                          <Button
                            size="sm"
                            onClick={() => handleToggleStatus(person, 'FOUND')}
                            className="text-xs bg-emerald-600 hover:bg-emerald-700 text-white font-semibold"
                          >
                            Mark Found
                          </Button>
                        ) : (
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => handleToggleStatus(person, 'MISSING')}
                            className="text-xs text-amber-600 dark:text-amber-400 border-amber-500/40 hover:bg-amber-500/10"
                          >
                            Reopen
                          </Button>
                        )}
                      </div>
                    </div>
                  </Card>
                );
              })}
            </div>
          )}
        </div>
      )}

      {/* ===================================================================== */}
      {/* TAB 2: VISUAL BIOMETRIC MATCHER (QDRANT CLOUD AI) */}
      {/* ===================================================================== */}
      {activeTab === 'VISUAL_SEARCH' && (
        <Card className="p-6 bg-white dark:bg-[#111A2E] border-[#E2E8F0] dark:border-[#1E293B]">
          <VisualRecognitionPanel
            prefilledPerson={prefilledMatchPerson}
            onConfirmIdentification={(matchedPerson) => {
              handleToggleStatus(matchedPerson, 'FOUND');
            }}
          />
        </Card>
      )}

      {/* ===================================================================== */}
      {/* MODALS */}
      {/* ===================================================================== */}

      {/* Modal: Report Missing Person */}
      {isReportModalOpen && (
        <ReportMissingModal
          availableIncidents={availableIncidents}
          onClose={() => setIsReportModalOpen(false)}
          onSuccess={() => {
            setIsReportModalOpen(false);
            fetchPersons();
            setOptimisticAlert({
              message: 'Missing person bulletin registered with full physical profile and indexed into Qdrant AI.',
              type: 'success',
            });
          }}
        />
      )}

      {/* Modal: Visual Recognition Match Found Person */}
      {isVisualSearchModalOpen && (
        <VisualRecognitionModal
          prefilledPerson={prefilledMatchPerson}
          onClose={() => {
            setIsVisualSearchModalOpen(false);
            setPrefilledMatchPerson(null);
          }}
          onConfirmIdentification={(matchedPerson) => {
            handleToggleStatus(matchedPerson, 'FOUND');
            setIsVisualSearchModalOpen(false);
            setPrefilledMatchPerson(null);
          }}
        />
      )}

      {/* Modal: Record Sighting */}
      {sightingModalPerson && (
        <RecordSightingModal
          person={sightingModalPerson}
          onClose={() => setSightingModalPerson(null)}
          onSuccess={() => {
            setSightingModalPerson(null);
            fetchPersons();
            setOptimisticAlert({
              message: `Citizen sighting recorded for ${sightingModalPerson.name}.`,
              type: 'success',
            });
          }}
        />
      )}

      {/* Modal: Person Detail Dossier */}
      {detailModalPerson && (
        <PersonDetailModal
          person={detailModalPerson}
          onClose={() => setDetailModalPerson(null)}
          onAddSighting={() => {
            const p = detailModalPerson;
            setDetailModalPerson(null);
            setSightingModalPerson(p);
          }}
          onToggleStatus={(nextStatus) => {
            handleToggleStatus(detailModalPerson, nextStatus);
          }}
          onInspectPhoto={() => {
            setLightboxPerson(detailModalPerson);
          }}
        />
      )}

      {/* Modal: Photo Lightbox & Biometric Inspector */}
      {lightboxPerson && (
        <PhotoLightboxModal
          person={lightboxPerson}
          onClose={() => setLightboxPerson(null)}
          onMatchPhoto={() => {
            const p = lightboxPerson;
            setLightboxPerson(null);
            setPrefilledMatchPerson(p);
            setIsVisualSearchModalOpen(true);
          }}
        />
      )}
    </div>
  );
};

// =============================================================================
// PHOTO LIGHTBOX & BIOMETRIC INSPECTOR MODAL
// =============================================================================

interface PhotoLightboxModalProps {
  person: MissingPerson;
  onClose: () => void;
  onMatchPhoto: () => void;
}

const PhotoLightboxModal: React.FC<PhotoLightboxModalProps> = ({
  person,
  onClose,
  onMatchPhoto,
}) => {
  const resolvedUrl = resolvePhotoUrl(person.photo_url);

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-md animate-in fade-in">
      <div className="w-full max-w-3xl bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden shadow-2xl flex flex-col max-h-[90vh]">
        {/* Header */}
        <div className="flex items-center justify-between p-4 border-b border-slate-800">
          <div className="flex items-center gap-2.5">
            <Sparkles className="w-5 h-5 text-cyan-400" />
            <div>
              <h2 className="text-base font-bold text-white">
                Biometric Identification Dossier: {person.name}
              </h2>
              <p className="text-xs text-slate-400">
                High-Resolution Visual Verification & Qdrant 512-D Feature Embeddings
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-1 rounded-lg text-slate-400 hover:text-white transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Content */}
        <div className="p-6 grid grid-cols-1 md:grid-cols-2 gap-6 overflow-y-auto">
          {/* Large Photo Preview */}
          <div className="relative rounded-xl overflow-hidden bg-black flex items-center justify-center min-h-[300px]">
            {resolvedUrl ? (
              <img
                src={resolvedUrl}
                alt={person.name}
                className="w-full h-full object-contain max-h-[400px]"
              />
            ) : (
              <User className="w-24 h-24 text-slate-700" />
            )}
          </div>

          {/* Details & Vector Specs */}
          <div className="space-y-4 text-xs">
            <div className="p-3 rounded-xl bg-slate-800/60 border border-slate-700/60 space-y-1.5">
              <div className="flex justify-between">
                <span className="text-slate-400">Status:</span>
                <span className={`font-bold ${person.status === 'FOUND' ? 'text-emerald-400' : 'text-amber-400'}`}>
                  {person.status}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-400">Age & Gender:</span>
                <span className="text-white font-medium">{person.age} yrs • {person.gender}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-400">Blood Group:</span>
                <span className="text-rose-400 font-bold">{person.blood_group || 'Unspecified'}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-400">Height:</span>
                <span className="text-white">{person.height_cm ? `${person.height_cm} cm` : 'Not recorded'}</span>
              </div>
            </div>

            <div className="p-3 rounded-xl bg-slate-800/60 border border-slate-700/60 space-y-2">
              <div>
                <strong className="text-cyan-400 block mb-0.5">Clothing Worn:</strong>
                <p className="text-slate-200">{person.clothing_last_seen || 'No clothing description logged'}</p>
              </div>
              <div>
                <strong className="text-cyan-400 block mb-0.5">Distinguishing Features:</strong>
                <p className="text-slate-200">{person.identifying_marks || 'No scars or marks recorded'}</p>
              </div>
              <div>
                <strong className="text-rose-400 block mb-0.5">Medical Vulnerabilities:</strong>
                <p className="text-rose-300 font-medium">{person.medical_needs || 'None'}</p>
              </div>
            </div>

            <div className="p-3 rounded-xl bg-cyan-950/40 border border-cyan-800/40 text-cyan-300">
              <div className="flex items-center gap-1.5 font-bold mb-1">
                <Sparkles className="w-4 h-4 text-cyan-400" />
                <span>Qdrant Cloud Vector Search Active</span>
              </div>
              <p className="text-[11px] text-cyan-200/80 leading-relaxed">
                512-dimensional HSV color moments and gradient orientation vectors indexed. Can be cross-matched against drone photos and field smartphone captures.
              </p>
            </div>
          </div>
        </div>

        {/* Footer */}
        <div className="p-4 border-t border-slate-800 flex items-center justify-between">
          <Button variant="outline" size="sm" onClick={onClose} className="text-slate-300 border-slate-700">
            Close
          </Button>
          <Button
            size="sm"
            onClick={onMatchPhoto}
            className="bg-[#0891B2] hover:bg-[#0e7490] text-white font-semibold flex items-center gap-2"
          >
            <Camera className="w-4 h-4" />
            <span>Search Qdrant Database with Photo</span>
          </Button>
        </div>
      </div>
    </div>
  );
};

// =============================================================================
// VISUAL RECOGNITION PANEL / MODAL COMPONENTS
// =============================================================================

interface VisualRecognitionProps {
  prefilledPerson?: MissingPerson | null;
  onConfirmIdentification: (person: MissingPerson) => void;
  onClose?: () => void;
}

export const VisualRecognitionPanel: React.FC<VisualRecognitionProps> = ({
  prefilledPerson,
  onConfirmIdentification,
  onClose,
}) => {
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [isScanning, setIsScanning] = useState(false);
  const [searchResult, setSearchResult] = useState<VisualSearchResult | null>(null);
  const [searchError, setSearchError] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  // If prefilled with a missing person with photo, set preview
  useEffect(() => {
    if (prefilledPerson?.photo_url) {
      setPreviewUrl(resolvePhotoUrl(prefilledPerson.photo_url) || null);
    }
  }, [prefilledPerson]);

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      const file = e.target.files[0];
      setSelectedFile(file);
      setSearchResult(null);
      setSearchError(null);

      const reader = new FileReader();
      reader.onload = () => {
        setPreviewUrl(reader.result as string);
      };
      reader.readAsDataURL(file);
    }
  };

  const handleScan = async () => {
    if (!selectedFile && !prefilledPerson?.photo_url) return;
    setIsScanning(true);
    setSearchError(null);

    try {
      let fileToScan = selectedFile;
      if (!fileToScan && prefilledPerson?.photo_url) {
        // Fetch remote photo as blob
        const res = await fetch(resolvePhotoUrl(prefilledPerson.photo_url)!);
        const blob = await res.blob();
        fileToScan = new File([blob], 'query.jpg', { type: blob.type || 'image/jpeg' });
      }

      if (fileToScan) {
        const result = await searchMissingPersonByPhoto(fileToScan);
        setSearchResult(result);
      }
    } catch (err: unknown) {
      console.error('Visual recognition scan failed:', err);
      setSearchError(
        'Failed to process visual biometrics search. Please check your image format or connection.'
      );
    } finally {
      setIsScanning(false);
    }
  };

  const handleReset = () => {
    setSelectedFile(null);
    setPreviewUrl(null);
    setSearchResult(null);
    setSearchError(null);
    if (fileInputRef.current) {
      fileInputRef.current.value = '';
    }
  };

  return (
    <div className="space-y-6">
      {/* Description Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-4 border-b border-[#E2E8F0] dark:border-[#1E293B]">
        <div className="flex items-center gap-2.5">
          <div className="p-2 bg-[#0891B2]/15 text-[#0891B2] dark:text-[#06B6D4] rounded-lg">
            <Camera className="w-5 h-5" />
          </div>
          <div>
            <h2 className="text-base font-bold text-[#0F172A] dark:text-[#F8FAFC]">
              Visual Biometric Matcher (Qdrant Cloud)
            </h2>
            <p className="text-xs text-[#64748B] dark:text-[#94A3B8]">
              Upload a photograph of an unidentified survivor, rescued child, or drone face crop to run instant 512-D vector cosine matching
            </p>
          </div>
        </div>
        {onClose && (
          <button
            onClick={onClose}
            className="text-[#94A3B8] hover:text-[#0F172A] dark:hover:text-[#F8FAFC]"
          >
            <X className="w-5 h-5" />
          </button>
        )}
      </div>

      {/* Upload & Dropzone Area */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div>
          <label className="block text-xs font-semibold text-[#475569] dark:text-[#CBD5E1] mb-2">
            Field Photograph / Drone Crop
          </label>

          <input
            type="file"
            ref={fileInputRef}
            onChange={handleFileChange}
            accept="image/*"
            className="hidden"
          />

          {!previewUrl ? (
            <div
              onClick={() => fileInputRef.current?.click()}
              className="border-2 border-dashed border-[#CBD5E1] dark:border-[#334155] rounded-xl p-8 flex flex-col items-center justify-center gap-3 cursor-pointer hover:border-[#0891B2] dark:hover:border-[#0891B2] bg-[#F8FAFC] dark:bg-[#0B1220] transition-colors"
            >
              <div className="w-12 h-12 rounded-full bg-[#0891B2]/10 flex items-center justify-center text-[#0891B2]">
                <UploadCloud className="w-6 h-6" />
              </div>
              <div className="text-center">
                <span className="text-sm font-semibold text-[#0F172A] dark:text-[#F8FAFC] block">
                  Click to select field photo
                </span>
                <span className="text-xs text-[#64748B] dark:text-[#94A3B8]">
                  JPEG, PNG, WebP up to 10MB
                </span>
              </div>
            </div>
          ) : (
            <div className="relative rounded-xl overflow-hidden border border-[#E2E8F0] dark:border-[#1E293B] bg-slate-900 group">
              <img
                src={previewUrl}
                alt="Query Preview"
                className="w-full h-64 object-contain"
              />
              <button
                type="button"
                onClick={handleReset}
                className="absolute top-2 right-2 p-1.5 rounded-full bg-black/60 text-white hover:bg-black/80 transition-colors"
                title="Remove photo"
              >
                <X className="w-4 h-4" />
              </button>
            </div>
          )}

          <div className="mt-4 flex items-center gap-3">
            <Button
              onClick={handleScan}
              disabled={(!selectedFile && !prefilledPerson?.photo_url) || isScanning}
              className="bg-[#0891B2] hover:bg-[#0e7490] text-white font-semibold flex items-center gap-2 text-sm flex-1"
            >
              <Scan className={`w-4 h-4 ${isScanning ? 'animate-spin' : ''}`} />
              <span>{isScanning ? 'Extracting 512-D Vectors...' : 'Run Qdrant Vector Match'}</span>
            </Button>

            {previewUrl && (
              <Button
                variant="outline"
                size="sm"
                onClick={handleReset}
                className="text-xs border-[#CBD5E1] dark:border-[#334155]"
              >
                Reset
              </Button>
            )}
          </div>
        </div>

        {/* Results / Live Radar Scanner Display */}
        <div className="flex flex-col justify-between">
          <label className="block text-xs font-semibold text-[#475569] dark:text-[#CBD5E1] mb-2">
            Biometric Match Results
          </label>

          {isScanning ? (
            <div className="h-64 rounded-xl border border-cyan-500/30 bg-cyan-950/20 flex flex-col items-center justify-center p-6 text-center space-y-3">
              <div className="relative w-16 h-16">
                <div className="absolute inset-0 rounded-full border-2 border-cyan-400 animate-ping opacity-75" />
                <div className="w-16 h-16 rounded-full bg-cyan-500/20 border border-cyan-400 flex items-center justify-center text-cyan-300">
                  <Sparkles className="w-6 h-6 animate-pulse" />
                </div>
              </div>
              <div>
                <strong className="text-sm font-bold text-white block">
                  Scanning Qdrant Cloud Vector Index
                </strong>
                <p className="text-xs text-cyan-300/80">
                  Calculating cosine distance across spatial moments & gradient orientations...
                </p>
              </div>
            </div>
          ) : searchError ? (
            <div className="p-4 rounded-xl bg-rose-50 dark:bg-rose-950/30 border border-rose-200 dark:border-rose-900/40 text-rose-700 dark:text-rose-300 text-xs">
              <AlertCircle className="w-5 h-5 text-rose-500 mb-1" />
              <span>{searchError}</span>
            </div>
          ) : searchResult ? (
            <div className="space-y-3">
              {searchResult.match_found && searchResult.matches.length > 0 ? (
                <>
                  <div className="p-2.5 rounded-lg bg-emerald-500/10 border border-emerald-500/30 flex items-center justify-between text-xs text-emerald-600 dark:text-emerald-400 font-bold">
                    <span>MATCH IDENTIFIED ({searchResult.matches.length} Candidates Found)</span>
                    <span>Top Similarity: {Math.round(searchResult.matches[0].similarity_score * 100)}%</span>
                  </div>

                  <div className="space-y-2.5 max-h-72 overflow-y-auto pr-1">
                    {searchResult.matches.map((match, idx) => (
                      <div
                        key={idx}
                        className="p-3 rounded-xl border border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-slate-900 flex items-center justify-between gap-3"
                      >
                        <div className="flex items-center gap-3">
                          <PersonAvatar
                            photoUrl={match.person.photo_url}
                            name={match.person.name}
                            size="md"
                          />
                          <div>
                            <strong className="text-sm font-bold text-slate-900 dark:text-white block">
                              {match.person.name}
                            </strong>
                            <span className="text-xs text-slate-500">
                              {match.person.age} yrs • {match.person.gender} • {match.person.last_seen_location}
                            </span>
                          </div>
                        </div>

                        <div className="flex flex-col items-end gap-1.5 shrink-0">
                          <span className="text-xs font-mono font-bold text-cyan-600 dark:text-cyan-400">
                            {Math.round(match.similarity_score * 100)}% Match
                          </span>
                          <Button
                            size="sm"
                            onClick={() => onConfirmIdentification(match.person)}
                            className="text-xs bg-emerald-600 hover:bg-emerald-700 text-white font-semibold py-1 px-2.5"
                          >
                            Confirm Found
                          </Button>
                        </div>
                      </div>
                    ))}
                  </div>
                </>
              ) : (
                <div className="p-6 text-center rounded-xl border border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-slate-900 text-slate-400">
                  <UserSearch className="w-8 h-8 mx-auto mb-2 opacity-50" />
                  <span className="text-sm font-semibold block text-slate-300">No Vector Match Found</span>
                  <p className="text-xs mt-1">
                    The query photo did not exceed the 65% cosine similarity threshold against registered records.
                  </p>
                </div>
              )}
            </div>
          ) : (
            <div className="p-6 text-center rounded-xl border border-dashed border-slate-200 dark:border-slate-800 bg-slate-50/50 dark:bg-slate-900/50 text-slate-400 text-xs">
              <Camera className="w-8 h-8 mx-auto mb-2 opacity-40 text-cyan-400" />
              <span>Select an image above and run match to compare against registered missing individuals.</span>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export const VisualRecognitionModal: React.FC<
  VisualRecognitionProps & { onClose: () => void }
> = ({ prefilledPerson, onConfirmIdentification, onClose }) => {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-in fade-in">
      <div className="w-full max-w-2xl bg-white dark:bg-[#111A2E] rounded-2xl shadow-2xl border border-[#E2E8F0] dark:border-[#1E293B] overflow-hidden p-6 max-h-[90vh] overflow-y-auto">
        <VisualRecognitionPanel
          prefilledPerson={prefilledPerson}
          onConfirmIdentification={onConfirmIdentification}
          onClose={onClose}
        />
      </div>
    </div>
  );
};

// =============================================================================
// REPORT MISSING PERSON MODAL (WITH INCIDENT & IDENTIFICATION FIELDS)
// =============================================================================

interface ReportMissingModalProps {
  availableIncidents: { id: string; title: string; disaster_type?: string }[];
  onClose: () => void;
  onSuccess: () => void;
}

const ReportMissingModal: React.FC<ReportMissingModalProps> = ({
  availableIncidents,
  onClose,
  onSuccess,
}) => {
  const [name, setName] = useState('');
  const [age, setAge] = useState<number | ''>('');
  const [gender, setGender] = useState('Male');
  const [bloodGroup, setBloodGroup] = useState('O+');
  const [incidentId, setIncidentId] = useState(availableIncidents[0]?.id || 'INC-FLD-2026-001');
  const [priority, setPriority] = useState('HIGH');
  const [lastSeenLocation, setLastSeenLocation] = useState('');
  const [clothingLastSeen, setClothingLastSeen] = useState('');
  const [heightCm, setHeightCm] = useState<number | ''>('');
  const [identifyingMarks, setIdentifyingMarks] = useState('');
  const [medicalNeeds, setMedicalNeeds] = useState('');
  const [assignedTeam, setAssignedTeam] = useState('');
  const [lat, setLat] = useState<string>('13.0827');
  const [lng, setLng] = useState<string>('80.2707');
  const [description, setDescription] = useState('');
  const [contactPhone, setContactPhone] = useState('');
  const [photoUrl, setPhotoUrl] = useState('');
  const [photoBase64, setPhotoBase64] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name || age === '' || !lastSeenLocation) return;

    setIsSubmitting(true);
    try {
      const selectedInc = availableIncidents.find((inc) => inc.id === incidentId);

      const payload: CreateMissingPersonPayload = {
        name,
        age: Number(age),
        gender,
        blood_group: bloodGroup,
        incident_id: incidentId || undefined,
        incident_title: selectedInc?.title || undefined,
        priority,
        last_seen_location: lastSeenLocation,
        clothing_last_seen: clothingLastSeen || undefined,
        height_cm: heightCm !== '' ? Number(heightCm) : undefined,
        identifying_marks: identifyingMarks || undefined,
        medical_needs: medicalNeeds || undefined,
        assigned_team: assignedTeam || undefined,
        lat: lat ? parseFloat(lat) : undefined,
        lng: lng ? parseFloat(lng) : undefined,
        description,
        contact_phone: contactPhone || undefined,
        photo_url: photoBase64 || photoUrl || undefined,
        status: 'MISSING',
        reported_by: 'Command Center Coordinator',
        biometric_indexed: !!(photoBase64 || photoUrl),
      };

      await createMissingPerson(payload);
      onSuccess();
    } catch (err) {
      console.error('Failed to submit missing person report:', err);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-in fade-in">
      <div className="w-full max-w-xl bg-white dark:bg-[#111A2E] rounded-2xl shadow-2xl border border-[#E2E8F0] dark:border-[#1E293B] overflow-hidden">
        {/* Header */}
        <div className="flex items-center justify-between p-5 border-b border-[#E2E8F0] dark:border-[#1E293B]">
          <div className="flex items-center gap-2">
            <div className="p-2 bg-[#FFD21F]/20 text-[#D97706] dark:text-[#FFD21F] rounded-lg">
              <UserSearch className="w-5 h-5" />
            </div>
            <div>
              <h2 className="text-lg font-bold text-[#0F172A] dark:text-[#F8FAFC]">
                Report Missing Person Bulletin
              </h2>
              <p className="text-xs text-[#64748B] dark:text-[#94A3B8]">
                Broadcasts physical features, clothing, and biometric vectors across mesh
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="text-[#94A3B8] hover:text-[#0F172A] dark:hover:text-[#F8FAFC]"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="p-5 space-y-3.5 max-h-[80vh] overflow-y-auto">
          {/* Linked Disaster Incident */}
          <div>
            <label className="block text-xs font-semibold text-[#475569] dark:text-[#CBD5E1] mb-1">
              Associated Disaster Incident *
            </label>
            <select
              value={incidentId}
              onChange={(e) => setIncidentId(e.target.value)}
              className="w-full px-3 py-2 text-xs font-semibold rounded-lg bg-[#F8FAFC] dark:bg-[#0B1220] border border-[#CBD5E1] dark:border-[#1E293B] text-[#0F172A] dark:text-[#F8FAFC] focus:ring-2 focus:ring-[#FFD21F] focus:outline-none"
            >
              {availableIncidents.map((inc) => (
                <option key={inc.id} value={inc.id}>
                  {inc.id}: {inc.title || inc.id}
                </option>
              ))}
            </select>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-semibold text-[#475569] dark:text-[#CBD5E1] mb-1">
                Full Name *
              </label>
              <input
                type="text"
                required
                placeholder="e.g. Rameshwar Sen"
                value={name}
                onChange={(e) => setName(e.target.value)}
                className="w-full px-3 py-2 text-sm rounded-lg bg-[#F8FAFC] dark:bg-[#0B1220] border border-[#CBD5E1] dark:border-[#1E293B] text-[#0F172A] dark:text-[#F8FAFC] focus:ring-2 focus:ring-[#FFD21F] focus:outline-none"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-[#475569] dark:text-[#CBD5E1] mb-1">
                Urgency Priority
              </label>
              <select
                value={priority}
                onChange={(e) => setPriority(e.target.value)}
                className="w-full px-3 py-2 text-sm rounded-lg bg-[#F8FAFC] dark:bg-[#0B1220] border border-[#CBD5E1] dark:border-[#1E293B] text-[#0F172A] dark:text-[#F8FAFC] focus:ring-2 focus:ring-[#FFD21F] focus:outline-none"
              >
                <option value="CRITICAL">🚨 CRITICAL (Child / Elderly / Medical)</option>
                <option value="HIGH">HIGH Priority</option>
                <option value="MEDIUM">MEDIUM Priority</option>
              </select>
            </div>
          </div>

          <div className="grid grid-cols-3 gap-3">
            <div>
              <label className="block text-xs font-semibold text-[#475569] dark:text-[#CBD5E1] mb-1">
                Age *
              </label>
              <input
                type="number"
                required
                placeholder="e.g. 68"
                value={age}
                onChange={(e) => setAge(e.target.value === '' ? '' : parseInt(e.target.value))}
                className="w-full px-3 py-2 text-sm rounded-lg bg-[#F8FAFC] dark:bg-[#0B1220] border border-[#CBD5E1] dark:border-[#1E293B] text-[#0F172A] dark:text-[#F8FAFC] focus:ring-2 focus:ring-[#FFD21F] focus:outline-none"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-[#475569] dark:text-[#CBD5E1] mb-1">
                Gender
              </label>
              <select
                value={gender}
                onChange={(e) => setGender(e.target.value)}
                className="w-full px-3 py-2 text-sm rounded-lg bg-[#F8FAFC] dark:bg-[#0B1220] border border-[#CBD5E1] dark:border-[#1E293B] text-[#0F172A] dark:text-[#F8FAFC] focus:ring-2 focus:ring-[#FFD21F] focus:outline-none"
              >
                <option value="Male">Male</option>
                <option value="Female">Female</option>
                <option value="Child">Child</option>
                <option value="Other">Other</option>
              </select>
            </div>

            <div>
              <label className="block text-xs font-semibold text-[#475569] dark:text-[#CBD5E1] mb-1">
                Blood Group
              </label>
              <select
                value={bloodGroup}
                onChange={(e) => setBloodGroup(e.target.value)}
                className="w-full px-3 py-2 text-sm rounded-lg bg-[#F8FAFC] dark:bg-[#0B1220] border border-[#CBD5E1] dark:border-[#1E293B] text-[#0F172A] dark:text-[#F8FAFC] focus:ring-2 focus:ring-[#FFD21F] focus:outline-none"
              >
                <option value="O+">O+</option>
                <option value="A+">A+</option>
                <option value="B+">B+</option>
                <option value="AB+">AB+</option>
                <option value="O-">O-</option>
                <option value="A-">A-</option>
                <option value="B-">B-</option>
                <option value="AB-">AB-</option>
              </select>
            </div>
          </div>

          {/* Clothing & Physical Attributes */}
          <div>
            <label className="block text-xs font-semibold text-[#475569] dark:text-[#CBD5E1] mb-1">
              Clothing Worn When Last Seen *
            </label>
            <input
              type="text"
              placeholder="e.g. Yellow hooded raincoat, navy denim trousers, pink sneakers"
              value={clothingLastSeen}
              onChange={(e) => setClothingLastSeen(e.target.value)}
              className="w-full px-3 py-2 text-sm rounded-lg bg-[#F8FAFC] dark:bg-[#0B1220] border border-[#CBD5E1] dark:border-[#1E293B] text-[#0F172A] dark:text-[#F8FAFC] focus:ring-2 focus:ring-[#FFD21F] focus:outline-none"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-semibold text-[#475569] dark:text-[#CBD5E1] mb-1">
                Height (cm)
              </label>
              <input
                type="number"
                placeholder="e.g. 168"
                value={heightCm}
                onChange={(e) => setHeightCm(e.target.value === '' ? '' : parseInt(e.target.value))}
                className="w-full px-3 py-2 text-sm rounded-lg bg-[#F8FAFC] dark:bg-[#0B1220] border border-[#CBD5E1] dark:border-[#1E293B] text-[#0F172A] dark:text-[#F8FAFC] focus:ring-2 focus:ring-[#FFD21F] focus:outline-none"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-[#475569] dark:text-[#CBD5E1] mb-1">
                Distinctive Marks / Scars
              </label>
              <input
                type="text"
                placeholder="e.g. Cataract in left eye, wooden cane"
                value={identifyingMarks}
                onChange={(e) => setIdentifyingMarks(e.target.value)}
                className="w-full px-3 py-2 text-sm rounded-lg bg-[#F8FAFC] dark:bg-[#0B1220] border border-[#CBD5E1] dark:border-[#1E293B] text-[#0F172A] dark:text-[#F8FAFC] focus:ring-2 focus:ring-[#FFD21F] focus:outline-none"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-semibold text-rose-600 dark:text-rose-400 mb-1">
              Medical Vulnerabilities / Critical Needs
            </label>
            <input
              type="text"
              placeholder="e.g. Type-1 Diabetic (requires insulin), mild asthma, hearing impaired"
              value={medicalNeeds}
              onChange={(e) => setMedicalNeeds(e.target.value)}
              className="w-full px-3 py-2 text-sm rounded-lg bg-[#F8FAFC] dark:bg-[#0B1220] border border-rose-300 dark:border-rose-900/60 text-[#0F172A] dark:text-[#F8FAFC] focus:ring-2 focus:ring-rose-500 focus:outline-none"
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-[#475569] dark:text-[#CBD5E1] mb-1">
              Last Seen Location & Landmark *
            </label>
            <input
              type="text"
              required
              placeholder="e.g. Ward 14 Relief Camp, Sector 3 Bridge"
              value={lastSeenLocation}
              onChange={(e) => setLastSeenLocation(e.target.value)}
              className="w-full px-3 py-2 text-sm rounded-lg bg-[#F8FAFC] dark:bg-[#0B1220] border border-[#CBD5E1] dark:border-[#1E293B] text-[#0F172A] dark:text-[#F8FAFC] focus:ring-2 focus:ring-[#FFD21F] focus:outline-none"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-semibold text-[#475569] dark:text-[#CBD5E1] mb-1">
                Latitude (GPS)
              </label>
              <input
                type="text"
                placeholder="13.0827"
                value={lat}
                onChange={(e) => setLat(e.target.value)}
                className="w-full px-3 py-2 text-sm rounded-lg bg-[#F8FAFC] dark:bg-[#0B1220] border border-[#CBD5E1] dark:border-[#1E293B] text-[#0F172A] dark:text-[#F8FAFC] font-mono text-xs"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-[#475569] dark:text-[#CBD5E1] mb-1">
                Longitude (GPS)
              </label>
              <input
                type="text"
                placeholder="80.2707"
                value={lng}
                onChange={(e) => setLng(e.target.value)}
                className="w-full px-3 py-2 text-sm rounded-lg bg-[#F8FAFC] dark:bg-[#0B1220] border border-[#CBD5E1] dark:border-[#1E293B] text-[#0F172A] dark:text-[#F8FAFC] font-mono text-xs"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-semibold text-[#475569] dark:text-[#CBD5E1] mb-1">
              Photograph (Indexes directly into Qdrant AI)
            </label>
            <div className="flex items-center gap-3">
              <input
                type="file"
                id="missing-photo-file-upload"
                accept="image/*"
                className="hidden"
                onChange={(e) => {
                  const file = e.target.files?.[0];
                  if (file) {
                    const reader = new FileReader();
                    reader.onload = () => setPhotoBase64(reader.result as string);
                    reader.readAsDataURL(file);
                  }
                }}
              />
              <button
                type="button"
                onClick={() => document.getElementById('missing-photo-file-upload')?.click()}
                className="px-3 py-1.5 text-xs font-semibold rounded-lg bg-[#0891B2]/15 text-[#0891B2] dark:text-[#06B6D4] border border-[#0891B2]/30 hover:bg-[#0891B2]/25 flex items-center gap-1.5"
              >
                <Camera className="w-3.5 h-3.5" />
                <span>Upload Face Photo</span>
              </button>
              {photoBase64 && (
                <span className="text-xs text-emerald-500 font-semibold flex items-center gap-1">
                  <Check className="w-3.5 h-3.5" /> Photo Attached
                </span>
              )}
            </div>
          </div>

          <div className="pt-3 border-t border-[#E2E8F0] dark:border-[#1E293B] flex items-center justify-end gap-3">
            <Button variant="outline" type="button" onClick={onClose}>
              Cancel
            </Button>
            <Button
              type="submit"
              disabled={isSubmitting}
              className="bg-[#FFD21F] text-[#0B1220] hover:bg-[#FACC15] font-semibold"
            >
              {isSubmitting ? 'Registering Bulletin...' : 'Publish Bulletin'}
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
};

// =============================================================================
// RECORD SIGHTING MODAL
// =============================================================================

interface RecordSightingModalProps {
  person: MissingPerson;
  onClose: () => void;
  onSuccess: () => void;
}

const RecordSightingModal: React.FC<RecordSightingModalProps> = ({
  person,
  onClose,
  onSuccess,
}) => {
  const [location, setLocation] = useState('');
  const [lat, setLat] = useState<string>(person.lat ? person.lat.toFixed(4) : '');
  const [lng, setLng] = useState<string>(person.lng ? person.lng.toFixed(4) : '');
  const [notes, setNotes] = useState('');
  const [reportedBy, setReportedBy] = useState('Citizen Field Mesh Node');
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!location) return;

    setIsSubmitting(true);
    try {
      const payload: CreateSightingPayload = {
        location,
        lat: lat ? parseFloat(lat) : undefined,
        lng: lng ? parseFloat(lng) : undefined,
        notes,
        reported_by: reportedBy,
      };
      await addMissingPersonSighting(person.id, payload);
      onSuccess();
    } catch (err) {
      console.error('Failed to add sighting:', err);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-in fade-in">
      <div className="w-full max-w-md bg-white dark:bg-[#111A2E] rounded-2xl shadow-2xl border border-[#E2E8F0] dark:border-[#1E293B] overflow-hidden">
        <div className="flex items-center justify-between p-5 border-b border-[#E2E8F0] dark:border-[#1E293B]">
          <div className="flex items-center gap-2">
            <div className="p-2 bg-[#06B6D4]/15 text-[#0891B2] dark:text-[#06B6D4] rounded-lg">
              <Eye className="w-5 h-5" />
            </div>
            <div>
              <h2 className="text-lg font-bold text-[#0F172A] dark:text-[#F8FAFC]">
                Record Field Sighting
              </h2>
              <p className="text-xs text-[#0891B2] dark:text-[#06B6D4] font-semibold">
                For: {person.name} ({person.age} yrs)
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="text-[#94A3B8] hover:text-[#0F172A] dark:hover:text-[#F8FAFC]"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-5 space-y-4">
          <div>
            <label className="block text-xs font-semibold text-[#475569] dark:text-[#CBD5E1] mb-1">
              Sighting Location / Landmark *
            </label>
            <input
              type="text"
              required
              placeholder="e.g. Near Sector 3 Relief Depot porch"
              value={location}
              onChange={(e) => setLocation(e.target.value)}
              className="w-full px-3 py-2 text-sm rounded-lg bg-[#F8FAFC] dark:bg-[#0B1220] border border-[#CBD5E1] dark:border-[#1E293B] text-[#0F172A] dark:text-[#F8FAFC] focus:ring-2 focus:ring-[#06B6D4] focus:outline-none"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-semibold text-[#475569] dark:text-[#CBD5E1] mb-1">
                Latitude (GPS)
              </label>
              <input
                type="text"
                placeholder="13.0840"
                value={lat}
                onChange={(e) => setLat(e.target.value)}
                className="w-full px-3 py-2 text-sm rounded-lg bg-[#F8FAFC] dark:bg-[#0B1220] border border-[#CBD5E1] dark:border-[#1E293B] text-[#0F172A] dark:text-[#F8FAFC] font-mono text-xs"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-[#475569] dark:text-[#CBD5E1] mb-1">
                Longitude (GPS)
              </label>
              <input
                type="text"
                placeholder="80.2720"
                value={lng}
                onChange={(e) => setLng(e.target.value)}
                className="w-full px-3 py-2 text-sm rounded-lg bg-[#F8FAFC] dark:bg-[#0B1220] border border-[#CBD5E1] dark:border-[#1E293B] text-[#0F172A] dark:text-[#F8FAFC] font-mono text-xs"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-semibold text-[#475569] dark:text-[#CBD5E1] mb-1">
              Notes / Condition Observed
            </label>
            <textarea
              rows={3}
              placeholder="e.g. Resting on porch, wearing blue jacket. Appears unhurt."
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              className="w-full px-3 py-2 text-sm rounded-lg bg-[#F8FAFC] dark:bg-[#0B1220] border border-[#CBD5E1] dark:border-[#1E293B] text-[#0F172A] dark:text-[#F8FAFC] focus:ring-2 focus:ring-[#06B6D4] focus:outline-none resize-none"
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-[#475569] dark:text-[#CBD5E1] mb-1">
              Reported By (Witness / Mule Node ID)
            </label>
            <input
              type="text"
              placeholder="e.g. Node SR-8F42 / Volunteer Kavitha"
              value={reportedBy}
              onChange={(e) => setReportedBy(e.target.value)}
              className="w-full px-3 py-2 text-sm rounded-lg bg-[#F8FAFC] dark:bg-[#0B1220] border border-[#CBD5E1] dark:border-[#1E293B] text-[#0F172A] dark:text-[#F8FAFC]"
            />
          </div>

          <div className="pt-3 border-t border-[#E2E8F0] dark:border-[#1E293B] flex items-center justify-end gap-3">
            <Button variant="outline" type="button" onClick={onClose}>
              Cancel
            </Button>
            <Button
              type="submit"
              disabled={isSubmitting}
              className="bg-[#0891B2] hover:bg-[#0e7490] text-white font-semibold"
            >
              {isSubmitting ? 'Logging...' : 'Log Sighting'}
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
};

// =============================================================================
// PERSON DETAIL & SIGHTINGS TIMELINE MODAL
// =============================================================================

interface PersonDetailModalProps {
  person: MissingPerson;
  onClose: () => void;
  onAddSighting: () => void;
  onToggleStatus: (nextStatus: 'MISSING' | 'FOUND') => void;
  onInspectPhoto: () => void;
}

const PersonDetailModal: React.FC<PersonDetailModalProps> = ({
  person,
  onClose,
  onAddSighting,
  onToggleStatus,
  onInspectPhoto,
}) => {
  const isFound = person.status.toUpperCase() === 'FOUND';
  const [copiedCoords, setCopiedCoords] = useState(false);

  const copyCoordinates = (lat: number, lng: number) => {
    navigator.clipboard.writeText(`${lat}, ${lng}`);
    setCopiedCoords(true);
    setTimeout(() => setCopiedCoords(false), 2000);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-in fade-in">
      <div className="w-full max-w-2xl bg-white dark:bg-[#111A2E] rounded-2xl shadow-2xl border border-[#E2E8F0] dark:border-[#1E293B] overflow-hidden flex flex-col max-h-[88vh]">
        {/* Header */}
        <div className="flex items-center justify-between p-5 border-b border-[#E2E8F0] dark:border-[#1E293B]">
          <div className="flex items-center gap-3">
            <PersonAvatar
              photoUrl={person.photo_url}
              name={person.name}
              isFound={isFound}
              size="lg"
              onClick={onInspectPhoto}
            />
            <div>
              <div className="flex items-center gap-2">
                <h2 className="text-xl font-bold text-[#0F172A] dark:text-[#F8FAFC]">
                  {person.name}
                </h2>
                <span
                  className={`text-xs px-2.5 py-0.5 rounded-full font-bold uppercase tracking-wider border ${
                    isFound
                      ? 'bg-emerald-500/15 text-emerald-600 dark:text-emerald-400 border-emerald-500/30'
                      : 'bg-amber-500/15 text-amber-600 dark:text-amber-400 border-amber-500/30'
                  }`}
                >
                  {isFound ? 'FOUND / REUNITED' : 'ACTIVE MISSING'}
                </span>
              </div>
              <p className="text-xs text-[#64748B] dark:text-[#94A3B8]">
                {person.age} years old • {person.gender} • Bulletin ID: {person.id}
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="text-[#94A3B8] hover:text-[#0F172A] dark:hover:text-[#F8FAFC]"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Body */}
        <div className="p-6 space-y-5 overflow-y-auto">
          {/* Linked Incident Box */}
          {person.incident_id && (
            <div className="p-3 rounded-xl bg-amber-50 dark:bg-amber-950/20 border border-amber-200 dark:border-amber-900/40 flex items-center justify-between text-xs">
              <div className="flex items-center gap-2">
                {getDisasterIcon(person.incident_title || '')}
                <span className="font-semibold text-amber-900 dark:text-amber-200">
                  Incident: {person.incident_title || person.incident_id}
                </span>
              </div>
              <Link
                to={`/app/incidents`}
                className="font-bold text-amber-700 dark:text-amber-400 hover:underline inline-flex items-center gap-1"
              >
                <span>View Incident Map</span>
                <ChevronRight className="w-3.5 h-3.5" />
              </Link>
            </div>
          )}

          {/* Key Facts Card */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 p-4 rounded-xl bg-[#F8FAFC] dark:bg-[#0B1220] border border-[#E2E8F0] dark:border-[#1E293B]">
            <div>
              <span className="text-xs font-semibold text-[#64748B] dark:text-[#94A3B8] block">
                Last Known Location
              </span>
              <span className="text-sm font-bold text-[#0F172A] dark:text-[#F8FAFC] block mt-0.5">
                {person.last_seen_location}
              </span>
              {person.lat && person.lng && (
                <div className="flex items-center gap-2 mt-1">
                  <span className="text-xs font-mono text-[#0891B2] dark:text-[#06B6D4]">
                    {person.lat.toFixed(4)}, {person.lng.toFixed(4)}
                  </span>
                  <button
                    onClick={() => copyCoordinates(person.lat!, person.lng!)}
                    className="text-[#64748B] hover:text-[#0891B2] text-xs inline-flex items-center gap-1"
                    title="Copy coordinates"
                  >
                    {copiedCoords ? (
                      <Check className="w-3.5 h-3.5 text-emerald-500" />
                    ) : (
                      <Copy className="w-3.5 h-3.5" />
                    )}
                  </button>
                </div>
              )}
            </div>

            <div>
              <span className="text-xs font-semibold text-[#64748B] dark:text-[#94A3B8] block">
                Emergency Contact
              </span>
              <span className="text-sm font-bold text-[#0F172A] dark:text-[#F8FAFC] block mt-0.5">
                {person.contact_phone || 'None provided'}
              </span>
              <span className="text-xs text-[#64748B] dark:text-[#94A3B8] block mt-1">
                Reported by: <strong>{person.reported_by}</strong>
              </span>
            </div>
          </div>

          {/* Detailed Physical Profile for Identification */}
          <div className="p-4 rounded-xl bg-slate-50 dark:bg-[#0B1220] border border-slate-200 dark:border-[#1E293B] space-y-2 text-xs">
            <h4 className="font-bold text-slate-900 dark:text-white uppercase tracking-wider text-[11px] mb-2">
              Physical Recognition Dossier
            </h4>
            <div className="grid grid-cols-2 gap-3">
              <div>
                <strong className="text-slate-500 block">Clothing Last Seen:</strong>
                <span className="text-slate-800 dark:text-slate-200 font-medium">
                  {person.clothing_last_seen || 'Not specified'}
                </span>
              </div>
              <div>
                <strong className="text-slate-500 block">Height & Build:</strong>
                <span className="text-slate-800 dark:text-slate-200 font-medium">
                  {person.height_cm ? `${person.height_cm} cm` : 'Unspecified'}
                </span>
              </div>
              <div>
                <strong className="text-slate-500 block">Blood Group:</strong>
                <span className="text-rose-500 font-bold">{person.blood_group || 'Unspecified'}</span>
              </div>
              <div>
                <strong className="text-slate-500 block">Assigned Rescue Unit:</strong>
                <span className="text-slate-800 dark:text-slate-200 font-medium">
                  {person.assigned_team || 'Field Dispatch Pending'}
                </span>
              </div>
            </div>

            {person.identifying_marks && (
              <div className="pt-2 border-t border-slate-200 dark:border-slate-800">
                <strong className="text-slate-500 block">Distinguishing Features:</strong>
                <span className="text-slate-800 dark:text-slate-200 font-medium">{person.identifying_marks}</span>
              </div>
            )}

            {person.medical_needs && person.medical_needs.toLowerCase() !== 'none' && (
              <div className="pt-2 border-t border-slate-200 dark:border-slate-800 text-rose-600 dark:text-rose-400 font-medium">
                <strong>Medical Needs: </strong>
                <span>{person.medical_needs}</span>
              </div>
            )}
          </div>

          {/* Sightings Timeline */}
          <div>
            <div className="flex items-center justify-between mb-3">
              <h3 className="text-sm font-bold text-[#0F172A] dark:text-[#F8FAFC]">
                Citizen Sightings Timeline ({person.sightings?.length || 0})
              </h3>
              <Button
                variant="outline"
                size="sm"
                onClick={onAddSighting}
                className="text-xs text-[#0891B2] border-[#0891B2]/40"
              >
                + Add Sighting
              </Button>
            </div>

            {person.sightings && person.sightings.length > 0 ? (
              <div className="space-y-3">
                {person.sightings.map((sighting, idx) => (
                  <div
                    key={idx}
                    className="p-3.5 rounded-xl border border-cyan-500/20 bg-cyan-500/5 dark:bg-cyan-950/20 flex flex-col gap-1 text-xs"
                  >
                    <div className="flex items-center justify-between">
                      <strong className="text-cyan-700 dark:text-cyan-300 font-semibold">
                        📍 {sighting.location}
                      </strong>
                      <span className="text-slate-400 text-[11px]">
                        {new Date(sighting.timestamp).toLocaleTimeString([], {
                          hour: '2-digit',
                          minute: '2-digit',
                        })}
                      </span>
                    </div>
                    {sighting.notes && (
                      <p className="text-slate-600 dark:text-slate-300 mt-1">{sighting.notes}</p>
                    )}
                    <div className="text-[10px] text-slate-400 mt-1">
                      Reported by: {sighting.reported_by}
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <div className="p-6 text-center rounded-xl border border-dashed border-slate-200 dark:border-slate-800 text-slate-400 text-xs">
                No sightings recorded yet for this individual.
              </div>
            )}
          </div>
        </div>

        {/* Footer */}
        <div className="p-4 border-t border-[#E2E8F0] dark:border-[#1E293B] flex items-center justify-between">
          <Button variant="outline" size="sm" onClick={onClose}>
            Close
          </Button>
          <div className="flex items-center gap-2">
            {!isFound ? (
              <Button
                size="sm"
                onClick={() => onToggleStatus('FOUND')}
                className="bg-emerald-600 hover:bg-emerald-700 text-white font-semibold"
              >
                Mark as Reunited / Found
              </Button>
            ) : (
              <Button
                variant="outline"
                size="sm"
                onClick={() => onToggleStatus('MISSING')}
                className="text-amber-600 border-amber-500/40"
              >
                Reopen as Active Missing
              </Button>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default MissingPersonsPage;

import React, { useState, useEffect, useRef, useCallback } from 'react';
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

/**
 * Resolves any photo path: full URL, base64 data URI, blob URL, or relative backend path.
 */
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
}

export const PersonAvatar: React.FC<PersonAvatarProps> = ({
  photoUrl,
  name,
  isFound = false,
  size = 'md',
  className = '',
}) => {
  const [hasError, setHasError] = useState(false);
  const resolvedUrl = resolvePhotoUrl(photoUrl);

  const initial = (name || '?').trim().charAt(0).toUpperCase();

  const sizeClasses = {
    sm: 'w-10 h-10 text-sm',
    md: 'w-12 h-12 text-base',
    lg: 'w-16 h-16 text-xl',
    xl: 'w-24 h-24 text-3xl',
  }[size];

  // Reset error state if url changes
  useEffect(() => {
    setHasError(false);
  }, [photoUrl]);

  if (resolvedUrl && !hasError) {
    return (
      <div
        className={`relative shrink-0 rounded-xl overflow-hidden border ${
          isFound
            ? 'border-emerald-500/40 ring-1 ring-emerald-500/30'
            : 'border-amber-500/40 ring-1 ring-amber-500/20'
        } ${sizeClasses} ${className}`}
      >
        <img
          src={resolvedUrl}
          alt={name}
          onError={() => setHasError(true)}
          className="w-full h-full object-cover object-center transition-transform hover:scale-105 duration-200"
          loading="lazy"
        />
      </div>
    );
  }

  return (
    <div
      className={`relative shrink-0 rounded-xl flex flex-col items-center justify-center font-bold border transition-colors ${
        isFound
          ? 'bg-emerald-500/15 border-emerald-500/30 text-emerald-600 dark:text-emerald-400'
          : 'bg-[#FFD21F]/20 border-amber-500/30 text-amber-700 dark:text-[#FFD21F]'
      } ${sizeClasses} ${className}`}
      title={name}
    >
      <span>{initial}</span>
      <User className="w-3 h-3 opacity-60 absolute bottom-1 right-1" />
    </div>
  );
};

// =============================================================================
// MAIN MISSING PERSONS COMPONENT
// =============================================================================

export const MissingPersonsPage: React.FC = () => {
  const [persons, setPersons] = useState<MissingPerson[]>([]);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [isRefreshing, setIsRefreshing] = useState<boolean>(false);
  const [selectedStatus, setSelectedStatus] = useState<MissingPersonStatusFilter>('ALL');
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [activeTab, setActiveTab] = useState<'DIRECTORY' | 'VISUAL_SEARCH'>('DIRECTORY');

  // Modals state
  const [isReportModalOpen, setIsReportModalOpen] = useState<boolean>(false);
  const [isVisualSearchModalOpen, setIsVisualSearchModalOpen] = useState<boolean>(false);
  const [sightingModalPerson, setSightingModalPerson] = useState<MissingPerson | null>(null);
  const [detailModalPerson, setDetailModalPerson] = useState<MissingPerson | null>(null);

  // Status update indicator
  const [optimisticAlert, setOptimisticAlert] = useState<{
    message: string;
    type: 'success' | 'info';
  } | null>(null);

  // Real-time Gateway WebSocket uplink
  const { status: wsStatus, lastMessage } = useWebSocket();
  const [lastSyncTime, setLastSyncTime] = useState<number>(Date.now());

  const fetchPersons = useCallback(async (isBackground = false) => {
    if (!isBackground) setIsLoading(true);
    else setIsRefreshing(true);

    try {
      const data = await getMissingPersons(
        selectedStatus === 'ALL' ? undefined : selectedStatus,
        searchQuery
      );
      setPersons(data);
      setLastSyncTime(Date.now());

      // If detail modal is currently open, keep it updated
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
  }, [selectedStatus, searchQuery]);

  // Initial fetch and on filter/search change
  useEffect(() => {
    fetchPersons();
  }, [fetchPersons]);

  // Real-time WebSocket event reaction: "once any network available device find all show in web site"
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

  // Periodic resilient polling every 12 seconds to guarantee field updates from mesh uploads
  useEffect(() => {
    const timer = setInterval(() => {
      fetchPersons(true);
    }, 12000);
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
  const totalSightings = persons.reduce((acc, p) => acc + (p.sightings?.length || 0), 0);

  // Status toggle handler with INSTANT optimistic update
  const handleToggleStatus = async (
    person: MissingPerson,
    targetStatus: 'MISSING' | 'FOUND'
  ) => {
    const prevPersons = [...persons];

    // Optimistic local update
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
      message: `${person.name} marked as ${targetStatus === 'FOUND' ? 'FOUND & REUNITED' : 'ACTIVE MISSING'}`,
      type: 'success',
    });

    try {
      await updateMissingPersonStatus(person.id, targetStatus);
      // Fetch fresh data in background to confirm consistency
      fetchPersons(true);
    } catch (err) {
      console.error('Failed to update person status:', err);
      // Revert optimistic update on error
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
      {/* Toast / Notification Banner */}
      {optimisticAlert && (
        <div className="fixed top-5 right-5 z-50 animate-in fade-in slide-in-from-top-4 duration-300">
          <div className="flex items-center gap-2 px-4 py-3 rounded-xl bg-emerald-600 text-white shadow-xl border border-emerald-500 font-medium text-sm">
            <CheckCircle2 className="w-5 h-5 shrink-0" />
            <span>{optimisticAlert.message}</span>
            <button
              onClick={() => setOptimisticAlert(null)}
              className="ml-2 hover:opacity-80"
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
                Disaster reunification directory, mesh field bulletins, citizen sightings & AI visual matching
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
            onClick={() => setIsVisualSearchModalOpen(true)}
            className="bg-[#0891B2] hover:bg-[#0e7490] text-white font-semibold flex items-center gap-2 shadow-sm text-sm"
          >
            <Camera className="w-4 h-4" />
            <span>Match Found Person (AI)</span>
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
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
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

        <Card className="p-4 bg-white dark:bg-[#111A2E] border-[#E2E8F0] dark:border-[#1E293B] shadow-sm">
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
            <Camera className="w-4 h-4" />
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
          {/* Search & Filter Controls */}
          <Card className="p-4 bg-white dark:bg-[#111A2E] border-[#E2E8F0] dark:border-[#1E293B] shadow-sm">
            <div className="flex flex-col sm:flex-row gap-4 items-center justify-between">
              {/* Search Box */}
              <div className="relative w-full sm:w-96">
                <Search className="w-4 h-4 absolute left-3 top-1/2 transform -translate-y-1/2 text-[#94A3B8]" />
                <input
                  type="text"
                  placeholder="Search by name, location, clothing..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="w-full pl-9 pr-4 py-2 text-sm rounded-lg bg-[#F8FAFC] dark:bg-[#0B1220] border border-[#CBD5E1] dark:border-[#1E293B] text-[#0F172A] dark:text-[#F8FAFC] placeholder-[#94A3B8] focus:outline-none focus:ring-2 focus:ring-[#FFD21F]"
                />
              </div>

              {/* Filter Pills */}
              <div className="flex items-center gap-2 w-full sm:w-auto">
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
                      ? `Active Missing (${missingCount})`
                      : `Found / Reunited (${foundCount})`}
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
                  className="h-64 rounded-xl bg-gray-200 dark:bg-gray-800 animate-pulse"
                />
              ))}
            </div>
          ) : persons.length === 0 ? (
            <Card className="p-12 text-center bg-white dark:bg-[#111A2E] border-[#E2E8F0] dark:border-[#1E293B]">
              <div className="mx-auto w-12 h-12 rounded-full bg-[#FFD21F]/15 flex items-center justify-center text-[#D97706] mb-4">
                <UserSearch className="w-6 h-6" />
              </div>
              <h3 className="text-lg font-semibold text-[#0F172A] dark:text-[#F8FAFC]">
                No Missing Persons Registered
              </h3>
              <p className="text-sm text-[#64748B] dark:text-[#94A3B8] max-w-sm mx-auto mt-1 mb-4">
                No matching reports found for current filters. Reports submitted from field
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
              {persons.map((person) => {
                const isFound = person.status.toUpperCase() === 'FOUND';

                return (
                  <Card
                    key={person.id}
                    className={`overflow-hidden transition-all duration-200 hover:shadow-md bg-white dark:bg-[#111A2E] border ${
                      isFound
                        ? 'border-emerald-500/30 dark:border-emerald-500/40'
                        : 'border-[#E2E8F0] dark:border-[#1E293B]'
                    }`}
                  >
                    <div className="p-5 flex flex-col justify-between h-full">
                      <div>
                        {/* Header: Avatar, Name, Age/Gender, Status Toggle & Badge */}
                        <div className="flex items-start justify-between gap-3">
                          <div className="flex items-center gap-3">
                            <PersonAvatar
                              photoUrl={person.photo_url}
                              name={person.name}
                              isFound={isFound}
                              size="md"
                            />
                            <div>
                              <h3 className="font-bold text-base text-[#0F172A] dark:text-[#F8FAFC] leading-snug">
                                {person.name}
                              </h3>
                              <div className="flex items-center gap-1.5 text-xs text-[#64748B] dark:text-[#94A3B8]">
                                <span>{person.age} yrs</span>
                                <span>•</span>
                                <span>{person.gender}</span>
                              </div>
                            </div>
                          </div>

                          {/* Status Badge & Fast Toggle */}
                          <div className="flex flex-col items-end gap-1.5">
                            <span
                              className={`text-xs px-2.5 py-0.5 rounded-full uppercase tracking-wide font-bold border ${
                                isFound
                                  ? 'bg-emerald-500/15 text-emerald-600 dark:text-emerald-400 border-emerald-500/30'
                                  : 'bg-amber-500/15 text-amber-600 dark:text-amber-400 border-amber-500/30'
                              }`}
                            >
                              {isFound ? 'FOUND' : 'MISSING'}
                            </span>
                            <button
                              onClick={() =>
                                handleToggleStatus(
                                  person,
                                  isFound ? 'MISSING' : 'FOUND'
                                )
                              }
                              className={`text-[10px] font-semibold underline transition-colors ${
                                isFound
                                  ? 'text-amber-600 dark:text-amber-400 hover:text-amber-700'
                                  : 'text-emerald-600 dark:text-emerald-400 hover:text-emerald-700'
                              }`}
                              title={
                                isFound
                                  ? 'Reopen as Missing'
                                  : 'Instant mark Found'
                              }
                            >
                              {isFound ? 'Set Missing' : 'Set Found'}
                            </button>
                          </div>
                        </div>

                        {/* Last Seen Location */}
                        <div className="mt-4 flex items-start gap-2 text-xs text-[#334155] dark:text-[#CBD5E1]">
                          <MapPin className="w-4 h-4 text-[#D97706] dark:text-[#FFD21F] shrink-0 mt-0.5" />
                          <div>
                            <span className="font-semibold text-[#0F172A] dark:text-[#F8FAFC]">
                              {person.last_seen_location}
                            </span>
                            {person.lat && person.lng && (
                              <div className="flex items-center gap-1.5 mt-0.5">
                                <span className="text-[11px] text-[#0891B2] dark:text-[#06B6D4] font-mono">
                                  [{person.lat.toFixed(4)}, {person.lng.toFixed(4)}]
                                </span>
                                <a
                                  href={`https://www.google.com/maps/search/?api=1&query=${person.lat},${person.lng}`}
                                  target="_blank"
                                  rel="noreferrer"
                                  className="text-[#64748B] hover:text-[#0891B2] inline-flex items-center"
                                  title="View on Google Maps"
                                >
                                  <ExternalLink className="w-3 h-3" />
                                </a>
                              </div>
                            )}
                          </div>
                        </div>

                        {/* Description */}
                        {person.description && (
                          <p className="mt-2.5 text-xs text-[#475569] dark:text-[#94A3B8] line-clamp-2 leading-relaxed">
                            {person.description}
                          </p>
                        )}

                        {/* Contact Phone & Reported Time */}
                        <div className="mt-3 pt-3 border-t border-[#F1F5F9] dark:border-[#1E293B] flex flex-col gap-1 text-[11px] text-[#64748B] dark:text-[#94A3B8]">
                          {person.contact_phone && (
                            <div className="flex items-center gap-1.5 text-[#0F172A] dark:text-[#E2E8F0]">
                              <Phone className="w-3.5 h-3.5 text-[#3B82F6]" />
                              <span className="font-medium">{person.contact_phone}</span>
                            </div>
                          )}
                          <div className="flex items-center gap-1.5">
                            <Clock className="w-3.5 h-3.5 text-[#94A3B8]" />
                            <span>
                              Reported {formatTimeAgo(person.reported_at)} by{' '}
                              <strong className="text-[#334155] dark:text-[#CBD5E1]">
                                {person.reported_by}
                              </strong>
                            </span>
                          </div>
                        </div>

                        {/* Sightings Snippet */}
                        <div className="mt-3">
                          {person.sightings && person.sightings.length > 0 ? (
                            <div className="p-2.5 rounded-lg bg-[#06B6D4]/10 dark:bg-[#06B6D4]/15 border border-[#06B6D4]/20 flex items-center justify-between">
                              <div className="flex items-center gap-2">
                                <Eye className="w-4 h-4 text-[#0891B2] dark:text-[#06B6D4]" />
                                <span className="text-xs font-semibold text-[#0891B2] dark:text-[#06B6D4]">
                                  {person.sightings.length} Citizen Sighting
                                  {person.sightings.length > 1 ? 's' : ''}
                                </span>
                              </div>
                              <button
                                onClick={() => setDetailModalPerson(person)}
                                className="text-[11px] font-bold text-[#0891B2] dark:text-[#06B6D4] hover:underline"
                              >
                                View Timeline →
                              </button>
                            </div>
                          ) : (
                            <div className="p-2 rounded-lg bg-[#F8FAFC] dark:bg-[#0B1220] border border-[#E2E8F0] dark:border-[#1E293B] text-[11px] text-[#94A3B8] text-center">
                              No citizen sightings logged yet
                            </div>
                          )}
                        </div>
                      </div>

                      {/* Actions Footer */}
                      <div className="mt-5 pt-3 border-t border-[#F1F5F9] dark:border-[#1E293B] flex items-center justify-between gap-2">
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => setDetailModalPerson(person)}
                          className="text-xs flex-1 text-[#334155] dark:text-[#CBD5E1]"
                        >
                          Details & Sightings
                        </Button>

                        {!isFound ? (
                          <>
                            <Button
                              variant="outline"
                              size="sm"
                              onClick={() => setSightingModalPerson(person)}
                              className="text-xs text-[#0891B2] border-[#0891B2]/40 hover:bg-[#0891B2]/10"
                            >
                              + Sighting
                            </Button>
                            <Button
                              size="sm"
                              onClick={() => handleToggleStatus(person, 'FOUND')}
                              className="text-xs bg-emerald-600 hover:bg-emerald-700 text-white font-semibold"
                            >
                              Mark Found
                            </Button>
                          </>
                        ) : (
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => handleToggleStatus(person, 'MISSING')}
                            className="text-xs text-amber-600 dark:text-amber-400 border-amber-500/40 hover:bg-amber-500/10"
                          >
                            Mark Missing
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
      {/* TAB 2: VISUAL RECOGNITION SCANNER (EMBEDDED VIEW) */}
      {/* ===================================================================== */}
      {activeTab === 'VISUAL_SEARCH' && (
        <Card className="p-6 bg-white dark:bg-[#111A2E] border-[#E2E8F0] dark:border-[#1E293B]">
          <VisualRecognitionPanel
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
          onClose={() => setIsReportModalOpen(false)}
          onSuccess={() => {
            setIsReportModalOpen(false);
            fetchPersons();
            setOptimisticAlert({
              message: 'Missing person bulletin registered and propagated to mesh network.',
              type: 'success',
            });
          }}
        />
      )}

      {/* Modal: Visual Recognition Match Found Person */}
      {isVisualSearchModalOpen && (
        <VisualRecognitionModal
          onClose={() => setIsVisualSearchModalOpen(false)}
          onConfirmIdentification={(matchedPerson) => {
            handleToggleStatus(matchedPerson, 'FOUND');
            setIsVisualSearchModalOpen(false);
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

      {/* Modal: Person Detail & Sightings Timeline */}
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
        />
      )}
    </div>
  );
};

// =============================================================================
// VISUAL RECOGNITION PANEL / MODAL COMPONENTS
// =============================================================================

interface VisualRecognitionProps {
  onConfirmIdentification: (person: MissingPerson) => void;
  onClose?: () => void;
}

export const VisualRecognitionPanel: React.FC<VisualRecognitionProps> = ({
  onConfirmIdentification,
  onClose,
}) => {
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [isScanning, setIsScanning] = useState(false);
  const [searchResult, setSearchResult] = useState<VisualSearchResult | null>(null);
  const [searchError, setSearchError] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      const file = e.target.files[0];
      setSelectedFile(file);
      setSearchResult(null);
      setSearchError(null);

      // Local preview
      const reader = new FileReader();
      reader.onload = () => {
        setPreviewUrl(reader.result as string);
      };
      reader.readAsDataURL(file);
    }
  };

  const handleScan = async () => {
    if (!selectedFile) return;
    setIsScanning(true);
    setSearchError(null);

    try {
      const result = await searchMissingPersonByPhoto(selectedFile);
      setSearchResult(result);
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
      {/* Header Banner */}
      <div className="flex items-start justify-between">
        <div className="flex items-center gap-3">
          <div className="p-3 rounded-xl bg-[#0891B2]/15 text-[#0891B2] dark:text-[#06B6D4] border border-[#0891B2]/30">
            <Scan className="w-6 h-6" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h2 className="text-xl font-bold text-[#0F172A] dark:text-[#F8FAFC]">
                Visual Biometric Recognition & Facial Matching
              </h2>
              <span className="px-2 py-0.5 text-[11px] rounded-full font-bold bg-[#0891B2]/20 text-[#0891B2] dark:text-[#06B6D4]">
                Qdrant Vector Engine
              </span>
            </div>
            <p className="text-xs text-[#64748B] dark:text-[#94A3B8] mt-0.5">
              Upload a photograph of an unidentified rescued survivor or evacuee to match against the Missing Persons Registry using vector embeddings.
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

      {/* Upload Zone */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="md:col-span-1 space-y-4">
          <div
            onClick={() => fileInputRef.current?.click()}
            className={`border-2 border-dashed rounded-2xl p-6 text-center cursor-pointer transition-all flex flex-col items-center justify-center min-h-[220px] ${
              previewUrl
                ? 'border-[#0891B2] bg-[#0891B2]/5'
                : 'border-[#CBD5E1] dark:border-[#334155] hover:border-[#0891B2] bg-[#F8FAFC] dark:bg-[#0B1220]'
            }`}
          >
            <input
              type="file"
              ref={fileInputRef}
              accept="image/*"
              onChange={handleFileChange}
              className="hidden"
            />

            {previewUrl ? (
              <div className="relative group w-full">
                <img
                  src={previewUrl}
                  alt="Query Subject Preview"
                  className="w-full max-h-48 object-contain rounded-xl mx-auto shadow-md"
                />
                <div className="mt-2 text-xs font-semibold text-[#0891B2] dark:text-[#06B6D4]">
                  Click to replace image
                </div>
              </div>
            ) : (
              <>
                <div className="w-12 h-12 rounded-full bg-[#0891B2]/15 flex items-center justify-center text-[#0891B2] dark:text-[#06B6D4] mb-3">
                  <UploadCloud className="w-6 h-6" />
                </div>
                <h4 className="text-sm font-bold text-[#0F172A] dark:text-[#F8FAFC]">
                  Upload Found Person Photo
                </h4>
                <p className="text-xs text-[#64748B] dark:text-[#94A3B8] mt-1">
                  Drag and drop or browse JPEG, PNG, WebP
                </p>
              </>
            )}
          </div>

          {selectedFile && (
            <div className="flex items-center gap-2">
              <Button
                onClick={handleScan}
                disabled={isScanning}
                className="flex-1 bg-[#0891B2] hover:bg-[#0e7490] text-white font-semibold flex items-center justify-center gap-2"
              >
                {isScanning ? (
                  <>
                    <RefreshCw className="w-4 h-4 animate-spin" />
                    <span>Scanning Vectors...</span>
                  </>
                ) : (
                  <>
                    <Sparkles className="w-4 h-4" />
                    <span>Scan Vector Matches</span>
                  </>
                )}
              </Button>
              <Button
                variant="outline"
                size="sm"
                onClick={handleReset}
                disabled={isScanning}
                className="text-xs text-[#64748B]"
              >
                Reset
              </Button>
            </div>
          )}

          {searchError && (
            <div className="p-3 rounded-xl bg-red-500/10 border border-red-500/30 text-red-600 dark:text-red-400 text-xs flex items-center gap-2">
              <AlertCircle className="w-4 h-4 shrink-0" />
              <span>{searchError}</span>
            </div>
          )}
        </div>

        {/* Results / Matching Zone */}
        <div className="md:col-span-2">
          {isScanning ? (
            <div className="h-full min-h-[260px] rounded-2xl bg-[#F8FAFC] dark:bg-[#0B1220] border border-[#E2E8F0] dark:border-[#1E293B] flex flex-col items-center justify-center p-8 text-center space-y-4">
              <div className="relative">
                <div className="w-16 h-16 rounded-full border-4 border-[#0891B2]/30 border-t-[#0891B2] animate-spin" />
                <Sparkles className="w-6 h-6 text-[#0891B2] absolute inset-0 m-auto" />
              </div>
              <div>
                <h4 className="text-base font-bold text-[#0F172A] dark:text-[#F8FAFC]">
                  Running Qdrant Cosine Similarity Search
                </h4>
                <p className="text-xs text-[#64748B] dark:text-[#94A3B8] max-w-md mt-1">
                  Extracting cranial landmarks, iris pattern vectors, and color histograms to cross-reference disaster registry records...
                </p>
              </div>
            </div>
          ) : searchResult ? (
            <div className="space-y-4">
              {/* Scan summary header */}
              <div className="flex items-center justify-between p-3 rounded-xl bg-[#0891B2]/10 border border-[#0891B2]/20 text-xs">
                <span className="font-semibold text-[#0891B2] dark:text-[#06B6D4]">
                  Engine: {searchResult.engine || 'Qdrant Biometrics DB'}
                </span>
                <span className="text-[#64748B] dark:text-[#94A3B8]">
                  Scanned {searchResult.total_candidates_scanned || 0} candidates in{' '}
                  {searchResult.search_latency_ms || 18}ms
                </span>
              </div>

              {searchResult.matches.length === 0 ? (
                <div className="p-8 text-center rounded-2xl bg-[#F8FAFC] dark:bg-[#0B1220] border border-[#E2E8F0] dark:border-[#1E293B]">
                  <AlertCircle className="w-8 h-8 text-amber-500 mx-auto mb-2" />
                  <h4 className="text-sm font-bold text-[#0F172A] dark:text-[#F8FAFC]">
                    No Vector Similarity Matches Found
                  </h4>
                  <p className="text-xs text-[#64748B] dark:text-[#94A3B8] max-w-sm mx-auto mt-1">
                    None of the registered missing person records met the minimum confidence threshold. You can register this found person as a new bulletin.
                  </p>
                </div>
              ) : (
                <div className="space-y-3 max-h-[500px] overflow-y-auto pr-1">
                  {searchResult.matches.map((match: VisualMatch, idx: number) => {
                    const isHighConfidence = match.confidence_score >= 85;
                    const isMediumConfidence = match.confidence_score >= 70;
                    const p = match.person;

                    return (
                      <div
                        key={idx}
                        className={`p-4 rounded-xl border transition-all ${
                          idx === 0
                            ? 'bg-white dark:bg-[#111A2E] border-[#0891B2] ring-1 ring-[#0891B2]/30 shadow-md'
                            : 'bg-white dark:bg-[#111A2E] border-[#E2E8F0] dark:border-[#1E293B]'
                        }`}
                      >
                        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
                          {/* Person Info */}
                          <div className="flex items-center gap-3">
                            <PersonAvatar
                              photoUrl={p.photo_url}
                              name={p.name}
                              isFound={p.status.toUpperCase() === 'FOUND'}
                              size="lg"
                            />
                            <div>
                              <div className="flex items-center gap-2">
                                <h4 className="font-bold text-base text-[#0F172A] dark:text-[#F8FAFC]">
                                  {p.name}
                                </h4>
                                <span
                                  className={`text-[11px] px-2 py-0.5 rounded-full font-bold ${
                                    isHighConfidence
                                      ? 'bg-emerald-500/15 text-emerald-600 dark:text-emerald-400 border border-emerald-500/30'
                                      : isMediumConfidence
                                      ? 'bg-amber-500/15 text-amber-600 dark:text-amber-400 border border-amber-500/30'
                                      : 'bg-gray-500/15 text-gray-600 dark:text-gray-400 border border-gray-500/30'
                                  }`}
                                >
                                  {match.confidence_score}% Match
                                </span>
                              </div>
                              <p className="text-xs text-[#64748B] dark:text-[#94A3B8]">
                                {p.age} yrs • {p.gender} • ID: {p.id}
                              </p>
                              <div className="flex items-center gap-1.5 text-xs text-[#334155] dark:text-[#CBD5E1] mt-0.5">
                                <MapPin className="w-3.5 h-3.5 text-[#D97706] shrink-0" />
                                <span>{p.last_seen_location}</span>
                              </div>
                            </div>
                          </div>

                          {/* Confirm Button */}
                          <div className="flex sm:flex-col items-end gap-2 shrink-0">
                            <span
                              className={`text-[10px] uppercase font-bold px-2 py-0.5 rounded-full border ${
                                p.status.toUpperCase() === 'FOUND'
                                  ? 'bg-emerald-500/15 text-emerald-600 border-emerald-500/30'
                                  : 'bg-amber-500/15 text-amber-600 border-amber-500/30'
                              }`}
                            >
                              Current: {p.status}
                            </span>
                            <Button
                              size="sm"
                              onClick={() => onConfirmIdentification(p)}
                              className="text-xs bg-emerald-600 hover:bg-emerald-700 text-white font-semibold flex items-center gap-1.5"
                            >
                              <Check className="w-3.5 h-3.5" />
                              <span>Confirm Identification</span>
                            </Button>
                          </div>
                        </div>

                        {/* Matched Vector Features */}
                        {match.matched_features && match.matched_features.length > 0 && (
                          <div className="mt-3 pt-3 border-t border-[#F1F5F9] dark:border-[#1E293B] flex flex-wrap gap-1.5 items-center">
                            <span className="text-[11px] font-semibold text-[#64748B] dark:text-[#94A3B8]">
                              Biometric Resonance:
                            </span>
                            {match.matched_features.map((feat, fidx) => (
                              <span
                                key={fidx}
                                className="px-2 py-0.5 text-[10px] rounded-md bg-[#F1F5F9] dark:bg-[#1E293B] text-[#475569] dark:text-[#CBD5E1] font-mono"
                              >
                                {feat}
                              </span>
                            ))}
                          </div>
                        )}

                        {match.notes && (
                          <div className="mt-2 text-[11px] text-[#64748B] dark:text-[#94A3B8] italic">
                            {match.notes}
                          </div>
                        )}
                      </div>
                    );
                  })}
                </div>
              )}
            </div>
          ) : (
            <div className="h-full min-h-[260px] rounded-2xl bg-[#F8FAFC] dark:bg-[#0B1220] border border-[#E2E8F0] dark:border-[#1E293B] flex flex-col items-center justify-center p-8 text-center">
              <Camera className="w-10 h-10 text-[#94A3B8] mb-3" />
              <h4 className="text-base font-bold text-[#0F172A] dark:text-[#F8FAFC]">
                Ready for Biometric Search
              </h4>
              <p className="text-xs text-[#64748B] dark:text-[#94A3B8] max-w-sm mt-1">
                Upload a photo on the left and trigger vector matching. Qdrant will instantly rank candidates across the disaster registry.
              </p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export const VisualRecognitionModal: React.FC<{
  onClose: () => void;
  onConfirmIdentification: (person: MissingPerson) => void;
}> = ({ onClose, onConfirmIdentification }) => {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-in fade-in">
      <div className="w-full max-w-4xl bg-white dark:bg-[#111A2E] rounded-2xl shadow-2xl border border-[#E2E8F0] dark:border-[#1E293B] overflow-hidden max-h-[90vh] overflow-y-auto p-6">
        <VisualRecognitionPanel
          onConfirmIdentification={onConfirmIdentification}
          onClose={onClose}
        />
      </div>
    </div>
  );
};

// =============================================================================
// REPORT MISSING PERSON MODAL
// =============================================================================

interface ReportMissingModalProps {
  onClose: () => void;
  onSuccess: () => void;
}

const ReportMissingModal: React.FC<ReportMissingModalProps> = ({ onClose, onSuccess }) => {
  const [name, setName] = useState('');
  const [age, setAge] = useState<number | ''>('');
  const [gender, setGender] = useState('Male');
  const [lastSeenLocation, setLastSeenLocation] = useState('');
  const [lat, setLat] = useState<string>('13.0827');
  const [lng, setLng] = useState<string>('80.2707');
  const [description, setDescription] = useState('');
  const [contactPhone, setContactPhone] = useState('');
  const [photoUrl, setPhotoUrl] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name || age === '' || !lastSeenLocation) return;

    setIsSubmitting(true);
    try {
      const payload: CreateMissingPersonPayload = {
        name,
        age: Number(age),
        gender,
        last_seen_location: lastSeenLocation,
        lat: lat ? parseFloat(lat) : undefined,
        lng: lng ? parseFloat(lng) : undefined,
        description,
        contact_phone: contactPhone || undefined,
        photo_url: photoUrl || undefined,
        status: 'MISSING',
        reported_by: 'Command Center Coordinator',
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
      <div className="w-full max-w-lg bg-white dark:bg-[#111A2E] rounded-2xl shadow-2xl border border-[#E2E8F0] dark:border-[#1E293B] overflow-hidden">
        {/* Header */}
        <div className="flex items-center justify-between p-5 border-b border-[#E2E8F0] dark:border-[#1E293B]">
          <div className="flex items-center gap-2">
            <div className="p-2 bg-[#FFD21F]/20 text-[#D97706] dark:text-[#FFD21F] rounded-lg">
              <UserSearch className="w-5 h-5" />
            </div>
            <div>
              <h2 className="text-lg font-bold text-[#0F172A] dark:text-[#F8FAFC]">
                Report Missing Person
              </h2>
              <p className="text-xs text-[#64748B] dark:text-[#94A3B8]">
                Disaster bulletin propagates to mobile mesh nodes & field responders
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
        <form onSubmit={handleSubmit} className="p-5 space-y-4 max-h-[80vh] overflow-y-auto">
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

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-semibold text-[#475569] dark:text-[#CBD5E1] mb-1">
                Age (years) *
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
                <option value="Elderly">Elderly</option>
                <option value="Other">Other</option>
              </select>
            </div>
          </div>

          <div>
            <label className="block text-xs font-semibold text-[#475569] dark:text-[#CBD5E1] mb-1">
              Last Seen Location *
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
                Latitude (optional)
              </label>
              <input
                type="text"
                placeholder="13.0827"
                value={lat}
                onChange={(e) => setLat(e.target.value)}
                className="w-full px-3 py-2 text-sm rounded-lg bg-[#F8FAFC] dark:bg-[#0B1220] border border-[#CBD5E1] dark:border-[#1E293B] text-[#0F172A] dark:text-[#F8FAFC] focus:ring-2 focus:ring-[#FFD21F] focus:outline-none font-mono"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-[#475569] dark:text-[#CBD5E1] mb-1">
                Longitude (optional)
              </label>
              <input
                type="text"
                placeholder="80.2707"
                value={lng}
                onChange={(e) => setLng(e.target.value)}
                className="w-full px-3 py-2 text-sm rounded-lg bg-[#F8FAFC] dark:bg-[#0B1220] border border-[#CBD5E1] dark:border-[#1E293B] text-[#0F172A] dark:text-[#F8FAFC] focus:ring-2 focus:ring-[#FFD21F] focus:outline-none font-mono"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-semibold text-[#475569] dark:text-[#CBD5E1] mb-1">
              Physical Description & Clothing
            </label>
            <textarea
              rows={3}
              placeholder="e.g. White kurta, brown shawl. Separated during flood waters."
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              className="w-full px-3 py-2 text-sm rounded-lg bg-[#F8FAFC] dark:bg-[#0B1220] border border-[#CBD5E1] dark:border-[#1E293B] text-[#0F172A] dark:text-[#F8FAFC] focus:ring-2 focus:ring-[#FFD21F] focus:outline-none resize-none"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-semibold text-[#475569] dark:text-[#CBD5E1] mb-1">
                Family Phone Number
              </label>
              <input
                type="text"
                placeholder="+91 98401 22345"
                value={contactPhone}
                onChange={(e) => setContactPhone(e.target.value)}
                className="w-full px-3 py-2 text-sm rounded-lg bg-[#F8FAFC] dark:bg-[#0B1220] border border-[#CBD5E1] dark:border-[#1E293B] text-[#0F172A] dark:text-[#F8FAFC] focus:ring-2 focus:ring-[#FFD21F] focus:outline-none"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-[#475569] dark:text-[#CBD5E1] mb-1">
                Photo URL / Base64 / Relative Path
              </label>
              <input
                type="text"
                placeholder="https://... or /uploads/..."
                value={photoUrl}
                onChange={(e) => setPhotoUrl(e.target.value)}
                className="w-full px-3 py-2 text-sm rounded-lg bg-[#F8FAFC] dark:bg-[#0B1220] border border-[#CBD5E1] dark:border-[#1E293B] text-[#0F172A] dark:text-[#F8FAFC] focus:ring-2 focus:ring-[#FFD21F] focus:outline-none"
              />
            </div>
          </div>

          {/* Buttons */}
          <div className="pt-3 border-t border-[#E2E8F0] dark:border-[#1E293B] flex items-center justify-end gap-3">
            <Button variant="outline" type="button" onClick={onClose}>
              Cancel
            </Button>
            <Button
              type="submit"
              disabled={isSubmitting}
              className="bg-[#FFD21F] text-[#0B1220] hover:bg-[#FACC15] font-semibold"
            >
              {isSubmitting ? 'Publishing...' : 'Publish Bulletin'}
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
  const [lat, setLat] = useState<string>('13.0840');
  const [lng, setLng] = useState<string>('80.2720');
  const [notes, setNotes] = useState('');
  const [reportedBy, setReportedBy] = useState('Volunteer Unit');
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
                Record Citizen Sighting
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
                Latitude
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
                Longitude
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
}

const PersonDetailModal: React.FC<PersonDetailModalProps> = ({
  person,
  onClose,
  onAddSighting,
  onToggleStatus,
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
        <div className="p-6 space-y-6 overflow-y-auto">
          {/* Key Facts Card */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 p-4 rounded-xl bg-[#F8FAFC] dark:bg-[#0B1220] border border-[#E2E8F0] dark:border-[#1E293B]">
            <div>
              <span className="text-xs font-semibold text-[#64748B] dark:text-[#94A3B8] block">
                Last Seen Location
              </span>
              <span className="text-sm font-semibold text-[#0F172A] dark:text-[#F8FAFC]">
                {person.last_seen_location}
              </span>
              {person.lat && person.lng && (
                <div className="flex items-center gap-2 mt-1">
                  <span className="text-xs text-[#0891B2] dark:text-[#06B6D4] font-mono">
                    [{person.lat.toFixed(4)}, {person.lng.toFixed(4)}]
                  </span>
                  <button
                    onClick={() => copyCoordinates(person.lat!, person.lng!)}
                    className="text-[11px] text-[#64748B] hover:text-[#0891B2] flex items-center gap-0.5"
                    title="Copy coordinates"
                  >
                    <Copy className="w-3 h-3" />
                    <span>{copiedCoords ? 'Copied' : 'Copy'}</span>
                  </button>
                  <a
                    href={`https://www.google.com/maps/search/?api=1&query=${person.lat},${person.lng}`}
                    target="_blank"
                    rel="noreferrer"
                    className="text-[11px] text-[#0891B2] hover:underline flex items-center gap-0.5"
                  >
                    <ExternalLink className="w-3 h-3" />
                    <span>Map</span>
                  </a>
                </div>
              )}
            </div>

            <div>
              <span className="text-xs font-semibold text-[#64748B] dark:text-[#94A3B8] block">
                Family Emergency Contact
              </span>
              <span className="text-sm font-semibold text-[#0F172A] dark:text-[#F8FAFC]">
                {person.contact_phone || 'None provided'}
              </span>
              <span className="text-xs text-[#64748B] dark:text-[#94A3B8] block mt-1">
                Reported by: <strong className="text-[#334155] dark:text-[#CBD5E1]">{person.reported_by}</strong>
              </span>
            </div>

            <div className="sm:col-span-2">
              <span className="text-xs font-semibold text-[#64748B] dark:text-[#94A3B8] block">
                Physical Description & Identifying Features
              </span>
              <p className="text-sm text-[#334155] dark:text-[#CBD5E1] mt-0.5 leading-relaxed">
                {person.description || 'No physical description recorded.'}
              </p>
            </div>
          </div>

          {/* Sightings Timeline */}
          <div>
            <div className="flex items-center justify-between mb-3">
              <h3 className="text-sm font-bold text-[#0F172A] dark:text-[#F8FAFC] flex items-center gap-2">
                <Eye className="w-4 h-4 text-[#06B6D4]" />
                <span>Citizen Sightings Timeline ({person.sightings?.length || 0})</span>
              </h3>
              <Button
                size="sm"
                variant="outline"
                onClick={onAddSighting}
                className="text-xs text-[#0891B2] border-[#0891B2]/40"
              >
                + Add Sighting
              </Button>
            </div>

            {!person.sightings || person.sightings.length === 0 ? (
              <div className="p-5 rounded-xl bg-[#F8FAFC] dark:bg-[#0B1220] border border-[#E2E8F0] dark:border-[#1E293B] text-center text-xs text-[#94A3B8]">
                No sightings recorded yet. Nearby citizen mesh nodes or drone sweeps will log sightings as detected.
              </div>
            ) : (
              <div className="space-y-3">
                {person.sightings.map((st, idx) => (
                  <div
                    key={idx}
                    className="p-3.5 rounded-xl bg-[#F8FAFC] dark:bg-[#0B1220] border border-[#E2E8F0] dark:border-[#1E293B] flex items-start gap-3"
                  >
                    <div className="p-2 rounded-lg bg-[#06B6D4]/15 text-[#0891B2] dark:text-[#06B6D4] shrink-0 mt-0.5">
                      <Compass className="w-4 h-4" />
                    </div>
                    <div className="flex-1">
                      <div className="flex items-center justify-between">
                        <span className="text-xs font-bold text-[#0F172A] dark:text-[#F8FAFC]">
                          {st.location}
                        </span>
                        <span className="text-[11px] text-[#64748B] dark:text-[#94A3B8]">
                          {new Date(st.timestamp).toLocaleString()}
                        </span>
                      </div>
                      {st.notes && (
                        <p className="text-xs text-[#475569] dark:text-[#94A3B8] mt-1">
                          {st.notes}
                        </p>
                      )}
                      <div className="mt-2 flex flex-wrap items-center gap-3 text-[11px] text-[#64748B] dark:text-[#94A3B8]">
                        <span>
                          Reported by:{' '}
                          <strong className="text-[#0891B2] dark:text-[#06B6D4]">
                            {st.reported_by}
                          </strong>
                        </span>
                        {st.lat && st.lng && (
                          <div className="flex items-center gap-1.5 font-mono text-[10.5px] bg-[#E2E8F0] dark:bg-[#1E293B] px-2 py-0.5 rounded">
                            <span>
                              GPS: {st.lat.toFixed(4)}, {st.lng.toFixed(4)}
                            </span>
                            <a
                              href={`https://www.google.com/maps/search/?api=1&query=${st.lat},${st.lng}`}
                              target="_blank"
                              rel="noreferrer"
                              className="text-[#0891B2] hover:underline"
                              title="Open in Maps"
                            >
                              <ExternalLink className="w-3 h-3" />
                            </a>
                          </div>
                        )}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>

        {/* Footer Actions */}
        <div className="p-4 border-t border-[#E2E8F0] dark:border-[#1E293B] flex items-center justify-between">
          <Button variant="outline" onClick={onClose}>
            Close
          </Button>

          <div className="flex items-center gap-2">
            {isFound ? (
              <Button
                variant="outline"
                onClick={() => onToggleStatus('MISSING')}
                className="text-xs text-amber-600 dark:text-amber-400 border-amber-500/40 hover:bg-amber-500/10"
              >
                Mark as Active Missing
              </Button>
            ) : (
              <Button
                onClick={() => onToggleStatus('FOUND')}
                className="bg-emerald-600 hover:bg-emerald-700 text-white font-semibold flex items-center gap-1.5"
              >
                <CheckCircle2 className="w-4 h-4" />
                <span>Mark as Found & Reunited</span>
              </Button>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default MissingPersonsPage;

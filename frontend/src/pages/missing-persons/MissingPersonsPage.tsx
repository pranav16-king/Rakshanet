import React, { useState, useEffect } from 'react';
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
  Calendar,
  ShieldAlert,
} from 'lucide-react';
import { Card } from '../../components/common/Card';
import { Button } from '../../components/common/Button';
import {
  getMissingPersons,
  createMissingPerson,
  updateMissingPersonStatus,
  addMissingPersonSighting,
} from '../../api/missingPersons';
import type {
  MissingPerson,
  MissingPersonStatusFilter,
  CreateMissingPersonPayload,
  CreateSightingPayload,
} from '../../types/missingPerson';

export const MissingPersonsPage: React.FC = () => {
  const [persons, setPersons] = useState<MissingPerson[]>([]);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [selectedStatus, setSelectedStatus] = useState<MissingPersonStatusFilter>('ALL');
  const [searchQuery, setSearchQuery] = useState<string>('');

  // Modals state
  const [isReportModalOpen, setIsReportModalOpen] = useState<boolean>(false);
  const [sightingModalPerson, setSightingModalPerson] = useState<MissingPerson | null>(null);
  const [detailModalPerson, setDetailModalPerson] = useState<MissingPerson | null>(null);

  const fetchPersons = async () => {
    setIsLoading(true);
    try {
      const data = await getMissingPersons(
        selectedStatus === 'ALL' ? undefined : selectedStatus,
        searchQuery
      );
      setPersons(data);
      // If detail modal is open, keep it in sync
      if (detailModalPerson) {
        const updated = data.find((p) => p.id === detailModalPerson.id);
        if (updated) setDetailModalPerson(updated);
      }
    } catch (err) {
      console.error('Failed to load missing persons:', err);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchPersons();
  }, [selectedStatus, searchQuery]);

  const totalCount = persons.length;
  const missingCount = persons.filter((p) => p.status.toUpperCase() !== 'FOUND').length;
  const foundCount = persons.filter((p) => p.status.toUpperCase() === 'FOUND').length;
  const totalSightings = persons.reduce((acc, p) => acc + (p.sightings?.length || 0), 0);

  const handleMarkFound = async (person: MissingPerson) => {
    try {
      await updateMissingPersonStatus(person.id, 'FOUND');
      fetchPersons();
    } catch (err) {
      console.error('Failed to mark found:', err);
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
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <div className="p-2 bg-[#FFD21F]/15 dark:bg-[#FFD21F]/20 text-[#D97706] dark:text-[#FFD21F] rounded-lg">
              <UserSearch className="w-6 h-6" />
            </div>
            <div>
              <h1 className="text-2xl font-bold tracking-tight text-[#16202D] dark:text-[#EEF2F8]">
                Missing Persons Registry
              </h1>
              <p className="text-sm text-[#4E6178] dark:text-[#8E9EB5]">
                Disaster family reunification registry, peer-to-peer mesh bulletins & citizen sightings
              </p>
            </div>
          </div>
        </div>

        <Button
          onClick={() => setIsReportModalOpen(true)}
          className="bg-[#FFD21F] text-[#0B1220] hover:bg-[#FACC15] font-semibold flex items-center gap-2 shadow-sm"
        >
          <Plus className="w-4 h-4" />
          Report Missing Person
        </Button>
      </div>

      {/* KPI Metrics Strip */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <Card className="p-4 bg-white dark:bg-[#111A2E] border-[#E2E8F0] dark:border-[#1E293B]">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-[#64748B] dark:text-[#94A3B8] uppercase tracking-wider">
              Total Bulletins
            </span>
            <Users className="w-4 h-4 text-[#3B82F6]" />
          </div>
          <div className="mt-2 text-2xl font-bold text-[#0F172A] dark:text-[#F8FAFC]">
            {totalCount}
          </div>
        </Card>

        <Card className="p-4 bg-white dark:bg-[#111A2E] border-[#E2E8F0] dark:border-[#1E293B]">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-[#F59E0B] uppercase tracking-wider">
              Active Missing
            </span>
            <AlertCircle className="w-4 h-4 text-[#F59E0B]" />
          </div>
          <div className="mt-2 text-2xl font-bold text-[#F59E0B]">
            {missingCount}
          </div>
        </Card>

        <Card className="p-4 bg-white dark:bg-[#111A2E] border-[#E2E8F0] dark:border-[#1E293B]">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-[#10B981] uppercase tracking-wider">
              Reunited / Found
            </span>
            <CheckCircle2 className="w-4 h-4 text-[#10B981]" />
          </div>
          <div className="mt-2 text-2xl font-bold text-[#10B981]">
            {foundCount}
          </div>
        </Card>

        <Card className="p-4 bg-white dark:bg-[#111A2E] border-[#E2E8F0] dark:border-[#1E293B]">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-[#06B6D4] uppercase tracking-wider">
              Sightings Logged
            </span>
            <Eye className="w-4 h-4 text-[#06B6D4]" />
          </div>
          <div className="mt-2 text-2xl font-bold text-[#06B6D4]">
            {totalSightings}
          </div>
        </Card>
      </div>

      {/* Search & Filter Controls */}
      <Card className="p-4 bg-white dark:bg-[#111A2E] border-[#E2E8F0] dark:border-[#1E293B]">
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
                {st === 'ALL' ? 'All Bulletins' : st === 'MISSING' ? 'Active Missing' : 'Found / Reunited'}
              </button>
            ))}
          </div>
        </div>
      </Card>

      {/* Main Grid */}
      {isLoading ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
          {[1, 2, 3].map((i) => (
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
            No matching reports found for current filters. Reports submitted from field mobiles over mesh or cloud will appear here immediately.
          </p>
          <Button
            onClick={() => setIsReportModalOpen(true)}
            className="bg-[#FFD21F] text-[#0B1220] hover:bg-[#FACC15] font-semibold"
          >
            Create New Report
          </Button>
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
                    ? 'border-[#10B981]/30 dark:border-[#10B981]/40'
                    : 'border-[#E2E8F0] dark:border-[#1E293B]'
                }`}
              >
                <div className="p-5 flex flex-col justify-between h-full">
                  <div>
                    {/* Header: Photo/Avatar, Name, Age/Gender, Status Badge */}
                    <div className="flex items-start justify-between gap-3">
                      <div className="flex items-center gap-3">
                        {person.photo_url ? (
                          <img
                            src={person.photo_url}
                            alt={person.name}
                            className="w-12 h-12 rounded-xl object-cover border border-[#E2E8F0] dark:border-[#334155]"
                          />
                        ) : (
                          <div
                            className={`w-12 h-12 rounded-xl flex items-center justify-center font-bold text-lg ${
                              isFound
                                ? 'bg-[#10B981]/15 text-[#10B981]'
                                : 'bg-[#FFD21F]/20 text-[#B45309] dark:text-[#FFD21F]'
                            }`}
                          >
                            {person.name.charAt(0).toUpperCase()}
                          </div>
                        )}
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

                      <span
                        className={`text-xs px-2.5 py-0.5 rounded-full uppercase tracking-wide font-bold border ${
                          isFound
                            ? 'bg-[#10B981]/15 text-[#10B981] border-[#10B981]/30'
                            : 'bg-[#F59E0B]/15 text-[#F59E0B] border-[#F59E0B]/30'
                        }`}
                      >
                        {isFound ? 'FOUND' : 'MISSING'}
                      </span>
                    </div>

                    {/* Last Seen Location */}
                    <div className="mt-4 flex items-start gap-2 text-xs text-[#334155] dark:text-[#CBD5E1]">
                      <MapPin className="w-4 h-4 text-[#D97706] dark:text-[#FFD21F] shrink-0 mt-0.5" />
                      <div>
                        <span className="font-semibold text-[#0F172A] dark:text-[#F8FAFC]">
                          {person.last_seen_location}
                        </span>
                        {person.lat && person.lng && (
                          <span className="block text-[11px] text-[#64748B] dark:text-[#94A3B8] font-mono">
                            [{person.lat.toFixed(4)}, {person.lng.toFixed(4)}]
                          </span>
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
                        <span>Reported {formatTimeAgo(person.reported_at)} by {person.reported_by}</span>
                      </div>
                    </div>

                    {/* Sightings Snippet */}
                    <div className="mt-3">
                      {person.sightings && person.sightings.length > 0 ? (
                        <div className="p-2.5 rounded-lg bg-[#06B6D4]/10 dark:bg-[#06B6D4]/15 border border-[#06B6D4]/20 flex items-center justify-between">
                          <div className="flex items-center gap-2">
                            <Eye className="w-4 h-4 text-[#0891B2] dark:text-[#06B6D4]" />
                            <span className="text-xs font-semibold text-[#0891B2] dark:text-[#06B6D4]">
                              {person.sightings.length} Sighting{person.sightings.length > 1 ? 's' : ''} Logged
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
                      Details & History
                    </Button>

                    {!isFound && (
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
                          onClick={() => handleMarkFound(person)}
                          className="text-xs bg-[#10B981] hover:bg-[#059669] text-white"
                        >
                          Mark Found
                        </Button>
                      </>
                    )}
                  </div>
                </div>
              </Card>
            );
          })}
        </div>
      )}

      {/* Modal: Report Missing Person */}
      {isReportModalOpen && (
        <ReportMissingModal
          onClose={() => setIsReportModalOpen(false)}
          onSuccess={() => {
            setIsReportModalOpen(false);
            fetchPersons();
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
          }}
        />
      )}

      {/* Drawer / Modal: Person Detail & Sightings Timeline */}
      {detailModalPerson && (
        <PersonDetailModal
          person={detailModalPerson}
          onClose={() => setDetailModalPerson(null)}
          onAddSighting={() => {
            const p = detailModalPerson;
            setDetailModalPerson(null);
            setSightingModalPerson(p);
          }}
          onMarkFound={async () => {
            await handleMarkFound(detailModalPerson);
            setDetailModalPerson(null);
          }}
        />
      )}
    </div>
  );
};

// =============================================================================
// SUB-COMPONENTS & MODALS
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
                Photo URL (optional)
              </label>
              <input
                type="text"
                placeholder="https://..."
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

interface RecordSightingModalProps {
  person: MissingPerson;
  onClose: () => void;
  onSuccess: () => void;
}

const RecordSightingModal: React.FC<RecordSightingModalProps> = ({ person, onClose, onSuccess }) => {
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

interface PersonDetailModalProps {
  person: MissingPerson;
  onClose: () => void;
  onAddSighting: () => void;
  onMarkFound: () => void;
}

const PersonDetailModal: React.FC<PersonDetailModalProps> = ({
  person,
  onClose,
  onAddSighting,
  onMarkFound,
}) => {
  const isFound = person.status.toUpperCase() === 'FOUND';

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-in fade-in">
      <div className="w-full max-w-2xl bg-white dark:bg-[#111A2E] rounded-2xl shadow-2xl border border-[#E2E8F0] dark:border-[#1E293B] overflow-hidden flex flex-col max-h-[85vh]">
        {/* Header */}
        <div className="flex items-center justify-between p-5 border-b border-[#E2E8F0] dark:border-[#1E293B]">
          <div className="flex items-center gap-3">
            {person.photo_url ? (
              <img
                src={person.photo_url}
                alt={person.name}
                className="w-12 h-12 rounded-xl object-cover border border-[#CBD5E1]"
              />
            ) : (
              <div
                className={`w-12 h-12 rounded-xl flex items-center justify-center font-bold text-lg ${
                  isFound ? 'bg-[#10B981]/20 text-[#10B981]' : 'bg-[#FFD21F]/20 text-[#D97706]'
                }`}
              >
                {person.name.charAt(0).toUpperCase()}
              </div>
            )}
            <div>
              <div className="flex items-center gap-2">
                <h2 className="text-xl font-bold text-[#0F172A] dark:text-[#F8FAFC]">
                  {person.name}
                </h2>
                <span
                  className={`text-xs px-2.5 py-0.5 rounded-full font-bold uppercase tracking-wider border ${
                    isFound
                      ? 'bg-[#10B981]/15 text-[#10B981] border-[#10B981]/30'
                      : 'bg-[#F59E0B]/15 text-[#F59E0B] border-[#F59E0B]/30'
                  }`}
                >
                  {isFound ? 'FOUND / REUNITED' : 'ACTIVE MISSING'}
                </span>
              </div>
              <p className="text-xs text-[#64748B] dark:text-[#94A3B8]">
                {person.age} years old • {person.gender} • ID: {person.id}
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
                <span className="block text-xs text-[#06B6D4] font-mono mt-0.5">
                  Coordinates: {person.lat}, {person.lng}
                </span>
              )}
            </div>

            <div>
              <span className="text-xs font-semibold text-[#64748B] dark:text-[#94A3B8] block">
                Family Emergency Contact
              </span>
              <span className="text-sm font-semibold text-[#0F172A] dark:text-[#F8FAFC]">
                {person.contact_phone || 'None provided'}
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
                Citizen Sightings Timeline ({person.sightings?.length || 0})
              </h3>
              {!isFound && (
                <Button
                  size="sm"
                  variant="outline"
                  onClick={onAddSighting}
                  className="text-xs text-[#0891B2] border-[#0891B2]/40"
                >
                  + Add Sighting
                </Button>
              )}
            </div>

            {(!person.sightings || person.sightings.length === 0) ? (
              <div className="p-4 rounded-xl bg-[#F8FAFC] dark:bg-[#0B1220] border border-[#E2E8F0] dark:border-[#1E293B] text-center text-xs text-[#94A3B8]">
                No sightings recorded yet. Nearby citizen devices or search drones will log sightings as detected.
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
                      <div className="mt-1 flex items-center gap-3 text-[11px] text-[#64748B] dark:text-[#94A3B8]">
                        <span>Reported by: <strong className="text-[#0891B2] dark:text-[#06B6D4]">{st.reported_by}</strong></span>
                        {st.lat && st.lng && (
                          <span className="font-mono text-[10.5px]">GPS: {st.lat}, {st.lng}</span>
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

          {!isFound && (
            <Button
              onClick={onMarkFound}
              className="bg-[#10B981] hover:bg-[#059669] text-white font-semibold flex items-center gap-1.5"
            >
              <CheckCircle2 className="w-4 h-4" />
              Mark as Found & Reunited
            </Button>
          )}
        </div>
      </div>
    </div>
  );
};
export default MissingPersonsPage;

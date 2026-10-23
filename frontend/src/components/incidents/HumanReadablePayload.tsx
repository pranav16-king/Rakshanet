// frontend/src/components/incidents/HumanReadablePayload.tsx
import React from 'react';
import {
  UserSearch,
  ShieldAlert,
  Phone,
  MapPin,
  Clock,
  User,
  CheckCheck,
  Mic,
  Camera,
  FileText,
  AlertCircle,
  ExternalLink,
} from 'lucide-react';

interface HumanReadablePayloadProps {
  content: string;
  category?: string;
  title?: string;
  meta?: Record<string, any>;
}

export const HumanReadablePayload: React.FC<HumanReadablePayloadProps> = ({
  content,
  category,
  title,
  meta,
}) => {
  // Try parsing JSON if content begins with { or [
  let parsed: any = null;
  const trimmed = typeof content === 'string' ? content.trim() : '';

  if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
    try {
      parsed = JSON.parse(trimmed);
    } catch {
      parsed = null;
    }
  }

  // -------------------------------------------------------------
  // 1. MISSING PERSON RECORD (Parsed JSON or object)
  // -------------------------------------------------------------
  const isMissingPerson =
    (parsed && typeof parsed === 'object' && (parsed.name || parsed.id?.startsWith('mp_') || parsed.last_seen_location)) ||
    title === 'MISSING_PERSON';

  if (isMissingPerson && parsed) {
    const p = parsed;
    return (
      <div className="mt-2 p-3.5 rounded-xl bg-purple-500/5 dark:bg-purple-950/25 border border-purple-500/25 space-y-2.5">
        <div className="flex items-center justify-between gap-2 flex-wrap pb-2 border-b border-purple-500/20">
          <div className="flex items-center gap-2">
            <span className="p-1.5 rounded-lg bg-purple-600 text-white shrink-0">
              <UserSearch className="w-4 h-4" />
            </span>
            <div>
              <span className="text-[11px] font-bold uppercase tracking-wider text-purple-700 dark:text-purple-300">
                Missing Person Field Record
              </span>
              <h5 className="text-sm font-bold text-[#0F172A] dark:text-[#F8FAFC]">
                {p.name || 'Unnamed Individual'}
              </h5>
            </div>
          </div>

          <div className="flex items-center gap-1.5">
            {p.age && (
              <span className="text-xs px-2 py-0.5 rounded-md font-semibold bg-purple-100 dark:bg-purple-900/50 text-purple-800 dark:text-purple-200">
                {p.age} yrs {p.gender ? `• ${p.gender}` : ''}
              </span>
            )}
            <span className="text-xs px-2 py-0.5 rounded-md font-bold uppercase bg-red-500 text-white animate-pulse">
              {p.status || 'MISSING'}
            </span>
          </div>
        </div>

        {/* Key Attributes Grid */}
        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-2.5 text-xs text-[#334155] dark:text-[#CBD5E1]">
          {p.last_seen_location && (
            <div className="flex items-start gap-1.5">
              <MapPin className="w-3.5 h-3.5 text-cyan-600 dark:text-cyan-400 shrink-0 mt-0.5" />
              <div>
                <span className="text-[10px] uppercase font-bold text-[#64748B] dark:text-[#94A3B8] block">
                  Last Seen Location
                </span>
                <span className="font-semibold text-slate-900 dark:text-white capitalize">
                  {p.last_seen_location}
                </span>
              </div>
            </div>
          )}

          {p.description && (
            <div className="flex items-start gap-1.5">
              <User className="w-3.5 h-3.5 text-amber-600 dark:text-amber-400 shrink-0 mt-0.5" />
              <div>
                <span className="text-[10px] uppercase font-bold text-[#64748B] dark:text-[#94A3B8] block">
                  Appearance / Clothing
                </span>
                <span className="font-medium text-slate-800 dark:text-slate-200">
                  {p.description}
                </span>
              </div>
            </div>
          )}

          {p.contact_phone && (
            <div className="flex items-start gap-1.5">
              <Phone className="w-3.5 h-3.5 text-emerald-600 dark:text-emerald-400 shrink-0 mt-0.5" />
              <div>
                <span className="text-[10px] uppercase font-bold text-[#64748B] dark:text-[#94A3B8] block">
                  Family / Contact Phone
                </span>
                <a
                  href={`tel:${p.contact_phone}`}
                  className="font-mono font-bold text-emerald-700 dark:text-emerald-400 hover:underline"
                >
                  {p.contact_phone}
                </a>
              </div>
            </div>
          )}

          {p.reported_by && (
            <div className="flex items-start gap-1.5">
              <User className="w-3.5 h-3.5 text-slate-500 shrink-0 mt-0.5" />
              <div>
                <span className="text-[10px] uppercase font-bold text-[#64748B] dark:text-[#94A3B8] block">
                  Reported By
                </span>
                <span className="font-medium">{p.reported_by}</span>
              </div>
            </div>
          )}

          {p.id && (
            <div className="flex items-start gap-1.5">
              <FileText className="w-3.5 h-3.5 text-purple-500 shrink-0 mt-0.5" />
              <div>
                <span className="text-[10px] uppercase font-bold text-[#64748B] dark:text-[#94A3B8] block">
                  Docket ID
                </span>
                <span className="font-mono text-[11px] text-purple-700 dark:text-purple-300">
                  {p.id}
                </span>
              </div>
            </div>
          )}
        </div>

        {/* Photo attachment notification */}
        {(p.photo_path || p.photo_url) && (
          <div className="pt-2 border-t border-purple-500/15 flex items-center gap-2 text-xs text-purple-800 dark:text-purple-300">
            <Camera className="w-3.5 h-3.5 text-purple-600" />
            <span className="font-semibold">Handset Evidence Photo Attached:</span>
            <span className="font-mono text-[11px] truncate max-w-[240px] opacity-80">
              {p.photo_path ? p.photo_path.split('/').pop() : 'Cloud Photo URL Available'}
            </span>
          </div>
        )}
      </div>
    );
  }

  // -------------------------------------------------------------
  // 2. SOS DISTRESS PAYLOAD (Parsed JSON with category, people_count)
  // -------------------------------------------------------------
  const isSosPayload =
    (parsed && typeof parsed === 'object' && (parsed.category || parsed.people_count !== undefined)) ||
    category === 'SOS' ||
    title === 'SOS';

  if (isSosPayload && parsed) {
    return (
      <div className="mt-2 p-3 rounded-xl bg-red-500/10 dark:bg-red-950/30 border border-red-500/30 space-y-2">
        <div className="flex items-center gap-2 text-red-700 dark:text-red-300 font-bold text-xs uppercase tracking-wider">
          <ShieldAlert className="w-4 h-4 text-red-600 shrink-0" />
          <span>Critical Distress Signal: {parsed.category || 'Emergency SOS'}</span>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 text-xs">
          <div className="flex items-center gap-1.5">
            <span className="text-[#64748B] dark:text-[#94A3B8]">Persons at Risk:</span>
            <span className="font-bold text-red-700 dark:text-red-400 px-2 py-0.5 rounded bg-red-500/15">
              {parsed.people_count ?? parsed.peopleCount ?? 1} Person(s)
            </span>
          </div>

          <div className="flex items-center gap-1.5">
            <span className="text-[#64748B] dark:text-[#94A3B8]">Distress Note:</span>
            <span className="font-medium text-slate-800 dark:text-slate-200">
              {parsed.notes ? `"${parsed.notes}"` : 'Immediate rescue assistance requested'}
            </span>
          </div>
        </div>
      </div>
    );
  }

  // -------------------------------------------------------------
  // 3. DELIVERY ACKNOWLEDGMENT (UUID receipt)
  // -------------------------------------------------------------
  const isAck =
    title === 'DELIVERY_ACK' ||
    /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/.test(
      trimmed.replace(/^"|"$/g, '')
    );

  if (isAck) {
    const ackId = trimmed.replace(/^"|"$/g, '');
    return (
      <div className="mt-2 p-2.5 rounded-xl bg-emerald-500/10 dark:bg-emerald-950/30 border border-emerald-500/25 flex items-center justify-between gap-3 text-xs">
        <div className="flex items-center gap-2">
          <span className="p-1 rounded bg-emerald-600 text-white shrink-0">
            <CheckCheck className="w-3.5 h-3.5" />
          </span>
          <div>
            <span className="font-bold text-emerald-800 dark:text-emerald-300">
              Packet Delivery Confirmed
            </span>
            <div className="font-mono text-[11px] text-emerald-700 dark:text-emerald-400">
              Ack Receipt ID: {ackId}
            </div>
          </div>
        </div>
        <span className="px-2 py-0.5 rounded-full font-mono text-[10px] font-bold bg-emerald-500/20 text-emerald-700 dark:text-emerald-300">
          DELIVERED
        </span>
      </div>
    );
  }

  // -------------------------------------------------------------
  // 4. OFFLINE VOICE NOTE
  // -------------------------------------------------------------
  const isVoice = title === 'VOICE' || trimmed.includes('Offline Voice Note') || trimmed.includes('.aac');
  if (isVoice) {
    const cleanVoice = trimmed.replace(/^"|"$/g, '');
    return (
      <div className="mt-2 p-2.5 rounded-xl bg-purple-500/10 dark:bg-purple-950/30 border border-purple-500/25 flex items-center justify-between gap-3 text-xs">
        <div className="flex items-center gap-2">
          <span className="p-1.5 rounded-lg bg-purple-600 text-white shrink-0">
            <Mic className="w-3.5 h-3.5" />
          </span>
          <div>
            <span className="font-bold text-purple-900 dark:text-purple-200">
              Offline Tactical Voice Recording
            </span>
            <div className="text-[11px] text-purple-700 dark:text-purple-300 font-mono">
              {cleanVoice}
            </div>
          </div>
        </div>
        <div className="flex items-center gap-1 text-[10px] font-bold px-2 py-0.5 rounded-full bg-purple-500/20 text-purple-700 dark:text-purple-300 font-mono">
          <span>AUDIO CAPTURED</span>
        </div>
      </div>
    );
  }

  // -------------------------------------------------------------
  // 5. ATTACHED IMAGE
  // -------------------------------------------------------------
  const isImage = title === 'IMAGE' || trimmed.includes('📷 Image:') || trimmed.includes('.jpg');
  if (isImage) {
    const cleanImg = trimmed.replace(/^"|"$/g, '');
    return (
      <div className="mt-2 p-2.5 rounded-xl bg-cyan-500/10 dark:bg-cyan-950/30 border border-cyan-500/25 flex items-center justify-between gap-3 text-xs">
        <div className="flex items-center gap-2">
          <span className="p-1.5 rounded-lg bg-cyan-600 text-white shrink-0">
            <Camera className="w-3.5 h-3.5" />
          </span>
          <div>
            <span className="font-bold text-cyan-900 dark:text-cyan-200">
              Mesh Field Photo Ingested
            </span>
            <div className="text-[11px] text-cyan-700 dark:text-cyan-300 font-mono">
              {cleanImg}
            </div>
          </div>
        </div>
        <span className="px-2 py-0.5 rounded-full font-mono text-[10px] font-bold bg-cyan-500/20 text-cyan-700 dark:text-cyan-300">
          IMAGE ATTACHED
        </span>
      </div>
    );
  }

  // -------------------------------------------------------------
  // 6. STANDARD CLEAN TEXT (Strip accidental surrounding quotes)
  // -------------------------------------------------------------
  let displayText = trimmed;
  if (displayText.startsWith('"') && displayText.endsWith('"') && displayText.length >= 2) {
    displayText = displayText.slice(1, -1);
  }

  return (
    <p className="text-xs text-[#1E293B] dark:text-[#E2E8F0] mt-1.5 leading-relaxed font-normal">
      "{displayText}"
    </p>
  );
};

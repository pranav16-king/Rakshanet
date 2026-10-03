import React, { useState } from 'react';
import {
  X,
  Shield,
  ShieldAlert,
  ShieldCheck,
  Lock,
  Unlock,
  Phone,
  UserCheck,
  HeartPulse,
  Radio,
  MapPin,
  Clock,
} from 'lucide-react';
import type { Person } from '../../types/people';
import { StatusBadge } from '../common/StatusBadge';

interface UserDetailsModalProps {
  person: Person | null;
  isOpen: boolean;
  onClose: () => void;
  onAuthorizeChange: (personId: string, authorized: boolean) => void;
}

export const UserDetailsModal: React.FC<UserDetailsModalProps> = ({
  person,
  isOpen,
  onClose,
  onAuthorizeChange,
}) => {
  const [authReason, setAuthReason] = useState('');
  const [showAuthPrompt, setShowAuthPrompt] = useState(false);

  if (!isOpen || !person) return null;

  const isAuthorized = person.isAuthorized ?? false;

  const handleGrantAuth = (e: React.FormEvent) => {
    e.preventDefault();
    onAuthorizeChange(person.id, true);
    setShowAuthPrompt(false);
  };

  const handleRevokeAuth = () => {
    onAuthorizeChange(person.id, false);
  };

  // Masking helpers
  const maskPhone = (phone: string) => {
    if (isAuthorized) return phone;
    // e.g. +91 98765 43210 -> +91 ••••• ••210
    const parts = phone.split(' ');
    if (parts.length >= 3) {
      return `${parts[0]} ••••• ••${parts[2].slice(-3)}`;
    }
    return '+91 ••••• ••' + phone.slice(-3);
  };

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-labelledby="user-details-title"
      className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs"
    >
      <div className="bg-white dark:bg-slate-900 rounded-2xl max-w-lg w-full border border-slate-200 dark:border-slate-800 shadow-2xl overflow-hidden animate-in fade-in zoom-in-95 duration-150">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-slate-100 dark:border-slate-800 bg-slate-50 dark:bg-slate-800/40">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-[#FFC400]/20 text-[#8A5A00] dark:text-[#FFC400] flex items-center justify-center font-bold text-sm">
              {person.avatarInitial}
            </div>
            <div>
              <h3 id="user-details-title" className="text-base font-bold text-slate-900 dark:text-slate-100">
                {person.name}
              </h3>
              <div className="flex items-center gap-2 text-xs text-slate-500">
                <span>{person.role}</span>
                <span>•</span>
                <span>{person.location}</span>
              </div>
            </div>
          </div>
          <button
            onClick={onClose}
            className="text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 p-1.5 rounded-lg"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        <div className="p-6 space-y-6 max-h-[75vh] overflow-y-auto">
          {/* Privacy & Authorization Banner */}
          <div
            className={`p-3.5 rounded-xl border flex items-start gap-3 text-xs leading-relaxed ${
              isAuthorized
                ? 'bg-emerald-50 dark:bg-emerald-950/40 border-emerald-200 dark:border-emerald-900 text-emerald-800 dark:text-emerald-300'
                : 'bg-amber-50 dark:bg-amber-950/40 border-amber-200 dark:border-amber-900 text-amber-900 dark:text-amber-200'
            }`}
          >
            {isAuthorized ? (
              <ShieldCheck className="w-5 h-5 shrink-0 text-emerald-600 dark:text-emerald-400 mt-0.5" />
            ) : (
              <Lock className="w-5 h-5 shrink-0 text-amber-600 dark:text-amber-400 mt-0.5" />
            )}
            <div className="flex-1">
              <div className="font-bold flex items-center justify-between">
                <span>
                  {isAuthorized
                    ? 'Authorized Personnel Session Active'
                    : 'Privacy Protection Active (Sensitive Data Masked)'}
                </span>
                {isAuthorized ? (
                  <button
                    onClick={handleRevokeAuth}
                    className="text-xs text-emerald-700 dark:text-emerald-400 underline font-semibold ml-2 hover:opacity-80"
                  >
                    Lock Session
                  </button>
                ) : (
                  <button
                    onClick={() => setShowAuthPrompt(true)}
                    className="text-xs font-bold px-2 py-1 bg-amber-200 dark:bg-amber-800 text-amber-950 dark:text-amber-100 rounded-md hover:bg-amber-300 ml-2"
                  >
                    Authorize Access
                  </button>
                )}
              </div>
              <p className="mt-1 opacity-90">
                {isAuthorized
                  ? 'Access authorized under Emergency Response Mandate. Sensitive medical and contact records are visible for rescue coordination.'
                  : 'Personal medical records and emergency contact details are encrypted and masked to prevent unauthorized field disclosure.'}
              </p>
            </div>
          </div>

          {/* Authorization prompt popup inside modal */}
          {showAuthPrompt && (
            <form
              onSubmit={handleGrantAuth}
              className="p-4 rounded-xl border border-[#FFC400] bg-amber-50/50 dark:bg-slate-800 space-y-3"
            >
              <div className="flex items-center gap-2 text-xs font-bold text-slate-900 dark:text-slate-100">
                <ShieldAlert className="w-4 h-4 text-[#8A5A00] dark:text-[#FFC400]" />
                <span>Affirm Authorization & Specify Rescue Justification</span>
              </div>
              <input
                type="text"
                required
                placeholder="Reason (e.g. Active field medical dispatch in Sector 4)"
                value={authReason}
                onChange={(e) => setAuthReason(e.target.value)}
                className="w-full px-3 py-1.5 text-xs bg-white dark:bg-slate-900 border border-slate-300 dark:border-slate-700 rounded-lg text-slate-900 dark:text-slate-100"
              />
              <div className="flex justify-end gap-2">
                <button
                  type="button"
                  onClick={() => setShowAuthPrompt(false)}
                  className="px-3 py-1 text-xs text-slate-600 dark:text-slate-400 hover:bg-slate-200/50 rounded"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-3 py-1 text-xs font-bold bg-[#FFC400] text-slate-950 rounded hover:bg-[#E0AA00]"
                >
                  Confirm & Unmask
                </button>
              </div>
            </form>
          )}

          {/* General Device & Location Metadata */}
          <div className="grid grid-cols-2 gap-3 text-xs">
            <div className="p-3 rounded-xl bg-slate-50 dark:bg-slate-800/40 border border-slate-200/60 dark:border-slate-800">
              <span className="text-slate-400 block mb-1">Status & Network</span>
              <div className="flex items-center gap-2">
                <StatusBadge
                  label={person.status}
                  type={person.status === 'Online' ? 'online' : 'offline'}
                  dot
                />
                <span className="text-slate-500 font-mono text-[11px]">{person.deviceId}</span>
              </div>
            </div>

            <div className="p-3 rounded-xl bg-slate-50 dark:bg-slate-800/40 border border-slate-200/60 dark:border-slate-800">
              <span className="text-slate-400 block mb-1">Last Heartbeat</span>
              <div className="flex items-center gap-1.5 font-medium text-slate-700 dark:text-slate-300">
                <Clock className="w-3.5 h-3.5 text-slate-400" />
                <span>{person.lastActive}</span>
              </div>
            </div>
          </div>

          {/* Emergency Contact Card */}
          <div className="p-4 rounded-xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 space-y-2">
            <div className="flex items-center justify-between">
              <h4 className="text-xs font-bold text-slate-900 dark:text-slate-100 uppercase tracking-wider flex items-center gap-2">
                <Phone className="w-3.5 h-3.5 text-[#8A5A00] dark:text-[#FFC400]" />
                Emergency Contact
              </h4>
              {!isAuthorized && (
                <span className="text-[11px] text-amber-600 dark:text-amber-400 font-medium flex items-center gap-1">
                  <Lock className="w-3 h-3" /> Masked
                </span>
              )}
            </div>

            <div className="text-xs space-y-1.5 pt-1">
              <div className="flex justify-between">
                <span className="text-slate-400">Contact Name:</span>
                <span className="font-semibold text-slate-800 dark:text-slate-200">
                  {person.emergencyContact.name} ({person.emergencyContact.relationship})
                </span>
              </div>

              <div className="flex justify-between items-center">
                <span className="text-slate-400">Emergency Phone:</span>
                <span className={`font-mono text-xs ${isAuthorized ? 'text-emerald-700 dark:text-emerald-400 font-bold' : 'text-slate-500'}`}>
                  {maskPhone(person.emergencyContact.phone)}
                </span>
              </div>
            </div>
          </div>

          {/* Medical Details Card */}
          <div className="p-4 rounded-xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 space-y-2.5">
            <div className="flex items-center justify-between">
              <h4 className="text-xs font-bold text-slate-900 dark:text-slate-100 uppercase tracking-wider flex items-center gap-2">
                <HeartPulse className="w-3.5 h-3.5 text-red-500" />
                Medical & Triage Notes
              </h4>
              {!isAuthorized && (
                <span className="text-[11px] text-amber-600 dark:text-amber-400 font-medium flex items-center gap-1">
                  <Lock className="w-3 h-3" /> Restricted
                </span>
              )}
            </div>

            {isAuthorized ? (
              <div className="text-xs space-y-2 pt-1 animate-in fade-in duration-200">
                <div className="grid grid-cols-2 gap-2">
                  <div className="p-2 rounded bg-slate-50 dark:bg-slate-800">
                    <span className="text-slate-400 block text-[11px]">Blood Group</span>
                    <span className="font-bold text-slate-900 dark:text-slate-100">
                      {person.medicalDetails.bloodType}
                    </span>
                  </div>
                  <div className="p-2 rounded bg-slate-50 dark:bg-slate-800">
                    <span className="text-slate-400 block text-[11px]">Allergies</span>
                    <span className="font-medium text-slate-900 dark:text-slate-100">
                      {person.medicalDetails.allergies.join(', ') || 'None reported'}
                    </span>
                  </div>
                </div>

                {person.medicalDetails.chronicConditions.length > 0 && (
                  <div className="p-2 rounded bg-red-50 dark:bg-red-950/30 text-red-700 dark:text-red-300">
                    <span className="font-semibold block text-[11px]">Chronic Health Conditions:</span>
                    <span>{person.medicalDetails.chronicConditions.join('; ')}</span>
                  </div>
                )}

                <div className="p-2.5 rounded bg-slate-50 dark:bg-slate-800">
                  <span className="text-slate-400 block text-[11px] mb-1">Field Triage Notes:</span>
                  <p className="text-slate-700 dark:text-slate-200 leading-relaxed font-normal">
                    {person.medicalDetails.triageNotes}
                  </p>
                </div>
              </div>
            ) : (
              <div className="py-4 text-center space-y-2 bg-slate-50/70 dark:bg-slate-850/60 rounded-lg border border-dashed border-slate-200 dark:border-slate-800">
                <Lock className="w-6 h-6 text-slate-400 mx-auto" />
                <p className="text-xs text-slate-500 max-w-xs mx-auto">
                  Sensitive medical records (allergies, blood type, triage symptoms) are masked according to privacy guidelines.
                </p>
                <button
                  type="button"
                  onClick={() => setShowAuthPrompt(true)}
                  className="text-xs font-bold text-[#8A5A00] dark:text-[#FFC400] hover:underline"
                >
                  Request Medical Authorization
                </button>
              </div>
            )}
          </div>
        </div>

        {/* Footer */}
        <div className="flex items-center justify-end px-6 py-4 bg-slate-50 dark:bg-slate-800/50 border-t border-slate-100 dark:border-slate-800">
          <button
            type="button"
            onClick={onClose}
            className="px-4 py-2 text-xs font-semibold bg-slate-200 hover:bg-slate-300 dark:bg-slate-700 dark:hover:bg-slate-600 text-slate-800 dark:text-slate-200 rounded-lg transition-colors"
          >
            Close
          </button>
        </div>
      </div>
    </div>
  );
};

export default UserDetailsModal;

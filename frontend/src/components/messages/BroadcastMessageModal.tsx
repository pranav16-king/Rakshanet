import React, { useState } from 'react';
import { X, Send, Radio, AlertTriangle } from 'lucide-react';
import type { BroadcastMessagePayload, MessageBadgeType } from '../../types/messages';

interface BroadcastMessageModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSend: (payload: BroadcastMessagePayload) => Promise<void>;
}

export const BroadcastMessageModal: React.FC<BroadcastMessageModalProps> = ({
  isOpen,
  onClose,
  onSend,
}) => {
  const [recipient, setRecipient] = useState<BroadcastMessagePayload['recipientGroup']>('all');
  const [text, setText] = useState('');
  const [priority, setPriority] = useState<BroadcastMessagePayload['priority']>('NORMAL');
  const [location, setLocation] = useState('Sector 4B Riverside Colony');
  const [isSending, setIsSending] = useState(false);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!text.trim()) return;

    setIsSending(true);
    try {
      let badgeType: MessageBadgeType = 'team';
      if (priority === 'CRITICAL') badgeType = 'sos';
      else if (recipient === 'all') badgeType = 'system';

      await onSend({
        recipientGroup: recipient,
        text,
        location,
        badgeType,
        priority,
      });
      setText('');
      onClose();
    } finally {
      setIsSending(false);
    }
  };

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-labelledby="broadcast-title"
      className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-xs"
    >
      <div className="bg-white dark:bg-slate-900 rounded-2xl max-w-lg w-full border border-slate-200 dark:border-slate-800 shadow-2xl overflow-hidden animate-in fade-in zoom-in-95 duration-150">
        <div className="flex items-center justify-between px-6 py-4 border-b border-slate-100 dark:border-slate-800 bg-[#FFC400]/10">
          <div className="flex items-center gap-2">
            <Radio className="w-5 h-5 text-[#8A5A00] dark:text-[#FFC400] animate-pulse" />
            <h3 id="broadcast-title" className="text-base font-bold text-slate-900 dark:text-slate-100">
              Broadcast Over Mesh Network
            </h3>
          </div>
          <button
            onClick={onClose}
            className="text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 p-1.5 rounded-lg"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          <div>
            <label className="block text-xs font-semibold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-1.5">
              Target Audience
            </label>
            <select
              value={recipient}
              onChange={(e) =>
                setRecipient(e.target.value as BroadcastMessagePayload['recipientGroup'])
              }
              className="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg text-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-[#FFC400]"
            >
              <option value="all">Broadcast to All Connected Mesh Devices (326 nodes)</option>
              <option value="rescue_teams">Rescue Units & Operators Only</option>
              <option value="sos">Active SOS Beacon Users Only</option>
              <option value="field_users">Field Volunteers & Citizens</option>
            </select>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-semibold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-1.5">
                Priority Tier
              </label>
              <select
                value={priority}
                onChange={(e) =>
                  setPriority(e.target.value as BroadcastMessagePayload['priority'])
                }
                className="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg text-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-[#FFC400]"
              >
                <option value="NORMAL">Normal Advisory</option>
                <option value="HIGH">High Alert</option>
                <option value="CRITICAL">Critical Emergency (Override)</option>
              </select>
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-1.5">
                Sector / Location
              </label>
              <input
                type="text"
                value={location}
                onChange={(e) => setLocation(e.target.value)}
                className="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg text-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-[#FFC400]"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-1.5">
              Message Content (Compressed for LoRa / BLE P2P Packet Buffer)
            </label>
            <textarea
              rows={3}
              required
              value={text}
              onChange={(e) => setText(e.target.value)}
              placeholder="e.g. Flash flood warning: All civilians move immediately to higher ground above Sector 4 ridge."
              className="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg text-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-[#FFC400] resize-none"
            />
            <div className="flex justify-between items-center mt-1 text-[11px] text-slate-400">
              <span>Estimated packet size: {Math.max(12, text.length + 18)} bytes (within 240 byte MTU)</span>
              <span>{text.length}/200 chars</span>
            </div>
          </div>

          {priority === 'CRITICAL' && (
            <div className="p-3 rounded-lg bg-red-50 dark:bg-red-950/40 border border-red-200 dark:border-red-900 flex items-center gap-2 text-xs text-red-700 dark:text-red-300">
              <AlertTriangle className="w-4 h-4 shrink-0 text-red-600" />
              <span>Critical priority triggers audible beacon alerts on all recipient mobile devices.</span>
            </div>
          )}

          <div className="flex items-center justify-end gap-2 pt-3 border-t border-slate-100 dark:border-slate-800">
            <button
              type="button"
              onClick={onClose}
              disabled={isSending}
              className="px-4 py-2 text-xs font-semibold text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg transition-colors"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={isSending || !text.trim()}
              className="inline-flex items-center gap-2 px-5 py-2 text-xs font-bold bg-[#FFC400] hover:bg-[#E0AA00] text-slate-950 rounded-lg shadow-sm transition-colors disabled:opacity-50"
            >
              <Send className="w-3.5 h-3.5" />
              {isSending ? 'Transmitting...' : 'Transmit Mesh Broadcast'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default BroadcastMessageModal;

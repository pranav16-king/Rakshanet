import React from 'react';
import { MapPin, Clock, Radio, CheckCheck, MoreVertical, ShieldAlert } from 'lucide-react';
import type { FieldMessage } from '../../types/messages';
import { DeliveryTicks } from '../common/DeliveryTicks';
import { StatusBadge } from '../common/StatusBadge';
import { HumanReadablePayload } from '../incidents/HumanReadablePayload';

interface MessageItemProps {
  message: FieldMessage;
  onAcknowledge?: (id: string) => void;
  onSelect?: (message: FieldMessage) => void;
}

export const MessageItem: React.FC<MessageItemProps> = ({
  message,
  onAcknowledge,
  onSelect,
}) => {
  const getAvatarBg = (color: string) => {
    switch (color) {
      case 'sky':
        return 'bg-sky-100 text-sky-700 dark:bg-sky-950 dark:text-sky-300 border-sky-200 dark:border-sky-800';
      case 'blue':
        return 'bg-blue-100 text-blue-700 dark:bg-blue-950 dark:text-blue-300 border-blue-200 dark:border-blue-800';
      case 'purple':
        return 'bg-purple-100 text-purple-700 dark:bg-purple-950 dark:text-purple-300 border-purple-200 dark:border-purple-800';
      case 'rose':
        return 'bg-rose-100 text-rose-700 dark:bg-rose-950 dark:text-rose-300 border-rose-200 dark:border-rose-800';
      case 'teal':
        return 'bg-teal-100 text-teal-700 dark:bg-teal-950 dark:text-teal-300 border-teal-200 dark:border-teal-800';
      case 'indigo':
        return 'bg-indigo-100 text-indigo-700 dark:bg-indigo-950 dark:text-indigo-300 border-indigo-200 dark:border-indigo-800';
      case 'amber':
        return 'bg-amber-100 text-amber-700 dark:bg-amber-950 dark:text-amber-300 border-amber-200 dark:border-amber-800';
      default:
        return 'bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-300 border-slate-200 dark:border-slate-700';
    }
  };

  const isSOS = message.badgeType === 'sos';

  return (
    <div
      onClick={() => onSelect?.(message)}
      className={`group relative p-4 rounded-xl transition-all duration-200 cursor-pointer ${
        isSOS
          ? 'bg-red-50/30 hover:bg-red-50/60 dark:bg-red-950/20 dark:hover:bg-red-950/30 border border-red-200/80 dark:border-red-900/50 shadow-xs'
          : 'bg-white hover:bg-slate-50/90 dark:bg-slate-850 dark:hover:bg-slate-800 border border-slate-200 dark:border-slate-800 shadow-xs'
      }`}
    >
      <div className="flex items-start gap-3.5">
        {/* Avatar */}
        <div
          className={`w-10 h-10 rounded-full border flex items-center justify-center font-bold text-sm shrink-0 shadow-xs ${getAvatarBg(
            message.avatarColor
          )}`}
        >
          {message.senderAvatarInitial}
        </div>

        {/* Message Core Body */}
        <div className="flex-1 min-w-0">
          <div className="flex items-center justify-between gap-2 mb-1">
            <div className="flex items-center gap-2 flex-wrap">
              <h4 className="text-sm font-semibold text-slate-900 dark:text-slate-100 truncate">
                {message.senderName}
              </h4>
              {isSOS && (
                <span className="inline-flex items-center gap-1 text-[11px] font-semibold text-red-600 dark:text-red-400 bg-red-100 dark:bg-red-900/50 px-1.5 py-0.2 rounded">
                  <ShieldAlert className="w-3 h-3" />
                  EMERGENCY
                </span>
              )}
            </div>

            {/* Right side: Status badge & delivery ticks */}
            <div className="flex items-center gap-2.5 shrink-0">
              <StatusBadge
                label={message.statusBadge}
                type={message.badgeType}
                dot={isSOS}
              />
              <DeliveryTicks status={message.deliveryStatus} />
              <button
                type="button"
                onClick={(e) => {
                  e.stopPropagation();
                  onAcknowledge?.(message.id);
                }}
                className="opacity-60 hover:opacity-100 text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 p-1 rounded-md"
                title="Options"
              >
                <MoreVertical className="w-4 h-4" />
              </button>
            </div>
          </div>

          {/* Human-Readable Message Content */}
          <HumanReadablePayload
            content={message.text}
            title={message.statusBadge}
            category={message.badgeType}
          />

          {/* Metadata Row */}
          <div className="flex items-center gap-4 text-xs text-slate-500 dark:text-slate-400 flex-wrap">
            <div className="flex items-center gap-1">
              <MapPin className="w-3.5 h-3.5 text-slate-400" />
              <span>{message.location}</span>
            </div>

            <div className="flex items-center gap-1">
              <Clock className="w-3.5 h-3.5 text-slate-400" />
              <span>{message.timestamp}</span>
            </div>

            {message.meshHops !== undefined && (
              <div className="flex items-center gap-1 font-mono text-[11px] text-slate-400 dark:text-slate-500">
                <Radio className="w-3 h-3 text-[#FFC400]" />
                <span>
                  {message.meshHops === 1
                    ? '1 direct mesh hop'
                    : `${message.meshHops} hops ${
                        message.relayDeviceId ? `via ${message.relayDeviceId}` : ''
                      }`}
                </span>
              </div>
            )}

            {!message.acknowledged && (
              <button
                type="button"
                onClick={(e) => {
                  e.stopPropagation();
                  onAcknowledge?.(message.id);
                }}
                className="ml-auto text-xs font-semibold text-emerald-600 hover:text-emerald-700 dark:text-emerald-400 flex items-center gap-1 hover:underline"
              >
                <CheckCheck className="w-3.5 h-3.5" />
                Acknowledge
              </button>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default MessageItem;

import React from 'react';
import { X, MapPin, Radio, Shield, Users, Battery, Share2 } from 'lucide-react';
import { MapIncidentNode, LiveDevice } from '../../types/map';
import { SeverityBadge } from '../common/SeverityBadge';

export interface NodeDetailDrawerProps {
  selectedNode: MapIncidentNode | null;
  selectedDevice: LiveDevice | null;
  onClose: () => void;
  onAssignTeam?: (id: string) => void;
  onViewDetails?: (id: string) => void;
}

export const NodeDetailDrawer: React.FC<NodeDetailDrawerProps> = ({
  selectedNode,
  selectedDevice,
  onClose,
  onAssignTeam,
  onViewDetails,
}) => {
  if (!selectedNode && !selectedDevice) return null;

  const isIncident = Boolean(selectedNode);
  const title = isIncident ? selectedNode?.title : `Device ${selectedDevice?.id}`;
  const coordinates = isIncident
    ? `${selectedNode?.lat.toFixed(4)}, ${selectedNode?.lng.toFixed(4)}`
    : `${selectedDevice?.lat.toFixed(4)}, ${selectedDevice?.lng.toFixed(4)}`;

  return (
    <div className="absolute top-20 right-6 w-96 max-w-[calc(100vw-3rem)] bg-white dark:bg-[#0B1220] border border-[#E2E8F0] dark:border-[#26344F] rounded-2xl shadow-2xl p-5 z-30 animate-in fade-in slide-in-from-right-4 transition-all">
      {/* Header */}
      <div className="flex items-start justify-between gap-3 border-b border-[#E2E8F0] dark:border-[#26344F] pb-3 mb-4">
        <div>
          <div className="flex items-center gap-2 mb-1">
            {isIncident ? (
              <SeverityBadge severity={selectedNode?.severity || 'UNKNOWN'} size="sm" />
            ) : (
              <span className="px-2 py-0.5 rounded-full text-xs font-bold bg-[#D9F2E3] dark:bg-[#0F3322] text-[#1E8E4E] dark:text-[#4CD08A]">
                {selectedDevice?.status}
              </span>
            )}
            <span className="text-[11px] font-mono text-[#64748B] dark:text-[#9FADC2]">
              {isIncident ? selectedNode?.id : selectedDevice?.type}
            </span>
          </div>
          <h3 className="text-base font-bold text-[#0F172A] dark:text-[#EEF2F8] font-display">
            {title}
          </h3>
        </div>

        <button
          type="button"
          onClick={onClose}
          aria-label="Close inspector drawer"
          className="p-1 rounded-lg text-[#64748B] dark:text-[#9FADC2] hover:bg-[#F8FAFC] dark:hover:bg-[#162036] transition-colors cursor-pointer"
        >
          <X className="w-5 h-5" />
        </button>
      </div>

      {/* Body Details */}
      <div className="space-y-3.5 text-xs">
        {/* Coordinates */}
        <div className="flex items-center justify-between text-[#64748B] dark:text-[#9FADC2]">
          <span className="flex items-center gap-1.5 font-medium">
            <MapPin className="w-3.5 h-3.5 text-[#0E8A94] dark:text-[#3CC6D0]" />
            Coordinates
          </span>
          <span className="font-mono text-[#0F172A] dark:text-[#EEF2F8]">{coordinates}</span>
        </div>

        {/* Affected or Device Status */}
        {isIncident && (
          <>
            <div className="flex items-center justify-between text-[#64748B] dark:text-[#9FADC2]">
              <span className="flex items-center gap-1.5 font-medium">
                <Users className="w-3.5 h-3.5 text-[#FFC400]" />
                Impact Magnitude
              </span>
              <span className="font-bold text-[#0F172A] dark:text-[#EEF2F8]">
                {selectedNode?.countLabel}
              </span>
            </div>

            <div className="flex items-center justify-between text-[#64748B] dark:text-[#9FADC2]">
              <span className="flex items-center gap-1.5 font-medium">
                <Radio className="w-3.5 h-3.5 text-[#3CC6D0]" />
                Reported
              </span>
              <span className="text-[#0F172A] dark:text-[#EEF2F8]">
                {selectedNode?.reportedAgo || 'Recently'}
              </span>
            </div>

            <p className="p-3 rounded-xl bg-[#F8FAFC] dark:bg-[#162036] border border-[#E2E8F0] dark:border-[#26344F] text-[#0F172A] dark:text-[#EEF2F8] leading-relaxed">
              {selectedNode?.description}
            </p>
          </>
        )}

        {!isIncident && selectedDevice && (
          <>
            <div className="flex items-center justify-between text-[#64748B] dark:text-[#9FADC2]">
              <span className="flex items-center gap-1.5 font-medium">
                <Battery className="w-3.5 h-3.5 text-[#4CD08A]" />
                Battery Level
              </span>
              <span className="font-mono font-bold text-[#0F172A] dark:text-[#EEF2F8]">
                {selectedDevice.battery}%
              </span>
            </div>

            <div className="flex items-center justify-between text-[#64748B] dark:text-[#9FADC2]">
              <span className="flex items-center gap-1.5 font-medium">
                <Radio className="w-3.5 h-3.5 text-[#3CC6D0]" />
                Mesh Hops to Gateway
              </span>
              <span className="font-mono font-bold text-[#0F172A] dark:text-[#EEF2F8]">
                {selectedDevice.hops} hops
              </span>
            </div>

            <div className="flex items-center justify-between text-[#64748B] dark:text-[#9FADC2]">
              <span className="flex items-center gap-1.5 font-medium">
                <Share2 className="w-3.5 h-3.5 text-[#0E8A94]" />
                Last Synchronized
              </span>
              <span className="text-[#0F172A] dark:text-[#EEF2F8]">
                {selectedDevice.relativeTime}
              </span>
            </div>
          </>
        )}
      </div>

      {/* Action Footer */}
      <div className="mt-5 pt-3 border-t border-[#E2E8F0] dark:border-[#26344F] flex flex-col gap-2">
        {isIncident ? (
          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={() => onViewDetails?.(selectedNode?.id || '')}
              className="flex-1 min-h-[40px] px-3 py-2 rounded-xl text-xs font-bold bg-[#0E8A94] dark:bg-[#3CC6D0] text-white dark:text-[#0B1220] hover:opacity-90 transition-opacity flex items-center justify-center gap-1.5 shadow-xs cursor-pointer"
            >
              <Radio className="w-3.5 h-3.5" />
              View Comms & Map
            </button>
            <button
              type="button"
              onClick={() => onAssignTeam?.(selectedNode?.id || '')}
              className="px-3 py-2 min-h-[40px] rounded-xl text-xs font-bold bg-[#FFC400] dark:bg-[#FFD21F] text-[#1A1400] hover:bg-[#E0AA00] transition-colors flex items-center justify-center gap-1.5 shadow-xs cursor-pointer"
              title="Assign Response Team"
            >
              <Shield className="w-3.5 h-3.5" />
              Assign
            </button>
            <button
              type="button"
              onClick={onClose}
              className="px-3 py-2 min-h-[40px] rounded-xl text-xs font-semibold bg-gray-100 dark:bg-[#162036] text-[#64748B] dark:text-[#9FADC2] hover:bg-gray-200 dark:hover:bg-gray-800 transition-colors cursor-pointer"
            >
              Dismiss
            </button>
          </div>
        ) : (
          <div className="flex items-center gap-2">
            <button
              type="button"
              className="flex-1 min-h-[40px] px-3 py-2 rounded-xl text-xs font-bold bg-[#0E8A94] dark:bg-[#3CC6D0] text-white dark:text-[#0B1220] hover:opacity-90 transition-opacity flex items-center justify-center gap-1.5 shadow-xs cursor-pointer"
            >
              <Radio className="w-3.5 h-3.5" />
              Ping Device via Mesh
            </button>
            <button
              type="button"
              onClick={onClose}
              className="px-3 py-2 min-h-[40px] rounded-xl text-xs font-semibold bg-gray-100 dark:bg-[#162036] text-[#64748B] dark:text-[#9FADC2] hover:bg-gray-200 dark:hover:bg-gray-800 transition-colors cursor-pointer"
            >
              Dismiss
            </button>
          </div>
        )}
      </div>
    </div>
  );
};

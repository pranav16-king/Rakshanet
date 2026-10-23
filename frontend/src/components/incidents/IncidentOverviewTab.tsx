import React from 'react';
import type { Incident, IncidentMeshTopologyResponse } from '../../types/incident.ts';
import { IncidentAreaMeshMap } from './IncidentAreaMeshMap.tsx';
import { IncidentDescriptionCard } from './IncidentDescriptionCard.tsx';
import { IncidentKeyInfoCard } from './IncidentKeyInfoCard.tsx';
import { ResourcesNeededCard } from './ResourcesNeededCard.tsx';
import { IncidentAIExplanation } from './IncidentAIExplanation.tsx';

interface IncidentOverviewTabProps {
  incident: Incident;
  topology?: IncidentMeshTopologyResponse | null;
  onOpenAssignModal: () => void;
  onSelectNode?: (type: 'BEACON' | 'RELAY' | 'UNIT', id: string) => void;
}

export const IncidentOverviewTab: React.FC<IncidentOverviewTabProps> = ({
  incident,
  topology,
  onOpenAssignModal,
  onSelectNode,
}) => {
  return (
    <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
      {/* Left Column: Interactive Area Mesh Map + Description + AI Explainability */}
      <div className="lg:col-span-7 xl:col-span-8 space-y-6">
        {/* Dedicated Incident Area Mesh Map showing active SOS beacons, relays, and rescue units */}
        <div className="space-y-2">
          <div className="flex items-center justify-between">
            <h3 className="text-xs font-bold uppercase tracking-wider text-[#64748B] dark:text-[#94A3B8]">
              Geofenced Area Telemetry & Mesh Map
            </h3>
            <span className="text-[11px] font-mono text-[#0891B2] dark:text-[#06B6D4]">
              {topology?.sos_beacons?.length || 3} Beacons • {topology?.mesh_relays?.length || 2} Relays
            </span>
          </div>
          <IncidentAreaMeshMap
            incident={incident}
            topology={topology}
            height="440px"
            onSelectNode={onSelectNode}
          />
        </div>

        {/* Description Card */}
        <IncidentDescriptionCard incident={incident} />

        {/* AI Analysis & Explainability Box */}
        <IncidentAIExplanation explainability={incident.aiExplainability} />
      </div>

      {/* Right Column: Key Information + Resources Needed */}
      <div className="lg:col-span-5 xl:col-span-4 space-y-6">
        {/* Right Key Information Card */}
        <IncidentKeyInfoCard incident={incident} />

        {/* Resources Needed Card */}
        <ResourcesNeededCard
          resources={incident.resourcesNeeded}
          onManageResources={onOpenAssignModal}
        />
      </div>
    </div>
  );
};

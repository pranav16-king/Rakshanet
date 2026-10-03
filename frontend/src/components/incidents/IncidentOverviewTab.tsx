import React from 'react';
import type { Incident } from '../../types/incident.ts';
import { IncidentLeafletMap } from './IncidentLeafletMap.tsx';
import { IncidentDescriptionCard } from './IncidentDescriptionCard.tsx';
import { IncidentKeyInfoCard } from './IncidentKeyInfoCard.tsx';
import { ResourcesNeededCard } from './ResourcesNeededCard.tsx';
import { IncidentAIExplanation } from './IncidentAIExplanation.tsx';

interface IncidentOverviewTabProps {
  incident: Incident;
  onOpenAssignModal: () => void;
}

export const IncidentOverviewTab: React.FC<IncidentOverviewTabProps> = ({
  incident,
  onOpenAssignModal,
}) => {
  return (
    <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
      {/* Left Column: Map + Description + AI Explainability (approx 7 or 8 columns out of 12) */}
      <div className="lg:col-span-7 xl:col-span-8 space-y-6">
        {/* Left Map Box: Leaflet map showing affected area polygon & centroid */}
        <IncidentLeafletMap incident={incident} height="420px" />

        {/* Description Card */}
        <IncidentDescriptionCard incident={incident} />

        {/* AI Analysis & Explainability Box (strictly adhering to design.md rule 5 and 11) */}
        <IncidentAIExplanation explainability={incident.aiExplainability} />
      </div>

      {/* Right Column: Key Information + Resources Needed (approx 5 or 4 columns out of 12) */}
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

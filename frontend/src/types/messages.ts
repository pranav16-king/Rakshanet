export type MessageFilterTab = 'all' | 'sos' | 'report' | 'team' | 'system';

export type DeliveryStatus = 'queued' | 'relayed' | 'delivered';

export type MessageBadgeType = 'sos' | 'report' | 'medical' | 'team' | 'system';

export interface FieldMessage {
  id: string;
  senderName: string;
  senderAvatarInitial: string;
  avatarColor: 'blue' | 'sky' | 'purple' | 'rose' | 'teal' | 'indigo' | 'amber';
  text: string;
  location: string;
  timestamp: string;
  createdAt: number;
  statusBadge: string; // e.g. 'SOS INC-2025-001', 'Report', 'Medical', 'Team', 'System'
  badgeType: MessageBadgeType;
  deliveryStatus: DeliveryStatus; // 'queued' (1 tick), 'relayed' (2 ticks), 'delivered' (double green)
  meshHops?: number;
  relayDeviceId?: string;
  incidentId?: string;
  acknowledged?: boolean;
}

export interface BroadcastMessagePayload {
  recipientGroup: 'all' | 'sos' | 'field_users' | 'rescue_teams';
  text: string;
  location?: string;
  badgeType: MessageBadgeType;
  priority: 'CRITICAL' | 'HIGH' | 'NORMAL';
}

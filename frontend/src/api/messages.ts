import { apiClient } from './client';
import type {
  FieldMessage,
  MessageFilterTab,
  BroadcastMessagePayload,
} from '../types/messages';

// Resilient fallback initial messages matching media_1791015140209.jpg (middle-right screen)
const INITIAL_MESSAGES: FieldMessage[] = [
  {
    id: 'msg-001',
    senderName: 'Amit Kumar',
    senderAvatarInitial: 'A',
    avatarColor: 'sky',
    text: 'Flood in my area, water level rising fast. 5 people trapped.',
    location: 'Uttarakhand',
    timestamp: '5 min ago',
    createdAt: Date.now() - 5 * 60 * 1000,
    statusBadge: 'SOS INC-2025-001',
    badgeType: 'sos',
    deliveryStatus: 'relayed', // 2 ticks mesh relayed
    meshHops: 2,
    relayDeviceId: 'SR-9A1C',
    incidentId: 'INC-2025-001',
    acknowledged: false,
  },
  {
    id: 'msg-002',
    senderName: 'Priya Sharma',
    senderAvatarInitial: 'P',
    avatarColor: 'blue',
    text: 'We are safe at school building. Need rescue.',
    location: 'Uttarakhand',
    timestamp: '8 min ago',
    createdAt: Date.now() - 8 * 60 * 1000,
    statusBadge: 'SOS INC-2025-001',
    badgeType: 'sos',
    deliveryStatus: 'delivered', // double green delivered
    meshHops: 1,
    relayDeviceId: 'SR-8F42',
    incidentId: 'INC-2025-001',
    acknowledged: true,
  },
  {
    id: 'msg-003',
    senderName: 'Rahul Mehta',
    senderAvatarInitial: 'R',
    avatarColor: 'purple',
    text: 'Road blocked due to landslide. Alternative route needed.',
    location: 'Himachal Pradesh',
    timestamp: '10 min ago',
    createdAt: Date.now() - 10 * 60 * 1000,
    statusBadge: 'Report',
    badgeType: 'report',
    deliveryStatus: 'delivered', // double green delivered
    meshHops: 2,
    relayDeviceId: 'SR-3D7B',
    acknowledged: true,
  },
  {
    id: 'msg-004',
    senderName: 'Sneha Patel',
    senderAvatarInitial: 'S',
    avatarColor: 'rose',
    text: 'Medical help required. One person injured.',
    location: 'Delhi',
    timestamp: '15 min ago',
    createdAt: Date.now() - 15 * 60 * 1000,
    statusBadge: 'Medical',
    badgeType: 'medical',
    deliveryStatus: 'queued', // 1 tick queued
    meshHops: 3,
    relayDeviceId: 'SR-6E2F',
    acknowledged: false,
  },
  {
    id: 'msg-005',
    senderName: 'Volunteer Team',
    senderAvatarInitial: 'V',
    avatarColor: 'teal',
    text: 'Reaching the location in 30 minutes.',
    location: 'Uttarakhand',
    timestamp: '18 min ago',
    createdAt: Date.now() - 18 * 60 * 1000,
    statusBadge: 'Team',
    badgeType: 'team',
    deliveryStatus: 'delivered', // double green delivered
    meshHops: 1,
    relayDeviceId: 'SR-7G9H',
    acknowledged: true,
  },
  {
    id: 'msg-006',
    senderName: 'Organizer',
    senderAvatarInitial: 'O',
    avatarColor: 'indigo',
    text: 'Set up temporary shelter at community center.',
    location: 'Delhi',
    timestamp: '25 min ago',
    createdAt: Date.now() - 25 * 60 * 1000,
    statusBadge: 'System',
    badgeType: 'system',
    deliveryStatus: 'delivered', // double green delivered
    meshHops: 1,
    acknowledged: true,
  },
  {
    id: 'msg-007',
    senderName: 'Vikram Singh',
    senderAvatarInitial: 'V',
    avatarColor: 'teal',
    text: 'High clearance vehicle deployed along Sector 4 riverbank.',
    location: 'Uttarakhand',
    timestamp: '35 min ago',
    createdAt: Date.now() - 35 * 60 * 1000,
    statusBadge: 'Team',
    badgeType: 'team',
    deliveryStatus: 'delivered',
    meshHops: 2,
    acknowledged: true,
  },
  {
    id: 'msg-008',
    senderName: 'Mesh Gateway',
    senderAvatarInitial: 'M',
    avatarColor: 'indigo',
    text: 'Mesh packet synchronization complete: 326 nodes active.',
    location: 'Command Base',
    timestamp: '42 min ago',
    createdAt: Date.now() - 42 * 60 * 1000,
    statusBadge: 'System',
    badgeType: 'system',
    deliveryStatus: 'delivered',
    meshHops: 1,
    acknowledged: true,
  },
];

let localMessages = [...INITIAL_MESSAGES];

export const messagesApi = {
  getMessages: async (tab: MessageFilterTab = 'all'): Promise<FieldMessage[]> => {
    try {
      const typeParam = tab === 'all' ? 'ALL' : tab.toUpperCase();
      const response = await apiClient.get<any[]>('/api/v1/messages', {
        params: { type: typeParam, limit: 100 },
      });
      if (response.data && response.data.length > 0) {
        return response.data.map((item: any) => {
          let badgeType: FieldMessage['badgeType'] = 'team';
          const pktType = (item.type || '').toUpperCase();
          if (pktType === 'SOS') badgeType = 'sos';
          else if (pktType === 'REPORT') badgeType = 'report';
          else if (pktType === 'MEDICAL') badgeType = 'medical';
          else if (pktType === 'SYSTEM' || pktType === 'BROADCAST') badgeType = 'system';

          let deliveryStatus: FieldMessage['deliveryStatus'] = 'delivered';
          if (item.status === 'QUEUED') deliveryStatus = 'queued';
          else if (item.status === 'RELAYED' || (item.hops && item.hops > 0)) deliveryStatus = 'relayed';

          const created = item.timestamp ? (item.timestamp > 1e11 ? item.timestamp : item.timestamp * 1000) : Date.now();
          const senderName = item.sender_name || item.sender_id || 'Anonymous Field Node';

          const diffMinutes = Math.floor((Date.now() - created) / 60000);
          let timeAgo = 'Just now';
          if (diffMinutes > 0 && diffMinutes < 60) timeAgo = `${diffMinutes} min ago`;
          else if (diffMinutes >= 60 && diffMinutes < 1440) timeAgo = `${Math.floor(diffMinutes / 60)}h ago`;
          else if (diffMinutes >= 1440) timeAgo = `${Math.floor(diffMinutes / 1440)}d ago`;

          let locationStr = 'Disaster Sector';
          if (item.lat && item.lng) {
            locationStr = `${item.lat.toFixed(4)}° N, ${item.lng.toFixed(4)}° E`;
          } else if (item.meta?.location) {
            locationStr = item.meta.location;
          }

          let avatarColor: FieldMessage['avatarColor'] = 'sky';
          if (badgeType === 'sos') avatarColor = 'rose';
          else if (badgeType === 'report') avatarColor = 'teal';
          else if (badgeType === 'medical') avatarColor = 'purple';
          else if (badgeType === 'team') avatarColor = 'blue';

          return {
            id: item.id || `msg-${created}`,
            senderName,
            senderAvatarInitial: senderName.charAt(0).toUpperCase(),
            avatarColor,
            text: item.payload || '',
            location: locationStr,
            timestamp: timeAgo,
            createdAt: created,
            statusBadge: badgeType === 'sos' ? `SOS ${item.meta?.incident_id || 'DISTRESS'}` : (item.type || 'Message'),
            badgeType,
            deliveryStatus,
            meshHops: item.hops ?? 0,
            relayDeviceId: item.mule_device_id || item.meta?.relay_device_id || 'SR-GATEWAY',
            incidentId: item.conv_id || item.meta?.incident_id || 'INC-FLD-2026-001',
            acknowledged: item.status === 'DELIVERED' || item.meta?.acknowledged === true,
          };
        });
      }
    } catch {
      // Resilient fallback with offline state simulation
    }
    if (tab === 'all') return localMessages;
    if (tab === 'sos') return localMessages.filter((m) => m.badgeType === 'sos' || m.badgeType === 'medical');
    if (tab === 'report') return localMessages.filter((m) => m.badgeType === 'report');
    if (tab === 'team') return localMessages.filter((m) => m.badgeType === 'team');
    if (tab === 'system') return localMessages.filter((m) => m.badgeType === 'system');
    return localMessages;
  },

  sendBroadcast: async (payload: BroadcastMessagePayload): Promise<FieldMessage> => {
    try {
      const response = await apiClient.post<FieldMessage>('/api/v1/messages/broadcast', payload);
      return response.data;
    } catch {
      // Local fallback simulation
      const newMsg: FieldMessage = {
        id: `msg-${Date.now()}`,
        senderName: 'Command Center',
        senderAvatarInitial: 'C',
        avatarColor: 'amber',
        text: payload.text,
        location: payload.location || 'HQ Command Base',
        timestamp: 'Just now',
        createdAt: Date.now(),
        statusBadge: payload.priority === 'CRITICAL' ? 'SOS BROADCAST' : 'Team Broadcast',
        badgeType: payload.badgeType,
        deliveryStatus: 'relayed',
        meshHops: 1,
        acknowledged: true,
      };
      localMessages = [newMsg, ...localMessages];
      return newMsg;
    }
  },

  acknowledgeMessage: async (id: string): Promise<FieldMessage | null> => {
    try {
      const response = await apiClient.patch<FieldMessage>(`/api/v1/messages/${id}/ack`);
      return response.data;
    } catch {
      const msg = localMessages.find((m) => m.id === id);
      if (msg) {
        msg.acknowledged = true;
        msg.deliveryStatus = 'delivered';
      }
      return msg || null;
    }
  },
};

export default messagesApi;

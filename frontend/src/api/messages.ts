import { apiClient } from './client';
import type {
  FieldMessage,
  MessageFilterTab,
  BroadcastMessagePayload,
} from '../types/messages';

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

          const created = item.timestamp
            ? item.timestamp > 1e11 ? item.timestamp : item.timestamp * 1000
            : Date.now();
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
            statusBadge: badgeType === 'sos'
              ? `SOS ${item.meta?.incident_id || 'DISTRESS'}`
              : (item.type || 'Message'),
            badgeType,
            deliveryStatus,
            meshHops: item.hops ?? 0,
            relayDeviceId: item.mule_device_id || item.meta?.relay_device_id || 'SR-GATEWAY',
            incidentId: item.conv_id || item.meta?.incident_id,
            acknowledged: item.status === 'DELIVERED' || item.meta?.acknowledged === true,
          };
        });
      }
      return [];
    } catch {
      return [];
    }
  },

  sendBroadcast: async (payload: BroadcastMessagePayload): Promise<FieldMessage> => {
    const response = await apiClient.post<FieldMessage>('/api/v1/messages/broadcast', payload);
    return response.data;
  },

  acknowledgeMessage: async (id: string): Promise<FieldMessage | null> => {
    try {
      const response = await apiClient.patch<FieldMessage>(`/api/v1/messages/${id}/ack`);
      return response.data;
    } catch {
      return null;
    }
  },
};

export default messagesApi;

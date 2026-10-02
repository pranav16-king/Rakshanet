export type ConversationType = 'DIRECT' | 'GROUP' | 'RELAY' | 'BROADCAST';

export type MessageStatus =
  | 'SAVED'
  | 'QUEUED'
  | 'SENDING'
  | 'SENT_TO_NEARBY'
  | 'RELAYED'
  | 'DELIVERED'
  | 'FAILED'
  | 'EXPIRED';

export type MessageType = 'TEXT' | 'STATUS' | 'RELAY_ACK';

export interface Conversation {
  id: string;
  conversationId: string;
  type: ConversationType;
  title: string;
  createdAt: number;
  updatedAt: number;
  lastMessage?: string;
  unreadCount?: number;
}

export interface ConversationParticipant {
  id: string;
  conversationId: string;
  deviceId: string;
  displayName: string;
  joinedAt: number;
  lastSeen: number;
}

export interface Message {
  id: string;
  messageId: string; // e.g. "MSG-7A2B-9C01"
  conversationId: string;
  senderDeviceId: string;
  senderName: string;
  messageType: MessageType;
  content: string;
  createdAt: number;
  expiresAt: number;
  status: MessageStatus;
  hopCount: number;
  ttl: number;
}

export interface MessageRelay {
  id: string;
  messageId: string;
  fromDeviceId: string;
  toDeviceId: string;
  hopNumber: number;
  receivedAt: number;
  forwardedAt?: number;
  status: 'RECEIVED' | 'FORWARDED' | 'DROPPED';
}

/**
 * Compact binary/JSON packet serialized across Bluetooth GATT / Wi-Fi Direct
 */
export interface NetworkPacket {
  ver: number;
  msg_id: string;
  conv_id: string;
  sender_id: string;
  sender_name: string;
  ts: number;
  ttl: number;
  hops: number;
  type: MessageType;
  payload: string;
  sig?: string; // Ed25519 signature
}

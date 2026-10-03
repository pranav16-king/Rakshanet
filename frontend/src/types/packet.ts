export type PacketType = 'TEXT' | 'SOS' | 'REPORT' | 'SAFE' | 'BEACON' | 'TELEMETRY';

export interface LocationPayload {
  lat: number;
  lng: number;
  altitude?: number | null;
  accuracy?: number | null;
  fix_type?: 'LIVE_GPS' | 'LAST_KNOWN' | 'ESTIMATED_ZONE' | string;
}

export interface Packet {
  ver?: number;
  msg_id: string;
  sender_id: string;
  sender_name: string;
  conv_id?: string;
  ts: number;
  ttl?: number;
  hops: number;
  type: PacketType;
  payload: string;
  recipient_target?: string | null;
  location?: LocationPayload | null;
  meta?: Record<string, unknown> | null;
  chk?: string | null;
  is_relayed?: boolean;
  received_at?: number;
}

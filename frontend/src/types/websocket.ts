import type { Packet } from './packet';
import type { Incident } from './incident';

export type WebSocketEventType = 
  | 'CONNECTED'
  | 'NEW_PACKET_INGESTED'
  | 'INCIDENTS_UPDATED'
  | 'BLACK_HOLE_ALERT'
  | 'DISPATCH_PLAN_GENERATED'
  | 'PING'
  | 'PONG';

export interface WebSocketEventMessage<T = unknown> {
  event: WebSocketEventType;
  packet?: Packet;
  mule_id?: string;
  incidents?: Incident[];
  count?: number;
  anomalies?: unknown[];
  plan_id?: string;
  timestamp?: number;
  message?: string;
  data?: T;
}

import { useEffect, useRef, useState, useCallback } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import type { WebSocketEventMessage } from '../types';

export type WebSocketStatus = 'connecting' | 'connected' | 'disconnected' | 'reconnecting';

interface UseWebSocketOptions {
  url?: string;
  autoConnect?: boolean;
  reconnectInterval?: number;
  maxReconnectAttempts?: number;
}

const DEFAULT_WS_URL = import.meta.env.VITE_WS_URL || 'ws://localhost:8000/ws/mesh';

export function useWebSocket(options: UseWebSocketOptions = {}) {
  const {
    url = DEFAULT_WS_URL,
    autoConnect = true,
    reconnectInterval = 3000,
    maxReconnectAttempts = 10,
  } = options;

  const queryClient = useQueryClient();
  const [status, setStatus] = useState<WebSocketStatus>('disconnected');
  const [lastMessage, setLastMessage] = useState<WebSocketEventMessage | null>(null);
  const [reconnectCount, setReconnectCount] = useState(0);

  const socketRef = useRef<WebSocket | null>(null);
  const reconnectTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const shouldReconnectRef = useRef(true);

  const connect = useCallback(() => {
    if (socketRef.current?.readyState === WebSocket.OPEN) return;

    try {
      setStatus('connecting');
      const ws = new WebSocket(url);
      socketRef.current = ws;

      ws.onopen = () => {
        setStatus('connected');
        setReconnectCount(0);
        // Invalidate telemetry stats on initial connection
        queryClient.invalidateQueries({ queryKey: ['telemetryStats'] });
      };

      ws.onmessage = (event) => {
        try {
          const parsed = JSON.parse(event.data) as WebSocketEventMessage;
          setLastMessage(parsed);

          // Handle query cache invalidation based on backend event types
          switch (parsed.event) {
            case 'NEW_PACKET_INGESTED':
              queryClient.invalidateQueries({ queryKey: ['packets'] });
              queryClient.invalidateQueries({ queryKey: ['telemetryStats'] });
              queryClient.invalidateQueries({ queryKey: ['analytics'] });
              break;

            case 'INCIDENTS_UPDATED':
              queryClient.invalidateQueries({ queryKey: ['incidents'] });
              queryClient.invalidateQueries({ queryKey: ['analytics'] });
              break;

            case 'BLACK_HOLE_ALERT':
              queryClient.invalidateQueries({ queryKey: ['blackHoles'] });
              queryClient.invalidateQueries({ queryKey: ['anomalies'] });
              break;

            case 'DISPATCH_PLAN_GENERATED':
              queryClient.invalidateQueries({ queryKey: ['dispatchPlan'] });
              queryClient.invalidateQueries({ queryKey: ['rescueFleet'] });
              break;

            case 'CONNECTED':
              queryClient.invalidateQueries({ queryKey: ['telemetryStats'] });
              break;

            default:
              break;
          }
        } catch {
          // Non-JSON or raw text message
        }
      };

      ws.onerror = () => {
        // Handled in onclose
      };

      ws.onclose = () => {
        setStatus('disconnected');
        socketRef.current = null;

        if (shouldReconnectRef.current) {
          setReconnectCount((prev) => {
            if (prev < maxReconnectAttempts) {
              setStatus('reconnecting');
              reconnectTimeoutRef.current = setTimeout(() => {
                connect();
              }, reconnectInterval);
              return prev + 1;
            }
            return prev;
          });
        }
      };
    } catch {
      setStatus('disconnected');
    }
  }, [url, reconnectInterval, maxReconnectAttempts, queryClient]);

  const disconnect = useCallback(() => {
    shouldReconnectRef.current = false;
    if (reconnectTimeoutRef.current) {
      clearTimeout(reconnectTimeoutRef.current);
    }
    if (socketRef.current) {
      socketRef.current.close();
      socketRef.current = null;
    }
    setStatus('disconnected');
  }, []);

  const sendMessage = useCallback((data: unknown) => {
    if (socketRef.current?.readyState === WebSocket.OPEN) {
      const payload = typeof data === 'string' ? data : JSON.stringify(data);
      socketRef.current.send(payload);
      return true;
    }
    return false;
  }, []);

  useEffect(() => {
    if (autoConnect) {
      shouldReconnectRef.current = true;
      connect();
    }
    return () => {
      shouldReconnectRef.current = false;
      if (reconnectTimeoutRef.current) {
        clearTimeout(reconnectTimeoutRef.current);
      }
      if (socketRef.current) {
        socketRef.current.close();
      }
    };
  }, [autoConnect, connect]);

  return {
    status,
    isConnected: status === 'connected',
    isReconnecting: status === 'reconnecting',
    lastMessage,
    reconnectCount,
    connect,
    disconnect,
    sendMessage,
  };
}

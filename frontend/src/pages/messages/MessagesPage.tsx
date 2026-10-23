import React, { useState, useEffect, useCallback, useMemo } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  MessageSquare,
  Search,
  Filter,
  Radio,
  Send,
  RefreshCw,
  AlertOctagon,
  ShieldAlert,
  CheckCheck,
  MapPin,
  Clock,
  Share2,
  X,
  ExternalLink,
  Copy,
  Check,
  Activity,
  Layers,
  ArrowRight,
} from 'lucide-react';
import { messagesApi } from '../../api/messages';
import { MessageItem } from '../../components/messages/MessageItem';
import { MessageTabs } from '../../components/messages/MessageTabs';
import { BroadcastMessageModal } from '../../components/messages/BroadcastMessageModal';
import { useWebSocket } from '../../hooks/useWebSocket';
import type {
  FieldMessage,
  MessageFilterTab,
  BroadcastMessagePayload,
} from '../../types/messages';

export const MessagesPage: React.FC = () => {
  const navigate = useNavigate();
  const { lastMessage } = useWebSocket();

  // State
  const [messages, setMessages] = useState<FieldMessage[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<MessageFilterTab>('all');
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedHopFilter, setSelectedHopFilter] = useState<'all' | 'direct' | 'multihop'>('all');
  const [selectedMessage, setSelectedMessage] = useState<FieldMessage | null>(null);
  const [isBroadcastOpen, setIsBroadcastOpen] = useState(false);
  const [isCopied, setIsCopied] = useState(false);
  const [replyText, setReplyText] = useState('');
  const [isSendingReply, setIsSendingReply] = useState(false);

  // Fetch messages from backend API
  const fetchMessages = useCallback(async () => {
    try {
      const data = await messagesApi.getMessages(activeTab);
      setMessages(data);
    } catch (err) {
      console.error('Failed to fetch field messages:', err);
    } finally {
      setIsLoading(false);
    }
  }, [activeTab]);

  useEffect(() => {
    fetchMessages();
  }, [fetchMessages]);

  // Handle incoming real-time WebSocket packet ingestion
  useEffect(() => {
    if (!lastMessage) return;
    try {
      if (lastMessage.event === 'NEW_PACKET_INGESTED' && lastMessage.packet) {
        const p: any = lastMessage.packet;
        const pktType = (p.packet_type || p.type || '').toUpperCase();
        const lat = p.lat ?? p.location?.lat;
        const lng = p.lng ?? p.location?.lng;
        const isSos = pktType === 'SOS';

        const newMsg: FieldMessage = {
          id: p.msg_id || p.id || `pkt-${Date.now()}`,
          senderName: p.sender_name || p.sender_id || 'Field Mesh Node',
          senderAvatarInitial: (p.sender_name || 'F').charAt(0).toUpperCase(),
          avatarColor: isSos ? 'rose' : pktType === 'REPORT' ? 'teal' : 'sky',
          text: p.payload || '',
          location: lat && lng ? `${lat.toFixed(4)}°, ${lng.toFixed(4)}°` : 'Sector Grid',
          timestamp: 'Just now',
          createdAt: Date.now(),
          statusBadge: isSos ? 'SOS DISTRESS' : pktType || 'Message',
          badgeType: isSos ? 'sos' : pktType === 'REPORT' ? 'report' : 'team',
          deliveryStatus: (p.hops ?? 0) > 0 ? 'relayed' : 'delivered',
          meshHops: p.hops ?? 0,
          relayDeviceId: lastMessage.mule_id || 'GATEWAY-MULE',
          incidentId: p.conv_id || 'INC-FLD-2026-001',
          acknowledged: false,
        };
        setMessages((prev) => [newMsg, ...prev.filter((m) => m.id !== newMsg.id)]);
      }
    } catch (err) {
      console.warn('Error handling WS packet:', err);
    }
  }, [lastMessage]);

  // Tab counts
  const tabCounts = useMemo(() => {
    return {
      all: messages.length,
      sos: messages.filter((m) => m.badgeType === 'sos' || m.badgeType === 'medical').length,
      report: messages.filter((m) => m.badgeType === 'report').length,
      team: messages.filter((m) => m.badgeType === 'team').length,
      system: messages.filter((m) => m.badgeType === 'system').length,
    };
  }, [messages]);

  // Filtered messages
  const filteredMessages = useMemo(() => {
    return messages.filter((msg) => {
      // Tab filter
      if (activeTab === 'sos' && msg.badgeType !== 'sos' && msg.badgeType !== 'medical') return false;
      if (activeTab === 'report' && msg.badgeType !== 'report') return false;
      if (activeTab === 'team' && msg.badgeType !== 'team') return false;
      if (activeTab === 'system' && msg.badgeType !== 'system') return false;

      // Hop filter
      if (selectedHopFilter === 'direct' && (msg.meshHops ?? 0) > 0) return false;
      if (selectedHopFilter === 'multihop' && (msg.meshHops ?? 0) === 0) return false;

      // Search term
      if (searchTerm.trim()) {
        const query = searchTerm.toLowerCase();
        const matchesSender = msg.senderName.toLowerCase().includes(query);
        const matchesText = msg.text.toLowerCase().includes(query);
        const matchesLocation = msg.location.toLowerCase().includes(query);
        const matchesId = msg.id.toLowerCase().includes(query);
        return matchesSender || matchesText || matchesLocation || matchesId;
      }

      return true;
    });
  }, [messages, activeTab, selectedHopFilter, searchTerm]);

  // Acknowledge a message
  const handleAcknowledge = async (id: string) => {
    try {
      await messagesApi.acknowledgeMessage(id);
      setMessages((prev) =>
        prev.map((m) =>
          m.id === id ? { ...m, acknowledged: true, deliveryStatus: 'delivered' } : m
        )
      );
      if (selectedMessage?.id === id) {
        setSelectedMessage((prev) => (prev ? { ...prev, acknowledged: true, deliveryStatus: 'delivered' } : null));
      }
    } catch (e) {
      console.error('Failed to acknowledge message:', e);
    }
  };

  // Broadcast dispatch
  const handleSendBroadcast = async (payload: BroadcastMessagePayload) => {
    const created = await messagesApi.sendBroadcast(payload);
    setMessages((prev) => [created, ...prev]);
    setIsBroadcastOpen(false);
  };

  // Quick reply inside inspection drawer
  const handleSendReply = async () => {
    if (!replyText.trim() || !selectedMessage) return;
    setIsSendingReply(true);
    try {
      await handleSendBroadcast({
        recipientGroup: 'field_users',
        text: `Reply to ${selectedMessage.senderName} (${selectedMessage.id}): ${replyText.trim()}`,
        badgeType: 'team',
        priority: 'NORMAL',
        location: selectedMessage.location,
      });
      setReplyText('');
    } finally {
      setIsSendingReply(false);
    }
  };

  const handleCopyId = (id: string) => {
    navigator.clipboard.writeText(id);
    setIsCopied(true);
    setTimeout(() => setIsCopied(false), 2000);
  };

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2.5">
            <h1
              className="text-2xl sm:text-3xl font-black text-slate-900 dark:text-white tracking-tight"
              style={{ fontFamily: '"Barlow Semi Condensed", sans-serif' }}
            >
              Messages & Communications
            </h1>
            <span className="flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-bold bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20">
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
              Live DTN Mesh
            </span>
          </div>
          <p className="text-xs sm:text-sm text-slate-500 dark:text-slate-400 mt-1">
            Real-time peer telemetry, emergency distress signals & store-and-forward delay-tolerant mesh packets
          </p>
        </div>

        <div className="flex items-center gap-3">
          <button
            onClick={() => {
              setIsLoading(true);
              fetchMessages();
            }}
            className="p-2.5 rounded-xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-[#162036] text-slate-700 dark:text-slate-300 hover:text-slate-900 dark:hover:text-white hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors cursor-pointer shadow-xs"
            title="Refresh packet feed"
          >
            <RefreshCw size={16} className={isLoading ? 'animate-spin' : ''} />
          </button>

          <button
            onClick={() => setIsBroadcastOpen(true)}
            className="flex items-center gap-2 px-4 py-2.5 rounded-xl bg-[#FFC400] text-slate-950 font-bold text-xs sm:text-sm hover:bg-[#E0AA00] transition-colors shadow-sm cursor-pointer"
          >
            <Radio size={16} />
            <span>Broadcast Over Mesh</span>
          </button>
        </div>
      </div>

      {/* KPI Overview Metrics Strip */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 sm:gap-4">
        <div className="p-4 rounded-xl bg-white dark:bg-[#162036] border border-slate-200 dark:border-slate-800 shadow-xs">
          <div className="flex items-center justify-between text-slate-500 dark:text-slate-400 mb-1">
            <span className="text-xs font-semibold uppercase tracking-wider">Total Packets</span>
            <Activity size={16} className="text-sky-500" />
          </div>
          <div className="text-2xl font-black text-slate-900 dark:text-white">{tabCounts.all}</div>
          <span className="text-[11px] text-slate-500 dark:text-slate-400">Ingested from field network</span>
        </div>

        <div className="p-4 rounded-xl bg-white dark:bg-[#162036] border border-red-200/60 dark:border-red-900/40 shadow-xs">
          <div className="flex items-center justify-between text-red-600 dark:text-red-400 mb-1">
            <span className="text-xs font-semibold uppercase tracking-wider">Active SOS</span>
            <ShieldAlert size={16} className="animate-pulse" />
          </div>
          <div className="text-2xl font-black text-red-600 dark:text-red-400">{tabCounts.sos}</div>
          <span className="text-[11px] text-red-600/80 dark:text-red-400/80">Immediate rescue required</span>
        </div>

        <div className="p-4 rounded-xl bg-white dark:bg-[#162036] border border-slate-200 dark:border-slate-800 shadow-xs">
          <div className="flex items-center justify-between text-teal-600 dark:text-teal-400 mb-1">
            <span className="text-xs font-semibold uppercase tracking-wider">Field Sitreps</span>
            <Layers size={16} />
          </div>
          <div className="text-2xl font-black text-teal-600 dark:text-teal-400">{tabCounts.report}</div>
          <span className="text-[11px] text-slate-500 dark:text-slate-400">Obstacles & resource needs</span>
        </div>

        <div className="p-4 rounded-xl bg-white dark:bg-[#162036] border border-slate-200 dark:border-slate-800 shadow-xs">
          <div className="flex items-center justify-between text-indigo-600 dark:text-indigo-400 mb-1">
            <span className="text-xs font-semibold uppercase tracking-wider">Mesh Relay Ratio</span>
            <Share2 size={16} />
          </div>
          <div className="text-2xl font-black text-indigo-600 dark:text-indigo-400">
            {messages.length > 0
              ? `${Math.round(
                  (messages.filter((m) => (m.meshHops ?? 0) > 0).length / messages.length) * 100
                )}%`
              : '0%'}
          </div>
          <span className="text-[11px] text-slate-500 dark:text-slate-400">Store-and-forward relayed</span>
        </div>
      </div>

      {/* Main Filter & Tabs Bar */}
      <div className="flex flex-col lg:flex-row items-stretch lg:items-center justify-between gap-3 p-3 rounded-2xl bg-white dark:bg-[#162036] border border-slate-200 dark:border-slate-800 shadow-xs">
        <MessageTabs activeTab={activeTab} onTabChange={setActiveTab} counts={tabCounts} />

        <div className="flex items-center gap-2.5">
          {/* Hop Routing Filter */}
          <select
            value={selectedHopFilter}
            onChange={(e) => setSelectedHopFilter(e.target.value as any)}
            className="h-9 px-3 text-xs font-semibold rounded-xl bg-slate-50 dark:bg-[#0B1220] border border-slate-200 dark:border-slate-800 text-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-[#FFC400]"
          >
            <option value="all">All Routing (Direct + Multi-Hop)</option>
            <option value="direct">Direct Radios Only (0 Hops)</option>
            <option value="multihop">DTN Relayed Only (1+ Hops)</option>
          </select>

          {/* Search Field */}
          <div className="relative flex-1 sm:w-64">
            <Search
              size={15}
              className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 dark:text-slate-500"
            />
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder="Search sender, text, ID..."
              className="w-full h-9 pl-9 pr-3 rounded-xl bg-slate-50 dark:bg-[#0B1220] border border-slate-200 dark:border-slate-800 text-xs text-slate-900 dark:text-white placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-[#FFC400]"
            />
            {searchTerm && (
              <button
                onClick={() => setSearchTerm('')}
                className="absolute right-2.5 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600 dark:hover:text-slate-200"
              >
                <X size={14} />
              </button>
            )}
          </div>
        </div>
      </div>

      {/* Main Messages Feed / Empty State */}
      <div className="space-y-3">
        {isLoading ? (
          <div className="space-y-3">
            {[1, 2, 3, 4].map((i) => (
              <div
                key={i}
                className="p-5 rounded-2xl bg-white dark:bg-[#162036] border border-slate-200 dark:border-slate-800 animate-pulse flex items-start gap-4"
              >
                <div className="w-10 h-10 rounded-full bg-slate-200 dark:bg-slate-700 shrink-0" />
                <div className="flex-1 space-y-2">
                  <div className="h-4 bg-slate-200 dark:bg-slate-700 rounded w-1/4" />
                  <div className="h-3 bg-slate-200 dark:bg-slate-700 rounded w-3/4" />
                  <div className="h-3 bg-slate-200 dark:bg-slate-700 rounded w-1/3" />
                </div>
              </div>
            ))}
          </div>
        ) : filteredMessages.length === 0 ? (
          <div className="text-center py-16 px-4 rounded-2xl bg-white dark:bg-[#162036] border border-slate-200 dark:border-slate-800">
            <div className="w-16 h-16 mx-auto mb-4 rounded-full bg-slate-100 dark:bg-slate-800 flex items-center justify-center text-slate-400">
              <MessageSquare size={28} />
            </div>
            <h3 className="text-base font-bold text-slate-900 dark:text-white mb-1">
              No Packets Found in Filter
            </h3>
            <p className="text-xs text-slate-500 dark:text-slate-400 max-w-sm mx-auto">
              There are currently no messages matching "{activeTab}" with the selected filter. Listening on local mesh gateway port 8000.
            </p>
          </div>
        ) : (
          filteredMessages.map((msg) => (
            <MessageItem
              key={msg.id}
              message={msg}
              onSelect={(m) => setSelectedMessage(m)}
              onAcknowledge={(id) => handleAcknowledge(id)}
            />
          ))
        )}
      </div>

      {/* Packet Inspection Drawer (Sliding Right Panel) */}
      {selectedMessage && (
        <div
          role="dialog"
          aria-modal="true"
          className="fixed inset-0 z-50 overflow-hidden bg-black/40 backdrop-blur-xs flex justify-end animate-in fade-in duration-200"
          onClick={() => setSelectedMessage(null)}
        >
          <div
            className="w-full max-w-md bg-white dark:bg-[#0B1220] h-full shadow-2xl border-l border-slate-200 dark:border-slate-800 flex flex-col overflow-hidden animate-in slide-in-from-right duration-250"
            onClick={(e) => e.stopPropagation()}
          >
            {/* Drawer Header */}
            <div className="px-6 py-4 border-b border-slate-200 dark:border-slate-800 flex items-center justify-between bg-slate-50 dark:bg-[#162036]">
              <div className="flex items-center gap-2">
                <Radio className="w-5 h-5 text-[#FFC400] animate-pulse" />
                <h3 className="text-base font-bold text-slate-900 dark:text-white">
                  DTN Packet Inspector
                </h3>
              </div>
              <button
                onClick={() => setSelectedMessage(null)}
                className="p-1.5 rounded-lg text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 hover:bg-slate-200 dark:hover:bg-slate-700 transition-colors"
              >
                <X size={18} />
              </button>
            </div>

            {/* Drawer Body */}
            <div className="flex-1 overflow-y-auto p-6 space-y-5">
              {/* Message UUID with Copy Action */}
              <div className="p-3.5 rounded-xl bg-slate-50 dark:bg-[#162036] border border-slate-200 dark:border-slate-800 flex items-center justify-between">
                <div>
                  <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">
                    Packet ID
                  </span>
                  <span className="text-xs font-mono font-bold text-slate-900 dark:text-slate-100">
                    {selectedMessage.id}
                  </span>
                </div>
                <button
                  onClick={() => handleCopyId(selectedMessage.id)}
                  className="p-2 rounded-lg bg-white dark:bg-[#0B1220] border border-slate-200 dark:border-slate-700 text-slate-600 dark:text-slate-300 hover:text-slate-900 dark:hover:text-white transition-colors"
                  title="Copy Packet ID"
                >
                  {isCopied ? <Check size={14} className="text-emerald-500" /> : <Copy size={14} />}
                </button>
              </div>

              {/* Sender & Status Row */}
              <div className="flex items-center gap-3">
                <div className="w-12 h-12 rounded-full bg-slate-100 dark:bg-[#162036] border border-slate-200 dark:border-slate-700 flex items-center justify-center font-bold text-lg text-[#FFC400] shrink-0">
                  {selectedMessage.senderAvatarInitial}
                </div>
                <div className="flex-1 min-w-0">
                  <h4 className="text-base font-bold text-slate-900 dark:text-white truncate">
                    {selectedMessage.senderName}
                  </h4>
                  <div className="flex items-center gap-2 mt-0.5">
                    <span className="text-xs text-slate-500 dark:text-slate-400">
                      {selectedMessage.timestamp}
                    </span>
                    <span>•</span>
                    <span
                      className={`text-[10px] font-bold px-2 py-0.5 rounded-full uppercase ${
                        selectedMessage.badgeType === 'sos'
                          ? 'bg-red-500/15 text-red-600 dark:text-red-400'
                          : 'bg-teal-500/15 text-teal-600 dark:text-teal-400'
                      }`}
                    >
                      {selectedMessage.statusBadge}
                    </span>
                  </div>
                </div>
              </div>

              {/* Message Payload Box */}
              <div className="p-4 rounded-xl bg-slate-50 dark:bg-[#162036] border border-slate-200 dark:border-slate-800">
                <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block mb-1">
                  Message Payload
                </span>
                <p className="text-sm text-slate-800 dark:text-slate-100 leading-relaxed font-medium">
                  {selectedMessage.text}
                </p>
              </div>

              {/* Telemetry & Routing Specs */}
              <div className="space-y-2.5 text-xs">
                <div className="flex items-center justify-between py-2 border-b border-slate-100 dark:border-slate-800">
                  <span className="text-slate-500 dark:text-slate-400">Geographic Location</span>
                  <span className="font-semibold text-slate-900 dark:text-white flex items-center gap-1">
                    <MapPin size={13} className="text-[#0E8A94]" />
                    {selectedMessage.location}
                  </span>
                </div>

                <div className="flex items-center justify-between py-2 border-b border-slate-100 dark:border-slate-800">
                  <span className="text-slate-500 dark:text-slate-400">DTN Routing Hops</span>
                  <span className="font-mono font-bold text-slate-900 dark:text-white">
                    {selectedMessage.meshHops ?? 0} Hops
                  </span>
                </div>

                <div className="flex items-center justify-between py-2 border-b border-slate-100 dark:border-slate-800">
                  <span className="text-slate-500 dark:text-slate-400">Relay Data Mule Node</span>
                  <span className="font-mono font-semibold text-slate-900 dark:text-white">
                    {selectedMessage.relayDeviceId || 'Direct RF Link'}
                  </span>
                </div>

                <div className="flex items-center justify-between py-2 border-b border-slate-100 dark:border-slate-800">
                  <span className="text-slate-500 dark:text-slate-400">Incident Affiliation</span>
                  <span className="font-semibold text-slate-900 dark:text-white">
                    {selectedMessage.incidentId || 'INC-FLD-2026-001'}
                  </span>
                </div>

                <div className="flex items-center justify-between py-2">
                  <span className="text-slate-500 dark:text-slate-400">Delivery Status</span>
                  <span
                    className={`font-bold uppercase text-[11px] ${
                      selectedMessage.acknowledged
                        ? 'text-emerald-600 dark:text-emerald-400'
                        : 'text-amber-600 dark:text-amber-400'
                    }`}
                  >
                    {selectedMessage.acknowledged ? 'Acknowledged' : 'Pending Acknowledgment'}
                  </span>
                </div>
              </div>

              {/* Hop Routing Diagram */}
              <div className="p-4 rounded-xl bg-slate-50 dark:bg-[#162036] border border-slate-200 dark:border-slate-800">
                <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block mb-2">
                  Relay Hop Timeline
                </span>
                <div className="flex items-center justify-between text-center text-xs">
                  <div className="flex flex-col items-center">
                    <div className="w-7 h-7 rounded-full bg-sky-500/20 text-sky-600 dark:text-sky-400 flex items-center justify-center font-bold mb-1">
                      1
                    </div>
                    <span className="text-[10px] text-slate-500">Origin</span>
                    <span className="font-bold text-[10px] text-slate-700 dark:text-slate-200 truncate max-w-[70px]">
                      {selectedMessage.senderName.split(' ')[0]}
                    </span>
                  </div>

                  <ArrowRight size={14} className="text-slate-400" />

                  <div className="flex flex-col items-center">
                    <div className="w-7 h-7 rounded-full bg-teal-500/20 text-teal-600 dark:text-teal-400 flex items-center justify-center font-bold mb-1">
                      2
                    </div>
                    <span className="text-[10px] text-slate-500">Mule Node</span>
                    <span className="font-bold text-[10px] text-slate-700 dark:text-slate-200 truncate max-w-[70px]">
                      {selectedMessage.relayDeviceId || 'Direct'}
                    </span>
                  </div>

                  <ArrowRight size={14} className="text-slate-400" />

                  <div className="flex flex-col items-center">
                    <div className="w-7 h-7 rounded-full bg-emerald-500/20 text-emerald-600 dark:text-emerald-400 flex items-center justify-center font-bold mb-1">
                      3
                    </div>
                    <span className="text-[10px] text-slate-500">Gateway</span>
                    <span className="font-bold text-[10px] text-slate-700 dark:text-slate-200 truncate max-w-[70px]">
                      Command HQ
                    </span>
                  </div>
                </div>
              </div>

              {/* Quick Reply Form */}
              <div className="space-y-2">
                <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">
                  Quick Reply to Node
                </span>
                <div className="flex items-center gap-2">
                  <input
                    type="text"
                    value={replyText}
                    onChange={(e) => setReplyText(e.target.value)}
                    placeholder={`Broadcast reply to ${selectedMessage.senderName}...`}
                    className="flex-1 h-9 px-3 text-xs bg-slate-50 dark:bg-[#162036] border border-slate-200 dark:border-slate-800 rounded-xl text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-[#FFC400]"
                  />
                  <button
                    onClick={handleSendReply}
                    disabled={!replyText.trim() || isSendingReply}
                    className="h-9 px-3 rounded-xl bg-[#FFC400] text-slate-950 font-bold text-xs hover:bg-[#E0AA00] disabled:opacity-50 transition-colors flex items-center gap-1 cursor-pointer"
                  >
                    <Send size={13} />
                    <span>Send</span>
                  </button>
                </div>
              </div>
            </div>

            {/* Drawer Bottom Actions */}
            <div className="p-4 border-t border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-[#162036] flex items-center gap-3">
              {!selectedMessage.acknowledged && (
                <button
                  onClick={() => handleAcknowledge(selectedMessage.id)}
                  className="flex-1 py-2.5 rounded-xl bg-emerald-600 text-white font-bold text-xs hover:bg-emerald-700 transition-colors flex items-center justify-center gap-1.5 shadow-sm cursor-pointer"
                >
                  <CheckCheck size={16} />
                  <span>Acknowledge Beacon</span>
                </button>
              )}

              <button
                onClick={() => navigate('/app/map')}
                className="flex-1 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-[#0B1220] text-slate-800 dark:text-white font-bold text-xs hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors flex items-center justify-center gap-1.5 shadow-xs cursor-pointer"
              >
                <ExternalLink size={15} />
                <span>Locate on Live Map</span>
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Broadcast Modal */}
      <BroadcastMessageModal
        isOpen={isBroadcastOpen}
        onClose={() => setIsBroadcastOpen(false)}
        onSend={handleSendBroadcast}
      />
    </div>
  );
};

export default MessagesPage;

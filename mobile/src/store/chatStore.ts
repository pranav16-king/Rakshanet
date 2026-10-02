import { create } from 'zustand';
import { Conversation, Message } from '@/types/chat';
import { chatRepository } from '@/database/repositories/chatRepository';
import { chatService } from '@/services/chat/chatService';

interface ChatStoreState {
  conversations: Conversation[];
  activeMessages: Record<string, Message[]>; // conversationId -> messages
  pendingCount: number;
  loadConversations: () => Promise<void>;
  loadMessages: (conversationId: string) => Promise<void>;
  sendMessage: (
    conversationId: string,
    content: string,
    senderDeviceId: string,
    senderName: string
  ) => Promise<void>;
}

export const useChatStore = create<ChatStoreState>((set, get) => ({
  conversations: [],
  activeMessages: {},
  pendingCount: 0,

  loadConversations: async () => {
    // Ensure default Community Mesh group exists
    await chatRepository.getOrCreateConversation(
      'COMMUNITY_MESH',
      'Community Mesh (All Nearby)',
      'GROUP'
    );
    const convs = await chatRepository.getConversations();
    const pending = await chatRepository.getPendingQueue();
    set({ conversations: convs, pendingCount: pending.length });
  },

  loadMessages: async (conversationId: string) => {
    const msgs = await chatRepository.getMessages(conversationId);
    set((state) => ({
      activeMessages: {
        ...state.activeMessages,
        [conversationId]: msgs,
      },
    }));
  },

  sendMessage: async (conversationId, content, senderDeviceId, senderName) => {
    const newMsg = await chatService.sendMessage(
      conversationId,
      content,
      senderDeviceId,
      senderName
    );

    // Update active UI messages instantly
    set((state) => {
      const current = state.activeMessages[conversationId] || [];
      return {
        activeMessages: {
          ...state.activeMessages,
          [conversationId]: [...current, newMsg],
        },
        pendingCount: state.pendingCount + 1,
      };
    });

    // Refresh conversation list preview
    const convs = await chatRepository.getConversations();
    set({ conversations: convs });
  },
}));

import { chatRepository } from '@/database/repositories/chatRepository';
import { meshService } from '../mesh/meshService';
import { Message, Conversation } from '@/types/chat';

export class ChatService {
  /**
   * Save-Before-Send Transactional Message Pipeline
   */
  public async sendMessage(
    conversationId: string,
    content: string,
    senderDeviceId: string,
    senderName: string
  ): Promise<Message> {
    const randomHex = () => Math.random().toString(16).substring(2, 6).toUpperCase();
    const messageId = `MSG-${randomHex()}-${randomHex()}`;
    const now = Date.now();

    const newMessage: Message = {
      id: `msg_${now}_${Math.random().toString(36).substring(2, 6)}`,
      messageId,
      conversationId,
      senderDeviceId,
      senderName,
      messageType: 'TEXT',
      content,
      createdAt: now,
      expiresAt: now + 86400000 * 3, // 72hr
      status: 'SAVED',
      hopCount: 0,
      ttl: 5,
    };

    // 1. Durably persist to SQLite FIRST
    await chatRepository.saveMessage(newMessage);

    // 2. Trigger asynchronous mesh transmission
    meshService.flushOutbox().catch((err) => {
      console.warn('[ChatService] Outbox flush deferred', err);
    });

    return newMessage;
  }

  public async getConversations(): Promise<Conversation[]> {
    return await chatRepository.getConversations();
  }

  public async getMessages(conversationId: string): Promise<Message[]> {
    return await chatRepository.getMessages(conversationId);
  }
}

export const chatService = new ChatService();

import { dbManager } from '../sqlite';
import { Conversation, Message, MessageRelay, MessageStatus } from '@/types/chat';

export class ChatRepository {
  public async getConversations(): Promise<Conversation[]> {
    const table = dbManager.getMockTable('conversations');
    return [...table].sort((a, b) => b.updatedAt - a.updatedAt);
  }

  public async getOrCreateConversation(
    conversationId: string,
    title: string,
    type: 'DIRECT' | 'GROUP' | 'RELAY' | 'BROADCAST' = 'DIRECT'
  ): Promise<Conversation> {
    const table = dbManager.getMockTable('conversations');
    let conv = table.find((c: Conversation) => c.conversationId === conversationId);
    if (!conv) {
      conv = {
        id: `conv_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`,
        conversationId,
        type,
        title,
        createdAt: Date.now(),
        updatedAt: Date.now(),
      };
      table.push(conv);
      dbManager.setMockTable('conversations', table);
    }
    return conv;
  }

  public async getMessages(conversationId: string): Promise<Message[]> {
    const table = dbManager.getMockTable('messages');
    return table
      .filter((m: Message) => m.conversationId === conversationId)
      .sort((a: Message, b: Message) => a.createdAt - b.createdAt);
  }

  public async hasMessage(messageId: string): Promise<boolean> {
    const table = dbManager.getMockTable('messages');
    return table.some((m: Message) => m.messageId === messageId);
  }

  public async saveMessage(message: Message): Promise<void> {
    const table = dbManager.getMockTable('messages');
    const existingIndex = table.findIndex((m: Message) => m.messageId === message.messageId);
    if (existingIndex >= 0) {
      table[existingIndex] = message;
    } else {
      table.push(message);
    }
    dbManager.setMockTable('messages', table);

    // Update parent conversation timestamp and lastMessage preview
    const convTable = dbManager.getMockTable('conversations');
    const convIndex = convTable.findIndex((c: Conversation) => c.conversationId === message.conversationId);
    if (convIndex >= 0) {
      convTable[convIndex].updatedAt = message.createdAt;
      convTable[convIndex].lastMessage = message.content;
      dbManager.setMockTable('conversations', convTable);
    }
  }

  public async updateMessageStatus(messageId: string, status: MessageStatus, hopCount?: number): Promise<void> {
    const table = dbManager.getMockTable('messages');
    const index = table.findIndex((m: Message) => m.messageId === messageId);
    if (index >= 0) {
      table[index].status = status;
      if (hopCount !== undefined) {
        table[index].hopCount = hopCount;
      }
      dbManager.setMockTable('messages', table);
    }
  }

  public async getPendingQueue(): Promise<Message[]> {
    const table = dbManager.getMockTable('messages');
    return table.filter((m: Message) => ['SAVED', 'QUEUED', 'SENDING'].includes(m.status));
  }

  public async addRelayHop(relay: MessageRelay): Promise<void> {
    const table = dbManager.getMockTable('message_relays');
    table.push(relay);
    dbManager.setMockTable('message_relays', table);
  }

  public async getRelaysForMessage(messageId: string): Promise<MessageRelay[]> {
    const table = dbManager.getMockTable('message_relays');
    return table.filter((r: MessageRelay) => r.messageId === messageId);
  }
}

export const chatRepository = new ChatRepository();

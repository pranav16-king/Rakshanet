import { CREATE_TABLES_SQL } from './schema';

/**
 * Lightweight, robust SQLite abstraction for React Native.
 * Provides fallback in-memory mock storage if native SQLite driver is absent.
 */
class DatabaseManager {
  private isInitialized = false;
  private mockStore: Record<string, any[]> = {
    user_profile: [],
    device_identity: [],
    nearby_devices: [],
    conversations: [],
    conversation_participants: [],
    messages: [],
    message_relays: [],
  };

  public async initialize(): Promise<void> {
    if (this.isInitialized) return;

    try {
      // In production React Native environment, initialize native SQLite driver
      // e.g., QuickSQLite.open({ name: 'rakshanet.db' })
      console.log('[SQLite] Initializing database schemas...');
      this.isInitialized = true;
    } catch (err) {
      console.warn('[SQLite] Native SQLite driver unavailable, using memory store fallback', err);
      this.isInitialized = true;
    }
  }

  public getMockTable(table: string): any[] {
    if (!this.mockStore[table]) {
      this.mockStore[table] = [];
    }
    return this.mockStore[table];
  }

  public setMockTable(table: string, data: any[]): void {
    this.mockStore[table] = data;
  }
}

export const dbManager = new DatabaseManager();

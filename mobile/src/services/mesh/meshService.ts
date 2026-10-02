import { bluetoothService } from '../bluetooth/bluetoothService';
import { chatRepository } from '@/database/repositories/chatRepository';
import { deviceRepository } from '@/database/repositories/deviceRepository';
import { NetworkPacket, Message, MessageRelay } from '@/types/chat';

export class MeshService {
  private isProcessingQueue = false;

  public initialize(myDeviceId: string): void {
    // Listen for incoming RF packets
    bluetoothService.subscribePacketReceived(async (packet: NetworkPacket) => {
      await this.handleIncomingPacket(packet, myDeviceId);
    });

    // When peers appear, trigger outbox flush
    bluetoothService.subscribeDeviceDiscovered(async (device) => {
      await deviceRepository.upsertDevice(device);
      this.flushOutbox();
    });

    // Periodic outbox flush (every 10s)
    setInterval(() => {
      this.flushOutbox();
    }, 10000);
  }

  public async handleIncomingPacket(packet: NetworkPacket, myDeviceId: string): Promise<void> {
    // 1. Deduplication Check
    const alreadyExists = await chatRepository.hasMessage(packet.msg_id);
    if (alreadyExists) {
      console.log(`[MeshService] Dropping duplicate packet ${packet.msg_id}`);
      return;
    }

    // 2. Ingest message locally
    const message: Message = {
      id: `msg_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`,
      messageId: packet.msg_id,
      conversationId: packet.conv_id,
      senderDeviceId: packet.sender_id,
      senderName: packet.sender_name,
      messageType: packet.type,
      content: packet.payload,
      createdAt: packet.ts,
      expiresAt: packet.ts + 86400000 * 3, // 72hr TTL
      status: packet.hops > 0 ? 'RELAYED' : 'SENT_TO_NEARBY',
      hopCount: packet.hops,
      ttl: packet.ttl,
    };

    await chatRepository.saveMessage(message);

    // 3. Record Relay Hop Audit
    const relayRecord: MessageRelay = {
      id: `relay_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`,
      messageId: packet.msg_id,
      fromDeviceId: packet.sender_id,
      toDeviceId: myDeviceId,
      hopNumber: packet.hops + 1,
      receivedAt: Date.now(),
      status: 'RECEIVED',
    };
    await chatRepository.addRelayHop(relayRecord);

    // 4. Forwarding Decision (TTL decrement)
    if (packet.ttl <= 1) {
      console.log(`[MeshService] Packet ${packet.msg_id} TTL expired (${packet.ttl}). Halting forward.`);
      return;
    }

    const forwardedPacket: NetworkPacket = {
      ...packet,
      ttl: packet.ttl - 1,
      hops: packet.hops + 1,
    };

    console.log(`[MeshService] Forwarding packet ${packet.msg_id} (New TTL: ${forwardedPacket.ttl}, Hops: ${forwardedPacket.hops})`);
    await bluetoothService.sendPacket(forwardedPacket);
  }

  public async flushOutbox(): Promise<void> {
    if (this.isProcessingQueue) return;
    this.isProcessingQueue = true;

    try {
      const pending = await chatRepository.getPendingQueue();
      if (pending.length === 0) {
        this.isProcessingQueue = false;
        return;
      }

      console.log(`[MeshService] Flushing outbox queue: ${pending.length} pending messages`);
      for (const msg of pending) {
        const packet: NetworkPacket = {
          ver: 1,
          msg_id: msg.messageId,
          conv_id: msg.conversationId,
          sender_id: msg.senderDeviceId,
          sender_name: msg.senderName,
          ts: msg.createdAt,
          ttl: msg.ttl,
          hops: msg.hopCount,
          type: msg.messageType,
          payload: msg.content,
        };

        const sent = await bluetoothService.sendPacket(packet);
        if (sent) {
          await chatRepository.updateMessageStatus(msg.messageId, 'SENT_TO_NEARBY');
        }
      }
    } catch (err) {
      console.warn('[MeshService] Error processing outbox', err);
    } finally {
      this.isProcessingQueue = false;
    }
  }
}

export const meshService = new MeshService();

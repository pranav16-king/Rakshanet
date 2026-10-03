/// Represents an authenticated cryptographic delivery ACK receipt.
class DeliveryReceipt {
  final String receiptId;
  final String messageId;
  final String recipientId;
  final int ackTimestamp;
  final String? signature;

  const DeliveryReceipt({
    required this.receiptId,
    required this.messageId,
    required this.recipientId,
    required this.ackTimestamp,
    this.signature,
  });

  Map<String, dynamic> toMap() {
    return {
      'receipt_id': receiptId,
      'message_id': messageId,
      'recipient_id': recipientId,
      'ack_timestamp': ackTimestamp,
      if (signature != null) 'signature': signature,
    };
  }

  factory DeliveryReceipt.fromMap(Map<String, dynamic> map) {
    return DeliveryReceipt(
      receiptId: (map['receipt_id'] ?? map['receiptId'] ?? '') as String,
      messageId: (map['message_id'] ?? map['messageId'] ?? '') as String,
      recipientId: (map['recipient_id'] ?? map['recipientId'] ?? '') as String,
      ackTimestamp:
          (map['ack_timestamp'] ?? map['ackTimestamp'] as num?)?.toInt() ?? 0,
      signature: (map['signature']) as String?,
    );
  }
}

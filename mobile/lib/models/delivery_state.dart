import 'package:flutter/material.dart';

import 'chat_message.dart';

/// Comprehensive lifecycle states for store-and-forward mesh message delivery.
enum MeshDeliveryState {
  saved,
  queued,
  relayed,
  deliveredToRecipient,
  syncedToServer,
  failed,
  expired;

  /// Human-readable UI status string.
  /// For [relayed], formats "Relayed by $hopCount devices".
  String statusString([int hopCount = 0]) {
    switch (this) {
      case MeshDeliveryState.saved:
        return 'Saved on this phone';
      case MeshDeliveryState.queued:
        return 'Queued in outbox';
      case MeshDeliveryState.relayed:
        final count = hopCount > 0 ? hopCount : 1;
        return 'Relayed by $count devices';
      case MeshDeliveryState.deliveredToRecipient:
        return 'Reached recipient';
      case MeshDeliveryState.syncedToServer:
        return 'Synced to command center';
      case MeshDeliveryState.failed:
        return 'Delivery failed';
      case MeshDeliveryState.expired:
        return 'Message expired';
    }
  }

  /// Display icon representing the state in the UI.
  IconData get icon {
    switch (this) {
      case MeshDeliveryState.saved:
        return Icons.check; // Single checkmark
      case MeshDeliveryState.queued:
        return Icons.access_time_rounded; // Clock / pending icon
      case MeshDeliveryState.relayed:
        return Icons.compare_arrows_rounded; // Double arrow / relay icon
      case MeshDeliveryState.deliveredToRecipient:
        return Icons.done_all_rounded; // Double checkmarks
      case MeshDeliveryState.syncedToServer:
        return Icons.cloud_done_rounded; // Cloud checkmark
      case MeshDeliveryState.failed:
        return Icons.error_outline_rounded;
      case MeshDeliveryState.expired:
        return Icons.timer_off_outlined;
    }
  }

  /// Semantic theme color for status badges, icons, and labels.
  Color get color {
    switch (this) {
      case MeshDeliveryState.saved:
        return const Color(0xFF9AA1AB);
      case MeshDeliveryState.queued:
        return const Color(0xFFFFC400);
      case MeshDeliveryState.relayed:
        return const Color(0xFF0E8A94);
      case MeshDeliveryState.deliveredToRecipient:
        return const Color(0xFF1E8E4E); // Green checkmark
      case MeshDeliveryState.syncedToServer:
        return const Color(0xFF3B82F6); // Blue cloud
      case MeshDeliveryState.failed:
        return const Color(0xFFD92D20); // Emergency / SOS Red
      case MeshDeliveryState.expired:
        return const Color(0xFF5F6E86);
    }
  }

  /// SQLite database storage representation.
  String toDbString() {
    switch (this) {
      case MeshDeliveryState.saved:
        return 'SAVED';
      case MeshDeliveryState.queued:
        return 'QUEUED';
      case MeshDeliveryState.relayed:
        return 'RELAYED';
      case MeshDeliveryState.deliveredToRecipient:
        return 'DELIVERED';
      case MeshDeliveryState.syncedToServer:
        return 'SYNCED';
      case MeshDeliveryState.failed:
        return 'FAILED';
      case MeshDeliveryState.expired:
        return 'EXPIRED';
    }
  }

  /// Parse from raw string or enum token.
  static MeshDeliveryState fromString(String? val) {
    if (val == null) return MeshDeliveryState.saved;
    final upper = val.trim().toUpperCase();
    switch (upper) {
      case 'SAVED':
      case 'MESHDELIVERYSTATE.SAVED':
        return MeshDeliveryState.saved;
      case 'QUEUED':
      case 'SENDING':
      case 'MESHDELIVERYSTATE.QUEUED':
        return MeshDeliveryState.queued;
      case 'RELAYED':
      case 'SENT_NEARBY':
      case 'SENTNEARBY':
      case 'MESHDELIVERYSTATE.RELAYED':
        return MeshDeliveryState.relayed;
      case 'DELIVERED':
      case 'DELIVERED_TO_RECIPIENT':
      case 'DELIVEREDTORECIPIENT':
      case 'MESHDELIVERYSTATE.DELIVEREDTORECIPIENT':
        return MeshDeliveryState.deliveredToRecipient;
      case 'SYNCED':
      case 'SYNCED_TO_SERVER':
      case 'SYNCEDTOSERVER':
      case 'MESHDELIVERYSTATE.SYNCEDTOSERVER':
        return MeshDeliveryState.syncedToServer;
      case 'FAILED':
      case 'MESHDELIVERYSTATE.FAILED':
        return MeshDeliveryState.failed;
      case 'EXPIRED':
      case 'MESHDELIVERYSTATE.EXPIRED':
        return MeshDeliveryState.expired;
      default:
        return MeshDeliveryState.saved;
    }
  }

  static MeshDeliveryState fromDynamic(dynamic val) {
    if (val is MeshDeliveryState) return val;
    return fromString(val?.toString());
  }

  /// Maps to legacy MessageDeliveryStatus for backwards compatibility.
  MessageDeliveryStatus toMessageDeliveryStatus() {
    switch (this) {
      case MeshDeliveryState.saved:
        return MessageDeliveryStatus.saved;
      case MeshDeliveryState.queued:
        return MessageDeliveryStatus.queued;
      case MeshDeliveryState.relayed:
        return MessageDeliveryStatus.relayed;
      case MeshDeliveryState.deliveredToRecipient:
        return MessageDeliveryStatus.delivered;
      case MeshDeliveryState.syncedToServer:
        return MessageDeliveryStatus.delivered;
      case MeshDeliveryState.failed:
        return MessageDeliveryStatus.failed;
      case MeshDeliveryState.expired:
        return MessageDeliveryStatus.failed;
    }
  }
}

import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { useTheme } from '@/theme';
import { Message } from '@/types/chat';

interface Props {
  message: Message;
  isMine: boolean;
}

export function ChatBubble({ message, isMine }: Props) {
  const { c, type, radius } = useTheme();

  // Status label & icon
  let statusText = 'Saved';
  let statusColor = c.textMuted;
  if (message.status === 'SAVED') {
    statusText = '✓ Saved on phone';
  } else if (message.status === 'QUEUED') {
    statusText = '⏱ Queued in outbox';
  } else if (message.status === 'SENT_TO_NEARBY') {
    statusText = '✓✓ Sent nearby';
    statusColor = c.info;
  } else if (message.status === 'RELAYED') {
    statusText = `↗ Relayed (${message.hopCount} hops)`;
    statusColor = c.info;
  } else if (message.status === 'DELIVERED') {
    statusText = '✓✓ Reached team';
    statusColor = c.success;
  }

  const timeString = new Date(message.createdAt).toLocaleTimeString([], {
    hour: '2-digit',
    minute: '2-digit',
  });

  return (
    <View
      style={[
        styles.container,
        isMine ? styles.myContainer : styles.theirContainer,
      ]}
    >
      <View
        style={[
          styles.bubble,
          {
            borderRadius: radius.md,
            backgroundColor: isMine ? c.primarySoft : c.surfaceSunken,
            borderColor: isMine ? c.borderStrong : c.border,
          },
        ]}
      >
        {!isMine && (
          <Text style={[styles.sender, type.micro, { color: c.info }]}>
            {message.senderName} ({message.senderDeviceId})
          </Text>
        )}
        <Text style={[styles.content, type.body, { color: c.text }]}>
          {message.content}
        </Text>
        <View style={styles.footer}>
          <Text style={[styles.time, type.micro, { color: c.textMuted }]}>
            {timeString}
          </Text>
          {isMine && (
            <Text style={[styles.status, type.micro, { color: statusColor }]}>
              {statusText}
            </Text>
          )}
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    marginVertical: 4,
    paddingHorizontal: 12,
  },
  myContainer: {
    alignItems: 'flex-end',
  },
  theirContainer: {
    alignItems: 'flex-start',
  },
  bubble: {
    maxWidth: '82%',
    paddingVertical: 10,
    paddingHorizontal: 14,
    borderWidth: 1,
  },
  sender: {
    marginBottom: 4,
  },
  content: {
    marginBottom: 6,
  },
  footer: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'flex-end',
    gap: 8,
  },
  time: {
    fontSize: 11,
  },
  status: {
    fontSize: 11,
    fontWeight: '600',
  },
});

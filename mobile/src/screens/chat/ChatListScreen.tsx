import React, { useEffect } from 'react';
import { View, Text, FlatList, Pressable, StyleSheet } from 'react-native';
import { useTheme } from '@/theme';
import { StatusStrip } from '@/components/StatusStrip';
import { useChatStore } from '@/store/chatStore';
import { Conversation } from '@/types/chat';

interface Props {
  navigation: any;
}

export function ChatListScreen({ navigation }: Props) {
  const { c, type, radius } = useTheme();
  const { conversations, loadConversations } = useChatStore();

  useEffect(() => {
    loadConversations();
  }, [loadConversations]);

  const renderItem = ({ item }: { item: Conversation }) => {
    const isCommunity = item.conversationId === 'COMMUNITY_MESH';

    return (
      <Pressable
        onPress={() =>
          navigation.navigate('ChatDetail', {
            conversationId: item.conversationId,
            title: item.title,
          })
        }
        style={({ pressed }) => [
          styles.row,
          {
            backgroundColor: c.surface,
            borderColor: c.border,
            borderRadius: radius.md,
            transform: [{ scale: pressed ? 0.98 : 1 }],
          },
        ]}
      >
        <View style={styles.iconBox}>
          <Text style={styles.icon}>{isCommunity ? '📢' : '💬'}</Text>
        </View>

        <View style={styles.info}>
          <View style={styles.header}>
            <Text style={[styles.title, type.h3, { color: c.text }]}>
              {item.title}
            </Text>
            <Text style={[styles.time, type.micro, { color: c.textMuted }]}>
              {new Date(item.updatedAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
            </Text>
          </View>
          <Text
            numberOfLines={1}
            style={[styles.preview, type.body, { color: c.textMuted }]}
          >
            {item.lastMessage || 'No messages yet. Send an offline distress ping.'}
          </Text>
        </View>
      </Pressable>
    );
  };

  return (
    <View style={[styles.container, { backgroundColor: c.bg }]}>
      <StatusStrip />

      <View style={styles.content}>
        <View style={styles.pageHeader}>
          <Text style={[styles.heading, type.h1, { color: c.text }]}>
            Offline Chats
          </Text>
          <Text style={[styles.subheading, type.caption, { color: c.textMuted }]}>
            All messages propagate over local Bluetooth mesh and persist in SQLite.
          </Text>
        </View>

        <FlatList
          data={conversations}
          keyExtractor={(item) => item.conversationId}
          renderItem={renderItem}
          contentContainerStyle={styles.list}
        />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  content: {
    flex: 1,
    padding: 16,
  },
  pageHeader: {
    marginBottom: 16,
  },
  heading: {
    marginBottom: 4,
  },
  subheading: {
    lineHeight: 18,
  },
  list: {
    gap: 10,
    paddingBottom: 24,
  },
  row: {
    flexDirection: 'row',
    padding: 14,
    borderWidth: 1,
    alignItems: 'center',
  },
  iconBox: {
    width: 44,
    height: 44,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 12,
  },
  icon: {
    fontSize: 24,
  },
  info: {
    flex: 1,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 4,
  },
  title: {
    fontSize: 16,
  },
  time: {
    fontSize: 11,
  },
  preview: {
    fontSize: 14,
  },
});

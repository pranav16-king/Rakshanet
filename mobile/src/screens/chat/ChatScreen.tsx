import React, { useState, useEffect, useRef } from 'react';
import {
  View,
  Text,
  FlatList,
  TextInput,
  Pressable,
  StyleSheet,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { useTheme } from '@/theme';
import { StatusStrip } from '@/components/StatusStrip';
import { ChatBubble } from '@/components/ChatBubble';
import { useChatStore } from '@/store/chatStore';
import { useProfileStore } from '@/store/profileStore';

interface Props {
  route: any;
  navigation: any;
}

export function ChatScreen({ route, navigation }: Props) {
  const { conversationId, title } = route.params || {
    conversationId: 'COMMUNITY_MESH',
    title: 'Community Mesh',
  };
  const { c, type, radius, size } = useTheme();
  const [inputText, setInputText] = useState('');
  const flatListRef = useRef<FlatList>(null);

  const { activeMessages, loadMessages, sendMessage } = useChatStore();
  const { profile, identity } = useProfileStore();

  const messages = activeMessages[conversationId] || [];

  useEffect(() => {
    loadMessages(conversationId);
  }, [conversationId, loadMessages]);

  const handleSend = async (textToSend?: string) => {
    const text = (textToSend || inputText).trim();
    if (!text || !identity) return;

    setInputText('');
    await sendMessage(
      conversationId,
      text,
      identity.deviceId,
      profile?.name || 'Local User'
    );

    setTimeout(() => {
      flatListRef.current?.scrollToEnd({ animated: true });
    }, 100);
  };

  const quickShortcuts = [
    'Need medical help',
    'We are safe here',
    'Road blocked ahead',
    'Water available here',
  ];

  return (
    <KeyboardAvoidingView
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      style={[styles.container, { backgroundColor: c.bg }]}
    >
      <StatusStrip />

      {/* Screen Title Bar */}
      <View style={[styles.titleBar, { backgroundColor: c.surface, borderBottomColor: c.border }]}>
        <Pressable onPress={() => navigation.goBack()} style={styles.backBtn}>
          <Text style={[styles.backText, type.h3, { color: c.text }]}>←</Text>
        </Pressable>
        <View style={styles.titleInfo}>
          <Text style={[styles.convTitle, type.h3, { color: c.text }]}>
            {title}
          </Text>
          <Text style={[styles.convSub, type.micro, { color: c.info }]}>
            ● Offline RF Mesh Mode
          </Text>
        </View>
      </View>

      {/* Messages Stream */}
      <FlatList
        ref={flatListRef}
        data={messages}
        keyExtractor={(item) => item.messageId}
        renderItem={({ item }) => (
          <ChatBubble
            message={item}
            isMine={item.senderDeviceId === identity?.deviceId}
          />
        )}
        contentContainerStyle={styles.listContent}
        ListEmptyComponent={
          <View style={styles.emptyContainer}>
            <Text style={styles.emptyIcon}>📡</Text>
            <Text style={[styles.emptyTitle, type.h3, { color: c.text }]}>
              No Offline Messages Yet
            </Text>
            <Text style={[styles.emptyText, type.caption, { color: c.textMuted }]}>
              Type a message or tap an emergency shortcut below. Messages propagate peer-to-peer even with zero internet.
            </Text>
          </View>
        }
      />

      {/* Emergency Quick Action Shortcuts */}
      <View style={styles.shortcutContainer}>
        <FlatList
          horizontal
          showsHorizontalScrollIndicator={false}
          data={quickShortcuts}
          keyExtractor={(item) => item}
          contentContainerStyle={styles.shortcutList}
          renderItem={({ item }) => (
            <Pressable
              onPress={() => handleSend(item)}
              style={({ pressed }) => [
                styles.shortcutChip,
                {
                  backgroundColor: c.surfaceSunken,
                  borderColor: c.border,
                  borderRadius: radius.pill,
                  transform: [{ scale: pressed ? 0.96 : 1 }],
                },
              ]}
            >
              <Text style={[styles.shortcutText, type.micro, { color: c.text }]}>
                {item}
              </Text>
            </Pressable>
          )}
        />
      </View>

      {/* Input Bar */}
      <View style={[styles.inputBar, { backgroundColor: c.surface, borderTopColor: c.border }]}>
        <TextInput
          placeholder="Offline message..."
          placeholderTextColor={c.textDisabled}
          value={inputText}
          onChangeText={setInputText}
          style={[
            styles.input,
            type.body,
            {
              backgroundColor: c.surfaceSunken,
              borderColor: c.border,
              borderRadius: radius.sm,
              color: c.text,
            },
          ]}
        />
        <Pressable
          accessibilityRole="button"
          accessibilityLabel="Send offline message"
          onPress={() => handleSend()}
          style={({ pressed }) => [
            styles.sendBtn,
            {
              backgroundColor: inputText.trim() ? c.primary : c.border,
              borderRadius: radius.sm,
              transform: [{ scale: pressed ? 0.96 : 1 }],
            },
          ]}
        >
          <Text style={[styles.sendText, type.h3, { color: c.onPrimary }]}>
            ➤
          </Text>
        </Pressable>
      </View>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  titleBar: {
    height: 56,
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    borderBottomWidth: 1,
  },
  backBtn: {
    paddingRight: 14,
    paddingVertical: 8,
  },
  backText: {
    fontSize: 20,
  },
  titleInfo: {
    flex: 1,
  },
  convTitle: {
    fontSize: 16,
  },
  convSub: {
    fontSize: 11,
  },
  listContent: {
    flexGrow: 1,
    paddingVertical: 12,
  },
  emptyContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 32,
    marginTop: 60,
  },
  emptyIcon: {
    fontSize: 48,
    marginBottom: 16,
  },
  emptyTitle: {
    marginBottom: 8,
    textAlign: 'center',
  },
  emptyText: {
    textAlign: 'center',
    lineHeight: 20,
    maxWidth: 280,
  },
  shortcutContainer: {
    paddingVertical: 6,
  },
  shortcutList: {
    paddingHorizontal: 12,
    gap: 8,
  },
  shortcutChip: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderWidth: 1,
  },
  shortcutText: {
    fontSize: 12,
  },
  inputBar: {
    flexDirection: 'row',
    padding: 10,
    borderTopWidth: 1,
    alignItems: 'center',
    gap: 8,
  },
  input: {
    flex: 1,
    height: 48,
    paddingHorizontal: 14,
    borderWidth: 1,
  },
  sendBtn: {
    width: 48,
    height: 48,
    alignItems: 'center',
    justifyContent: 'center',
  },
  sendText: {
    fontSize: 18,
  },
});

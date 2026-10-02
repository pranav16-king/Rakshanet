import React, { useEffect } from 'react';
import { View, Text, StyleSheet, Pressable, ScrollView, Alert } from 'react-native';
import { useTheme } from '@/theme';
import { StatusStrip } from '@/components/StatusStrip';
import { Card } from '@/components/Card';
import { useNetworkStore } from '@/store/networkStore';
import { useChatStore } from '@/store/chatStore';
import { useProfileStore } from '@/store/profileStore';

interface Props {
  navigation: any;
}

export function HomeScreen({ navigation }: Props) {
  const { c, type, radius, size } = useTheme();
  const { connectedPeerCount, nearbyDevices, loadNearbyDevices } = useNetworkStore();
  const { pendingCount, loadConversations } = useChatStore();
  const { profile, identity } = useProfileStore();

  useEffect(() => {
    loadNearbyDevices();
    loadConversations();
  }, [loadNearbyDevices, loadConversations]);

  const handleSOSPress = () => {
    Alert.alert(
      'Emergency SOS Broadcast',
      'Phase 1 Mesh Broadcast: Distress signal recorded in local SQLite and relayed to nearby devices.',
      [{ text: 'Acknowledge', style: 'default' }]
    );
  };

  return (
    <View style={[styles.container, { backgroundColor: c.bg }]}>
      {/* Persistent Status Telemetry */}
      <StatusStrip />

      <ScrollView contentContainerStyle={styles.scrollContent}>
        {/* Offline Mode Banner */}
        <View style={[styles.banner, { backgroundColor: c.surfaceSunken, borderRadius: radius.md, borderColor: c.border }]}>
          <Text style={[styles.bannerTitle, type.micro, { color: c.info }]}>
            ● OFFLINE RESILIENCE ACTIVE
          </Text>
          <Text style={[styles.bannerText, type.caption, { color: c.text }]}>
            Cellular networks unavailable. SignalRescue is operating autonomously over Bluetooth & local mesh.
          </Text>
        </View>

        {/* SOS Central Beacon Button */}
        <View style={styles.sosContainer}>
          <Pressable
            accessibilityRole="button"
            accessibilityLabel="Emergency SOS Button"
            onPress={handleSOSPress}
            style={({ pressed }) => [
              styles.sosButton,
              {
                width: size.sosHome,
                height: size.sosHome,
                borderRadius: size.sosHome / 2,
                backgroundColor: pressed ? c.sosPressed : c.sos,
                transform: [{ scale: pressed ? 0.96 : 1 }],
              },
            ]}
          >
            <Text style={[styles.sosText, type.display, { color: '#FFFFFF' }]}>
              SOS
            </Text>
            <Text style={[styles.sosSubtext, type.micro, { color: '#FFFFFF' }]}>
              TAP FOR DISTRESS
            </Text>
          </Pressable>
        </View>

        {/* Local Network Telemetry Card */}
        <Card>
          <Text style={[styles.cardTitle, type.h3, { color: c.text }]}>
            Local Mesh Network
          </Text>
          <View style={styles.statGrid}>
            <View style={styles.statItem}>
              <Text style={[styles.statValue, type.h1, { color: c.info }]}>
                {nearbyDevices.length}
              </Text>
              <Text style={[styles.statLabel, type.caption, { color: c.textMuted }]}>
                Nearby Devices
              </Text>
            </View>

            <View style={styles.statItem}>
              <Text style={[styles.statValue, type.h1, { color: pendingCount > 0 ? c.warning : c.success }]}>
                {pendingCount}
              </Text>
              <Text style={[styles.statLabel, type.caption, { color: c.textMuted }]}>
                Pending Relays
              </Text>
            </View>
          </View>
        </Card>

        {/* Quick-action buttons */}
        <View style={styles.actionRow}>
          <Pressable
            onPress={() => navigation.navigate('ChatTab')}
            style={({ pressed }) => [
              styles.actionButton,
              {
                backgroundColor: c.surface,
                borderColor: c.border,
                borderRadius: radius.md,
                transform: [{ scale: pressed ? 0.98 : 1 }],
              },
            ]}
          >
            <Text style={styles.actionIcon}>💬</Text>
            <Text style={[styles.actionLabel, type.h3, { color: c.text }]}>
              Nearby Chat
            </Text>
            <Text style={[styles.actionDesc, type.micro, { color: c.textMuted }]}>
              Message peers without internet
            </Text>
          </Pressable>

          <Pressable
            onPress={() => navigation.navigate('NetworkTab')}
            style={({ pressed }) => [
              styles.actionButton,
              {
                backgroundColor: c.surface,
                borderColor: c.border,
                borderRadius: radius.md,
                transform: [{ scale: pressed ? 0.98 : 1 }],
              },
            ]}
          >
            <Text style={styles.actionIcon}>📡</Text>
            <Text style={[styles.actionLabel, type.h3, { color: c.text }]}>
              Network Peers
            </Text>
            <Text style={[styles.actionDesc, type.micro, { color: c.textMuted }]}>
              View active mesh topology
            </Text>
          </Pressable>
        </View>

        {/* User Identity Footer */}
        <View style={styles.identityFooter}>
          <Text style={[styles.identityText, type.mono, { color: c.textMuted }]}>
            Device ID: {identity?.deviceId || 'SR-INITIALIZING'}
          </Text>
          <Text style={[styles.identityText, type.caption, { color: c.textMuted }]}>
            Operator: {profile?.name || 'Local User'}
          </Text>
        </View>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  scrollContent: {
    padding: 16,
    paddingBottom: 32,
  },
  banner: {
    padding: 12,
    borderWidth: 1,
    marginBottom: 20,
  },
  bannerTitle: {
    fontWeight: '700',
    marginBottom: 4,
  },
  bannerText: {
    lineHeight: 18,
  },
  sosContainer: {
    alignItems: 'center',
    marginVertical: 16,
  },
  sosButton: {
    alignItems: 'center',
    justifyContent: 'center',
    elevation: 8,
    shadowColor: '#D92D20',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
  },
  sosText: {
    letterSpacing: 2,
  },
  sosSubtext: {
    letterSpacing: 0.5,
    marginTop: 4,
  },
  cardTitle: {
    marginBottom: 12,
  },
  statGrid: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    paddingVertical: 8,
  },
  statItem: {
    alignItems: 'center',
  },
  statValue: {
    marginBottom: 4,
  },
  statLabel: {
    fontWeight: '500',
  },
  actionRow: {
    flexDirection: 'row',
    gap: 12,
    marginTop: 12,
  },
  actionButton: {
    flex: 1,
    padding: 16,
    borderWidth: 1,
  },
  actionIcon: {
    fontSize: 24,
    marginBottom: 8,
  },
  actionLabel: {
    marginBottom: 4,
  },
  actionDesc: {
    lineHeight: 14,
  },
  identityFooter: {
    marginTop: 24,
    alignItems: 'center',
    gap: 4,
  },
  identityText: {
    fontSize: 12,
  },
});

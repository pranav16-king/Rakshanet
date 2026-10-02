import React, { useEffect } from 'react';
import { View, Text, FlatList, StyleSheet, Pressable } from 'react-native';
import { useTheme } from '@/theme';
import { StatusStrip } from '@/components/StatusStrip';
import { DeviceCard } from '@/components/DeviceCard';
import { Card } from '@/components/Card';
import { useNetworkStore } from '@/store/networkStore';
import { useSettingsStore } from '@/store/settingsStore';
import { RadioMode } from '@/types/network';

interface Props {
  navigation: any;
}

export function NetworkScreen({ navigation }: Props) {
  const { c, type, radius } = useTheme();
  const { nearbyDevices, loadNearbyDevices, meshState, connectedPeerCount } = useNetworkStore();
  const { radioMode, setRadioMode } = useSettingsStore();

  useEffect(() => {
    loadNearbyDevices();
  }, [loadNearbyDevices]);

  const modes: { key: RadioMode; label: string; desc: string }[] = [
    { key: 'NORMAL', label: 'Normal', desc: 'Standard BLE scan cycles' },
    { key: 'LOW_POWER', label: 'Save Battery', desc: 'Conservative RF intervals' },
    { key: 'EMERGENCY', label: 'Emergency', desc: 'High-frequency broadcast' },
  ];

  return (
    <View style={[styles.container, { backgroundColor: c.bg }]}>
      <StatusStrip />

      <FlatList
        data={nearbyDevices}
        keyExtractor={(item) => item.deviceId}
        renderItem={({ item }) => (
          <DeviceCard
            device={item}
            onPress={() =>
              navigation.navigate('ChatDetail', {
                conversationId: item.deviceId,
                title: item.displayName,
              })
            }
          />
        )}
        contentContainerStyle={styles.listContent}
        ListHeaderComponent={
          <View style={styles.header}>
            <Text style={[styles.heading, type.h1, { color: c.text }]}>
              Network Mesh
            </Text>
            <Text style={[styles.subheading, type.caption, { color: c.textMuted }]}>
              Autonomous peer topology. Zero reliance on telecom towers.
            </Text>

            {/* Radio State Overview */}
            <Card style={styles.stateCard}>
              <View style={styles.stateRow}>
                <Text style={[styles.stateLabel, type.body, { color: c.text }]}>Cellular / Internet</Text>
                <View style={[styles.badge, { backgroundColor: c.surfaceSunken, borderRadius: radius.xs }]}>
                  <Text style={[styles.badgeText, type.micro, { color: c.textMuted }]}>OFFLINE</Text>
                </View>
              </View>

              <View style={styles.stateRow}>
                <Text style={[styles.stateLabel, type.body, { color: c.text }]}>Bluetooth Low Energy</Text>
                <View style={[styles.badge, { backgroundColor: c.infoSoft, borderRadius: radius.xs }]}>
                  <Text style={[styles.badgeText, type.micro, { color: c.info }]}>ACTIVE</Text>
                </View>
              </View>

              <View style={styles.stateRow}>
                <Text style={[styles.stateLabel, type.body, { color: c.text }]}>Local Mesh Status</Text>
                <View style={[styles.badge, { backgroundColor: c.successSoft, borderRadius: radius.xs }]}>
                  <Text style={[styles.badgeText, type.micro, { color: c.success }]}>
                    {meshState === 'CONNECTED' ? `CONNECTED (${connectedPeerCount})` : 'SEARCHING'}
                  </Text>
                </View>
              </View>
            </Card>

            {/* Battery Radio Governance */}
            <Text style={[styles.sectionTitle, type.h3, { color: c.text }]}>
              Radio Battery Governance
            </Text>
            <View style={styles.modesRow}>
              {modes.map((m) => (
                <Pressable
                  key={m.key}
                  onPress={() => setRadioMode(m.key)}
                  style={[
                    styles.modeChip,
                    {
                      backgroundColor: radioMode === m.key ? c.primarySoft : c.surface,
                      borderColor: radioMode === m.key ? c.primaryInk : c.border,
                      borderRadius: radius.md,
                    },
                  ]}
                >
                  <Text
                    style={[
                      styles.modeLabel,
                      type.caption,
                      { color: radioMode === m.key ? c.primaryInk : c.text, fontWeight: '700' },
                    ]}
                  >
                    {m.label}
                  </Text>
                  <Text style={[styles.modeDesc, type.micro, { color: c.textMuted }]}>
                    {m.desc}
                  </Text>
                </Pressable>
              ))}
            </View>

            <Text style={[styles.sectionTitle, type.h3, { color: c.text, marginTop: 24 }]}>
              Detected Responders & Peers ({nearbyDevices.length})
            </Text>
          </View>
        }
        ListEmptyComponent={
          <View style={styles.empty}>
            <Text style={styles.emptyIcon}>🔍</Text>
            <Text style={[styles.emptyText, type.body, { color: c.textMuted }]}>
              Scanning for nearby SignalRescue devices...
            </Text>
          </View>
        }
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  listContent: {
    padding: 16,
    paddingBottom: 32,
  },
  header: {
    marginBottom: 8,
  },
  heading: {
    marginBottom: 4,
  },
  subheading: {
    marginBottom: 16,
    lineHeight: 18,
  },
  stateCard: {
    gap: 10,
    marginBottom: 20,
  },
  stateRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  stateLabel: {
    fontSize: 14,
  },
  badge: {
    paddingHorizontal: 8,
    paddingVertical: 4,
  },
  badgeText: {
    fontWeight: '700',
  },
  sectionTitle: {
    marginBottom: 10,
  },
  modesRow: {
    flexDirection: 'row',
    gap: 8,
  },
  modeChip: {
    flex: 1,
    padding: 10,
    borderWidth: 1,
  },
  modeLabel: {
    marginBottom: 4,
  },
  modeDesc: {
    fontSize: 10,
    lineHeight: 12,
  },
  empty: {
    alignItems: 'center',
    padding: 32,
  },
  emptyIcon: {
    fontSize: 32,
    marginBottom: 8,
  },
  emptyText: {
    textAlign: 'center',
  },
});

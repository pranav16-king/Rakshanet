import React from 'react';
import { View, Text, StyleSheet, Pressable } from 'react-native';
import { useTheme } from '@/theme';
import { NearbyDevice } from '@/types/device';

interface Props {
  device: NearbyDevice;
  onPress?: () => void;
}

export function DeviceCard({ device, onPress }: Props) {
  const { c, type, radius } = useTheme();

  let proximityText = 'About 15m away';
  if (device.proximityBand === 'IMMEDIATE') {
    proximityText = 'Very close (< 5m)';
  } else if (device.proximityBand === 'FAR') {
    proximityText = 'Distant (25m - 50m)';
  }

  return (
    <Pressable
      onPress={onPress}
      style={({ pressed }) => [
        styles.card,
        {
          borderRadius: radius.md,
          backgroundColor: c.surface,
          borderColor: c.border,
          transform: [{ scale: pressed ? 0.98 : 1 }],
        },
      ]}
    >
      <View style={styles.header}>
        <View style={styles.titleRow}>
          <View style={[styles.statusDot, { backgroundColor: device.isConnected ? c.info : c.textMuted }]} />
          <Text style={[styles.name, type.h3, { color: c.text }]}>
            {device.displayName}
          </Text>
        </View>
        <Text style={[styles.id, type.mono, { color: c.textMuted }]}>
          {device.deviceId}
        </Text>
      </View>

      <View style={styles.metaRow}>
        <View style={[styles.badge, { backgroundColor: c.infoSoft, borderRadius: radius.xs }]}>
          <Text style={[styles.badgeText, type.micro, { color: c.info }]}>
            {device.connectionType} • {device.hopCount === 1 ? 'Direct Peer' : `${device.hopCount} Hops`}
          </Text>
        </View>

        <Text style={[styles.proximity, type.caption, { color: c.textMuted }]}>
          {proximityText}
        </Text>

        {device.batteryLevel !== undefined && (
          <Text style={[styles.battery, type.micro, { color: c.text }]}>
            ⚡ {device.batteryLevel}%
          </Text>
        )}
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  card: {
    padding: 14,
    marginVertical: 6,
    borderWidth: 1,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  titleRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  statusDot: {
    width: 10,
    height: 10,
    borderRadius: 5,
    marginRight: 8,
  },
  name: {
    fontSize: 16,
  },
  id: {
    fontSize: 12,
  },
  metaRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  badge: {
    paddingHorizontal: 8,
    paddingVertical: 3,
  },
  badgeText: {
    fontSize: 11,
    fontWeight: '700',
  },
  proximity: {
    fontSize: 12,
  },
  battery: {
    fontSize: 12,
  },
});

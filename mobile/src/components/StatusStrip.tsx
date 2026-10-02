import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { useTheme } from '@/theme';
import { useNetworkStore } from '@/store/networkStore';

export function StatusStrip() {
  const { c, type, radius } = useTheme();
  const { meshState, internetOnline, gpsFix, batteryLevel, connectedPeerCount } = useNetworkStore();

  const isMeshOk = meshState === 'CONNECTED';
  const meshColor = isMeshOk ? c.info : c.warning;
  const meshLabel = isMeshOk ? `Mesh: ${connectedPeerCount} nearby` : 'Mesh: Searching';

  const netColor = internetOnline ? c.success : c.textMuted;
  const netLabel = internetOnline ? 'Net: Online' : 'Net: Offline';

  const gpsColor = gpsFix === 'GOOD' ? c.success : c.warning;
  const gpsLabel = gpsFix === 'GOOD' ? 'GPS: OK' : 'GPS: Last Fix';

  return (
    <View style={[styles.container, { backgroundColor: c.surfaceSunken, borderBottomColor: c.border }]}>
      {/* Mesh pill */}
      <View style={[styles.pill, { backgroundColor: c.surface, borderRadius: radius.pill }]}>
        <View style={[styles.dot, { backgroundColor: meshColor }]} />
        <Text style={[styles.pillText, type.micro, { color: c.text }]}>{meshLabel}</Text>
      </View>

      {/* Internet pill */}
      <View style={[styles.pill, { backgroundColor: c.surface, borderRadius: radius.pill }]}>
        <View style={[styles.dot, { backgroundColor: netColor }]} />
        <Text style={[styles.pillText, type.micro, { color: c.textMuted }]}>{netLabel}</Text>
      </View>

      {/* GPS pill */}
      <View style={[styles.pill, { backgroundColor: c.surface, borderRadius: radius.pill }]}>
        <View style={[styles.dot, { backgroundColor: gpsColor }]} />
        <Text style={[styles.pillText, type.micro, { color: c.text }]}>{gpsLabel}</Text>
      </View>

      {/* Battery pill */}
      <View style={[styles.pill, { backgroundColor: c.surface, borderRadius: radius.pill }]}>
        <Text style={[styles.pillText, type.micro, { color: batteryLevel < 20 ? c.sos : c.text }]}>
          ⚡ {batteryLevel}%
        </Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    height: 40,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 12,
    borderBottomWidth: 1,
  },
  pill: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 8,
    paddingVertical: 4,
  },
  dot: {
    width: 6,
    height: 6,
    borderRadius: 3,
    marginRight: 4,
  },
  pillText: {
    fontSize: 11,
  },
});

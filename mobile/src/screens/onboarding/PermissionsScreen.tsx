import React, { useState } from 'react';
import { View, Text, StyleSheet, Alert } from 'react-native';
import { useTheme } from '@/theme';
import { PrimaryButton } from '@/components/PrimaryButton';
import { permissionService } from '@/services/permissions/permissionService';

interface Props {
  navigation: any;
}

export function PermissionsScreen({ navigation }: Props) {
  const { c, type, radius } = useTheme();
  const [granted, setGranted] = useState(false);
  const [loading, setLoading] = useState(false);

  const handleRequest = async () => {
    setLoading(true);
    const result = await permissionService.requestNearbyDevicesPermission();
    setLoading(false);
    if (result.granted) {
      setGranted(true);
    } else {
      Alert.alert(
        'Permission Needed',
        'SignalRescue needs nearby device access to discover other phones when the internet is dead. You can also grant this later in Android Settings.',
        [{ text: 'Continue Anyway', onPress: () => navigation.navigate('ProfileSetup') }]
      );
    }
  };

  return (
    <View style={[styles.container, { backgroundColor: c.bg }]}>
      <View style={styles.content}>
        <View style={[styles.iconContainer, { backgroundColor: c.infoSoft, borderRadius: radius.round }]}>
          <Text style={styles.icon}>📶</Text>
        </View>

        <Text style={[styles.title, type.h1, { color: c.text }]}>
          Enable Nearby Devices
        </Text>

        <Text style={[styles.description, type.body, { color: c.textMuted }]}>
          To create a temporary mesh network with surrounding phones during a disaster, SignalRescue requires permission to search for and connect to nearby Bluetooth devices.
        </Text>

        <View style={[styles.permissionCard, { backgroundColor: c.surface, borderRadius: radius.md, borderColor: c.border }]}>
          <Text style={[styles.permissionTitle, type.h3, { color: c.text }]}>
            Nearby Device Communication
          </Text>
          <Text style={[styles.permissionText, type.caption, { color: c.textMuted }]}>
            Used strictly for peer-to-peer message transmission. We never share your physical location, contacts, or hardware serial numbers.
          </Text>
          {granted && (
            <View style={[styles.grantedBadge, { backgroundColor: c.successSoft, borderRadius: radius.xs }]}>
              <Text style={[styles.grantedText, type.micro, { color: c.success }]}>
                ✓ NEARBY DEVICES ENABLED
              </Text>
            </View>
          )}
        </View>
      </View>

      <View style={styles.footer}>
        {!granted ? (
          <PrimaryButton
            label={loading ? 'Requesting...' : 'Allow Nearby Devices'}
            onPress={handleRequest}
            disabled={loading}
          />
        ) : (
          <PrimaryButton
            label="Continue"
            onPress={() => navigation.navigate('ProfileSetup')}
          />
        )}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 24,
    justifyContent: 'space-between',
  },
  content: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  iconContainer: {
    width: 80,
    height: 80,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 20,
  },
  icon: {
    fontSize: 38,
  },
  title: {
    textAlign: 'center',
    marginBottom: 12,
  },
  description: {
    textAlign: 'center',
    marginBottom: 24,
    lineHeight: 22,
  },
  permissionCard: {
    width: '100%',
    padding: 16,
    borderWidth: 1,
  },
  permissionTitle: {
    marginBottom: 6,
  },
  permissionText: {
    lineHeight: 20,
  },
  grantedBadge: {
    marginTop: 12,
    paddingHorizontal: 10,
    paddingVertical: 4,
    alignSelf: 'flex-start',
  },
  grantedText: {
    fontWeight: '700',
  },
  footer: {
    paddingBottom: 16,
  },
});

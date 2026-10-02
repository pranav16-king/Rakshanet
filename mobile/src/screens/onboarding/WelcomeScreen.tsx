import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { useTheme } from '@/theme';
import { PrimaryButton } from '@/components/PrimaryButton';

interface Props {
  navigation: any;
}

export function WelcomeScreen({ navigation }: Props) {
  const { c, type, radius } = useTheme();

  return (
    <View style={[styles.container, { backgroundColor: c.bg }]}>
      <View style={styles.content}>
        <View style={[styles.iconContainer, { backgroundColor: c.primarySoft, borderRadius: radius.round }]}>
          <Text style={styles.icon}>📡</Text>
        </View>

        <Text style={[styles.title, type.h1, { color: c.text }]}>
          Connect Without Cell Towers or Internet
        </Text>

        <Text style={[styles.description, type.body, { color: c.textMuted }]}>
          SignalRescue turns nearby phones into an autonomous emergency network. Even when cellular backhauls are completely destroyed, your phone relays distress messages hop-by-hop.
        </Text>

        <View style={[styles.featureList, { backgroundColor: c.surface, borderRadius: radius.md, borderColor: c.border }]}>
          <View style={styles.featureRow}>
            <Text style={styles.featureBullet}>●</Text>
            <Text style={[styles.featureText, type.caption, { color: c.text }]}>
              Works 100% offline via local Bluetooth & Wi-Fi
            </Text>
          </View>
          <View style={styles.featureRow}>
            <Text style={styles.featureBullet}>●</Text>
            <Text style={[styles.featureText, type.caption, { color: c.text }]}>
              Messages are saved locally on this device first
            </Text>
          </View>
          <View style={styles.featureRow}>
            <Text style={styles.featureBullet}>●</Text>
            <Text style={[styles.featureText, type.caption, { color: c.text }]}>
              Zero tracking — your hardware identity is never shared
            </Text>
          </View>
        </View>
      </View>

      <View style={styles.footer}>
        <PrimaryButton
          label="Get Started"
          onPress={() => navigation.navigate('Permissions')}
        />
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
    marginBottom: 24,
  },
  icon: {
    fontSize: 40,
  },
  title: {
    textAlign: 'center',
    marginBottom: 16,
  },
  description: {
    textAlign: 'center',
    marginBottom: 28,
    lineHeight: 22,
  },
  featureList: {
    width: '100%',
    padding: 16,
    borderWidth: 1,
    gap: 12,
  },
  featureRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  featureBullet: {
    color: '#FFC400',
    fontSize: 12,
    marginRight: 10,
  },
  featureText: {
    flex: 1,
    fontSize: 14,
  },
  footer: {
    paddingBottom: 16,
  },
});

import React, { useEffect } from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { useTheme } from '@/theme';
import { useProfileStore } from '@/store/profileStore';

interface Props {
  navigation: any;
}

export function SplashScreen({ navigation }: Props) {
  const { c, type, radius } = useTheme();
  const { loadProfile, isOnboarded } = useProfileStore();

  useEffect(() => {
    async function checkBootstrap() {
      await loadProfile();
      setTimeout(() => {
        if (useProfileStore.getState().isOnboarded) {
          navigation.replace('MainTabs');
        } else {
          navigation.replace('Welcome');
        }
      }, 1200);
    }
    checkBootstrap();
  }, [navigation, loadProfile]);

  return (
    <View style={[styles.container, { backgroundColor: c.bg }]}>
      <View style={[styles.badge, { backgroundColor: c.primarySoft, borderRadius: radius.pill }]}>
        <Text style={[styles.badgeText, type.micro, { color: c.primaryInk }]}>
          OFFLINE EMERGENCY MESH
        </Text>
      </View>
      <Text style={[styles.title, type.display, { color: c.text }]}>
        SIGNALRESCUE
      </Text>
      <Text style={[styles.subtitle, type.body, { color: c.textMuted }]}>
        Life-saving communication when all networks fail.
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 24,
  },
  badge: {
    paddingHorizontal: 14,
    paddingVertical: 6,
    marginBottom: 16,
  },
  badgeText: {
    letterSpacing: 1,
  },
  title: {
    textAlign: 'center',
    marginBottom: 8,
  },
  subtitle: {
    textAlign: 'center',
    maxWidth: 280,
  },
});

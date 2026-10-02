import React from 'react';
import { View, Text, StyleSheet, Pressable, ScrollView } from 'react-native';
import { useTheme, ThemeMode } from '@/theme';
import { StatusStrip } from '@/components/StatusStrip';
import { Card } from '@/components/Card';
import { useSettingsStore } from '@/store/settingsStore';
import { useProfileStore } from '@/store/profileStore';

export function SettingsScreen() {
  const { c, type, radius } = useTheme();
  const { themeMode, setThemeMode } = useSettingsStore();
  const { profile, identity } = useProfileStore();

  const themes: { key: ThemeMode; label: string; desc: string }[] = [
    { key: 'dark', label: 'Dark Mode', desc: 'Night navy palette, yellow hero' },
    { key: 'lowPower', label: 'Low Power OLED', desc: 'True #000000 black, max battery' },
    { key: 'light', label: 'Light Mode', desc: 'Warm hi-vis yellow tint' },
  ];

  return (
    <View style={[styles.container, { backgroundColor: c.bg }]}>
      <StatusStrip />

      <ScrollView contentContainerStyle={styles.scrollContent}>
        <Text style={[styles.heading, type.h1, { color: c.text }]}>
          Settings & Power
        </Text>
        <Text style={[styles.subheading, type.caption, { color: c.textMuted }]}>
          Configure power preservation and local mesh telemetry.
        </Text>

        {/* Theme / OLED Power Card */}
        <Card>
          <Text style={[styles.cardTitle, type.h3, { color: c.text }]}>
            Display & Battery Profile
          </Text>
          <View style={styles.themeGroup}>
            {themes.map((t) => (
              <Pressable
                key={t.key}
                onPress={() => setThemeMode(t.key)}
                style={[
                  styles.themeRow,
                  {
                    backgroundColor: themeMode === t.key ? c.primarySoft : c.surfaceSunken,
                    borderColor: themeMode === t.key ? c.primaryInk : c.border,
                    borderRadius: radius.sm,
                  },
                ]}
              >
                <View>
                  <Text
                    style={[
                      styles.themeLabel,
                      type.body,
                      { color: themeMode === t.key ? c.primaryInk : c.text, fontWeight: '700' },
                    ]}
                  >
                    {t.label}
                  </Text>
                  <Text style={[styles.themeDesc, type.micro, { color: c.textMuted }]}>
                    {t.desc}
                  </Text>
                </View>
                {themeMode === t.key && (
                  <Text style={[styles.check, type.h3, { color: c.primaryInk }]}>
                    ✓
                  </Text>
                )}
              </Pressable>
            ))}
          </View>
        </Card>

        {/* Identity & Security Card */}
        <Card>
          <Text style={[styles.cardTitle, type.h3, { color: c.text }]}>
            Anonymous Hardware Identity
          </Text>
          <View style={styles.infoRow}>
            <Text style={[styles.infoLabel, type.caption, { color: c.textMuted }]}>
              Local Device ID
            </Text>
            <Text style={[styles.infoValue, type.mono, { color: c.text }]}>
              {identity?.deviceId || 'SR-UNASSIGNED'}
            </Text>
          </View>
          <View style={styles.infoRow}>
            <Text style={[styles.infoLabel, type.caption, { color: c.textMuted }]}>
              Registered Operator
            </Text>
            <Text style={[styles.infoValue, type.body, { color: c.text }]}>
              {profile?.name || 'Local User'}
            </Text>
          </View>
          <View style={styles.infoRow}>
            <Text style={[styles.infoLabel, type.caption, { color: c.textMuted }]}>
              Preferred Language
            </Text>
            <Text style={[styles.infoValue, type.body, { color: c.text }]}>
              {profile?.preferredLanguage || 'English'}
            </Text>
          </View>
        </Card>

        {/* Local SQLite Database Info */}
        <Card>
          <Text style={[styles.cardTitle, type.h3, { color: c.text }]}>
            Local SQLite Persistence
          </Text>
          <Text style={[styles.dbText, type.caption, { color: c.textMuted }]}>
            Status: Active (Source of Truth)
            {'\n'}Schema: Version 1 (7 Relational Tables)
            {'\n'}Storage: 100% on-device local storage. Zero cloud telemetry.
          </Text>
        </Card>
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
    gap: 16,
  },
  heading: {
    marginBottom: 4,
  },
  subheading: {
    marginBottom: 8,
    lineHeight: 18,
  },
  cardTitle: {
    marginBottom: 12,
  },
  themeGroup: {
    gap: 8,
  },
  themeRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 12,
    borderWidth: 1,
  },
  themeLabel: {
    marginBottom: 2,
  },
  themeDesc: {
    fontSize: 11,
  },
  check: {
    fontSize: 16,
  },
  infoRow: {
    paddingVertical: 6,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: 'rgba(255,255,255,0.1)',
  },
  infoLabel: {
    marginBottom: 2,
  },
  infoValue: {
    fontWeight: '600',
  },
  dbText: {
    lineHeight: 20,
  },
});

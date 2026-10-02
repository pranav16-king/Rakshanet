import React, { useState } from 'react';
import { View, Text, TextInput, StyleSheet, Alert } from 'react-native';
import { useTheme } from '@/theme';
import { PrimaryButton } from '@/components/PrimaryButton';
import { useProfileStore } from '@/store/profileStore';
import { bluetoothService } from '@/services/bluetooth/bluetoothService';
import { meshService } from '@/services/mesh/meshService';

interface Props {
  navigation: any;
}

export function ProfileSetupScreen({ navigation }: Props) {
  const { c, type, radius, size } = useTheme();
  const [name, setName] = useState('');
  const [language, setLanguage] = useState('English');
  const [saving, setSaving] = useState(false);
  const { saveProfile } = useProfileStore();

  const handleSave = async () => {
    if (!name.trim()) {
      Alert.alert('Name Required', 'Please enter a name so nearby responders can recognize your messages.');
      return;
    }

    setSaving(true);
    try {
      await saveProfile(name.trim(), language);
      const identity = useProfileStore.getState().identity;

      if (identity) {
        // Initialize background mesh network & radio
        meshService.initialize(identity.deviceId);
        await bluetoothService.startMesh(identity.deviceId, name.trim());
      }

      navigation.replace('MainTabs');
    } catch (err) {
      console.warn('[ProfileSetup] Error saving profile', err);
      Alert.alert('Error', 'Failed to save profile to local database.');
    } finally {
      setSaving(false);
    }
  };

  return (
    <View style={[styles.container, { backgroundColor: c.bg }]}>
      <View style={styles.content}>
        <Text style={[styles.title, type.h1, { color: c.text }]}>
          Emergency Profile
        </Text>
        <Text style={[styles.subtitle, type.body, { color: c.textMuted }]}>
          Keep this minimal. Only your name will be visible to nearby responders. Medical notes can be added later.
        </Text>

        <View style={styles.fieldGroup}>
          <Text style={[styles.label, type.caption, { color: c.text }]}>
            Your Name or Nickname *
          </Text>
          <TextInput
            placeholder="e.g. Rahul / Ananya"
            placeholderTextColor={c.textDisabled}
            value={name}
            onChangeText={setName}
            style={[
              styles.input,
              type.body,
              {
                minHeight: size.input,
                borderRadius: radius.sm,
                backgroundColor: c.surfaceSunken,
                borderColor: c.border,
                color: c.text,
              },
            ]}
          />
        </View>

        <View style={styles.fieldGroup}>
          <Text style={[styles.label, type.caption, { color: c.text }]}>
            Preferred Language
          </Text>
          <View style={[styles.langRow, { gap: 8 }]}>
            {['English', 'Hindi', 'Nepali'].map((lang) => (
              <View
                key={lang}
                onTouchEnd={() => setLanguage(lang)}
                style={[
                  styles.chip,
                  {
                    borderRadius: radius.pill,
                    backgroundColor: language === lang ? c.primarySoft : c.surface,
                    borderColor: language === lang ? c.primaryInk : c.border,
                  },
                ]}
              >
                <Text
                  style={[
                    styles.chipText,
                    type.caption,
                    { color: language === lang ? c.primaryInk : c.textMuted },
                  ]}
                >
                  {lang}
                </Text>
              </View>
            ))}
          </View>
        </View>

        <View style={[styles.noteBox, { backgroundColor: c.surface, borderRadius: radius.md, borderColor: c.border }]}>
          <Text style={[styles.noteText, type.caption, { color: c.textMuted }]}>
            🔒 All profile and chat data is stored locally in your phone's SQLite database. Nothing is sent to cloud servers unless an internet connection becomes available.
          </Text>
        </View>
      </View>

      <View style={styles.footer}>
        <PrimaryButton
          label={saving ? 'Initializing...' : 'Save & Enter Offline Mesh'}
          onPress={handleSave}
          disabled={saving}
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
    paddingTop: 32,
  },
  title: {
    marginBottom: 8,
  },
  subtitle: {
    marginBottom: 28,
    lineHeight: 22,
  },
  fieldGroup: {
    marginBottom: 20,
  },
  label: {
    marginBottom: 8,
    fontWeight: '700',
  },
  input: {
    paddingHorizontal: 16,
    borderWidth: 1,
  },
  langRow: {
    flexDirection: 'row',
  },
  chip: {
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderWidth: 1,
  },
  chipText: {
    fontWeight: '600',
  },
  noteBox: {
    marginTop: 16,
    padding: 14,
    borderWidth: 1,
  },
  noteText: {
    lineHeight: 20,
  },
  footer: {
    paddingBottom: 16,
  },
});

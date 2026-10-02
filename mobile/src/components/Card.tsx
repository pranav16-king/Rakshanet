import React from 'react';
import { View, StyleSheet, ViewStyle } from 'react-native';
import { useTheme } from '@/theme';

interface Props {
  children: React.ReactNode;
  style?: ViewStyle;
}

export function Card({ children, style }: Props) {
  const { c, radius } = useTheme();

  return (
    <View
      style={[
        styles.card,
        {
          borderRadius: radius.md,
          backgroundColor: c.surface,
          borderColor: c.border,
        },
        style,
      ]}
    >
      {children}
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    padding: 16,
    borderWidth: 1,
    marginVertical: 6,
  },
});

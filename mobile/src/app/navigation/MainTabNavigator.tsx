import React from 'react';
import { Text, StyleSheet } from 'react-native';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { useTheme } from '@/theme';
import { HomeScreen } from '@/screens/home/HomeScreen';
import { ChatListScreen } from '@/screens/chat/ChatListScreen';
import { NetworkScreen } from '@/screens/network/NetworkScreen';
import { SettingsScreen } from '@/screens/settings/SettingsScreen';

const Tab = createBottomTabNavigator();

export function MainTabNavigator() {
  const { c, size, type } = useTheme();

  return (
    <Tab.Navigator
      screenOptions={{
        headerShown: false,
        tabBarStyle: {
          height: size.tabBar,
          backgroundColor: c.surface,
          borderTopColor: c.border,
          paddingBottom: 8,
          paddingTop: 8,
        },
        tabBarActiveTintColor: c.primary,
        tabBarInactiveTintColor: c.textMuted,
        tabBarLabelStyle: {
          fontSize: 12,
          fontWeight: '600',
        },
      }}
    >
      <Tab.Screen
        name="HomeTab"
        component={HomeScreen}
        options={{
          tabBarLabel: 'Home',
          tabBarIcon: ({ color }) => <Text style={{ fontSize: 20 }}>🏠</Text>,
        }}
      />
      <Tab.Screen
        name="ChatTab"
        component={ChatListScreen}
        options={{
          tabBarLabel: 'Chat',
          tabBarIcon: ({ color }) => <Text style={{ fontSize: 20 }}>💬</Text>,
        }}
      />
      <Tab.Screen
        name="NetworkTab"
        component={NetworkScreen}
        options={{
          tabBarLabel: 'Network',
          tabBarIcon: ({ color }) => <Text style={{ fontSize: 20 }}>📡</Text>,
        }}
      />
      <Tab.Screen
        name="SettingsTab"
        component={SettingsScreen}
        options={{
          tabBarLabel: 'Settings',
          tabBarIcon: ({ color }) => <Text style={{ fontSize: 20 }}>⚙️</Text>,
        }}
      />
    </Tab.Navigator>
  );
}

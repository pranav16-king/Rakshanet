import React, { useEffect } from 'react';
import { StatusBar } from 'react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { NavigationContainer } from '@react-navigation/native';
import { RootNavigator } from '@/app/navigation/RootNavigator';
import { dbManager } from '@/database/sqlite';
import { useTheme } from '@/theme';

export default function App() {
  const { c, themeMode } = useTheme();

  useEffect(() => {
    // Initialize durable SQLite schemas upon application launch
    dbManager.initialize().catch((err) => {
      console.warn('[App] SQLite initialization error', err);
    });
  }, []);

  return (
    <SafeAreaProvider>
      <StatusBar
        barStyle={themeMode === 'light' ? 'dark-content' : 'light-content'}
        backgroundColor={c.bg}
      />
      <NavigationContainer>
        <RootNavigator />
      </NavigationContainer>
    </SafeAreaProvider>
  );
}

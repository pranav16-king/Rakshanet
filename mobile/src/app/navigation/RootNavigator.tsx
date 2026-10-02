import React from 'react';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { SplashScreen } from '@/screens/onboarding/SplashScreen';
import { WelcomeScreen } from '@/screens/onboarding/WelcomeScreen';
import { PermissionsScreen } from '@/screens/onboarding/PermissionsScreen';
import { ProfileSetupScreen } from '@/screens/onboarding/ProfileSetupScreen';
import { MainTabNavigator } from './MainTabNavigator';
import { ChatScreen } from '@/screens/chat/ChatScreen';

const Stack = createNativeStackNavigator();

export function RootNavigator() {
  return (
    <Stack.Navigator
      initialRouteName="Splash"
      screenOptions={{
        headerShown: false,
        animation: 'fade',
      }}
    >
      {/* Onboarding Stack */}
      <Stack.Screen name="Splash" component={SplashScreen} />
      <Stack.Screen name="Welcome" component={WelcomeScreen} />
      <Stack.Screen name="Permissions" component={PermissionsScreen} />
      <Stack.Screen name="ProfileSetup" component={ProfileSetupScreen} />

      {/* Main Core Application */}
      <Stack.Screen name="MainTabs" component={MainTabNavigator} />
      <Stack.Screen
        name="ChatDetail"
        component={ChatScreen}
        options={{
          animation: 'slide_from_right',
        }}
      />
    </Stack.Navigator>
  );
}

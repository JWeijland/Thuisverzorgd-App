import {
  Baloo2_600SemiBold,
  Baloo2_700Bold,
  Baloo2_800ExtraBold,
} from '@expo-google-fonts/baloo-2';
import { Caveat_500Medium, Caveat_600SemiBold } from '@expo-google-fonts/caveat';
import {
  ComicNeue_400Regular,
  ComicNeue_400Regular_Italic,
  ComicNeue_700Bold,
} from '@expo-google-fonts/comic-neue';
import { QueryClientProvider } from '@tanstack/react-query';
import { useFonts } from 'expo-font';
import { Stack } from 'expo-router';
import * as SplashScreen from 'expo-splash-screen';
import { StatusBar } from 'expo-status-bar';
import { useEffect } from 'react';

import { NotificationGateway } from '@/features/notifications/NotificationGateway';
import { AppRondleiding } from '@/features/onboarding/AppRondleiding';
import { AuthProvider } from '@/features/onboarding/useAuth';
import { TaskBanner } from '@/features/tasks/TaskBanner';
import { queryClient } from '@/lib/queryClient';
import { TextScaleProvider } from '@/theme';
import { ErrorBoundary } from '@/ui/ErrorBoundary';

SplashScreen.preventAutoHideAsync();

/** De pagina's die je met de schuifjes bereikt (zie features/navigatie/paden.ts). */
const PAD_ROUTES = [
  'weten/wegwijzer',
  'weten/forum',
  'weten/zorgmakelaars',
  'regelen/voorzieningen',
  'regelen/planning',
  'regelen/kring',
  'vrijwilliger/buurt',
  'vrijwilliger/taken',
  'vrijwilliger/steun',
] as const;

export default function RootLayout() {
  const [fontsLoaded] = useFonts({
    Baloo2_600SemiBold,
    Baloo2_700Bold,
    Baloo2_800ExtraBold,
    ComicNeue_400Regular,
    ComicNeue_400Regular_Italic,
    ComicNeue_700Bold,
    Caveat_500Medium,
    Caveat_600SemiBold,
  });

  useEffect(() => {
    if (fontsLoaded) {
      SplashScreen.hideAsync();
    }
  }, [fontsLoaded]);

  if (!fontsLoaded) {
    return null;
  }

  return (
    <ErrorBoundary>
      <QueryClientProvider client={queryClient}>
        <AuthProvider>
          <TextScaleProvider>
            <StatusBar style="light" />
            <NotificationGateway />
            <Stack screenOptions={{ headerShown: false }}>
              {/* De schuifjes van een pad wisselen met `replace`. De eigen
                  overgang zit in PadPagina; de systeemovergang staat daarom
                  uit, anders schuift het scherm twee kanten tegelijk op. */}
              {PAD_ROUTES.map((naam) => (
                <Stack.Screen key={naam} name={naam} options={{ animation: 'none' }} />
              ))}
            </Stack>
            {/* Stonden vroeger in de tabbalk-layout; die bestaat niet meer,
                dus ze hangen nu boven de hele app. */}
            <TaskBanner />
            <AppRondleiding />
          </TextScaleProvider>
        </AuthProvider>
      </QueryClientProvider>
    </ErrorBoundary>
  );
}

import * as Notifications from 'expo-notifications';
import * as Device from 'expo-device';
import Constants from 'expo-constants';
import { Platform } from 'react-native';

import type { Task } from '@/features/tasks/api';
import { taskLabel } from '@/features/tasks/logic';
import { parseDateString } from '@/lib/dates';
import { supabase } from '@/lib/supabase';

/** tvz://rooster → /rooster (voor navigatie vanuit een melding). */
/**
 * De routes zijn met de herstructurering verhuisd (geen tabbalk meer), maar
 * meldingen die al verstuurd zijn en de edge functions gebruiken nog de oude
 * namen. Die vertalen we hier, zodat oude pushberichten blijven werken.
 */
const OUDE_ROUTES: Record<string, string> = {
  rooster: '/regelen/planning',
  steun: '/weten/wegwijzer',
  kring: '/regelen/kring',
  voorzien: '/regelen/voorzieningen',
  forum: '/weten/forum',
  hulpmakelaar: '/regelen/makelaar',
  'wegwijzer-lijst': '/weten/wegwijzer',
};

export function deeplinkToPath(deeplink: string | null | undefined): string {
  if (!deeplink) return '/inbox';
  const path = deeplink.replace(/^tvz:\/\//, '').replace(/^\/+/, '');
  return OUDE_ROUTES[path] ?? `/${path}`;
}

Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowBanner: true,
    shouldShowList: true,
    shouldPlaySound: false,
    shouldSetBadge: false,
  }),
});

/** Registreert het Expo-pushtoken voor deze gebruiker (device_tokens-tabel). */
export async function registerPushToken(profileId: string): Promise<void> {
  try {
    if (!Device.isDevice) return;
    const { status } = await Notifications.getPermissionsAsync();
    let granted = status === 'granted';
    if (!granted) {
      const request = await Notifications.requestPermissionsAsync();
      granted = request.status === 'granted';
    }
    if (!granted) return;

    if (Platform.OS === 'android') {
      await Notifications.setNotificationChannelAsync('default', {
        name: 'Meldingen',
        importance: Notifications.AndroidImportance.DEFAULT,
      });
    }

    const projectId = Constants.expoConfig?.extra?.eas?.projectId as string | undefined;
    const token = (await Notifications.getExpoPushTokenAsync({ projectId })).data;
    await supabase.from('device_tokens').upsert({
      token,
      profile_id: profileId,
      platform: Platform.OS,
      updated_at: new Date().toISOString(),
    });
  } catch {
    // push is nice-to-have; nooit de app blokkeren
  }
}

/** Token opruimen bij uitloggen (privacy-eis uit de superprompt). */
export async function removePushToken(): Promise<void> {
  try {
    if (!Device.isDevice) return;
    const projectId = Constants.expoConfig?.extra?.eas?.projectId as string | undefined;
    const token = (await Notifications.getExpoPushTokenAsync({ projectId })).data;
    await supabase.from('device_tokens').delete().eq('token', token);
  } catch {
    // stil falen is prima
  }
}

/** Lokale herinnering 1 uur vóór een aangenomen taak. */
export async function scheduleTaskReminder(task: Task): Promise<void> {
  try {
    const date = parseDateString(task.date);
    const [hours, minutes] = task.time.split(':').map(Number);
    date.setHours(hours ?? 0, minutes ?? 0, 0, 0);
    const remindAt = new Date(date.getTime() - 60 * 60 * 1000);
    if (remindAt <= new Date()) return;
    await Notifications.scheduleNotificationAsync({
      identifier: `taak-${task.id}`,
      content: {
        title: 'Over een uur',
        body: `${taskLabel(task)} · ${task.time.slice(0, 5)}`,
        data: { deeplink: 'tvz://rooster' },
      },
      trigger: { type: Notifications.SchedulableTriggerInputTypes.DATE, date: remindAt },
    });
  } catch {
    // herinnering is nice-to-have
  }
}

export async function cancelTaskReminder(taskId: string): Promise<void> {
  await Notifications.cancelScheduledNotificationAsync(`taak-${taskId}`).catch(() => {});
}

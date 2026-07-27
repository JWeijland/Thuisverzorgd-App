import * as Notifications from 'expo-notifications';
import { router } from 'expo-router';
import { useEffect, useRef } from 'react';

import { useSession } from '@/features/onboarding/useAuth';
import { deeplinkToPath, registerPushToken } from '@/features/notifications/push';

/**
 * Verbindt push met de app:
 * - registreert het device token zodra er een sessie is
 * - navigeert naar het deeplink-doel bij het aantikken van een melding,
 *   óók vanuit koude start (getLastNotificationResponseAsync)
 */
export function NotificationGateway() {
  const { session } = useSession();
  const handledColdStart = useRef(false);

  useEffect(() => {
    if (session) {
      registerPushToken(session.user.id);
    }
  }, [session]);

  useEffect(() => {
    const subscription = Notifications.addNotificationResponseReceivedListener((response) => {
      const deeplink = response.notification.request.content.data?.deeplink as string | undefined;
      router.navigate(deeplinkToPath(deeplink) as never);
    });

    if (!handledColdStart.current) {
      handledColdStart.current = true;
      Notifications.getLastNotificationResponseAsync().then((response) => {
        if (response) {
          const deeplink = response.notification.request.content.data?.deeplink as
            string | undefined;
          router.navigate(deeplinkToPath(deeplink) as never);
        }
      });
    }

    return () => subscription.remove();
  }, []);

  return null;
}

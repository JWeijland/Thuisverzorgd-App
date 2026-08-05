import { removePushToken } from '@/features/notifications/push';
import { supabase } from '@/lib/supabase';

/**
 * Uitloggen dat áltijd slaagt. `signOut()` praat eerst met de server en liet
 * je vroeger ingelogd staan als dat misging (geen bereik, sessie al verlopen);
 * daarom valt deze helper terug op lokaal uitloggen, zodat je nooit vast
 * blijft zitten. Het pushtoken opruimen is best effort met een korte
 * tijdslimiet en mag het uitloggen nooit blokkeren.
 */
export async function logUit(): Promise<void> {
  await Promise.race([
    removePushToken().catch(() => {}),
    new Promise((resolve) => setTimeout(resolve, 2500)),
  ]);
  const { error } = await supabase.auth
    .signOut()
    .catch((err: unknown) => ({ error: err as Error }));
  if (error) {
    await supabase.auth.signOut({ scope: 'local' }).catch(() => {});
  }
}

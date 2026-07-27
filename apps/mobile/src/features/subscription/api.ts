import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import { useSession } from '@/features/onboarding/useAuth';
import { supabase } from '@/lib/supabase';

export type Subscription = {
  status: 'gratis' | 'proef' | 'actief' | 'verlopen';
  expires_at: string | null;
};

export function useSubscription() {
  const { session } = useSession();
  return useQuery({
    queryKey: ['subscription', session?.user.id],
    enabled: !!session,
    queryFn: async (): Promise<Subscription> => {
      const { data, error } = await supabase
        .from('subscriptions')
        .select('status, expires_at')
        .eq('profile_id', session!.user.id)
        .maybeSingle();
      if (error) throw error;
      return (data as Subscription) ?? { status: 'gratis', expires_at: null };
    },
  });
}

/**
 * Pilot-stub (ADR-0002): activeert de proefmaand direct, zonder betaling.
 * RevenueCat + Apple IAP vervangen dit vóór de publieke release.
 */
export function useActivateSubscription() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async () => {
      const { error } = await supabase.rpc('activate_subscription_stub');
      if (error) throw error;
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['subscription'] }),
  });
}

/** Losse profielvelden bijwerken (buddy-pool, beschikbaarheid, vakantie, agenda). */
export function useUpdateProfile() {
  const { session } = useSession();
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (patch: Record<string, unknown>) => {
      const { error } = await supabase.from('profiles').update(patch).eq('id', session!.user.id);
      if (error) throw error;
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['profile'] }),
  });
}

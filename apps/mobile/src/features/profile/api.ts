import { useMutation, useQueryClient } from '@tanstack/react-query';

import { useSession } from '@/features/onboarding/useAuth';
import { supabase } from '@/lib/supabase';

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

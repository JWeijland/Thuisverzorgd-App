import { useQuery } from '@tanstack/react-query';

import { supabase } from '@/lib/supabase';

/**
 * Signed URL voor een profielfoto uit de privé avatars-bucket (RLS bepaalt wie
 * mag kijken: jijzelf, kringgenoten en iedereen voor makelaars). Een uur geldig;
 * ruim daarbinnen verversen zodat een lopende sessie nooit een dode link toont.
 */
export function useAvatarUrl(path: string | null | undefined) {
  return useQuery({
    queryKey: ['avatar-url', path],
    enabled: !!path,
    staleTime: 45 * 60 * 1000,
    queryFn: async (): Promise<string | null> => {
      const { data, error } = await supabase.storage.from('avatars').createSignedUrl(path!, 3600);
      if (error) return null;
      return data.signedUrl;
    },
  });
}

import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import { useSession } from '@/features/onboarding/useAuth';
import { haptics } from '@/lib/haptics';
import { supabase } from '@/lib/supabase';

export type Aanbieder = {
  id: string;
  name: string;
  business: string;
  note: string;
  distance_km: number;
  avatar_path: string | null;
};

export type Dienst = {
  id: string;
  slug: string;
  name: string;
  description: string;
  price_cents: number;
  unit: 'bezoek' | 'uur';
  duration_min: number | null;
  rating: number;
  rating_count: number;
  provider: Aanbieder;
};

const DIENST_SELECT =
  'id, slug, name, description, price_cents, unit, duration_min, rating, rating_count, ' +
  'provider:providers (id, name, business, note, distance_km, avatar_path)';

/** De catalogus: alle actieve diensten, in de vaste volgorde van de handoff. */
export function useDiensten() {
  const { session } = useSession();
  return useQuery({
    queryKey: ['diensten'],
    enabled: !!session,
    queryFn: async (): Promise<Dienst[]> => {
      const { data, error } = await supabase
        .from('services')
        .select(DIENST_SELECT)
        .eq('active', true)
        .order('sort_order');
      if (error) throw error;
      return (data ?? []) as unknown as Dienst[];
    },
  });
}

/**
 * De boekbare momenten van een dienst: berekend in de database uit het
 * werkritme van de aanbieder min zijn afwezigheid en bestaande boekingen.
 */
export function useSlots(serviceId: string | undefined) {
  const { session } = useSession();
  return useQuery({
    queryKey: ['slots', serviceId],
    enabled: !!session && !!serviceId,
    queryFn: async (): Promise<string[]> => {
      const { data, error } = await supabase.rpc('beschikbare_slots', {
        p_service: serviceId!,
      });
      if (error) throw error;
      return ((data ?? []) as { slot_at: string }[]).map((rij) => rij.slot_at);
    },
  });
}

export type Boeking = {
  id: string;
  slot_at: string;
  status: 'geboekt' | 'afgerond' | 'geannuleerd';
  price_cents: number;
  service: {
    name: string;
    slug: string;
    provider: { name: string; business: string } | null;
  } | null;
};

const BOEKING_SELECT =
  'id, slot_at, status, price_cents, service:services (name, slug, provider:providers (name, business))';

/** Je eigen komende boekingen (voor het rooster). */
export function useBoekingen() {
  const { session } = useSession();
  return useQuery({
    queryKey: ['boekingen', session?.user.id],
    enabled: !!session,
    queryFn: async (): Promise<Boeking[]> => {
      const vanaf = new Date();
      vanaf.setHours(0, 0, 0, 0);
      const { data, error } = await supabase
        .from('bookings')
        .select(BOEKING_SELECT)
        .eq('status', 'geboekt')
        .gte('slot_at', vanaf.toISOString())
        .order('slot_at');
      if (error) throw error;
      return (data ?? []) as unknown as Boeking[];
    },
  });
}

/** Boeking vastleggen; de prijs en de melding regelt de server. */
export function useCreateBoeking() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (input: {
      serviceId: string;
      slotIso: string;
      method: 'apple_pay' | 'ideal';
    }): Promise<string> => {
      const { data, error } = await supabase.rpc('create_booking', {
        p_service: input.serviceId,
        p_slot: input.slotIso,
        p_method: input.method,
      });
      if (error) throw error;
      return data as string;
    },
    onSuccess: () => {
      // Het "aankoop rond"-moment: lang en bevredigend.
      void haptics.voltooid();
      queryClient.invalidateQueries({ queryKey: ['boekingen'] });
      // Het geboekte moment is nu bezet voor iedereen.
      queryClient.invalidateQueries({ queryKey: ['slots'] });
    },
    onError: () => void haptics.fout(),
  });
}

/** Annuleren; de server weigert binnen 24 uur vóór het bezoek. */
export function useCancelBoeking() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (boekingId: string) => {
      const { error } = await supabase.rpc('cancel_booking', { p_booking: boekingId });
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['boekingen'] });
      // Het moment komt weer vrij voor anderen.
      queryClient.invalidateQueries({ queryKey: ['slots'] });
    },
  });
}

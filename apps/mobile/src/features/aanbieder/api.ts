import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import type { Afwezigheid, WerkritmeDag } from '@/features/aanbieder/agenda';
import { useSession } from '@/features/onboarding/useAuth';
import { toDateString } from '@/lib/dates';
import { haptics } from '@/lib/haptics';
import { supabase } from '@/lib/supabase';

export type MijnAanbieder = {
  id: string;
  name: string;
  business: string;
  avatar_path: string | null;
};

/** De providers-rij die aan dit account hangt; null als er geen koppeling is. */
export function useMijnAanbieder() {
  const { session } = useSession();
  return useQuery({
    queryKey: ['mijn-aanbieder', session?.user.id],
    enabled: !!session,
    queryFn: async (): Promise<MijnAanbieder | null> => {
      const { data, error } = await supabase
        .from('providers')
        .select('id, name, business, avatar_path')
        .eq('profile_id', session!.user.id)
        .maybeSingle();
      if (error) throw error;
      return data as MijnAanbieder | null;
    },
  });
}

/** Het vaste weekritme (ma=1 ... zo=7); geen rij = die dag dicht. */
export function useWerkritme(providerId: string | undefined) {
  return useQuery({
    queryKey: ['werkritme', providerId],
    enabled: !!providerId,
    queryFn: async (): Promise<WerkritmeDag[]> => {
      const { data, error } = await supabase
        .from('provider_hours')
        .select('weekday, start_time, end_time')
        .eq('provider_id', providerId!)
        .order('weekday');
      if (error) throw error;
      return (data ?? []) as WerkritmeDag[];
    },
  });
}

/** Dag openzetten of tijden wijzigen (één blok per weekdag). */
export function useZetDag(providerId: string | undefined) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (input: { weekday: number; start: string; eind: string }) => {
      const { error } = await supabase.from('provider_hours').upsert(
        {
          provider_id: providerId!,
          weekday: input.weekday,
          start_time: input.start,
          end_time: input.eind,
        },
        { onConflict: 'provider_id,weekday' },
      );
      if (error) throw error;
    },
    onSuccess: () => {
      void haptics.selectie();
      queryClient.invalidateQueries({ queryKey: ['werkritme', providerId] });
    },
    onError: () => void haptics.fout(),
  });
}

/** Dag dichtzetten. */
export function useSluitDag(providerId: string | undefined) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (weekday: number) => {
      const { error } = await supabase
        .from('provider_hours')
        .delete()
        .eq('provider_id', providerId!)
        .eq('weekday', weekday);
      if (error) throw error;
    },
    onSuccess: () => {
      void haptics.selectie();
      queryClient.invalidateQueries({ queryKey: ['werkritme', providerId] });
    },
    onError: () => void haptics.fout(),
  });
}

/** Komende afwezigheidsperiodes (vandaag of later). */
export function useAfwezigheid(providerId: string | undefined) {
  return useQuery({
    queryKey: ['afwezigheid', providerId],
    enabled: !!providerId,
    queryFn: async (): Promise<Afwezigheid[]> => {
      const { data, error } = await supabase
        .from('provider_absences')
        .select('id, start_date, end_date')
        .eq('provider_id', providerId!)
        .gte('end_date', toDateString(new Date()))
        .order('start_date');
      if (error) throw error;
      return (data ?? []) as Afwezigheid[];
    },
  });
}

export function useMeldAfwezig(providerId: string | undefined) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (input: { start: string; eind: string }) => {
      const { error } = await supabase.from('provider_absences').insert({
        provider_id: providerId!,
        start_date: input.start,
        end_date: input.eind,
      });
      if (error) throw error;
    },
    onSuccess: () => {
      void haptics.selectie();
      queryClient.invalidateQueries({ queryKey: ['afwezigheid', providerId] });
    },
    onError: () => void haptics.fout(),
  });
}

export function useVerwijderAfwezig(providerId: string | undefined) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase.from('provider_absences').delete().eq('id', id);
      if (error) throw error;
    },
    onSuccess: () => {
      void haptics.selectie();
      queryClient.invalidateQueries({ queryKey: ['afwezigheid', providerId] });
    },
    onError: () => void haptics.fout(),
  });
}

export type AanbiederAfspraak = {
  id: string;
  slot_at: string;
  service_name: string;
  duration_min: number;
  klant_naam: string;
  klant_adres: string | null;
  klant_plaats: string | null;
};

/** Komende afspraken van de ingelogde aanbieder (RPC, vanaf vandaag). */
export function useAanbiederAfspraken() {
  const { session } = useSession();
  return useQuery({
    queryKey: ['aanbieder-afspraken', session?.user.id],
    enabled: !!session,
    queryFn: async (): Promise<AanbiederAfspraak[]> => {
      const { data, error } = await supabase.rpc('aanbieder_afspraken');
      if (error) {
        // Geen gekoppeld aanbiedersprofiel: toon een lege agenda met uitleg.
        if (error.message.includes('geen_aanbieder')) return [];
        throw error;
      }
      return (data ?? []) as AanbiederAfspraak[];
    },
  });
}

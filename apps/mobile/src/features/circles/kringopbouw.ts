import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import { useSession } from '@/features/onboarding/useAuth';
import { supabase } from '@/lib/supabase';

/** De zes stappen van de kringopbouw (handoff §3e). */
export const KRINGOPBOUW_STAPPEN = 6;

export type TaakSoort = 'boodschappen' | 'wandelen' | 'vervoer' | 'koken' | 'gezelschap' | 'anders';

export type KringAntwoorden = {
  /** Stap 1: voor wie regel je hulp. */
  naam?: string;
  relatie?: string;
  /** Stap 2: waar woont diegene (volledig adres uit de suggesties). */
  adres?: string;
  /** Stap 3: welke taken zijn nodig. */
  taken?: TaakSoort[];
  /** Bij "anders": in eigen woorden wat er verder nodig is. */
  andereTaken?: string;
  /** Stap 4: wat de kring verder moet weten. */
  goedOmTeWeten?: string;
};

export type KringConcept = {
  id: string;
  stap: number;
  antwoorden: KringAntwoorden;
};

/**
 * Het lopende concept van de kringopbouw. Eén record per persoon, zodat je de
 * wizard kunt onderbreken en later op dezelfde stap terugkomt.
 */
export function useKringConcept() {
  const { session } = useSession();
  return useQuery({
    queryKey: ['kring-concept', session?.user.id],
    enabled: !!session,
    queryFn: async (): Promise<KringConcept | null> => {
      const { data, error } = await supabase
        .from('circle_drafts')
        .select('id, stap, antwoorden')
        .eq('owner_id', session!.user.id)
        .maybeSingle();
      if (error) throw error;
      return data ? ({ ...data, antwoorden: data.antwoorden ?? {} } as KringConcept) : null;
    },
  });
}

/** Slaat de stap en de antwoorden tot nu toe op (upsert op owner_id). */
export function useBewaarKringConcept() {
  const { session } = useSession();
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({ stap, antwoorden }: { stap: number; antwoorden: KringAntwoorden }) => {
      const { error } = await supabase.from('circle_drafts').upsert(
        { owner_id: session!.user.id, stap, antwoorden },
        { onConflict: 'owner_id' },
      );
      if (error) throw error;
    },
    onSuccess: () =>
      queryClient.invalidateQueries({ queryKey: ['kring-concept', session?.user.id] }),
  });
}

/** Ruimt het concept op zodra de kring er echt is. */
export function useWisKringConcept() {
  const { session } = useSession();
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async () => {
      const { error } = await supabase
        .from('circle_drafts')
        .delete()
        .eq('owner_id', session!.user.id);
      if (error) throw error;
    },
    onSuccess: () =>
      queryClient.invalidateQueries({ queryKey: ['kring-concept', session?.user.id] }),
  });
}

/**
 * Start de proefweek: het voorstel van Bo gaat als taken de kring in en de
 * teller van zeven dagen begint te lopen. De taken staan open, zodat de kring
 * ze in die week kan oppakken en ruilen.
 */
export function useStartProefweek() {
  const { session } = useSession();
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({
      circleId,
      taken,
    }: {
      circleId: string;
      taken: { type: TaakSoort; date: string; time: string }[];
    }) => {
      if (taken.length > 0) {
        const { error } = await supabase.from('tasks').insert(
          taken.map((taak) => ({
            circle_id: circleId,
            type: taak.type,
            date: taak.date,
            time: taak.time,
            recurrence: 'wekelijks' as const,
            status: 'open' as const,
            created_by: session!.user.id,
          })),
        );
        if (error) throw error;
      }
      const { error: kringError } = await supabase
        .from('circles')
        .update({ trial_started_at: new Date().toISOString() })
        .eq('id', circleId);
      if (kringError) throw kringError;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['my-circle'] });
      queryClient.invalidateQueries({ queryKey: ['tasks'] });
    },
  });
}

/** Bevestigt na de proefweek dat het rooster werkte. */
export function useBevestigProefweek() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (circleId: string) => {
      const { error } = await supabase.rpc('bevestig_proefweek', { p_circle: circleId });
      if (error) throw error;
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['my-circle'] }),
  });
}

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
  /** De persoonlijke code van de naaste, als die de app al heeft. */
  code?: string;
  /** Stap 4: wat de kring verder moet weten. */
  goedOmTeWeten?: string;
  /** Stap 6: één eerste taak, als je die al weet. Mag leeg blijven. */
  eersteTaak?: TaakSoort;
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
 * Koppelt de persoon voor wie je zorgt aan je kring met zijn eigen code
 * (feedback Jelle 11-08). De oudere leest die code voor; jij vult hem in.
 */
export function useKoppelNaaste() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({ circleId, code }: { circleId: string; code: string }) => {
      const { error } = await supabase.rpc('koppel_naaste', {
        p_circle: circleId,
        p_code: code.trim().toUpperCase(),
      });
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['circle-members'] });
      queryClient.invalidateQueries({ queryKey: ['my-circle'] });
    },
  });
}

/** Vertaalt de foutcodes van `koppel_naaste` naar begrijpelijke tekst. */
export function koppelFoutTekst(fout: unknown): string {
  const bericht = fout instanceof Error ? fout.message : '';
  if (bericht.includes('code_onbekend')) return 'mijnCode.foutOnbekend';
  if (bericht.includes('geen_hulpvrager')) return 'mijnCode.foutGeenHulpvrager';
  if (bericht.includes('al_in_kring')) return 'mijnCode.foutAlInKring';
  if (bericht.includes('eigen_code')) return 'mijnCode.foutEigenCode';
  return 'mijnCode.foutOnbekend';
}


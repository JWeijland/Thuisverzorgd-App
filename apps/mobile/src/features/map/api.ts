import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import { supabase } from '@/lib/supabase';

export type MapCircle = {
  id: string;
  name: string;
  lat: number;
  lon: number;
  /** Open taken die nog opgepakt kunnen worden. */
  plekken_vrij: number;
  /** Actieve leden: de beheerder plus de buddy's. */
  leden: number;
};
export type MapBuddy = {
  id: string;
  voornaam: string;
  avatar_path: string | null;
  lat: number;
  lon: number;
};

export function useMapCircles() {
  return useQuery({
    queryKey: ['map-circles'],
    queryFn: async (): Promise<MapCircle[]> => {
      const { data, error } = await supabase
        .from('v_map_circles')
        .select('id, name, lat, lon, plekken_vrij, leden');
      if (error) throw error;
      return data as MapCircle[];
    },
  });
}

/** Ben ik al lid van deze kring, of heb ik al een aanvraag lopen? */
export function useMyCircleStatus(circleId: string | undefined) {
  return useQuery({
    queryKey: ['circle-status', circleId],
    enabled: !!circleId,
    queryFn: async (): Promise<'lid' | 'aangevraagd' | 'geen'> => {
      const { data, error } = await supabase.rpc('my_circle_status', { p_circle: circleId! });
      if (error) throw error;
      return (data as 'lid' | 'aangevraagd' | 'geen') ?? 'geen';
    },
  });
}

/** Aanmelding bij een kring terugnemen zolang de beheerder nog niets deed. */
export function useWithdrawJoin() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (circleId: string) => {
      const { error } = await supabase.rpc('trek_aanmelding_in', { p_circle: circleId });
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['circle-status'] });
      queryClient.invalidateQueries({ queryKey: ['map-circles'] });
    },
  });
}

/** Aanmelden bij een kring vanaf de kaart; de beheerder beslist. */
export function useRequestToJoin() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({ circleId, message }: { circleId: string; message?: string }) => {
      const { error } = await supabase.rpc('request_to_join_circle', {
        p_circle: circleId,
        p_message: message ?? null,
      });
      if (error) throw error;
    },
    onSuccess: (_data, variables) => {
      queryClient.invalidateQueries({ queryKey: ['circle-status', variables.circleId] });
    },
  });
}

export function useMapBuddies(enabled: boolean) {
  return useQuery({
    queryKey: ['map-buddies'],
    enabled,
    queryFn: async (): Promise<MapBuddy[]> => {
      const { data, error } = await supabase
        .from('v_map_buddies')
        .select('id, voornaam, avatar_path, lat, lon');
      if (error) throw error;
      return data as MapBuddy[];
    },
  });
}

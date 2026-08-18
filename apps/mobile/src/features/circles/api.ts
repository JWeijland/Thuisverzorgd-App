import AsyncStorage from '@react-native-async-storage/async-storage';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useEffect } from 'react';

import { useSession } from '@/features/onboarding/useAuth';
import type { LatLng } from '@/lib/geo';
import { supabase } from '@/lib/supabase';

export type Circle = {
  id: string;
  owner_id: string;
  name: string;
  link_code: string;
  /** Naam van de naaste uit de kringopbouw; ook zonder eigen account. */
  naaste_naam?: string | null;
  /** Relatie van de beheerder tot de naaste (moeder, buurman, ...). */
  naaste_relatie?: string | null;
  /** Adres van de naaste; bepaalt waar de kring op de kaart staat. */
  address?: string | null;
  /** Start van de proefweek; na 7 dagen vraagt Bo of het rooster werkte. */
  trial_started_at?: string | null;
  /** Moment waarop de kring bevestigde dat het proefrooster klopt. */
  trial_confirmed_at?: string | null;
};

export type Member = {
  id: string;
  circle_id: string;
  profile_id: string;
  member_role: 'beheerder' | 'vrijwilliger' | 'hulpvrager';
  status: 'actief' | 'uitgenodigd' | 'id_check' | 'kijkt_mee';
  profile: { id: string; name: string; phone: string | null; avatar_path: string | null } | null;
};

export type ChatMessage = {
  id: string;
  circle_id: string;
  sender_id: string;
  body: string;
  created_at: string;
  sender: { name: string; avatar_path: string | null } | null;
};

/** De (eerste) kring waar de gebruiker lid van is; v1 gaat uit van één kring in de UI. */
export function useMyCircle() {
  const { session } = useSession();
  return useQuery({
    queryKey: ['my-circle', session?.user.id],
    enabled: !!session,
    queryFn: async (): Promise<Circle | null> => {
      const { data, error } = await supabase
        .from('circles')
        .select(
          'id, owner_id, name, link_code, naaste_naam, naaste_relatie, address, trial_started_at, trial_confirmed_at',
        )
        .order('created_at', { ascending: true })
        .limit(1);
      if (error) throw error;
      return (data?.[0] as Circle) ?? null;
    },
  });
}

/**
 * Alle kringen waar je lid van bent. Een vrijwilliger kan er meerdere hebben;
 * die staan als rondjes rechtsonder op de kaart (handoff, scherm 08). RLS
 * zorgt dat je alleen je eigen kringen terugkrijgt.
 */
export function useMyCircles() {
  const { session } = useSession();
  return useQuery({
    queryKey: ['my-circles', session?.user.id],
    enabled: !!session,
    queryFn: async (): Promise<Circle[]> => {
      const { data, error } = await supabase
        .from('circles')
        .select('id, owner_id, name, link_code')
        .order('created_at', { ascending: true });
      if (error) throw error;
      return (data ?? []) as Circle[];
    },
  });
}

export type NieuweKring = {
  name: string;
  /** Wie de kring omringt: naam en adres volstaan, een koppelcode hoeft niet. */
  naasteNaam?: string;
  naasteRelatie?: string;
  naasteInfo?: string;
  adres?: string;
  /** Coördinaten bij het adres (PDOK); zet de kring op de kaart. */
  locatie?: LatLng | null;
};

export function useCreateCircle() {
  const { session } = useSession();
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (kring: NieuweKring): Promise<Circle> => {
      const { data, error } = await supabase
        .from('circles')
        .insert({
          owner_id: session!.user.id,
          name: kring.name,
          naaste_naam: kring.naasteNaam?.trim() || null,
          naaste_relatie: kring.naasteRelatie?.trim() || null,
          naaste_info: kring.naasteInfo?.trim() || null,
          address: kring.adres?.trim() || null,
          // WKT voor de geography-kolom; de trigger rondt location_rounded af.
          location: kring.locatie ? `POINT(${kring.locatie.lon} ${kring.locatie.lat})` : null,
        })
        .select('id, owner_id, name, link_code')
        .single();
      if (error) throw error;
      const { error: memberError } = await supabase.from('circle_members').insert({
        circle_id: data.id,
        profile_id: session!.user.id,
        member_role: 'beheerder',
        status: 'actief',
      });
      if (memberError) throw memberError;
      return data as Circle;
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['my-circle'] }),
  });
}

export function useCircleMembers(circleId: string | undefined) {
  return useQuery({
    queryKey: ['circle-members', circleId],
    enabled: !!circleId,
    queryFn: async (): Promise<Member[]> => {
      const { data, error } = await supabase
        .from('circle_members')
        .select(
          'id, circle_id, profile_id, member_role, status, profile:profiles (id, name, phone, avatar_path)',
        )
        .eq('circle_id', circleId!)
        .order('joined_at', { ascending: true });
      if (error) throw error;
      return data as unknown as Member[];
    },
  });
}

export function useMessages(circleId: string | undefined) {
  const queryClient = useQueryClient();

  useEffect(() => {
    if (!circleId) return;
    const channel = supabase
      .channel(`messages-${circleId}-${Math.random().toString(36).slice(2)}`)
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'messages',
          filter: `circle_id=eq.${circleId}`,
        },
        () => queryClient.invalidateQueries({ queryKey: ['messages', circleId] }),
      )
      .subscribe();
    return () => {
      supabase.removeChannel(channel);
    };
  }, [circleId, queryClient]);

  return useQuery({
    queryKey: ['messages', circleId],
    enabled: !!circleId,
    queryFn: async (): Promise<ChatMessage[]> => {
      const { data, error } = await supabase
        .from('messages')
        .select('id, circle_id, sender_id, body, created_at, sender:profiles (name, avatar_path)')
        .eq('circle_id', circleId!)
        .order('created_at', { ascending: true })
        .limit(200);
      if (error) throw error;
      return data as unknown as ChatMessage[];
    },
  });
}

const gelezenKey = (circleId: string) => `kringchat-gelezen-${circleId}`;

/** Kringchat als gelezen markeren (tijdstempel lokaal per kring). */
export async function markCircleChatRead(circleId: string) {
  await AsyncStorage.setItem(gelezenKey(circleId), new Date().toISOString()).catch(() => {});
}

/**
 * Hoeveel berichten van anderen kwamen er ná je laatste bezoek aan de kringchat?
 * Het "gelezen tot"-moment staat op het toestel; de teller komt van de server.
 */
export function useUnreadCircleMessages(circleId: string | undefined) {
  const { session } = useSession();
  const queryClient = useQueryClient();

  useEffect(() => {
    if (!circleId) return;
    const channel = supabase
      .channel(`unread-${circleId}-${Math.random().toString(36).slice(2)}`)
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'messages',
          filter: `circle_id=eq.${circleId}`,
        },
        () => queryClient.invalidateQueries({ queryKey: ['messages-unread', circleId] }),
      )
      .subscribe();
    return () => {
      supabase.removeChannel(channel);
    };
  }, [circleId, queryClient]);

  const query = useQuery({
    queryKey: ['messages-unread', circleId, session?.user.id],
    enabled: !!circleId && !!session,
    queryFn: async (): Promise<number> => {
      const sinds = await AsyncStorage.getItem(gelezenKey(circleId!));
      let request = supabase
        .from('messages')
        .select('id', { count: 'exact', head: true })
        .eq('circle_id', circleId!)
        .neq('sender_id', session!.user.id);
      if (sinds) request = request.gt('created_at', sinds);
      const { count, error } = await request;
      if (error) throw error;
      return count ?? 0;
    },
  });

  return query.data ?? 0;
}

export function useSendMessage(circleId: string | undefined) {
  const { session } = useSession();
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (body: string) => {
      const { error } = await supabase.from('messages').insert({
        circle_id: circleId!,
        sender_id: session!.user.id,
        body,
      });
      if (error) throw error;
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['messages', circleId] }),
  });
}

export type BuddyCard = {
  id: string;
  voornaam: string;
  city: string | null;
  helped_count: number;
  waardering: number | null;
  kringen: number;
  avatar_path: string | null;
  /** Korte beschrijving in eigen woorden; leeg als hij niets heeft ingevuld. */
  bio: string | null;
  /** Afstand tot de kring in km; null als een van beide locaties ontbreekt. */
  afstand_km: number | null;
};

/** Het buddykaartje zoals je het op zijn eigen pagina ziet. */
export type BuddyProfiel = {
  id: string;
  voornaam: string;
  city: string | null;
  bio: string | null;
  helped_count: number;
  waardering: number | null;
  beoordelingen: number;
  kringen: number;
  avatar_path: string | null;
  id_verified: boolean;
  availability: string[];
};

/**
 * Eén buddy bekijken voordat je hem uitnodigt (wens Jelle 11-08). Alleen wat
 * hij zelf openbaar heeft gemaakt: geen adres, geen telefoonnummer.
 */
export function useBuddyProfiel(buddyId: string | undefined) {
  return useQuery({
    queryKey: ['buddy-profiel', buddyId],
    enabled: !!buddyId,
    queryFn: async (): Promise<BuddyProfiel | null> => {
      const { data, error } = await supabase.rpc('buddy_profiel', { p_buddy: buddyId! });
      if (error) throw error;
      return ((data ?? [])[0] as BuddyProfiel | undefined) ?? null;
    },
  });
}

/**
 * Buddy's om uit te nodigen. Server-side gefilterd op hun eigen hulpstraal:
 * wie alleen in de eigen straat wil helpen, komt niet in beeld bij een kring
 * vijf kilometer verderop.
 */
export function useBestMatches(circleId: string | undefined) {
  return useQuery({
    queryKey: ['best-matches', circleId],
    enabled: !!circleId,
    queryFn: async (): Promise<BuddyCard[]> => {
      const { data, error } = await supabase.rpc('buddys_voor_kring', { p_circle: circleId! });
      if (error) throw error;
      return (data ?? []) as BuddyCard[];
    },
  });
}

export function useInvite(circleId: string | undefined) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({ target, message }: { target: string; message?: string }) => {
      const { error } = await supabase.rpc('create_invitation', {
        p_circle: circleId!,
        p_target: target,
        p_message: message ?? null,
      });
      if (error) throw error;
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['circle-members', circleId] }),
  });
}

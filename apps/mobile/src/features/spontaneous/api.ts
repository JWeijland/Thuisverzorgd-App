import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useEffect } from 'react';

import { useSession } from '@/features/onboarding/useAuth';
import { supabase } from '@/lib/supabase';

export type RequestType = 'boodschappen' | 'vervoer' | 'medicijnen' | 'gezelschap' | 'anders';

export type OpenRequest = {
  id: string;
  type: RequestType;
  status: 'open' | 'aanbod';
  created_at: string;
  note: string | null;
  voornaam: string;
  lat: number | null;
  lon: number | null;
};

export type MyRequest = {
  id: string;
  type: RequestType;
  status: 'open' | 'aanbod' | 'onderweg' | 'afgerond' | 'geannuleerd';
  note: string | null;
  address: string | null;
  helper_id: string | null;
  cancelled_message: string | null;
};

export type Offer = {
  id: string;
  request_id: string;
  volunteer_id: string;
  message: string | null;
  status: 'aangeboden' | 'geaccepteerd' | 'afgewezen' | 'ingetrokken';
};

/** Realtime invalidatie voor alles rond directe hulp. */
function useSpontaneousRealtime() {
  const queryClient = useQueryClient();
  useEffect(() => {
    // Unieke kanaalnaam per component: hetzelfde kanaal twee keer subscriben
    // (BuurtScreen + VolunteerFlow) gooit een realtime-fout.
    const channel = supabase
      .channel(`spontaneous-${Math.random().toString(36).slice(2)}`)
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'spontaneous_requests' },
        () => {
          queryClient.invalidateQueries({ queryKey: ['open-requests'] });
          queryClient.invalidateQueries({ queryKey: ['my-request'] });
        },
      )
      .on('postgres_changes', { event: '*', schema: 'public', table: 'request_offers' }, () => {
        queryClient.invalidateQueries({ queryKey: ['request-offers'] });
        queryClient.invalidateQueries({ queryKey: ['my-offer'] });
      })
      .subscribe();
    return () => {
      supabase.removeChannel(channel);
    };
  }, [queryClient]);
}

/** Open aanvragen op de kaart (zonder adres, wijkniveau). */
export function useOpenRequests() {
  useSpontaneousRealtime();
  return useQuery({
    queryKey: ['open-requests'],
    refetchInterval: 30_000,
    queryFn: async (): Promise<OpenRequest[]> => {
      const { data, error } = await supabase
        .from('v_open_requests')
        .select('id, type, status, created_at, note, voornaam, lat, lon');
      if (error) throw error;
      return data as OpenRequest[];
    },
  });
}

/** Mijn lopende aanvraag (als aanvrager). */
export function useMyRequest() {
  const { session } = useSession();
  return useQuery({
    queryKey: ['my-request', session?.user.id],
    enabled: !!session,
    queryFn: async (): Promise<MyRequest | null> => {
      const { data, error } = await supabase
        .from('spontaneous_requests')
        .select('id, type, status, note, address, helper_id, cancelled_message')
        .eq('requester_id', session!.user.id)
        .in('status', ['open', 'aanbod', 'onderweg'])
        .order('created_at', { ascending: false })
        .limit(1);
      if (error) throw error;
      return (data?.[0] as MyRequest) ?? null;
    },
  });
}

export function useRequestOffers(requestId: string | undefined) {
  return useQuery({
    queryKey: ['request-offers', requestId],
    enabled: !!requestId,
    queryFn: async (): Promise<(Offer & { voornaam: string })[]> => {
      const { data, error } = await supabase
        .from('request_offers')
        .select('id, request_id, volunteer_id, message, status')
        .eq('request_id', requestId!)
        .eq('status', 'aangeboden');
      if (error) throw error;
      const offers = data as Offer[];
      // Voornamen via de publieke buddy-view (profielen van vreemden zijn niet leesbaar).
      const ids = offers.map((offer) => offer.volunteer_id);
      let names = new Map<string, string>();
      if (ids.length > 0) {
        const { data: cards } = await supabase
          .from('v_buddy_cards')
          .select('id, voornaam')
          .in('id', ids);
        names = new Map((cards ?? []).map((card) => [card.id as string, card.voornaam as string]));
      }
      return offers.map((offer) => ({
        ...offer,
        voornaam: names.get(offer.volunteer_id) ?? 'Buddy',
      }));
    },
  });
}

/** Mijn laatste aanbod (als vrijwilliger), plus of de aanvraag nog bestaat. */
export function useMyOffer() {
  const { session } = useSession();
  return useQuery({
    queryKey: ['my-offer', session?.user.id],
    enabled: !!session,
    queryFn: async (): Promise<Offer | null> => {
      const { data, error } = await supabase
        .from('request_offers')
        .select('id, request_id, volunteer_id, message, status')
        .eq('volunteer_id', session!.user.id)
        .in('status', ['aangeboden', 'geaccepteerd'])
        .order('created_at', { ascending: false })
        .limit(1);
      if (error) throw error;
      return (data?.[0] as Offer) ?? null;
    },
  });
}

/** Detail van de aanvraag waar mijn geaccepteerde aanbod bij hoort. */
export function useAcceptedRequest(requestId: string | undefined, enabled: boolean) {
  const { session } = useSession();
  return useQuery({
    queryKey: ['my-request-as-helper', requestId],
    enabled: !!requestId && !!session && enabled,
    queryFn: async (): Promise<MyRequest | null> => {
      const { data, error } = await supabase
        .from('spontaneous_requests')
        .select('id, type, status, note, address, helper_id, cancelled_message')
        .eq('id', requestId!)
        .maybeSingle();
      if (error) throw error;
      return data as MyRequest | null;
    },
  });
}

export function useSpontaneousActions() {
  const queryClient = useQueryClient();
  const { session } = useSession();
  const invalidate = () => {
    queryClient.invalidateQueries({ queryKey: ['open-requests'] });
    queryClient.invalidateQueries({ queryKey: ['my-request'] });
    queryClient.invalidateQueries({ queryKey: ['request-offers'] });
    queryClient.invalidateQueries({ queryKey: ['my-offer'] });
    queryClient.invalidateQueries({ queryKey: ['my-request-as-helper'] });
  };

  const createRequest = useMutation({
    mutationFn: async (input: {
      type: RequestType;
      note?: string;
      address?: string;
      lat?: number;
      lon?: number;
      circleId?: string;
    }) => {
      const { error } = await supabase.rpc('create_spontaneous_request', {
        p_type: input.type,
        p_note: input.note ?? null,
        p_address: input.address ?? null,
        p_lat: input.lat ?? null,
        p_lon: input.lon ?? null,
        p_circle: input.circleId ?? null,
      });
      if (error) throw error;
    },
    onSuccess: invalidate,
  });

  const offerHelp = useMutation({
    mutationFn: async ({ requestId, message }: { requestId: string; message: string }) => {
      const { error } = await supabase.from('request_offers').insert({
        request_id: requestId,
        volunteer_id: session!.user.id,
        message: message || null,
      });
      if (error) throw error;
    },
    onSuccess: invalidate,
  });

  const acceptOffer = useMutation({
    mutationFn: async (offerId: string) => {
      const { error } = await supabase.rpc('accept_offer', { p_offer: offerId });
      if (error) throw error;
    },
    onSuccess: invalidate,
  });

  const rejectOffer = useMutation({
    mutationFn: async (offerId: string) => {
      const { error } = await supabase.rpc('reject_offer', { p_offer: offerId });
      if (error) throw error;
    },
    onSuccess: invalidate,
  });

  const cancelRequest = useMutation({
    mutationFn: async ({ requestId, message }: { requestId: string; message?: string }) => {
      const { error } = await supabase.rpc('cancel_request', {
        p_request: requestId,
        p_message: message ?? null,
      });
      if (error) throw error;
    },
    onSuccess: invalidate,
  });

  const completeRequest = useMutation({
    mutationFn: async (requestId: string) => {
      const { error } = await supabase.rpc('complete_request', { p_request: requestId });
      if (error) throw error;
    },
    onSuccess: invalidate,
  });

  return { createRequest, offerHelp, acceptOffer, rejectOffer, cancelRequest, completeRequest };
}

export function useRequestContact(requestId: string | undefined, enabled: boolean) {
  return useQuery({
    queryKey: ['request-contact', requestId],
    enabled: !!requestId && enabled,
    queryFn: async (): Promise<{ naam: string; telefoon: string | null } | null> => {
      const { data, error } = await supabase.rpc('get_request_contact', {
        p_request: requestId!,
      });
      if (error) return null;
      const row = (data as { naam: string; telefoon: string | null }[])?.[0];
      return row ?? null;
    },
  });
}

export function useRequestAddress(requestId: string | undefined, enabled: boolean) {
  return useQuery({
    queryKey: ['request-address', requestId],
    enabled: !!requestId && enabled,
    queryFn: async (): Promise<string | null> => {
      const { data, error } = await supabase.rpc('get_request_address', {
        p_request: requestId!,
      });
      if (error) return null;
      return data as string;
    },
  });
}

import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useEffect } from 'react';

import { useSession } from '@/features/onboarding/useAuth';
import { supabase } from '@/lib/supabase';

export type Circle = {
  id: string;
  owner_id: string;
  name: string;
  link_code: string;
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
  sender: { name: string } | null;
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
        .select('id, owner_id, name, link_code')
        .order('created_at', { ascending: true })
        .limit(1);
      if (error) throw error;
      return (data?.[0] as Circle) ?? null;
    },
  });
}

export function useCreateCircle() {
  const { session } = useSession();
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (name: string): Promise<Circle> => {
      const { data, error } = await supabase
        .from('circles')
        .insert({ owner_id: session!.user.id, name })
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
        .select('id, circle_id, sender_id, body, created_at, sender:profiles (name)')
        .eq('circle_id', circleId!)
        .order('created_at', { ascending: true })
        .limit(200);
      if (error) throw error;
      return data as unknown as ChatMessage[];
    },
  });
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
};

export function useBestMatches() {
  return useQuery({
    queryKey: ['best-matches'],
    queryFn: async (): Promise<BuddyCard[]> => {
      const { data, error } = await supabase
        .from('v_buddy_cards')
        .select('id, voornaam, city, helped_count, waardering, kringen')
        .order('helped_count', { ascending: false })
        .limit(5);
      if (error) throw error;
      return data as BuddyCard[];
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

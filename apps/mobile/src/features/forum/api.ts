import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useEffect, useState } from 'react';

import { useProfile, useSession } from '@/features/onboarding/useAuth';
import { supabase } from '@/lib/supabase';

export type ForumTag = 'wonen' | 'werk' | 'financien' | 'dementie' | 'overig';

export type ForumPost = {
  id: string;
  title: string;
  body: string;
  tag: ForumTag;
  city: string | null;
  created_at: string;
  author_id: string;
  voornaam: string;
  antwoorden: number;
};

export type ForumReply = {
  id: string;
  post_id: string;
  body: string;
  is_broker: boolean;
  created_at: string;
  author_id: string;
  voornaam: string;
};

export function usePosts(tag: ForumTag | null) {
  return useQuery({
    queryKey: ['forum-posts', tag],
    queryFn: async (): Promise<ForumPost[]> => {
      let query = supabase
        .from('v_forum_posts')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(50);
      if (tag) query = query.eq('tag', tag);
      const { data, error } = await query;
      if (error) throw error;
      return data as ForumPost[];
    },
  });
}

export function usePost(postId: string | undefined) {
  return useQuery({
    queryKey: ['forum-post', postId],
    enabled: !!postId,
    queryFn: async (): Promise<ForumPost | null> => {
      const { data, error } = await supabase
        .from('v_forum_posts')
        .select('*')
        .eq('id', postId!)
        .maybeSingle();
      if (error) throw error;
      return data as ForumPost | null;
    },
  });
}

export function useReplies(postId: string | undefined) {
  return useQuery({
    queryKey: ['forum-replies', postId],
    enabled: !!postId,
    queryFn: async (): Promise<ForumReply[]> => {
      const { data, error } = await supabase
        .from('v_forum_replies')
        .select('*')
        .eq('post_id', postId!)
        .order('created_at', { ascending: true });
      if (error) throw error;
      return data as ForumReply[];
    },
  });
}

export function useForumActions() {
  const { session } = useSession();
  const profile = useProfile();
  const queryClient = useQueryClient();
  const invalidate = () => {
    queryClient.invalidateQueries({ queryKey: ['forum-posts'] });
    queryClient.invalidateQueries({ queryKey: ['forum-post'] });
    queryClient.invalidateQueries({ queryKey: ['forum-replies'] });
  };

  const createPost = useMutation({
    mutationFn: async (input: { title: string; body: string; tag: ForumTag }) => {
      const { error } = await supabase.from('forum_posts').insert({
        author_id: session!.user.id,
        title: input.title,
        body: input.body,
        tag: input.tag,
        city: profile.data ? ((profile.data as { city?: string }).city ?? null) : null,
      });
      if (error) throw error;
    },
    onSuccess: invalidate,
  });

  const createReply = useMutation({
    mutationFn: async ({ postId, body }: { postId: string; body: string }) => {
      const { error } = await supabase.from('forum_replies').insert({
        post_id: postId,
        author_id: session!.user.id,
        body,
      });
      if (error) throw error;
    },
    onSuccess: invalidate,
  });

  const report = useMutation({
    mutationFn: async (input: {
      targetKind: 'post' | 'reply' | 'message' | 'profile';
      targetId: string;
      reason?: string;
    }) => {
      const { error } = await supabase.from('forum_reports').insert({
        target_kind: input.targetKind,
        target_id: input.targetId,
        reporter_id: session!.user.id,
        reason: input.reason ?? null,
      });
      if (error) throw error;
    },
  });

  const block = useMutation({
    mutationFn: async (blockedId: string) => {
      const { error } = await supabase.from('user_blocks').insert({
        blocker_id: session!.user.id,
        blocked_id: blockedId,
      });
      if (error && !error.message.includes('duplicate')) throw error;
    },
    onSuccess: invalidate,
  });

  return { createPost, createReply, report, block };
}

// ---------------------------------------------------------------------------
// Hulpmakelaar-chat
// ---------------------------------------------------------------------------

export type BrokerMessage = {
  id: string;
  chat_id: string;
  sender_id: string;
  body: string;
  created_at: string;
};

export function useMyBrokerChat() {
  const { session } = useSession();
  return useQuery({
    queryKey: ['broker-chat', session?.user.id],
    enabled: !!session,
    queryFn: async (): Promise<string> => {
      const { data, error } = await supabase.rpc('ensure_broker_chat');
      if (error) throw error;
      return data as string;
    },
  });
}

export function useBrokerMessages(chatId: string | undefined) {
  const queryClient = useQueryClient();

  useEffect(() => {
    if (!chatId) return;
    const channel = supabase
      .channel(`broker-${chatId}-${Math.random().toString(36).slice(2)}`)
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'broker_messages',
          filter: `chat_id=eq.${chatId}`,
        },
        () => queryClient.invalidateQueries({ queryKey: ['broker-messages', chatId] }),
      )
      .subscribe();
    return () => {
      supabase.removeChannel(channel);
    };
  }, [chatId, queryClient]);

  return useQuery({
    queryKey: ['broker-messages', chatId],
    enabled: !!chatId,
    queryFn: async (): Promise<BrokerMessage[]> => {
      const { data, error } = await supabase
        .from('broker_messages')
        .select('id, chat_id, sender_id, body, created_at')
        .eq('chat_id', chatId!)
        .order('created_at', { ascending: true })
        .limit(200);
      if (error) throw error;
      return data as BrokerMessage[];
    },
  });
}

export function useSendBrokerMessage(chatId: string | undefined) {
  const { session } = useSession();
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (body: string) => {
      const { error } = await supabase.from('broker_messages').insert({
        chat_id: chatId!,
        sender_id: session!.user.id,
        body,
      });
      if (error) throw error;
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['broker-messages', chatId] }),
  });
}

// ---------------------------------------------------------------------------
// Makelaar-console
// ---------------------------------------------------------------------------

export type BrokerChatOverview = {
  id: string;
  status: string;
  created_at: string;
  voornaam: string;
  laatste_bericht: string | null;
  laatste_activiteit: string | null;
};

export type Report = {
  id: string;
  target_kind: string;
  target_id: string;
  reason: string | null;
  status: 'open' | 'afgehandeld';
  created_at: string;
  samenvatting: string | null;
};

export function useBrokerChatsOverview(enabled: boolean) {
  return useQuery({
    queryKey: ['broker-chats-overview'],
    enabled,
    refetchInterval: 15_000,
    queryFn: async (): Promise<BrokerChatOverview[]> => {
      const { data, error } = await supabase
        .from('v_broker_chat_overview')
        .select('*')
        .order('laatste_activiteit', { ascending: false, nullsFirst: false });
      if (error) throw error;
      return data as BrokerChatOverview[];
    },
  });
}

export function useReports(enabled: boolean) {
  return useQuery({
    queryKey: ['reports'],
    enabled,
    refetchInterval: 30_000,
    queryFn: async (): Promise<Report[]> => {
      const { data, error } = await supabase
        .from('v_report_overview')
        .select('*')
        .eq('status', 'open')
        .order('created_at', { ascending: true });
      if (error) throw error;
      return data as Report[];
    },
  });
}

export function useResolveReport() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({ reportId, hide }: { reportId: string; hide: boolean }) => {
      const { error } = await supabase.rpc('resolve_report', {
        p_report: reportId,
        p_hide: hide,
      });
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['reports'] });
      queryClient.invalidateQueries({ queryKey: ['forum-posts'] });
      queryClient.invalidateQueries({ queryKey: ['forum-replies'] });
    },
  });
}

/**
 * Presence: hoeveel hulpmakelaars zijn er nu online? Makelaars melden zich aan.
 * Singleton-kanaal: de topicnaam moet voor iedereen gelijk zijn, maar binnen
 * één app mag hetzelfde kanaal niet twee keer gesubscribed worden.
 */
type PresenceListener = (count: number) => void;
let presenceChannel: ReturnType<typeof supabase.channel> | null = null;
const presenceListeners = new Set<PresenceListener>();
let presenceTracked = false;
let presenceCount = 0;

function ensurePresenceChannel(userId: string) {
  if (presenceChannel) return presenceChannel;
  presenceChannel = supabase.channel('online-makelaars', {
    config: { presence: { key: userId } },
  });
  presenceChannel
    .on('presence', { event: 'sync' }, () => {
      presenceCount = Object.keys(presenceChannel!.presenceState()).length;
      presenceListeners.forEach((listener) => listener(presenceCount));
    })
    .subscribe();
  return presenceChannel;
}

export function useBrokerPresence(): number {
  const profile = useProfile();
  const { session } = useSession();
  const [count, setCount] = useState(presenceCount);
  const isBroker = profile.data?.role === 'makelaar';

  useEffect(() => {
    if (!session) return;
    const channel = ensurePresenceChannel(session.user.id);
    presenceListeners.add(setCount);
    const sync = setTimeout(() => setCount(presenceCount), 0);
    if (isBroker && !presenceTracked) {
      presenceTracked = true;
      channel.track({ online: true }).catch(() => {});
    }
    return () => {
      clearTimeout(sync);
      presenceListeners.delete(setCount);
    };
  }, [session, isBroker]);

  return count;
}

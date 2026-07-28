import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useEffect } from 'react';

import { useSession } from '@/features/onboarding/useAuth';
import { supabase } from '@/lib/supabase';

export type AppNotification = {
  id: string;
  kind: string;
  title: string;
  body: string | null;
  deeplink: string | null;
  read: boolean;
  created_at: string;
};

export function useNotifications() {
  const { session } = useSession();
  const queryClient = useQueryClient();

  useEffect(() => {
    if (!session) return;
    const channel = supabase
      .channel(`notifications-${Math.random().toString(36).slice(2)}`)
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'notifications',
          filter: `profile_id=eq.${session.user.id}`,
        },
        () => queryClient.invalidateQueries({ queryKey: ['notifications'] }),
      )
      .subscribe();
    return () => {
      supabase.removeChannel(channel);
    };
  }, [session, queryClient]);

  return useQuery({
    queryKey: ['notifications', session?.user.id],
    enabled: !!session,
    queryFn: async (): Promise<AppNotification[]> => {
      const { data, error } = await supabase
        .from('notifications')
        .select('id, kind, title, body, deeplink, read, created_at')
        .order('created_at', { ascending: false })
        .limit(50);
      if (error) throw error;
      return data as AppNotification[];
    },
  });
}

export function useUnreadCount(): number {
  const notifications = useNotifications();
  return (notifications.data ?? []).filter((notification) => !notification.read).length;
}

export function useNotificationActions() {
  const queryClient = useQueryClient();
  const invalidate = () => queryClient.invalidateQueries({ queryKey: ['notifications'] });

  const markRead = useMutation({
    mutationFn: async (id: string) => {
      await supabase.from('notifications').update({ read: true }).eq('id', id);
    },
    onSuccess: invalidate,
  });
  const markAllRead = useMutation({
    mutationFn: async () => {
      await supabase.from('notifications').update({ read: true }).eq('read', false);
    },
    onSuccess: invalidate,
  });
  const remove = useMutation({
    mutationFn: async (id: string) => {
      await supabase.from('notifications').delete().eq('id', id);
    },
    onSuccess: invalidate,
  });
  return { markRead, markAllRead, remove };
}

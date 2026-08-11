import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useEffect } from 'react';

import { useSession } from '@/features/onboarding/useAuth';
import { haptics } from '@/lib/haptics';
import { supabase } from '@/lib/supabase';
import { toDateString } from '@/lib/dates';

export type Task = {
  id: string;
  circle_id: string;
  type: 'boodschappen' | 'wandelen' | 'vervoer' | 'koken' | 'gezelschap' | 'anders';
  custom_label: string | null;
  date: string;
  time: string;
  recurrence: 'eenmalig' | 'wekelijks' | 'tweewekelijks';
  status: 'open' | 'ingepland' | 'gedaan' | 'geannuleerd';
  claimed_by: string | null;
  claimer: {
    id: string;
    name: string;
    phone: string | null;
    avatar_path: string | null;
  } | null;
  circle: { name: string } | null;
};

export type TaskDraft = {
  id: string;
  circle_id: string;
  type: Task['type'];
  custom_label: string | null;
  date: string;
  time: string;
  recurrence: Task['recurrence'];
};

export type TaskLog = {
  id: string;
  note: string;
  created_at: string;
  author: { name: string } | null;
};

const TASK_SELECT =
  'id, circle_id, type, custom_label, date, time, recurrence, status, claimed_by, claimer:profiles!tasks_claimed_by_fkey (id, name, phone, avatar_path), circle:circles (name)';

/** Taken van een kring in een datumbereik, realtime bijgewerkt. */
export function useTasks(circleId: string | undefined, from: Date, to: Date) {
  const queryClient = useQueryClient();
  const fromKey = toDateString(from);
  const toKey = toDateString(to);

  useEffect(() => {
    if (!circleId) return;
    const channel = supabase
      .channel(`tasks-${circleId}-${Math.random().toString(36).slice(2)}`)
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'tasks', filter: `circle_id=eq.${circleId}` },
        () => queryClient.invalidateQueries({ queryKey: ['tasks', circleId] }),
      )
      .subscribe();
    return () => {
      supabase.removeChannel(channel);
    };
  }, [circleId, queryClient]);

  return useQuery({
    queryKey: ['tasks', circleId, fromKey, toKey],
    enabled: !!circleId,
    queryFn: async (): Promise<Task[]> => {
      const { data, error } = await supabase
        .from('tasks')
        .select(TASK_SELECT)
        .eq('circle_id', circleId!)
        .gte('date', fromKey)
        .lte('date', toKey)
        .neq('status', 'geannuleerd')
        .order('date')
        .order('time');
      if (error) throw error;
      return data as unknown as Task[];
    },
  });
}

/** Alle taken die ik geclaimd heb (voor de taakbanner en de teller). */
export function useMyClaimedTasks() {
  const { session } = useSession();
  return useQuery({
    queryKey: ['my-tasks', session?.user.id],
    enabled: !!session,
    queryFn: async (): Promise<Task[]> => {
      const { data, error } = await supabase
        .from('tasks')
        .select(TASK_SELECT)
        .eq('claimed_by', session!.user.id)
        .gte('date', toDateString(new Date()))
        .eq('status', 'ingepland')
        .order('date')
        .order('time');
      if (error) throw error;
      return data as unknown as Task[];
    },
  });
}

export type NewTask = {
  type: Task['type'];
  custom_label?: string | null;
  date: string;
  time: string;
  recurrence: Task['recurrence'];
  /**
   * Direct aan één kringlid toewijzen (handoff, scherm 06 "Wie"). Zonder dit
   * veld staat de taak open voor de hele kring.
   */
  claimed_by?: string | null;
  status?: Task['status'];
};

export function useCreateTask(circleId: string | undefined) {
  const { session } = useSession();
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (task: NewTask) => {
      const { error } = await supabase.from('tasks').insert({
        circle_id: circleId!,
        created_by: session!.user.id,
        ...task,
      });
      if (error) throw error;
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['tasks', circleId] }),
  });
}

/**
 * De hulpvrager vraagt zelf een buddy: via de RPC `vraag_buddy` wordt dat een
 * open taak in de eigen kring (ontwerp 4.0, rode draad).
 */
export function useVraagBuddy(circleId: string | undefined) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (input: { type: NewTask['type']; custom_label?: string | null }) => {
      const { error } = await supabase.rpc('vraag_buddy', {
        p_circle: circleId!,
        p_type: input.type,
        p_custom: input.custom_label ?? null,
      });
      if (error) throw error;
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['tasks', circleId] }),
  });
}

export function useTaskRpc(circleId: string | undefined) {
  const queryClient = useQueryClient();
  const invalidate = () => {
    queryClient.invalidateQueries({ queryKey: ['tasks', circleId] });
    queryClient.invalidateQueries({ queryKey: ['my-tasks'] });
    queryClient.invalidateQueries({ queryKey: ['task-logs', circleId] });
  };
  const claim = useMutation({
    mutationFn: async (taskId: string) => {
      const { data, error } = await supabase.rpc('claim_task', { p_task: taskId });
      if (error) throw error;
      return data as boolean;
    },
    onSuccess: (gelukt) => {
      if (gelukt) void haptics.voltooid();
      invalidate();
    },
    onError: () => void haptics.fout(),
  });
  const release = useMutation({
    mutationFn: async (taskId: string) => {
      const { error } = await supabase.rpc('release_task', { p_task: taskId });
      if (error) throw error;
    },
    onSuccess: invalidate,
  });
  const complete = useMutation({
    mutationFn: async ({ taskId, note }: { taskId: string; note?: string }) => {
      const { error } = await supabase.rpc('complete_task', {
        p_task: taskId,
        p_note: note ?? null,
      });
      if (error) throw error;
    },
    onSuccess: () => {
      void haptics.voltooid();
      invalidate();
    },
    onError: () => void haptics.fout(),
  });
  const cancel = useMutation({
    mutationFn: async (taskId: string) => {
      const { error } = await supabase.rpc('cancel_task', { p_task: taskId });
      if (error) throw error;
    },
    onSuccess: invalidate,
  });
  const uncomplete = useMutation({
    mutationFn: async (taskId: string) => {
      const { data, error } = await supabase.rpc('uncomplete_task', { p_task: taskId });
      if (error) throw error;
      return data as boolean;
    },
    onSuccess: invalidate,
  });
  return { claim, release, complete, cancel, uncomplete };
}

/** Begintijdstip van een taak (datum + tijd, lokale tijd). */
export function taskStart(task: Pick<Task, 'date' | 'time'>): Date {
  const [y, m, d] = task.date.split('-').map(Number);
  const [hh, mm] = task.time.split(':').map(Number);
  return new Date(y!, m! - 1, d!, hh ?? 0, mm ?? 0);
}

export function useTaskLogs(circleId: string | undefined) {
  return useQuery({
    queryKey: ['task-logs', circleId],
    enabled: !!circleId,
    queryFn: async (): Promise<TaskLog[]> => {
      const { data, error } = await supabase
        .from('task_logs')
        .select('id, note, created_at, author:profiles (name)')
        .eq('circle_id', circleId!)
        .order('created_at', { ascending: false })
        .limit(10);
      if (error) throw error;
      return data as unknown as TaskLog[];
    },
  });
}

export function useDrafts(circleId: string | undefined) {
  return useQuery({
    queryKey: ['drafts', circleId],
    enabled: !!circleId,
    queryFn: async (): Promise<TaskDraft[]> => {
      const { data, error } = await supabase
        .from('task_drafts')
        .select('id, circle_id, type, custom_label, date, time, recurrence')
        .eq('circle_id', circleId!)
        .order('date')
        .order('time');
      if (error) throw error;
      return data as TaskDraft[];
    },
  });
}

export function useDraftMutations(circleId: string | undefined) {
  const { session } = useSession();
  const queryClient = useQueryClient();
  const invalidate = () => {
    queryClient.invalidateQueries({ queryKey: ['drafts', circleId] });
    queryClient.invalidateQueries({ queryKey: ['tasks', circleId] });
  };
  const add = useMutation({
    mutationFn: async (task: NewTask) => {
      const { error } = await supabase.from('task_drafts').insert({
        circle_id: circleId!,
        created_by: session!.user.id,
        ...task,
      });
      if (error) throw error;
    },
    onSuccess: invalidate,
  });
  const remove = useMutation({
    mutationFn: async (draftId: string) => {
      const { error } = await supabase.from('task_drafts').delete().eq('id', draftId);
      if (error) throw error;
    },
    onSuccess: invalidate,
  });
  const publish = useMutation({
    mutationFn: async (): Promise<number> => {
      const { data, error } = await supabase.rpc('publish_drafts', { p_circle: circleId! });
      if (error) throw error;
      return data as number;
    },
    onSuccess: invalidate,
  });
  return { add, remove, publish };
}

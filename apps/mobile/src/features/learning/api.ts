import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import { useSession } from '@/features/onboarding/useAuth';
import { supabase } from '@/lib/supabase';

export type Course = {
  id: string;
  slug: string;
  title: string;
  subtitle: string | null;
  description: string | null;
  topic: string | null;
  duur_minuten: number;
  drempel: number;
  onderdelen: number;
  vragen: number;
  gelezen: number;
  gehaald: boolean;
  laatste_score: number | null;
  groepen_binnenkort: number;
};

export type CourseModule = {
  id: string;
  course_id: string;
  sortering: number;
  title: string;
  body: string | null;
  video_url: string | null;
  video_label: string | null;
};

export type CourseQuestion = {
  id: string;
  course_id: string;
  sortering: number;
  question: string;
  options: string[];
};

export type CourseGroup = {
  id: string;
  course_id: string;
  cursus: string;
  titel: string;
  begeleider: string;
  locatie: string;
  city: string | null;
  start_op: string;
  duur_minuten: number;
  plekken: number;
  aangemeld: number;
  ik_ga: boolean;
};

export type TestUitslag = { score: number; gehaald: boolean; drempel: number };

/** Alle gepubliceerde cursussen, met jouw voortgang erbij. */
export function useCourses() {
  const { session } = useSession();
  return useQuery({
    queryKey: ['courses', session?.user.id],
    enabled: !!session,
    queryFn: async (): Promise<Course[]> => {
      const { data, error } = await supabase.from('v_courses').select('*');
      if (error) throw error;
      return data as Course[];
    },
  });
}

export function useCourse(courseId: string | undefined) {
  const courses = useCourses();
  return courses.data?.find((course) => course.id === courseId);
}

export function useCourseModules(courseId: string | undefined) {
  return useQuery({
    queryKey: ['course-modules', courseId],
    enabled: !!courseId,
    queryFn: async (): Promise<CourseModule[]> => {
      const { data, error } = await supabase
        .from('course_modules')
        .select('id, course_id, sortering, title, body, video_url, video_label')
        .eq('course_id', courseId!)
        .order('sortering');
      if (error) throw error;
      return data as CourseModule[];
    },
  });
}

/** Toetsvragen zonder de juiste antwoorden (die blijven server-side). */
export function useCourseQuestions(courseId: string | undefined) {
  return useQuery({
    queryKey: ['course-questions', courseId],
    enabled: !!courseId,
    queryFn: async (): Promise<CourseQuestion[]> => {
      const { data, error } = await supabase
        .from('v_course_questions')
        .select('id, course_id, sortering, question, options')
        .eq('course_id', courseId!)
        .order('sortering');
      if (error) throw error;
      return data as CourseQuestion[];
    },
  });
}

export function useCourseActions(courseId: string | undefined) {
  const queryClient = useQueryClient();
  const invalidate = () => {
    queryClient.invalidateQueries({ queryKey: ['courses'] });
  };

  const markRead = useMutation({
    mutationFn: async (moduleId: string) => {
      const { error } = await supabase.rpc('mark_module_read', { p_module: moduleId });
      if (error) throw error;
    },
    onSuccess: invalidate,
  });

  const submitTest = useMutation({
    mutationFn: async (answers: number[]): Promise<TestUitslag> => {
      const { data, error } = await supabase.rpc('submit_course_test', {
        p_course: courseId!,
        p_answers: answers,
      });
      if (error) throw error;
      const row = (data as TestUitslag[])?.[0];
      return row ?? { score: 0, gehaald: false, drempel: 100 };
    },
    onSuccess: invalidate,
  });

  return { markRead, submitTest };
}

/** Juiste antwoorden + uitleg; mag pas na het inleveren van de toets. */
export function useCourseAnswers(courseId: string | undefined, enabled: boolean) {
  return useQuery({
    queryKey: ['course-answers', courseId],
    enabled: !!courseId && enabled,
    queryFn: async (): Promise<Record<string, { correct: number; uitleg: string | null }>> => {
      const { data, error } = await supabase.rpc('course_answers', { p_course: courseId! });
      if (error) return {};
      const rows = (data ?? []) as {
        question_id: string;
        correct_index: number;
        uitleg: string | null;
      }[];
      return Object.fromEntries(
        rows.map((row) => [row.question_id, { correct: row.correct_index, uitleg: row.uitleg }]),
      );
    },
  });
}

/** Klassikale groepen; optioneel gefilterd op één cursus. */
export function useCourseGroups(courseId?: string) {
  const { session } = useSession();
  return useQuery({
    queryKey: ['course-groups', courseId ?? 'alle', session?.user.id],
    enabled: !!session,
    queryFn: async (): Promise<CourseGroup[]> => {
      let query = supabase.from('v_course_groups').select('*');
      if (courseId) query = query.eq('course_id', courseId);
      const { data, error } = await query;
      if (error) throw error;
      return data as CourseGroup[];
    },
  });
}

export function useGroupActions() {
  const queryClient = useQueryClient();
  const invalidate = () => {
    queryClient.invalidateQueries({ queryKey: ['course-groups'] });
    queryClient.invalidateQueries({ queryKey: ['courses'] });
  };
  const join = useMutation({
    mutationFn: async (groupId: string) => {
      const { error } = await supabase.rpc('join_course_group', { p_group: groupId });
      if (error) throw error;
    },
    onSuccess: invalidate,
  });
  const leave = useMutation({
    mutationFn: async (groupId: string) => {
      const { error } = await supabase.rpc('leave_course_group', { p_group: groupId });
      if (error) throw error;
    },
    onSuccess: invalidate,
  });
  return { join, leave };
}

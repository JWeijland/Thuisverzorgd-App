import type { Session } from '@supabase/supabase-js';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { createContext, useContext, useEffect, useState, type ReactNode } from 'react';

import { supabase } from '@/lib/supabase';

export type Profile = {
  id: string;
  role: 'beheerder' | 'vrijwilliger' | 'hulpvrager' | 'admin' | 'makelaar' | null;
  name: string;
  email: string | null;
  tvz_id: string;
  avatar_path: string | null;
  id_verified: boolean;
  vacation_mode: boolean;
  pool_opt_in: boolean;
  large_text: boolean;
  helped_count: number;
  notification_prefs: Record<string, boolean>;
  availability: string[];
  calendar_sync: boolean;
};

type AuthValue = {
  session: Session | null;
  /** true zolang de opgeslagen sessie nog wordt geladen */
  loading: boolean;
};

const AuthContext = createContext<AuthValue>({ session: null, loading: true });

export function AuthProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<Session | null>(null);
  const [loading, setLoading] = useState(true);
  const queryClient = useQueryClient();

  useEffect(() => {
    supabase.auth.getSession().then(async ({ data }) => {
      // Dev-only: automatisch inloggen met testtokens uit .env (voor de simulator).
      if (__DEV__ && !data.session && process.env.EXPO_PUBLIC_DEV_ACCESS_TOKEN) {
        const { data: devData } = await supabase.auth.setSession({
          access_token: process.env.EXPO_PUBLIC_DEV_ACCESS_TOKEN,
          refresh_token: process.env.EXPO_PUBLIC_DEV_REFRESH_TOKEN ?? '',
        });
        setSession(devData.session);
        setLoading(false);
        return;
      }
      setSession(data.session);
      setLoading(false);
    });
    const { data: sub } = supabase.auth.onAuthStateChange((_event, newSession) => {
      setSession(newSession);
      if (!newSession) {
        queryClient.clear();
      }
    });
    return () => sub.subscription.unsubscribe();
  }, [queryClient]);

  return <AuthContext.Provider value={{ session, loading }}>{children}</AuthContext.Provider>;
}

export function useSession(): AuthValue {
  return useContext(AuthContext);
}

export function useProfile() {
  const { session } = useSession();
  return useQuery({
    queryKey: ['profile', session?.user.id],
    enabled: !!session,
    queryFn: async (): Promise<Profile> => {
      const { data, error } = await supabase
        .from('profiles')
        .select(
          'id, role, name, email, tvz_id, avatar_path, id_verified, vacation_mode, pool_opt_in, large_text, helped_count, notification_prefs, availability, calendar_sync',
        )
        .eq('id', session!.user.id)
        .single();
      if (error) throw error;
      return data as Profile;
    },
  });
}

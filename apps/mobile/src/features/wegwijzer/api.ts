import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useEffect, useState } from 'react';

import { useSession } from '@/features/onboarding/useAuth';
import { magZoeken, normaliseer } from '@/features/wegwijzer/zoekterm';
import { supabase } from '@/lib/supabase';

export type ThemaKleur = 'blauw' | 'groen' | 'oranje' | 'paars';

export type GuideTheme = {
  id: string;
  slug: string;
  titel: string;
  omschrijving: string | null;
  icoon: string;
  kleur: ThemaKleur;
  sortering: number;
  onderwerpen: number;
};

export type GuideModule = {
  id: string;
  slug: string;
  titel: string;
  samenvatting: string;
  kern: string[];
  wetten: string[];
  zoektermen: string[];
  leestijd_minuten: number;
  populair: boolean;
  bijgewerkt_op: string;
  sortering: number;
  theme_id: string;
  thema_slug: string;
  thema: string;
  thema_kleur: ThemaKleur;
  thema_icoon: string;
  bewaard: boolean;
  gelezen_op: string | null;
};

export type SectieSoort = 'uitleg' | 'stappen' | 'wet' | 'letop' | 'voorbeeld' | 'vraag';

export type GuideSection = {
  id: string;
  module_id: string;
  sortering: number;
  soort: SectieSoort;
  titel: string;
  body: string;
};

export type GuideLink = {
  id: string;
  module_id: string;
  sortering: number;
  titel: string;
  url: string;
};

export type Zoektreffer = {
  id: string;
  slug: string;
  titel: string;
  samenvatting: string;
  thema: string;
  thema_slug: string;
  thema_kleur: ThemaKleur;
  leestijd_minuten: number;
  /** Het stukje tekst met de treffer; het gevonden woord staat tussen « en ». */
  treffer: string | null;
  score: number;
};

export type Suggestie = { term: string; slug: string; titel: string };

export type AntwoordBron = { titel: string; url: string };

/** Het onderdeel uit de kennisbank dat een ingetypte vraag beantwoordt. */
export type Antwoord = {
  sectie_id: string;
  module_id: string;
  module_slug: string;
  module_titel: string;
  thema: string;
  thema_slug: string;
  thema_kleur: ThemaKleur;
  soort: SectieSoort;
  titel: string;
  antwoord: string;
  wetten: string[];
  bronnen: AntwoordBron[];
  score: number;
};

/** Alle thema's met hun aantal onderwerpen. */
export function useGuideThemes() {
  const { session } = useSession();
  return useQuery({
    queryKey: ['wegwijzer-themas', session?.user.id],
    enabled: !!session,
    staleTime: 5 * 60 * 1000,
    queryFn: async (): Promise<GuideTheme[]> => {
      const { data, error } = await supabase.from('v_guide_themes').select('*');
      if (error) throw error;
      return data as GuideTheme[];
    },
  });
}

/**
 * Alle onderwerpen in één keer. Het zijn er enkele tientallen, dus dat kan
 * prima in één query; daarmee werken filteren op thema, "verder lezen" en het
 * lokale vangnet bij zoeken zonder extra netwerkverkeer.
 */
export function useGuideModules() {
  const { session } = useSession();
  return useQuery({
    queryKey: ['wegwijzer-modules', session?.user.id],
    enabled: !!session,
    staleTime: 5 * 60 * 1000,
    queryFn: async (): Promise<GuideModule[]> => {
      const { data, error } = await supabase.from('v_guide_modules').select('*');
      if (error) throw error;
      return data as GuideModule[];
    },
  });
}

export function useGuideModule(id: string | undefined) {
  const modules = useGuideModules();
  return modules.data?.find((module) => module.id === id || module.slug === id);
}

export function useGuideSections(moduleId: string | undefined) {
  return useQuery({
    queryKey: ['wegwijzer-secties', moduleId],
    enabled: !!moduleId,
    staleTime: 5 * 60 * 1000,
    queryFn: async (): Promise<GuideSection[]> => {
      const { data, error } = await supabase
        .from('guide_sections')
        .select('id, module_id, sortering, soort, titel, body')
        .eq('module_id', moduleId!)
        .order('sortering');
      if (error) throw error;
      return data as GuideSection[];
    },
  });
}

export function useGuideLinks(moduleId: string | undefined) {
  return useQuery({
    queryKey: ['wegwijzer-links', moduleId],
    enabled: !!moduleId,
    staleTime: 5 * 60 * 1000,
    queryFn: async (): Promise<GuideLink[]> => {
      const { data, error } = await supabase
        .from('guide_links')
        .select('id, module_id, sortering, titel, url')
        .eq('module_id', moduleId!)
        .order('sortering');
      if (error) throw error;
      return data as GuideLink[];
    },
  });
}

/** Wacht met zoeken tot er even niet getypt is. */
export function useDebounced(waarde: string, ms = 250): string {
  const [traag, setTraag] = useState(waarde);
  useEffect(() => {
    const timer = setTimeout(() => setTraag(waarde), ms);
    return () => clearTimeout(timer);
  }, [waarde, ms]);
  return traag;
}

/** Zoeken op de server: full-text, synoniemen en een vangnet voor typefouten. */
export function useGuideSearch(term: string) {
  const { session } = useSession();
  const schoon = normaliseer(term);
  return useQuery({
    queryKey: ['wegwijzer-zoek', schoon],
    enabled: !!session && magZoeken(schoon),
    staleTime: 60 * 1000,
    queryFn: async (): Promise<Zoektreffer[]> => {
      const { data, error } = await supabase.rpc('search_wegwijzer', { p_zoek: schoon });
      if (error) throw error;
      return (data ?? []) as Zoektreffer[];
    },
  });
}

/**
 * Direct antwoord op een getypte vraag. De server geeft alleen iets terug als
 * álle inhoudswoorden van de vraag in één onderdeel voorkomen; daardoor is
 * een gevonden antwoord betrouwbaar en zwijgt de kaart bij twijfel.
 */
export function useGuideAntwoord(term: string) {
  const { session } = useSession();
  const schoon = normaliseer(term);
  return useQuery({
    queryKey: ['wegwijzer-antwoord', schoon],
    enabled: !!session && magZoeken(schoon),
    staleTime: 60 * 1000,
    queryFn: async (): Promise<Antwoord[]> => {
      const { data, error } = await supabase.rpc('wegwijzer_antwoord', { p_vraag: schoon });
      if (error) throw error;
      return (data ?? []) as Antwoord[];
    },
  });
}

/** Suggesties onder het zoekveld, terwijl je typt. */
export function useGuideSuggesties(term: string) {
  const { session } = useSession();
  const schoon = normaliseer(term);
  return useQuery({
    queryKey: ['wegwijzer-suggesties', schoon],
    enabled: !!session && magZoeken(schoon),
    staleTime: 60 * 1000,
    queryFn: async (): Promise<Suggestie[]> => {
      const { data, error } = await supabase.rpc('wegwijzer_suggesties', { p_zoek: schoon });
      if (error) throw error;
      return (data ?? []) as Suggestie[];
    },
  });
}

/**
 * Anoniem bijhouden waarop gezocht is en hoeveel er gevonden werd, zodat we
 * zien welke onderwerpen nog ontbreken. Er gaat geen profielgegeven mee.
 */
export function useLogZoekopdracht() {
  return useMutation({
    mutationFn: async ({ term, resultaten }: { term: string; resultaten: number }) => {
      await supabase.rpc('log_guide_search', { p_zoek: term, p_resultaten: resultaten });
    },
  });
}

export function useGuideActions() {
  const queryClient = useQueryClient();
  const invalidate = () => {
    queryClient.invalidateQueries({ queryKey: ['wegwijzer-modules'] });
  };

  const bewaar = useMutation({
    mutationFn: async (moduleId: string): Promise<boolean> => {
      const { data, error } = await supabase.rpc('toggle_guide_bookmark', { p_module: moduleId });
      if (error) throw error;
      return data as boolean;
    },
    onSuccess: invalidate,
  });

  const markeerGelezen = useMutation({
    mutationFn: async (moduleId: string) => {
      const { error } = await supabase.rpc('mark_guide_read', { p_module: moduleId });
      if (error) throw error;
    },
    onSuccess: invalidate,
  });

  return { bewaar, markeerGelezen };
}

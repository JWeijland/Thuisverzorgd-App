import { useQuery } from '@tanstack/react-query';

import { supabase } from '@/lib/supabase';

export type MapCircle = {
  id: string;
  name: string;
  lat: number;
  lon: number;
  plekken_vrij: number;
};
export type MapBuddy = { id: string; voornaam: string; lat: number; lon: number };

export function useMapCircles() {
  return useQuery({
    queryKey: ['map-circles'],
    queryFn: async (): Promise<MapCircle[]> => {
      const { data, error } = await supabase
        .from('v_map_circles')
        .select('id, name, lat, lon, plekken_vrij');
      if (error) throw error;
      return data as MapCircle[];
    },
  });
}

export function useMapBuddies(enabled: boolean) {
  return useQuery({
    queryKey: ['map-buddies'],
    enabled,
    queryFn: async (): Promise<MapBuddy[]> => {
      const { data, error } = await supabase.from('v_map_buddies').select('id, voornaam, lat, lon');
      if (error) throw error;
      return data as MapBuddy[];
    },
  });
}

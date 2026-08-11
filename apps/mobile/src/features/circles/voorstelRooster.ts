import type { Dagdeel, KringAntwoorden, TaakSoort } from '@/features/circles/kringopbouw';
import { toDateString } from '@/lib/dates';

export type VoorstelTaak = {
  type: TaakSoort;
  date: string;
  time: string;
};

/** Vaste tijden per dagdeel; dezelfde als de snelkeuzes bij taak inplannen. */
const TIJD_PER_DAGDEEL: Record<Dagdeel, string> = {
  ochtend: '09:00',
  middag: '14:00',
  avond: '19:00',
};

/**
 * Bo's voorstel-rooster voor de proefweek (handoff §3e, stap 6).
 *
 * De regel is bewust simpel en uitlegbaar: elke gekozen taak krijgt één plek
 * in de week, verspreid over de dagen, in een dagdeel dat de kring heeft
 * aangevinkt. Zo staat er na de wizard meteen een week die klopt, en die de
 * kring in de proefweek nog kan ruilen.
 */
export function voorstelRooster(antwoorden: KringAntwoorden, start: Date): VoorstelTaak[] {
  const taken = antwoorden.taken ?? [];
  const dagdelen = antwoorden.dagdelen?.length ? antwoorden.dagdelen : (['ochtend'] as Dagdeel[]);
  if (taken.length === 0) return [];

  // De taken verdelen over de zeven dagen, met zoveel mogelijk ruimte ertussen.
  const stap = Math.max(1, Math.floor(7 / taken.length));

  return taken.map((taak, i) => {
    const dag = new Date(start);
    dag.setDate(dag.getDate() + Math.min(6, i * stap));
    const dagdeel = dagdelen[i % dagdelen.length]!;
    return { type: taak, date: toDateString(dag), time: TIJD_PER_DAGDEEL[dagdeel] };
  });
}

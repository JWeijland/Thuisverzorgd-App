import type { KringAntwoorden, TaakSoort } from '@/features/circles/kringopbouw';
import { toDateString } from '@/lib/dates';

export type VoorstelTaak = {
  type: TaakSoort;
  date: string;
  time: string;
};

/**
 * Een tijd die bij de taak past, zodat het voorstel meteen logisch aanvoelt:
 * boodschappen in de ochtend, koken tegen etenstijd, wandelen 's middags.
 * De kring kan alles nog verzetten; dit is alleen het startpunt.
 */
const TIJD_PER_TAAK: Record<TaakSoort, string> = {
  boodschappen: '10:00',
  wandelen: '14:00',
  vervoer: '10:00',
  koken: '17:30',
  gezelschap: '14:00',
  anders: '14:00',
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
  if (taken.length === 0) return [];

  // De taken verdelen over de zeven dagen, met zoveel mogelijk ruimte ertussen.
  const stap = Math.max(1, Math.floor(7 / taken.length));

  return taken.map((taak, i) => {
    const dag = new Date(start);
    dag.setDate(dag.getDate() + Math.min(6, i * stap));
    return { type: taak, date: toDateString(dag), time: TIJD_PER_TAAK[taak] };
  });
}

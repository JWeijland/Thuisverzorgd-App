/**
 * Pure agenda-logica voor de aanbieder (kapper, tuinman, ...), los van React
 * en Supabase zodat hij testbaar is. Weekdagen volgen isodow: ma=1 ... zo=7,
 * dezelfde nummering als de database.
 */

import {
  formatShortDate,
  formatTime,
  parseDateString,
  toDateString,
  WEEKDAY_FULL,
  WEEKDAY_SHORT,
} from '@/lib/dates';

export type WerkritmeDag = {
  weekday: number;
  /** Postgres time, bijv. "09:00:00". */
  start_time: string;
  end_time: string;
};

export type Afwezigheid = {
  id: string;
  /** yyyy-mm-dd */
  start_date: string;
  end_date: string;
};

/** De zeven dagen op volgorde, met isodow-nummer en labels. */
export const WEEKDAGEN = WEEKDAY_FULL.map((vol, index) => ({
  weekday: index + 1,
  kort: WEEKDAY_SHORT[index]!,
  vol: `${vol.charAt(0).toUpperCase()}${vol.slice(1)}`,
}));

/** De rij van een weekdag, of null als de dag dicht is. */
export function ritmeVoorDag(ritme: WerkritmeDag[], weekday: number): WerkritmeDag | null {
  return ritme.find((rij) => rij.weekday === weekday) ?? null;
}

/** "09:00 – 17:00" zoals op de werkritme-rij. */
export function blokLabel(rij: WerkritmeDag): string {
  return `${formatTime(rij.start_time)} – ${formatTime(rij.end_time)}`;
}

/** Eindtijd moet na de begintijd liggen ("HH:MM"). */
export function geldigBlok(start: string, eind: string): boolean {
  return eind > start;
}

/** "ma 24 aug t/m vr 28 aug", of één dag: "ma 24 aug". */
export function periodeLabel(startDate: string, endDate: string): string {
  const start = dagLabel(startDate);
  if (startDate === endDate) return start;
  return `${start} t/m ${dagLabel(endDate)}`;
}

/** "ma 24 aug" voor een yyyy-mm-dd-datum. */
export function dagLabel(dateString: string): string {
  const d = parseDateString(dateString);
  const kort = WEEKDAY_SHORT[(d.getDay() + 6) % 7]!.toLowerCase();
  return `${kort} ${formatShortDate(d)}`;
}

/** Een aantal dagen bij een yyyy-mm-dd optellen (mag negatief). */
export function schuifDag(dateString: string, dagen: number): string {
  const d = parseDateString(dateString);
  d.setDate(d.getDate() + dagen);
  return toDateString(d);
}

/** "10:00 – 10:45" voor een afspraak met een duur in minuten. */
export function afspraakTijden(slotIso: string, durationMin: number): string {
  const start = new Date(slotIso);
  const eind = new Date(start.getTime() + durationMin * 60_000);
  const tijd = (d: Date) =>
    `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
  return `${tijd(start)} – ${tijd(eind)}`;
}

/**
 * Afspraken (of andere momenten) per dag groeperen, op volgorde. De sleutel
 * is de lokale datum, zodat de agenda per dag een kopje kan tonen.
 */
export function groepeerPerDag<T extends { slot_at: string }>(
  items: T[],
): { datum: string; items: T[] }[] {
  const gesorteerd = [...items].sort(
    (a, b) => new Date(a.slot_at).getTime() - new Date(b.slot_at).getTime(),
  );
  const groepen: { datum: string; items: T[] }[] = [];
  for (const item of gesorteerd) {
    const datum = toDateString(new Date(item.slot_at));
    const laatste = groepen[groepen.length - 1];
    if (laatste && laatste.datum === datum) laatste.items.push(item);
    else groepen.push({ datum, items: [item] });
  }
  return groepen;
}

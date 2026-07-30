/**
 * Datumhelpers voor het rooster ("Rooster · week 31", weekstrip Ma–Zo).
 * Weeknummers volgen ISO 8601, zoals gebruikelijk in Nederland.
 */

export const WEEKDAY_SHORT = ['Ma', 'Di', 'Wo', 'Do', 'Vr', 'Za', 'Zo'] as const;

/** ISO 8601-weeknummer (week 1 = de week met de eerste donderdag van het jaar). */
export function isoWeekNumber(date: Date): number {
  const d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
  const day = d.getUTCDay() || 7; // zondag (0) → 7
  d.setUTCDate(d.getUTCDate() + 4 - day);
  const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
  return Math.ceil(((d.getTime() - yearStart.getTime()) / 86400000 + 1) / 7);
}

/** Sleutel voor beschikbaarheid per week, bijv. "2026-W31" (ISO-weekjaar). */
export function isoWeekKey(date: Date): string {
  const d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
  const day = d.getUTCDay() || 7;
  d.setUTCDate(d.getUTCDate() + 4 - day);
  return `${d.getUTCFullYear()}-W${`${isoWeekNumber(date)}`.padStart(2, '0')}`;
}

/** Maandag van de week waarin `date` valt (lokale tijd, 00:00). */
export function startOfIsoWeek(date: Date): Date {
  const d = new Date(date.getFullYear(), date.getMonth(), date.getDate());
  const day = d.getDay() || 7;
  d.setDate(d.getDate() - (day - 1));
  return d;
}

/** De zeven dagen (Ma t/m Zo) van de week waarin `date` valt. */
export function isoWeekDays(date: Date): Date[] {
  const monday = startOfIsoWeek(date);
  return WEEKDAY_SHORT.map((_, i) => {
    const d = new Date(monday);
    d.setDate(monday.getDate() + i);
    return d;
  });
}

export const WEEKDAY_FULL = [
  'maandag',
  'dinsdag',
  'woensdag',
  'donderdag',
  'vrijdag',
  'zaterdag',
  'zondag',
] as const;

export const MONTH_FULL = [
  'januari',
  'februari',
  'maart',
  'april',
  'mei',
  'juni',
  'juli',
  'augustus',
  'september',
  'oktober',
  'november',
  'december',
] as const;

/** "Donderdag 23 juli" — voor de begroetingsregel. */
export function formatHumanDate(date: Date): string {
  const day = WEEKDAY_FULL[(date.getDay() + 6) % 7]!;
  return `${day.charAt(0).toUpperCase()}${day.slice(1)} ${date.getDate()} ${MONTH_FULL[date.getMonth()]}`;
}

/** Kort daglabel bij een taakrij: "Ma" + "27 jul". */
export function formatShortDate(date: Date): string {
  return `${date.getDate()} ${MONTH_FULL[date.getMonth()]!.slice(0, 3)}`;
}

/** "dinsdag 5 augustus · 19:00" — voor bijeenkomsten met datum én tijd. */
export function formatMoment(iso: string): string {
  const d = new Date(iso);
  const dag = WEEKDAY_FULL[(d.getDay() + 6) % 7]!;
  const uur = `${d.getHours()}`.padStart(2, '0');
  const min = `${d.getMinutes()}`.padStart(2, '0');
  return `${dag.charAt(0).toUpperCase()}${dag.slice(1)} ${d.getDate()} ${MONTH_FULL[d.getMonth()]} · ${uur}:${min}`;
}

/** "14:00:00" (Postgres time) → "14:00". */
export function formatTime(time: string): string {
  return time.slice(0, 5);
}

/** yyyy-mm-dd in lokale tijd (Postgres date-kolom). */
export function toDateString(date: Date): string {
  const m = `${date.getMonth() + 1}`.padStart(2, '0');
  const d = `${date.getDate()}`.padStart(2, '0');
  return `${date.getFullYear()}-${m}-${d}`;
}

export function parseDateString(value: string): Date {
  const [y, m, d] = value.split('-').map(Number);
  return new Date(y!, m! - 1, d!);
}

/** Begroeting op basis van het uur: goedemorgen / goedemiddag / goedenavond. */
export function greetingKey(hour: number): 'goedemorgen' | 'goedemiddag' | 'goedenavond' {
  if (hour < 12) return 'goedemorgen';
  if (hour < 18) return 'goedemiddag';
  return 'goedenavond';
}

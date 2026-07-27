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

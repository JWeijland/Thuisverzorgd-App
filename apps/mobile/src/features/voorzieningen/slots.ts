import { WEEKDAY_SHORT } from '@/lib/dates';

export type Tijdslot = {
  /** ISO-tijdstip, gaat mee de database in. */
  iso: string;
  /** Zoals op de radio-lijst en de boekknop: "di 10:00". */
  label: string;
  /** Het eerste slot krijgt het label "snelst". */
  snelst: boolean;
};

/** "di 10:00", kleine letters zoals in het prototype. */
export function slotLabel(date: Date): string {
  const dag = WEEKDAY_SHORT[(date.getDay() + 6) % 7]!.toLowerCase();
  const uren = String(date.getHours()).padStart(2, '0');
  const minuten = String(date.getMinutes()).padStart(2, '0');
  return `${dag} ${uren}:${minuten}`;
}

/**
 * De komende tijdsloten voor een dienst. Aanbieders hebben in de pilot nog
 * geen echte agenda, dus we bieden vaste momenten aan: morgen om 10:00 en
 * 14:00, overmorgen om 10:00 en 16:00.
 */
export function maakSlots(nu: Date): Tijdslot[] {
  const momenten: { dagen: number; uur: number }[] = [
    { dagen: 1, uur: 10 },
    { dagen: 1, uur: 14 },
    { dagen: 2, uur: 10 },
    { dagen: 2, uur: 16 },
  ];
  return momenten.map(({ dagen, uur }, index) => {
    const d = new Date(nu);
    d.setDate(d.getDate() + dagen);
    d.setHours(uur, 0, 0, 0);
    return { iso: d.toISOString(), label: slotLabel(d), snelst: index === 0 };
  });
}

/** €29 of €22,50 (zonder spatie, zoals in de handoff). */
export function euro(cents: number): string {
  const heel = Math.floor(cents / 100);
  const rest = cents % 100;
  return rest === 0 ? `€${heel}` : `€${heel},${String(rest).padStart(2, '0')}`;
}

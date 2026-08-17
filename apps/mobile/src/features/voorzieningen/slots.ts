import { formatShortDate, WEEKDAY_SHORT } from '@/lib/dates';

export type Tijdslot = {
  /** ISO-tijdstip, gaat mee de database in. */
  iso: string;
  /** Alleen de tijd, voor de lijst binnen een dag: "10:00". */
  tijd: string;
  /** Zoals op de boekknop: "di 10:00". */
  label: string;
};

export type SlotDag = {
  /** Sleutel van de dag (yyyy-mm-dd, lokale tijd). */
  datum: string;
  /** Zoals op het dagschuifje: "di 18 aug". */
  label: string;
  tijden: Tijdslot[];
};

/** "di 10:00", kleine letters zoals in het prototype. */
export function slotLabel(date: Date): string {
  const dag = WEEKDAY_SHORT[(date.getDay() + 6) % 7]!.toLowerCase();
  return `${dag} ${tijdLabel(date)}`;
}

function tijdLabel(date: Date): string {
  const uren = String(date.getHours()).padStart(2, '0');
  const minuten = String(date.getMinutes()).padStart(2, '0');
  return `${uren}:${minuten}`;
}

/**
 * De beschikbare momenten uit de database (RPC `beschikbare_slots`) gegroepeerd
 * per dag, voor de dagschuifjes met daaronder de tijden van die dag. De
 * volgorde van de RPC (oplopend) blijft bewaard.
 */
export function groepeerSlots(isoMomenten: string[]): SlotDag[] {
  const dagen: SlotDag[] = [];
  for (const iso of isoMomenten) {
    const d = new Date(iso);
    const datum = `${d.getFullYear()}-${`${d.getMonth() + 1}`.padStart(2, '0')}-${`${d.getDate()}`.padStart(2, '0')}`;
    const slot: Tijdslot = { iso, tijd: tijdLabel(d), label: slotLabel(d) };
    const laatste = dagen[dagen.length - 1];
    if (laatste && laatste.datum === datum) {
      laatste.tijden.push(slot);
    } else {
      const kort = WEEKDAY_SHORT[(d.getDay() + 6) % 7]!.toLowerCase();
      dagen.push({ datum, label: `${kort} ${formatShortDate(d)}`, tijden: [slot] });
    }
  }
  return dagen;
}

/** €29 of €22,50 (zonder spatie, zoals in de handoff). */
export function euro(cents: number): string {
  const heel = Math.floor(cents / 100);
  const rest = cents % 100;
  return rest === 0 ? `€${heel}` : `€${heel},${String(rest).padStart(2, '0')}`;
}

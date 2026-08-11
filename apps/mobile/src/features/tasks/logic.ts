import { t } from '@/i18n';
import type { Task } from '@/features/tasks/api';

/** Label van een taak: het type, of de vrije invoer bij "Anders". */
export function taskLabel(task: Pick<Task, 'type' | 'custom_label'>): string {
  if (task.type === 'anders' && task.custom_label) return task.custom_label;
  return taakSoortLabel(task.type);
}

/** Label van een taaksoort ("boodschappen" → "Boodschappen"). */
export function taakSoortLabel(type: string): string {
  return t(`planner.type${type.charAt(0).toUpperCase()}${type.slice(1)}`);
}

export type DayDot = 'open' | 'ingepland' | 'dienst';

/**
 * Stipjes in de weekstrip, de rode draad van de app: oranje = nog open,
 * groen = een buddy gaat (ingepland/gedaan), kringblauw = geboekte dienst.
 * `boekingDagen` zijn de datumsleutels (yyyy-mm-dd) van geboekte diensten.
 * Maximaal 3 stipjes per dag, taken eerst.
 */
export function dayDots(tasks: Task[], dateKey: string, boekingDagen: string[] = []): DayDot[] {
  const taakDots: DayDot[] = tasks
    .filter((task) => task.date === dateKey && task.status !== 'geannuleerd')
    .map((task) => (task.status === 'open' ? 'open' : 'ingepland'));
  const dienstDots: DayDot[] = boekingDagen
    .filter((dag) => dag === dateKey)
    .map(() => 'dienst' as const);
  return [...taakDots, ...dienstDots].slice(0, 3);
}

export type WorkloadRow = { profileId: string; name: string; count: number };

/**
 * "Wie doet wat deze maand?": geclaimde/afgeronde taken per vrijwilliger in de
 * maand van `now`, aflopend gesorteerd.
 */
export function computeWorkload(
  tasks: Pick<Task, 'claimed_by' | 'claimer' | 'date' | 'status'>[],
  now: Date,
): WorkloadRow[] {
  const monthPrefix = `${now.getFullYear()}-${`${now.getMonth() + 1}`.padStart(2, '0')}`;
  const counts = new Map<string, WorkloadRow>();
  for (const task of tasks) {
    if (!task.claimed_by || !task.claimer) continue;
    if (!task.date.startsWith(monthPrefix)) continue;
    if (task.status === 'geannuleerd') continue;
    const row = counts.get(task.claimed_by) ?? {
      profileId: task.claimed_by,
      name: task.claimer.name.split(' ')[0] ?? task.claimer.name,
      count: 0,
    };
    row.count += 1;
    counts.set(task.claimed_by, row);
  }
  return [...counts.values()].sort((a, b) => b.count - a.count);
}

/** Hoe lang een taak ongeveer duurt; hetzelfde als "± 1 uur" in de rooster-rij. */
export const TAAK_DUUR_MIN = 60;

function minutenVanaf(tijd: string): number {
  const [uur, minuut] = tijd.split(':');
  return Number(uur) * 60 + Number(minuut ?? 0);
}

/**
 * Taken die elkaar in de tijd overlappen (wens Jelle 11-08): twee dingen op
 * dezelfde dag binnen een uur van elkaar kunnen niet allebei door dezelfde
 * persoon gedaan worden, en ook voor de hulpvrager is het te veel tegelijk.
 * Geeft de ids terug van elke taak die met minstens één andere botst.
 *
 * `boekingen` zijn geboekte voorzieningen als {id, date, time}: een klusjesman
 * en een buddy tegelijk over de vloer is net zo goed dubbel geboekt.
 */
export function overlappendeTaken(
  taken: Pick<Task, 'id' | 'date' | 'time' | 'status'>[],
  boekingen: { id: string; date: string; time: string }[] = [],
): Set<string> {
  const items = [
    ...taken
      .filter((taak) => taak.status !== 'geannuleerd' && taak.status !== 'gedaan')
      .map((taak) => ({ id: taak.id, date: taak.date, start: minutenVanaf(taak.time) })),
    ...boekingen.map((boeking) => ({
      id: boeking.id,
      date: boeking.date,
      start: minutenVanaf(boeking.time),
    })),
  ];

  const botsend = new Set<string>();
  for (let i = 0; i < items.length; i += 1) {
    for (let j = i + 1; j < items.length; j += 1) {
      const a = items[i]!;
      const b = items[j]!;
      if (a.date !== b.date) continue;
      if (Math.abs(a.start - b.start) >= TAAK_DUUR_MIN) continue;
      botsend.add(a.id);
      botsend.add(b.id);
    }
  }
  return botsend;
}

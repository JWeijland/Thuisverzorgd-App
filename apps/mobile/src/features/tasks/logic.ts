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

import { t } from '@/i18n';
import type { Task } from '@/features/tasks/api';

/** Label van een taak: het type, of de vrije invoer bij "Anders". */
export function taskLabel(task: Pick<Task, 'type' | 'custom_label'>): string {
  if (task.type === 'anders' && task.custom_label) return task.custom_label;
  return t(`planner.type${task.type.charAt(0).toUpperCase()}${task.type.slice(1)}`);
}

export type DayDot = 'open' | 'ingepland';

/** Stipjes in de weekstrip: oranje = open, groen = ingepland/gedaan (max 3 per dag). */
export function dayDots(tasks: Task[], dateKey: string): DayDot[] {
  return tasks
    .filter((task) => task.date === dateKey && task.status !== 'geannuleerd')
    .slice(0, 3)
    .map((task) => (task.status === 'open' ? 'open' : 'ingepland'));
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

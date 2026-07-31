import type { Task } from '@/features/tasks/api';
import { computeWorkload, dayDots, taskLabel } from '@/features/tasks/logic';

const base = {
  id: 'x',
  circle_id: 'c',
  time: '14:00:00',
  recurrence: 'eenmalig',
  custom_label: null,
  claimed_by: null,
  claimer: null,
} as const;

function task(partial: Partial<Task>): Task {
  return { ...base, type: 'boodschappen', date: '2026-07-30', status: 'open', ...partial } as Task;
}

describe('taskLabel', () => {
  it('gebruikt de vrije invoer bij "Anders"', () => {
    expect(taskLabel({ type: 'anders', custom_label: 'Plantjes water geven' })).toBe(
      'Plantjes water geven',
    );
  });
  it('vertaalt het type', () => {
    expect(taskLabel({ type: 'boodschappen', custom_label: null })).toBe('Boodschappen');
    expect(taskLabel({ type: 'vervoer', custom_label: null })).toBe('Vervoer');
  });
});

describe('dayDots', () => {
  it('oranje voor open, groen voor ingepland/gedaan, max 3', () => {
    const tasks = [
      task({ status: 'open' }),
      task({ status: 'ingepland' }),
      task({ status: 'gedaan' }),
      task({ status: 'open' }),
    ];
    expect(dayDots(tasks, '2026-07-30')).toEqual(['open', 'ingepland', 'ingepland']);
    expect(dayDots(tasks, '2026-07-31')).toEqual([]);
  });
});

describe('computeWorkload', () => {
  it('telt per vrijwilliger binnen de maand en sorteert aflopend', () => {
    const anna = { id: 'a', name: 'Anna de Wit', phone: null, avatar_path: null };
    const tim = { id: 't', name: 'Tim Bakker', phone: null, avatar_path: null };
    const tasks = [
      task({ claimed_by: 'a', claimer: anna, status: 'gedaan', date: '2026-07-01' }),
      task({ claimed_by: 'a', claimer: anna, status: 'ingepland', date: '2026-07-20' }),
      task({ claimed_by: 't', claimer: tim, status: 'gedaan', date: '2026-07-05' }),
      // andere maand telt niet mee
      task({ claimed_by: 't', claimer: tim, status: 'gedaan', date: '2026-06-05' }),
    ];
    const rows = computeWorkload(tasks, new Date(2026, 6, 23));
    expect(rows).toEqual([
      { profileId: 'a', name: 'Anna', count: 2 },
      { profileId: 't', name: 'Tim', count: 1 },
    ]);
  });
});

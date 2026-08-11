import { overlappendeTaken } from '@/features/tasks/logic';

const taak = (id: string, date: string, time: string, status = 'ingepland') =>
  ({ id, date, time, status }) as never;

describe('overlappendeTaken', () => {
  it('ziet twee taken binnen een uur als overlap', () => {
    const gevonden = overlappendeTaken([
      taak('a', '2026-08-12', '10:00'),
      taak('b', '2026-08-12', '10:30'),
    ]);
    expect([...gevonden].sort()).toEqual(['a', 'b']);
  });

  it('laat taken die ver genoeg uit elkaar liggen met rust', () => {
    const gevonden = overlappendeTaken([
      taak('a', '2026-08-12', '10:00'),
      taak('b', '2026-08-12', '11:00'),
    ]);
    expect(gevonden.size).toBe(0);
  });

  it('kijkt per dag', () => {
    const gevonden = overlappendeTaken([
      taak('a', '2026-08-12', '10:00'),
      taak('b', '2026-08-13', '10:15'),
    ]);
    expect(gevonden.size).toBe(0);
  });

  it('negeert geannuleerde en afgeronde taken', () => {
    const gevonden = overlappendeTaken([
      taak('a', '2026-08-12', '10:00', 'geannuleerd'),
      taak('b', '2026-08-12', '10:15', 'gedaan'),
      taak('c', '2026-08-12', '10:20'),
    ]);
    expect(gevonden.size).toBe(0);
  });

  it('telt een geboekte voorziening mee', () => {
    const gevonden = overlappendeTaken(
      [taak('a', '2026-08-12', '14:00')],
      [{ id: 'dienst', date: '2026-08-12', time: '14:30' }],
    );
    expect([...gevonden].sort()).toEqual(['a', 'dienst']);
  });
});

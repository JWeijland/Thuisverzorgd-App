import { euro, groepeerSlots, slotLabel } from '@/features/voorzieningen/slots';

describe('groepeerSlots', () => {
  const iso = (dag: number, uur: number, minuut = 0) =>
    new Date(2026, 7, dag, uur, minuut).toISOString();

  test('groepeert momenten per dag, op volgorde', () => {
    const dagen = groepeerSlots([
      iso(18, 10),
      iso(18, 10, 30),
      iso(18, 14),
      iso(19, 9),
      iso(21, 16),
    ]);
    expect(dagen.map((dag) => dag.label)).toEqual(['di 18 aug', 'wo 19 aug', 'vr 21 aug']);
    expect(dagen[0]!.tijden.map((slot) => slot.tijd)).toEqual(['10:00', '10:30', '14:00']);
    expect(dagen[1]!.tijden).toHaveLength(1);
  });

  test('slots dragen de volledige boeklabel mee', () => {
    const dagen = groepeerSlots([iso(18, 10)]);
    expect(dagen[0]!.tijden[0]!.label).toBe('di 10:00');
    expect(dagen[0]!.tijden[0]!.iso).toBe(iso(18, 10));
  });

  test('leeg blijft leeg', () => {
    expect(groepeerSlots([])).toEqual([]);
  });
});

describe('slotLabel', () => {
  test('weekdag in kleine letters met tijd', () => {
    expect(slotLabel(new Date(2026, 7, 11, 10, 0))).toBe('di 10:00');
    expect(slotLabel(new Date(2026, 7, 5, 14, 5))).toBe('wo 14:05');
  });
});

describe('euro', () => {
  test('hele euro’s zonder centen', () => {
    expect(euro(2900)).toBe('€29');
    expect(euro(700)).toBe('€7');
  });

  test('centen met komma en voorloopnul', () => {
    expect(euro(2250)).toBe('€22,50');
    expect(euro(905)).toBe('€9,05');
  });
});

import { euro, maakSlots, slotLabel } from '@/features/voorzieningen/slots';

describe('maakSlots', () => {
  // Woensdag 5 augustus 2026, halverwege de ochtend.
  const nu = new Date(2026, 7, 5, 9, 30);

  test('vier vaste momenten: morgen 10:00 en 14:00, overmorgen 10:00 en 16:00', () => {
    const slots = maakSlots(nu);
    expect(slots.map((slot) => slot.label)).toEqual([
      'do 10:00',
      'do 14:00',
      'vr 10:00',
      'vr 16:00',
    ]);
  });

  test('alleen het eerste slot heet "snelst"', () => {
    const slots = maakSlots(nu);
    expect(slots[0]!.snelst).toBe(true);
    expect(slots.filter((slot) => slot.snelst)).toHaveLength(1);
  });

  test('alle slots liggen in de toekomst', () => {
    for (const slot of maakSlots(nu)) {
      expect(new Date(slot.iso).getTime()).toBeGreaterThan(nu.getTime());
    }
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

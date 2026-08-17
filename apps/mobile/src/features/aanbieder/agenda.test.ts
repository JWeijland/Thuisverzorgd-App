import {
  afspraakTijden,
  blokLabel,
  dagLabel,
  geldigBlok,
  groepeerPerDag,
  periodeLabel,
  ritmeVoorDag,
  schuifDag,
  WEEKDAGEN,
} from '@/features/aanbieder/agenda';

describe('WEEKDAGEN', () => {
  test('zeven dagen, isodow-nummering, maandag eerst', () => {
    expect(WEEKDAGEN).toHaveLength(7);
    expect(WEEKDAGEN[0]).toEqual({ weekday: 1, kort: 'Ma', vol: 'Maandag' });
    expect(WEEKDAGEN[6]).toEqual({ weekday: 7, kort: 'Zo', vol: 'Zondag' });
  });
});

describe('ritmeVoorDag en blokLabel', () => {
  const ritme = [{ weekday: 2, start_time: '09:00:00', end_time: '17:30:00' }];

  test('vindt de rij van een open dag', () => {
    expect(ritmeVoorDag(ritme, 2)).not.toBeNull();
    expect(ritmeVoorDag(ritme, 3)).toBeNull();
  });

  test('toont het blok zonder seconden', () => {
    expect(blokLabel(ritme[0]!)).toBe('09:00 – 17:30');
  });
});

describe('geldigBlok', () => {
  test('eind na start is geldig, gelijk of eerder niet', () => {
    expect(geldigBlok('09:00', '17:00')).toBe(true);
    expect(geldigBlok('09:00', '09:00')).toBe(false);
    expect(geldigBlok('17:00', '09:00')).toBe(false);
  });
});

describe('datums', () => {
  test('dagLabel: "ma 24 aug"', () => {
    // 24 augustus 2026 is een maandag.
    expect(dagLabel('2026-08-24')).toBe('ma 24 aug');
  });

  test('periodeLabel: één dag of van t/m', () => {
    expect(periodeLabel('2026-08-24', '2026-08-24')).toBe('ma 24 aug');
    expect(periodeLabel('2026-08-24', '2026-08-28')).toBe('ma 24 aug t/m vr 28 aug');
  });

  test('schuifDag telt dagen op, ook over een maandgrens', () => {
    expect(schuifDag('2026-08-30', 2)).toBe('2026-09-01');
    expect(schuifDag('2026-09-01', -1)).toBe('2026-08-31');
  });
});

describe('afspraakTijden', () => {
  test('start en eind uit de duur van de dienst', () => {
    const iso = new Date(2026, 7, 18, 10, 0).toISOString();
    expect(afspraakTijden(iso, 45)).toBe('10:00 – 10:45');
    expect(afspraakTijden(iso, 120)).toBe('10:00 – 12:00');
  });
});

describe('groepeerPerDag', () => {
  const om = (dag: number, uur: number) => ({
    slot_at: new Date(2026, 7, dag, uur, 0).toISOString(),
  });

  test('groepeert op lokale datum en sorteert op tijd', () => {
    const groepen = groepeerPerDag([om(19, 9), om(18, 14), om(18, 10)]);
    expect(groepen.map((groep) => groep.datum)).toEqual(['2026-08-18', '2026-08-19']);
    expect(groepen[0]!.items.map((item) => new Date(item.slot_at).getHours())).toEqual([10, 14]);
  });

  test('leeg blijft leeg', () => {
    expect(groepeerPerDag([])).toEqual([]);
  });
});

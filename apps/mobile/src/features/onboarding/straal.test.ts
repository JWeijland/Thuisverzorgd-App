import {
  STRAAL_OPTIES,
  STRAAL_STANDAARD,
  VERVAGING_MARGE_M,
  binnenStraal,
  dichtstbijzijndeStraal,
  straalLabel,
} from '@/features/onboarding/straal';

describe('straalLabel', () => {
  it('toont meters onder de kilometer', () => {
    expect(straalLabel(300)).toBe('300 m');
    expect(straalLabel(500)).toBe('500 m');
  });

  it('toont hele kilometers zonder komma', () => {
    expect(straalLabel(1000)).toBe('1 km');
    expect(straalLabel(25000)).toBe('25 km');
  });

  it('gebruikt een komma bij halve kilometers', () => {
    expect(straalLabel(1500)).toBe('1,5 km');
  });
});

describe('dichtstbijzijndeStraal', () => {
  it('valt terug op de standaard van 300 meter', () => {
    expect(dichtstbijzijndeStraal(null)).toBe(STRAAL_STANDAARD);
    expect(dichtstbijzijndeStraal(undefined)).toBe(300);
  });

  it('kiest de dichtstbijzijnde keuze bij een afwijkende waarde', () => {
    expect(dichtstbijzijndeStraal(400)).toBe(300);
    expect(dichtstbijzijndeStraal(450)).toBe(500);
    expect(dichtstbijzijndeStraal(99999)).toBe(25000);
  });

  it('laat bestaande keuzes ongemoeid', () => {
    for (const optie of STRAAL_OPTIES) {
      expect(dichtstbijzijndeStraal(optie)).toBe(optie);
    }
  });
});

describe('binnenStraal', () => {
  it('telt de vervagingsmarge mee', () => {
    // Locaties zijn ~1 km vervaagd; zonder marge zou je bij 300 meter je
    // buurvrouw kunnen mislopen puur door de afronding.
    expect(binnenStraal(1.4, 300)).toBe(true);
    expect(binnenStraal(1.6, 300)).toBe(false);
  });

  it('houdt grote stralen ruim', () => {
    expect(binnenStraal(20, 25000)).toBe(true);
    expect(binnenStraal(30, 25000)).toBe(false);
  });

  it('toont liever te veel dan niets bij een onbekende afstand', () => {
    expect(binnenStraal(null, 300)).toBe(true);
    expect(binnenStraal(undefined, 300)).toBe(true);
  });

  it('gebruikt dezelfde marge als de database', () => {
    expect(VERVAGING_MARGE_M).toBe(1200);
  });
});

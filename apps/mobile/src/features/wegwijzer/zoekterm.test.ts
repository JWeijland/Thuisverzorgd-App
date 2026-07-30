import { filterLokaal, magZoeken, normaliseer, splitsTreffer } from '@/features/wegwijzer/zoekterm';

describe('normaliseer', () => {
  it('haalt hoofdletters, accenten en dubbele spaties weg', () => {
    expect(normaliseer('  Financiën   REGELEN ')).toBe('financien regelen');
  });

  it('laat een gewone term ongemoeid', () => {
    expect(normaliseer('mantelwoning')).toBe('mantelwoning');
  });
});

describe('magZoeken', () => {
  it('zoekt pas vanaf twee tekens', () => {
    expect(magZoeken('m')).toBe(false);
    expect(magZoeken(' m ')).toBe(false);
    expect(magZoeken('wo')).toBe(true);
  });
});

describe('splitsTreffer', () => {
  it('knipt het gemarkeerde woord eruit', () => {
    expect(splitsTreffer('Een «mantelzorgwoning» in de tuin')).toEqual([
      { text: 'Een ', raak: false },
      { text: 'mantelzorgwoning', raak: true },
      { text: ' in de tuin', raak: false },
    ]);
  });

  it('kan meerdere markeringen aan', () => {
    const delen = splitsTreffer('«zorg» en nog eens «zorg»');
    expect(delen.filter((deel) => deel.raak).map((deel) => deel.text)).toEqual(['zorg', 'zorg']);
  });

  it('geeft een lege lijst zonder treffer', () => {
    expect(splitsTreffer(null)).toEqual([]);
    expect(splitsTreffer(undefined)).toEqual([]);
  });

  it('laat tekst zonder markering heel', () => {
    expect(splitsTreffer('gewone samenvatting')).toEqual([
      { text: 'gewone samenvatting', raak: false },
    ]);
  });
});

describe('filterLokaal', () => {
  const modules = [
    {
      titel: 'Mantelzorgwoning: een woning in de tuin',
      samenvatting: 'Een aparte woonruimte bij je huis.',
      zoektermen: ['mantelwoning', 'kangoeroewoning', 'unit in de tuin'],
    },
    {
      titel: 'Kortdurend zorgverlof',
      samenvatting: 'Verlof voor noodzakelijke zorg aan een naaste.',
      zoektermen: ['zorgverlof', 'vrij vragen werk'],
    },
  ];

  it('vindt een onderwerp via zijn synoniem', () => {
    // Precies de reden dat synoniemen bestaan: de Nederlandse stemmer knipt
    // "mantelwoning" niet los uit "mantelzorgwoning".
    expect(filterLokaal(modules, 'mantelwoning')).toHaveLength(1);
    expect(filterLokaal(modules, 'mantelwoning')[0]!.titel).toContain('Mantelzorgwoning');
  });

  it('zoekt op alle ingetypte woorden tegelijk', () => {
    expect(filterLokaal(modules, 'woning tuin')).toHaveLength(1);
    expect(filterLokaal(modules, 'woning zorgverlof')).toHaveLength(0);
  });

  it('trekt zich niets aan van hoofdletters en accenten', () => {
    expect(filterLokaal(modules, 'ZORGVERLOF')).toHaveLength(1);
  });

  it('zoekt niet bij één teken', () => {
    expect(filterLokaal(modules, 'm')).toEqual([]);
  });
});

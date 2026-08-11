import { voorstelRooster } from '@/features/circles/voorstelRooster';

const maandag = new Date(2026, 7, 10);

describe('voorstelRooster', () => {
  it('geeft niets terug zonder gekozen taken', () => {
    expect(voorstelRooster({}, maandag)).toEqual([]);
    expect(voorstelRooster({ taken: [] }, maandag)).toEqual([]);
  });

  it('zet elke taak één keer in de week', () => {
    const rooster = voorstelRooster(
      { taken: ['boodschappen', 'wandelen', 'gezelschap'], dagdelen: ['ochtend'] },
      maandag,
    );
    expect(rooster).toHaveLength(3);
    expect(rooster.map((taak) => taak.type)).toEqual(['boodschappen', 'wandelen', 'gezelschap']);
  });

  it('verspreidt de taken over de dagen en blijft binnen de week', () => {
    const rooster = voorstelRooster(
      { taken: ['boodschappen', 'wandelen'], dagdelen: ['ochtend'] },
      maandag,
    );
    expect(rooster[0]!.date).toBe('2026-08-10');
    expect(rooster[1]!.date).toBe('2026-08-13');

    const vol = voorstelRooster(
      { taken: ['boodschappen', 'wandelen', 'vervoer', 'koken', 'gezelschap', 'anders'] },
      maandag,
    );
    expect(vol.every((taak) => taak.date <= '2026-08-16')).toBe(true);
  });

  it('wisselt de dagdelen af die de kring heeft aangevinkt', () => {
    const rooster = voorstelRooster(
      { taken: ['boodschappen', 'wandelen', 'vervoer'], dagdelen: ['ochtend', 'avond'] },
      maandag,
    );
    expect(rooster.map((taak) => taak.time)).toEqual(['09:00', '19:00', '09:00']);
  });

  it('kiest de ochtend als er geen dagdeel is gekozen', () => {
    const rooster = voorstelRooster({ taken: ['koken'] }, maandag);
    expect(rooster[0]!.time).toBe('09:00');
  });
});

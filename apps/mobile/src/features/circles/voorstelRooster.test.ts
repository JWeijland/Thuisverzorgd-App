import { voorstelRooster } from '@/features/circles/voorstelRooster';

const maandag = new Date(2026, 7, 10);

describe('voorstelRooster', () => {
  it('geeft niets terug zonder gekozen taken', () => {
    expect(voorstelRooster({}, maandag)).toEqual([]);
    expect(voorstelRooster({ taken: [] }, maandag)).toEqual([]);
  });

  it('zet elke taak één keer in de week', () => {
    const rooster = voorstelRooster({ taken: ['boodschappen', 'wandelen', 'gezelschap'] }, maandag);
    expect(rooster).toHaveLength(3);
    expect(rooster.map((taak) => taak.type)).toEqual(['boodschappen', 'wandelen', 'gezelschap']);
  });

  it('verspreidt de taken over de dagen en blijft binnen de week', () => {
    const rooster = voorstelRooster({ taken: ['boodschappen', 'wandelen'] }, maandag);
    expect(rooster[0]!.date).toBe('2026-08-10');
    expect(rooster[1]!.date).toBe('2026-08-13');

    const vol = voorstelRooster(
      { taken: ['boodschappen', 'wandelen', 'vervoer', 'koken', 'gezelschap', 'anders'] },
      maandag,
    );
    expect(vol.every((taak) => taak.date <= '2026-08-16')).toBe(true);
  });

  it('geeft elke taak een tijd die bij die taak past', () => {
    const rooster = voorstelRooster({ taken: ['boodschappen', 'koken', 'wandelen'] }, maandag);
    expect(rooster.map((taak) => taak.time)).toEqual(['10:00', '17:30', '14:00']);
  });
});

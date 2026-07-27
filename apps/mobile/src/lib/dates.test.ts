import { isoWeekDays, isoWeekNumber, startOfIsoWeek, WEEKDAY_SHORT } from '@/lib/dates';

describe('isoWeekNumber', () => {
  it('geeft week 31 voor donderdag 23 juli 2026 (de demo-datum uit de handoff)', () => {
    expect(isoWeekNumber(new Date(2026, 6, 23))).toBe(30);
    expect(isoWeekNumber(new Date(2026, 6, 27))).toBe(31);
  });

  it('handelt jaargrenzen af volgens ISO 8601', () => {
    expect(isoWeekNumber(new Date(2026, 0, 1))).toBe(1); // do 1 jan 2026
    expect(isoWeekNumber(new Date(2027, 0, 1))).toBe(53); // vr 1 jan 2027 hoort bij week 53 van 2026
    expect(isoWeekNumber(new Date(2027, 0, 4))).toBe(1); // ma 4 jan 2027
  });
});

describe('startOfIsoWeek', () => {
  it('geeft de maandag van de week, ook op zondag', () => {
    const sunday = new Date(2026, 7, 2); // zo 2 aug 2026
    expect(startOfIsoWeek(sunday).getDate()).toBe(27); // ma 27 jul
  });
});

describe('isoWeekDays', () => {
  it('geeft zeven opeenvolgende dagen van maandag t/m zondag', () => {
    const days = isoWeekDays(new Date(2026, 6, 29));
    expect(days).toHaveLength(7);
    expect(days[0]!.getDay()).toBe(1);
    expect(days[6]!.getDay()).toBe(0);
    expect(WEEKDAY_SHORT[0]).toBe('Ma');
  });
});

import { isVolledigeKoppelcode, netteKoppelcode } from '@/features/circles/koppelcode';

describe('netteKoppelcode', () => {
  it('zet het voorvoegsel er zelf voor', () => {
    expect(netteKoppelcode('4q7b')).toBe('TVZ-4Q7B');
    expect(netteKoppelcode('4')).toBe('TVZ-4');
  });

  it('slikt een geplakte code met of zonder streepje', () => {
    expect(netteKoppelcode('TVZ-4Q7B')).toBe('TVZ-4Q7B');
    expect(netteKoppelcode('tvz4q7b')).toBe('TVZ-4Q7B');
    expect(netteKoppelcode(' TVZ - 4Q7B ')).toBe('TVZ-4Q7B');
  });

  it('gooit tekens weg die er niet in horen en stopt na vier', () => {
    expect(netteKoppelcode('4q7b9xz')).toBe('TVZ-4Q7B');
    expect(netteKoppelcode('4q.7b')).toBe('TVZ-4Q7B');
  });

  it('geeft niets terug bij een leeg veld', () => {
    expect(netteKoppelcode('')).toBe('');
    expect(netteKoppelcode('TVZ-')).toBe('');
  });
});

describe('isVolledigeKoppelcode', () => {
  it('herkent een volledige code', () => {
    expect(isVolledigeKoppelcode('TVZ-4Q7B')).toBe(true);
  });

  it('wijst een halve code af', () => {
    expect(isVolledigeKoppelcode('TVZ-4Q7')).toBe(false);
    expect(isVolledigeKoppelcode('')).toBe(false);
    expect(isVolledigeKoppelcode('4Q7B')).toBe(false);
  });
});

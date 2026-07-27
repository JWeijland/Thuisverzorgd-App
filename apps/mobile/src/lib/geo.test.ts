import { countInRegion, formatDistance, haversineKm, isInRegion } from '@/lib/geo';

describe('haversineKm', () => {
  it('Amsterdam–Utrecht is ongeveer 35 km', () => {
    const km = haversineKm({ lat: 52.3676, lon: 4.9041 }, { lat: 52.0907, lon: 5.1214 });
    expect(km).toBeGreaterThan(30);
    expect(km).toBeLessThan(40);
  });
});

describe('formatDistance', () => {
  it('meters onder de kilometer, komma-notatie daarboven', () => {
    expect(formatDistance(0.65)).toBe('650 m');
    expect(formatDistance(2.14)).toBe('2,1 km');
  });
});

describe('regio-teller', () => {
  const region = { latitude: 52.37, longitude: 4.9, latitudeDelta: 0.1, longitudeDelta: 0.1 };
  it('telt alleen punten in beeld', () => {
    expect(isInRegion({ lat: 52.37, lon: 4.9 }, region)).toBe(true);
    expect(isInRegion({ lat: 52.5, lon: 4.9 }, region)).toBe(false);
    expect(
      countInRegion(
        [
          { lat: 52.36, lon: 4.89 },
          { lat: 52.4, lon: 4.93 },
          { lat: 53.0, lon: 6.0 },
        ],
        region,
      ),
    ).toBe(2);
  });
});

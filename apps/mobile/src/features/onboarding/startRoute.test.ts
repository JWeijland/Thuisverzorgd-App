import { getStartRoute } from '@/features/onboarding/startRoute';
import { t } from '@/i18n';

describe('getStartRoute', () => {
  it('zonder sessie naar welkom', () => {
    expect(getStartRoute(false, null)).toBe('/welkom');
  });

  it('met sessie maar zonder rol eerst het verhaal, dan rolkeuze', () => {
    expect(getStartRoute(true, null)).toBe('/verhaal');
    expect(getStartRoute(true, { role: null, id_verified: false })).toBe('/verhaal');
  });

  it('vrijwilliger zonder ID-check naar id-en-foto', () => {
    expect(getStartRoute(true, { role: 'vrijwilliger', id_verified: false })).toBe('/id-en-foto');
  });

  it('vrijwilliger met ID-check naar de app', () => {
    expect(getStartRoute(true, { role: 'vrijwilliger', id_verified: true })).toBe('/rooster');
  });

  it('beheerder start op Steun (laag 1), hulpvrager op Vandaag', () => {
    expect(getStartRoute(true, { role: 'beheerder', id_verified: false })).toBe('/steun');
    expect(getStartRoute(true, { role: 'hulpvrager', id_verified: false })).toBe('/rooster');
  });
});

describe('i18n t()', () => {
  it('haalt copy op en vult variabelen in', () => {
    expect(t('welkom.tagline')).toBe('Hulp dichtbij, geregeld door de buurt');
    expect(t('checkMail.uitleg', { email: 'a@b.nl' })).toContain('a@b.nl');
  });

  it('geeft het pad terug bij een onbekende sleutel', () => {
    expect(t('bestaat.niet')).toBe('bestaat.niet');
  });
});

import { deeplinkToPath } from '@/features/notifications/push';
import { categoryEnabled, NOTIFICATION_CATEGORIES } from '@/features/notifications/categories';

describe('deeplinkToPath', () => {
  it('vertaalt tvz://-deeplinks naar routes', () => {
    expect(deeplinkToPath('tvz://rooster')).toBe('/rooster');
    expect(deeplinkToPath('tvz://buurt')).toBe('/buurt');
    expect(deeplinkToPath('tvz://inbox')).toBe('/inbox');
  });
  it('valt terug op de inbox', () => {
    expect(deeplinkToPath(null)).toBe('/inbox');
    expect(deeplinkToPath(undefined)).toBe('/inbox');
  });
});

describe('meldingscategorieën', () => {
  it('elke trigger-kind valt onder precies één categorie', () => {
    const all = NOTIFICATION_CATEGORIES.flatMap((category) => category.kinds);
    expect(new Set(all).size).toBe(all.length);
    expect(all.sort()).toEqual(
      [
        'aanbod',
        'aanbod_antwoord',
        'aanvraag_ingetrokken',
        'boeking',
        'forum_antwoord',
        'kringbericht',
        'makelaar',
        'taak_geannuleerd',
        'taak_geclaimd',
        'taak_nieuw',
        'uitnodiging',
      ].sort(),
    );
  });

  it('categorie staat aan tenzij expliciet uitgezet', () => {
    expect(categoryEnabled({}, ['taak_nieuw'])).toBe(true);
    expect(categoryEnabled({ taak_nieuw: false }, ['taak_nieuw', 'taak_geclaimd'])).toBe(false);
    expect(categoryEnabled({ taak_nieuw: true }, ['taak_nieuw'])).toBe(true);
  });
});

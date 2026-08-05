/** Categorie → de meldingssoorten (kinds) die de database-triggers gebruiken. */
export const NOTIFICATION_CATEGORIES: { labelKey: string; kinds: string[] }[] = [
  {
    labelKey: 'meldingen.catTaken',
    kinds: ['taak_nieuw', 'taak_geclaimd', 'taak_geannuleerd', 'boeking'],
  },
  {
    labelKey: 'meldingen.catDirecteHulp',
    kinds: ['aanbod', 'aanbod_antwoord', 'aanvraag_ingetrokken'],
  },
  { labelKey: 'meldingen.catKringberichten', kinds: ['kringbericht'] },
  { labelKey: 'meldingen.catForum', kinds: ['forum_antwoord', 'makelaar'] },
  { labelKey: 'meldingen.catUitnodigingen', kinds: ['uitnodiging'] },
];

/** Een categorie staat aan tenzij één van zijn kinds expliciet is uitgezet. */
export function categoryEnabled(prefs: Record<string, unknown>, kinds: string[]): boolean {
  return kinds.every((kind) => prefs[kind] !== false);
}

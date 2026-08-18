/**
 * De twee paden (handoff-voorzieningen, HERSTRUCTURERING.md).
 *
 * De tabbalk onderin bestaat niet meer. Na het inloggen kiest de gebruiker
 * eerst een rol en daarna een pad: "Ik wil het weten" (informatie) of
 * "Ik wil hulp regelen" (hulp). Binnen een pad navigeer je met schuifjes
 * bovenin, en de Bo-knop in de header brengt je altijd terug naar het
 * keuzescherm.
 *
 * De vrijwilliger slaat het keuzescherm over: die landt direct op de kaart
 * en heeft zijn eigen drie schuifjes.
 *
 * De aanbieder (kapper, tuinman, ...) slaat het keuzescherm ook over: die
 * landt in Mijn agenda met twee schuifjes (Beschikbaarheid en Mijn
 * afspraken). Zo'n account maakt Thuisverzorgd zelf aan; er is nergens in de
 * app een knop om aanbieder te worden.
 */

import { colors, gradient, gradientDonker } from '@/theme';

export type PadId = 'weten' | 'regelen' | 'vrijwilliger' | 'aanbieder';

export type Schuifje = {
  /** Route waar dit schuifje heen gaat (absoluut pad). */
  route: string;
  /** Sleutel in nl.json voor het label. */
  labelKey: string;
};

export type Pad = {
  id: PadId;
  titelKey: string;
  subtitelKey: string;
  /** Langere uitleg op de kaart van het keuzescherm. */
  uitlegKey: string;
  /** Gradient van de paginabalk. */
  gradient: readonly [string, string, ...string[]];
  /** Achtergrondkleur van de pagina's in dit pad. */
  achtergrond: string;
  /** Kleur van een niet-actief schuifje op de gekleurde balk. */
  schuifjeVlak: string;
  /** Tekstkleur van het actieve (witte) schuifje. */
  schuifjeActiefTekst: string;
  schuifjes: Schuifje[];
};

/**
 * Huisstijl v4: elk scherm begint met dezelfde Thuisrode paginabalk; het
 * verloop gaat nooit meer naar groen of blauw. Alleen de aanbieder (de
 * werkkant, een organisatiescherm) krijgt de donkere variant in Nachtbruin.
 */
const BALK_ROOD = gradient.colors;
const BALK_DONKER = gradientDonker.colors;

export const PADEN: Record<PadId, Pad> = {
  weten: {
    id: 'weten',
    titelKey: 'paden.weten.titel',
    subtitelKey: 'paden.weten.sub',
    uitlegKey: 'paden.weten.uitleg',
    gradient: BALK_ROOD,
    achtergrond: colors.bg,
    schuifjeVlak: 'rgba(255,255,255,0.18)',
    schuifjeActiefTekst: colors.primaryDark,
    // Zorgmakelaars is hier weg (17-08): de mantelzorgmakelaar is een
    // voorziening in het hulp-pad geworden (/regelen/makelaar).
    schuifjes: [
      { route: '/weten/wegwijzer', labelKey: 'paden.weten.wegwijzer' },
      { route: '/weten/forum', labelKey: 'paden.weten.forum' },
    ],
  },
  regelen: {
    id: 'regelen',
    titelKey: 'paden.regelen.titel',
    subtitelKey: 'paden.regelen.sub',
    uitlegKey: 'paden.regelen.uitleg',
    gradient: BALK_ROOD,
    achtergrond: colors.bg,
    schuifjeVlak: 'rgba(255,255,255,0.20)',
    schuifjeActiefTekst: colors.primaryDark,
    schuifjes: [
      { route: '/regelen/voorzieningen', labelKey: 'paden.regelen.voorzieningen' },
      { route: '/regelen/planning', labelKey: 'paden.regelen.planning' },
      { route: '/regelen/kring', labelKey: 'paden.regelen.kring' },
    ],
  },
  vrijwilliger: {
    id: 'vrijwilliger',
    titelKey: 'paden.vrijwilliger.titel',
    subtitelKey: 'paden.vrijwilliger.sub',
    uitlegKey: 'paden.vrijwilliger.uitleg',
    gradient: BALK_ROOD,
    achtergrond: colors.bg,
    schuifjeVlak: 'rgba(255,255,255,0.18)',
    schuifjeActiefTekst: colors.primaryDark,
    schuifjes: [
      { route: '/vrijwilliger/buurt', labelKey: 'paden.vrijwilliger.buurt' },
      { route: '/vrijwilliger/taken', labelKey: 'paden.vrijwilliger.taken' },
      { route: '/vrijwilliger/steun', labelKey: 'paden.vrijwilliger.steun' },
    ],
  },
  aanbieder: {
    id: 'aanbieder',
    titelKey: 'paden.aanbieder.titel',
    subtitelKey: 'paden.aanbieder.sub',
    uitlegKey: 'paden.aanbieder.uitleg',
    gradient: BALK_DONKER,
    achtergrond: colors.bg,
    schuifjeVlak: 'rgba(255,255,255,0.20)',
    schuifjeActiefTekst: colors.nachtbruin,
    schuifjes: [
      { route: '/aanbieder/beschikbaarheid', labelKey: 'paden.aanbieder.beschikbaarheid' },
      { route: '/aanbieder/afspraken', labelKey: 'paden.aanbieder.afspraken' },
    ],
  },
};

/** Het pad waar een route bij hoort, afgeleid uit het eerste segment. */
export function padVanRoute(pathname: string): PadId | null {
  const segment = pathname.split('/').filter(Boolean)[0];
  if (segment === 'weten') return 'weten';
  if (segment === 'regelen') return 'regelen';
  if (segment === 'vrijwilliger') return 'vrijwilliger';
  if (segment === 'aanbieder') return 'aanbieder';
  return null;
}

/**
 * Het actieve schuifje: de langste route die een prefix is van de huidige
 * pagina. Zo blijft "Voorzieningen" gevuld terwijl je in het dienst-detail
 * zit, precies zoals het kruimelspoor laat zien.
 */
export function actiefSchuifje(pad: Pad, pathname: string): Schuifje | null {
  let beste: Schuifje | null = null;
  for (const schuifje of pad.schuifjes) {
    if (pathname === schuifje.route || pathname.startsWith(`${schuifje.route}/`)) {
      if (!beste || schuifje.route.length > beste.route.length) beste = schuifje;
    }
  }
  return beste;
}

/**
 * De hulpvrager krijgt een eenvoudiger versie van de paden: minder schuifjes
 * en geen kruimelspoor, zodat er per scherm minder te kiezen valt. Het forum
 * hoort bij het lotgenotencontact van de beheerder; de oudere zelf gaat naar
 * de wegwijzer of naar een mens (afgestemd met Jelle).
 */
export function schuifjesVoor(pad: Pad, role: string | null | undefined): Schuifje[] {
  if (role !== 'hulpvrager') return pad.schuifjes;
  if (pad.id === 'weten') {
    return pad.schuifjes.filter((schuifje) => !schuifje.route.endsWith('/forum'));
  }
  return pad.schuifjes;
}

/** De hulpvrager ziet geen kruimelspoor: één ding per scherm is genoeg. */
export function toontKruimelspoor(role: string | null | undefined): boolean {
  return role !== 'hulpvrager';
}

/**
 * Rollen die het keuzescherm met de twee paden zien. De vrijwilliger niet:
 * die verleent hulp en landt direct op de kaart. De aanbieder ook niet: die
 * heeft alleen zijn agenda.
 */
export function heeftPadKeuze(role: string | null | undefined): boolean {
  return role === 'beheerder' || role === 'hulpvrager';
}

/** Waar "naar huis" heen gaat als er niets meer op de terugstapel staat. */
export function thuisRoute(role: string | null | undefined): string {
  if (heeftPadKeuze(role)) return '/pad';
  if (role === 'aanbieder') return '/aanbieder/beschikbaarheid';
  return '/vrijwilliger/buurt';
}

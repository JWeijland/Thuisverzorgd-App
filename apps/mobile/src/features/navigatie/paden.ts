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
 */

import { colors } from '@/theme';

export type PadId = 'weten' | 'regelen' | 'vrijwilliger';

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
  /** Gradient van de headerbalk. */
  gradient: [string, string];
  /** Achtergrondkleur van de pagina's in dit pad. */
  achtergrond: string;
  /** Kleur van een niet-actief schuifje op de gekleurde balk. */
  schuifjeVlak: string;
  /** Tekstkleur van het actieve (witte) schuifje. */
  schuifjeActiefTekst: string;
  schuifjes: Schuifje[];
};

/**
 * Hulpgroen voor het regel-pad (zoals de screenshots 03 t/m 07), blauw voor
 * het weet-pad. De keuze voor groen volgt het brandbook: groen geeft.
 */
const HULP_GROEN: [string, string] = ['#5FA22A', '#8DC93F'];
const INFO_BLAUW: [string, string] = [colors.primary, colors.primaryMid];
const VRIJWILLIGER_NAVY: [string, string] = [colors.primaryDark, colors.primaryMid];

export const PADEN: Record<PadId, Pad> = {
  weten: {
    id: 'weten',
    titelKey: 'paden.weten.titel',
    subtitelKey: 'paden.weten.sub',
    uitlegKey: 'paden.weten.uitleg',
    gradient: INFO_BLAUW,
    achtergrond: colors.bg,
    schuifjeVlak: 'rgba(255,255,255,0.18)',
    schuifjeActiefTekst: colors.primary,
    schuifjes: [
      { route: '/weten/wegwijzer', labelKey: 'paden.weten.wegwijzer' },
      { route: '/weten/forum', labelKey: 'paden.weten.forum' },
      { route: '/weten/zorgmakelaars', labelKey: 'paden.weten.zorgmakelaars' },
    ],
  },
  regelen: {
    id: 'regelen',
    titelKey: 'paden.regelen.titel',
    subtitelKey: 'paden.regelen.sub',
    uitlegKey: 'paden.regelen.uitleg',
    gradient: HULP_GROEN,
    achtergrond: colors.bg,
    schuifjeVlak: 'rgba(255,255,255,0.20)',
    schuifjeActiefTekst: colors.successText,
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
    gradient: VRIJWILLIGER_NAVY,
    achtergrond: colors.bg,
    schuifjeVlak: 'rgba(255,255,255,0.18)',
    schuifjeActiefTekst: colors.primary,
    schuifjes: [
      { route: '/vrijwilliger/buurt', labelKey: 'paden.vrijwilliger.buurt' },
      { route: '/vrijwilliger/taken', labelKey: 'paden.vrijwilliger.taken' },
      { route: '/vrijwilliger/steun', labelKey: 'paden.vrijwilliger.steun' },
    ],
  },
};

/** Het pad waar een route bij hoort, afgeleid uit het eerste segment. */
export function padVanRoute(pathname: string): PadId | null {
  const segment = pathname.split('/').filter(Boolean)[0];
  if (segment === 'weten') return 'weten';
  if (segment === 'regelen') return 'regelen';
  if (segment === 'vrijwilliger') return 'vrijwilliger';
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
 * die verleent hulp en landt direct op de kaart.
 */
export function heeftPadKeuze(role: string | null | undefined): boolean {
  return role === 'beheerder' || role === 'hulpvrager';
}

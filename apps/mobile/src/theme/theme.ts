/**
 * Design tokens van Thuisverzorgd, huisstijl v4.0 (augustus 2026).
 * Bron: Brand Guidelines v4.0, hoofdstuk 03 + DesignSystem/HUISSTIJL.md.
 *
 * Wat er veranderde t.o.v. v3: Thuisrood #E55A40 is de primaire merkkleur,
 * Linnenwit #FCF8F6 is het fundament, en groen is geen CTA-kleur meer maar
 * hoort bij Bo, bevestiging en beschikbaarheid. Kringblauw blijft, voor de
 * kring, de kaart en uitleg.
 *
 * Alle sleutels uit v3 bestaan nog, zodat schermen blijven werken.
 * Nooit losse hexwaarden in schermen gebruiken: alles via deze tokens.
 */

export const colors = {
  /** Diepbaksteen: rode tekst op licht, ingedrukte knop, donker merkvlak */
  primaryDark: '#9F2F21',
  /** Thuisrood: merk, paginabalk, actieve staat, primaire knoppen */
  primary: '#E55A40',
  /** Gloedrood: knop met witte tekst (4,9 : 1), links, iconen */
  primaryMid: '#CE3B24',
  /** Zachte merk-achtergrond (rood 50) */
  primarySoft: '#FEF4F1',
  /** Merk-tint voor chips, badges en avatars (rood 100) */
  primaryTint: '#FCE7E1',
  /** Nachtbruin: donkere vlakken, covers, schaduwkleur */
  nachtbruin: '#3A1D16',

  /** Hulpgroen: Bo, bevestiging, beschikbaar. Geen CTA meer. */
  accent: '#8DC93F',
  /** hover/donkere variant hulpgroen */
  accentDark: '#73B02B',
  /** hover op groene vlakken */
  accentHover: '#9AD44E',
  /** tekst of icoon bovenop accent of oker: nooit wit */
  onAccent: '#3A1D16',

  successBg: '#EEF7E0',
  successText: '#4C7A16',
  warnBg: '#FBF0D8',
  warnText: '#8A5E06',
  /** Okergeel (brandbook "warning"): open plekken in de week */
  warnDot: '#C98A0F',
  errorBg: '#F6E2E6',
  /** Alarmrood: donkerder en koeler dan het merk, altijd met icoon en woord */
  error: '#9B1B30',

  /** bodytekst (15,8 : 1 op linnen) */
  ink: '#2B1A16',
  /** secundaire tekst (6,3 : 1) */
  inkSoft: '#6E574F',
  /** tertiaire tekst, placeholders (3,3 : 1, alleen labels) */
  inkFaint: '#9C857C',
  /** randen, hairlines */
  line: '#EDE2DD',
  /** lichte vlakken, iconentegels */
  surfaceAlt: '#F6EEEA',

  /** Kringblauw-tint: pill-achtergrond voor kring en uitleg */
  tintBlue: '#EAF1F9',
  /** Kringblauw: kaart, kring, informatie */
  blue: '#2A6CB0',
  /** lichtblauw hero-vlak van het dienst-detail (handoff voorzieningen) */
  heroBlue: '#E9F1FA',

  /** app-achtergrond: Linnenwit, bijna wit met warme ondertoon */
  bg: '#FCF8F6',
  white: '#FFFFFF',
  /** chatbubbel eigen bericht */
  chatOwn: '#FCE7E1',
  /** chatbubbel ander */
  chatOther: '#EAF5D8',
} as const;

/**
 * Zachte bubbeltinten voor kringgenoten in de chat: iedere afzender krijgt
 * (op basis van zijn id) een vaste eigen tint.
 */
export const chatTints = ['#EAF5D8', '#FDF0DC', '#EFE6F7', '#DFF2F0', '#FCE7E1'] as const;

/** Deterministische tint voor een afzender (zelfde id → altijd dezelfde kleur). */
export function chatTintFor(senderId: string): string {
  let sum = 0;
  for (let i = 0; i < senderId.length; i += 1) sum = (sum + senderId.charCodeAt(i)) % 997;
  return chatTints[sum % chatTints.length]!;
}

/**
 * Themakleuren van de Wegwijzer: elk kennisthema krijgt een eigen tint voor de
 * iconentegel. Rood, groen en blauw komen uit het merkpalet, paars is de enige
 * extra tint en wordt nergens anders voor gebruikt.
 */
export const themaTints = {
  rood: { vlak: colors.primarySoft, icoon: colors.primaryDark },
  blauw: { vlak: colors.tintBlue, icoon: colors.blue },
  groen: { vlak: colors.successBg, icoon: colors.successText },
  oranje: { vlak: colors.warnBg, icoon: colors.warnText },
  paars: { vlak: '#EFE6F7', icoon: '#6B4E93' },
} as const;

export type ThemaTint = keyof typeof themaTints;

/**
 * Rolkleuren: het merk (rood) draagt de beheerder, groen geeft (buddy),
 * blauw vraagt (hulpvrager). De makelaar leent het wegwijzer-paars.
 */
export const rolTints = {
  beheerder: { vlak: colors.primarySoft, tekst: colors.primaryDark, stip: colors.primary },
  vrijwilliger: { vlak: colors.successBg, tekst: colors.successText, stip: colors.accentDark },
  hulpvrager: { vlak: colors.tintBlue, tekst: colors.blue, stip: colors.blue },
  makelaar: { vlak: '#EFE6F7', tekst: '#6B4E93', stip: '#6B4E93' },
} as const;

export type RolTint = keyof typeof rolTints;

/**
 * De paginabalk boven elk scherm: verloop van rood 400 naar rood 500 naar een
 * dieper rood, diagonaal. Nooit rood naar groen verlopen.
 */
export const gradient = {
  colors: ['#EE6E52', colors.primary, '#D0492F'] as [string, string, string],
  start: { x: 0, y: 0 },
  end: { x: 1, y: 1 },
} as const;

/** Donkere variant van de paginabalk: alleen beheer- en organisatieschermen. */
export const gradientDonker = {
  colors: ['#4A2A22', colors.nachtbruin] as [string, string],
  start: { x: 0, y: 0 },
  end: { x: 1, y: 1 },
} as const;

/** Groene gradient: bevestigingen en het profiel van een buddy. */
export const gradientGroen = {
  colors: ['#5FA22A', colors.accent] as [string, string],
  start: { x: 0, y: 0 },
  end: { x: 1, y: 1 },
} as const;

/**
 * Maten van de paginabalk (brandbook 7.2). Kies een variant, niet iets ertussenin.
 */
export const paginabalk = {
  hoogteGroot: 180,
  hoogteCompact: 120,
  hoogteKlein: 96,
  /** hoogte van de golfrand onderaan */
  golfHoogte: 8,
  /** Bo als wit silhouet op de achtergrond */
  boDekking: 0.12,
  boDekkingDonker: 0.08,
  /** kringelstreep linksonder, alleen bij de grote variant */
  kringelDekking: 0.5,
} as const;

/** Vlakken bijna vierkant; alles wat een actie of status is, is een pill. */
export const radius = {
  input: 8,
  row: 10,
  card: 12,
  tile: 16,
  pill: 999,
  bubble: 18,
  bubbleTail: 6,
} as const;

export const spacing = {
  xs: 4,
  sm: 8,
  md: 12,
  lg: 16,
  xl: 20,
  xxl: 24,
  screen: 20,
  cardGap: 10,
  cardPadding: 18,
  chipGap: 8,
} as const;

/** Gestippelde rand = concept / nog te doen (koppelcode, conceptplanning, foto-upload). */
export const dashedBorder = {
  borderWidth: 1.5,
  borderStyle: 'dashed' as const,
  borderColor: colors.primaryMid,
};

/** Onderste tabbalk: 5 tabs × 64px + 6px padding, zwevend. */
export const tabBar = {
  tabWidth: 64,
  padding: 6,
  bottomOffset: 16,
} as const;

/** Minimale tikdoelen (brandbook: alles ≥44, belangrijkste CTA's 72). */
export const hitTarget = {
  min: 44,
  cta: 56,
} as const;

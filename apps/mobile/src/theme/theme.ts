/**
 * Design tokens van Thuisverzorgd.
 * Bron: docs/design/README.md (sectie "Design Tokens") + brandbook v3 "Getekend".
 * Nooit losse hexwaarden in schermen gebruiken: alles via deze tokens.
 */

export const colors = {
  /** donkerste navy: gradients, videocall, directe-hulp-marker */
  primaryDark: '#112F50',
  /** primaire knoppen, actieve tabs, koppen */
  primary: '#1A4878',
  /** accent-navy, avatars, links, gradient-eind */
  primaryMid: '#2A6CB0',
  /** Hulpgroen: primaire CTA, actief/positief, pulserende status */
  accent: '#8DC93F',
  /** hover/donkere variant hulpgroen */
  accentDark: '#73B02B',
  /** hover op groene knoppen */
  accentHover: '#9AD44E',
  successBg: '#F1F8E4',
  successText: '#4C7A16',
  warnBg: '#FBF3E0',
  warnText: '#9A6E0B',
  /** semantisch oranje (brandbook "warning"): open plekken in de week */
  warnDot: '#E19E11',
  errorBg: '#FDEDEC',
  error: '#D9413A',
  /** bodytekst */
  ink: '#112640',
  /** secundaire tekst */
  inkSoft: '#5A687A',
  /** tertiaire tekst, placeholders */
  inkFaint: '#8F9AAA',
  /** randen */
  line: '#E3E8F1',
  /** lichte vlakken, iconentegels */
  surfaceAlt: '#EEF2F8',
  /** blauwe pill-achtergrond */
  tintBlue: '#EAF1F9',
  /** lichtblauw hero-vlak van het dienst-detail (handoff voorzieningen) */
  heroBlue: '#E9F1FA',
  /** app-achtergrond */
  bg: '#F5F8FC',
  white: '#FFFFFF',
  /** chatbubbel eigen bericht */
  chatOwn: '#DEE8F4',
  /** chatbubbel ander */
  chatOther: '#EAF5D8',
} as const;

/**
 * Zachte bubbeltinten voor kringgenoten in de chat: iedere afzender krijgt
 * (op basis van zijn id) een vaste eigen tint, zodat je berichten van
 * verschillende mensen in één oogopslag uit elkaar houdt.
 */
export const chatTints = ['#EAF5D8', '#FDF0DC', '#EFE6F7', '#DFF2F0', '#FBE8E8'] as const;

/** Deterministische tint voor een afzender (zelfde id → altijd dezelfde kleur). */
export function chatTintFor(senderId: string): string {
  let sum = 0;
  for (let i = 0; i < senderId.length; i += 1) sum = (sum + senderId.charCodeAt(i)) % 997;
  return chatTints[sum % chatTints.length]!;
}

/**
 * Themakleuren van de Wegwijzer: elk kennisthema krijgt een eigen tint voor de
 * iconentegel, zodat je thema's uit elkaar houdt zonder ze te hoeven lezen.
 * Blauw, groen en oranje komen uit het merkpalet; paars is de enige extra tint
 * (dezelfde als de lila chatbubbel) en wordt nergens anders voor gebruikt.
 */
export const themaTints = {
  blauw: { vlak: colors.tintBlue, icoon: colors.primaryMid },
  groen: { vlak: colors.successBg, icoon: colors.successText },
  oranje: { vlak: colors.warnBg, icoon: colors.warnText },
  paars: { vlak: '#EFE6F7', icoon: '#6B4E93' },
} as const;

export type ThemaTint = keyof typeof themaTints;

/**
 * Rolkleuren uit het logo-verhaal (brandbook 2.1/2.2): blauw vraagt
 * (hulpvrager), groen geeft (buddy), navy draagt (beheerder, "de steun").
 * De makelaar leent het wegwijzer-paars. Gebruikt door RolChip en Bo.
 */
export const rolTints = {
  beheerder: { vlak: '#E4EBF4', tekst: colors.primary, stip: colors.primary },
  vrijwilliger: { vlak: colors.successBg, tekst: colors.successText, stip: colors.accentDark },
  hulpvrager: { vlak: colors.tintBlue, tekst: colors.primaryMid, stip: colors.primaryMid },
  makelaar: { vlak: '#EFE6F7', tekst: '#6B4E93', stip: '#6B4E93' },
} as const;

export type RolTint = keyof typeof rolTints;

/** Standaard-gradient (headers, welkom, videocall): 115deg primaryDark → primaryMid. */
export const gradient = {
  colors: [colors.primaryDark, colors.primaryMid] as [string, string],
  start: { x: 0, y: 0 },
  end: { x: 1, y: 1 },
} as const;

/** Hulpgroene gradient van het regel-pad; ook voor de profielkop. */
export const gradientGroen = {
  colors: ['#5FA22A', colors.accent] as [string, string],
  start: { x: 0, y: 0 },
  end: { x: 1, y: 1 },
} as const;

/** Vlakken bijna vierkant; alles wat een actie of status is, is een pill. */
export const radius = {
  /** invoervelden */
  input: 8,
  /** kleine rijen */
  row: 10,
  /** kaarten */
  card: 12,
  /** iconentegels (15–17) */
  tile: 16,
  /** knoppen, chips, tabs, statuspillen */
  pill: 999,
  /** chatbubbels: 18 18 6 18 (eigen) / 18 18 18 6 (ander) */
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
  /** schermpadding 20–24 */
  screen: 20,
  /** verticale gap tussen kaarten */
  cardGap: 10,
  /** kaartpadding 16–22 */
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

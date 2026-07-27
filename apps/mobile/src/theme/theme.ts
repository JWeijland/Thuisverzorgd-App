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
  /** app-achtergrond */
  bg: '#F5F8FC',
  white: '#FFFFFF',
  /** chatbubbel eigen bericht */
  chatOwn: '#DEE8F4',
  /** chatbubbel ander */
  chatOther: '#EAF5D8',
} as const;

/** Standaard-gradient (headers, welkom, videocall): 115deg primaryDark → primaryMid. */
export const gradient = {
  colors: [colors.primaryDark, colors.primaryMid] as [string, string],
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

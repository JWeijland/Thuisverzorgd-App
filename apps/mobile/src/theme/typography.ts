import type { TextStyle } from 'react-native';

import { colors } from '@/theme/theme';

/**
 * Typografie: Baloo 2 voor koppen/knoppen/labels/pillen, Comic Neue voor body,
 * Caveat alleen voor rondleiding-wolkjes en losse notities.
 * Schaal uit de handoff: schermtitel 25–29 · sectiekop 16–19 · kaarttitel 16–18 ·
 * body 14.5–17 · secundair 13–14 · pill/meta 11.5–13. Regelhoogte body 1.5–1.6.
 */

export const fonts = {
  heading: 'Baloo2_600SemiBold',
  headingBold: 'Baloo2_700Bold',
  headingExtra: 'Baloo2_800ExtraBold',
  body: 'ComicNeue_400Regular',
  bodyBold: 'ComicNeue_700Bold',
  bodyItalic: 'ComicNeue_400Regular_Italic',
  hand: 'Caveat_600SemiBold',
  handMedium: 'Caveat_500Medium',
} as const;

export const text = {
  screenTitle: {
    fontFamily: fonts.headingBold,
    fontSize: 27,
    color: colors.ink,
  },
  sectionTitle: {
    fontFamily: fonts.heading,
    fontSize: 17,
    color: colors.primary,
  },
  cardTitle: {
    fontFamily: fonts.heading,
    fontSize: 17,
    color: colors.ink,
  },
  body: {
    fontFamily: fonts.body,
    fontSize: 15.5,
    lineHeight: 24,
    color: colors.ink,
  },
  bodyBold: {
    fontFamily: fonts.bodyBold,
    fontSize: 15.5,
    lineHeight: 24,
    color: colors.ink,
  },
  secondary: {
    fontFamily: fonts.body,
    fontSize: 13.5,
    lineHeight: 20,
    color: colors.inkSoft,
  },
  meta: {
    fontFamily: fonts.heading,
    fontSize: 12.5,
    color: colors.inkSoft,
  },
  button: {
    fontFamily: fonts.headingBold,
    fontSize: 16,
  },
  /** Caveat, alleen voor coachmarks en notities. */
  hand: {
    fontFamily: fonts.hand,
    fontSize: 21,
    color: colors.ink,
  },
} as const satisfies Record<string, TextStyle>;

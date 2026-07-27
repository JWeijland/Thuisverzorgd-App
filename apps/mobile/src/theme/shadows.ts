import type { ViewStyle } from 'react-native';

/**
 * Schaduwen uit de handoff. Merk-donkerkleur (17,47,80), nooit hard zwart.
 * Android krijgt een bescheiden elevation-equivalent.
 */

export const shadows = {
  /** kaart: 0 6–8px 18–24px rgba(17,47,80,.06–.08) */
  card: {
    shadowColor: '#112F50',
    shadowOffset: { width: 0, height: 7 },
    shadowOpacity: 0.07,
    shadowRadius: 21,
    elevation: 2,
  },
  /** zwevend element: 0 12–16px 32–40px rgba(17,47,80,.18–.22) */
  floating: {
    shadowColor: '#112F50',
    shadowOffset: { width: 0, height: 14 },
    shadowOpacity: 0.2,
    shadowRadius: 36,
    elevation: 8,
  },
  /** groene CTA: 0 8px 20px rgba(115,176,43,.3) */
  cta: {
    shadowColor: '#73B02B',
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.3,
    shadowRadius: 20,
    elevation: 4,
  },
} as const satisfies Record<string, ViewStyle>;

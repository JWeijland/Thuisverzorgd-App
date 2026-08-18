import type { ViewStyle } from 'react-native';

/**
 * Schaduwen uit huisstijl v4: altijd zacht en in Nachtbruin (58,29,22),
 * nooit hard zwart. Android krijgt een bescheiden elevation-equivalent.
 */

export const shadows = {
  /** kaart: 0 6–8px 18–24px rgba(58,29,22,.06–.08) */
  card: {
    shadowColor: '#3A1D16',
    shadowOffset: { width: 0, height: 7 },
    shadowOpacity: 0.07,
    shadowRadius: 21,
    elevation: 2,
  },
  /** zwevend element: 0 12–16px 32–40px rgba(58,29,22,.18–.22) */
  floating: {
    shadowColor: '#3A1D16',
    shadowOffset: { width: 0, height: 14 },
    shadowOpacity: 0.2,
    shadowRadius: 36,
    elevation: 8,
  },
  /** primaire CTA (Gloedrood): 0 8px 20px rgba(206,59,36,.3) */
  cta: {
    shadowColor: '#CE3B24',
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.3,
    shadowRadius: 20,
    elevation: 4,
  },
} as const satisfies Record<string, ViewStyle>;

import { useEffect, type ReactNode } from 'react';
import { StyleSheet, useWindowDimensions } from 'react-native';
import Animated, {
  Easing,
  useAnimatedStyle,
  useSharedValue,
  withTiming,
} from 'react-native-reanimated';
import { create } from 'zustand';

import { colors } from '@/theme';

type RichtingState = {
  /** Waar de pagina vandaan komt: 1 = van rechts, -1 = van links. */
  richting: 1 | -1;
  /** Index van het schuifje waar je vandaan komt. */
  vorigeIndex: number;
  zetRichting: (nieuweIndex: number) => void;
  /** Bij binnenkomst van buiten de schuifbalk: onthoud waar je staat. */
  meldActief: (index: number) => void;
};

/**
 * Onthoudt welke kant je op gaat tussen de schuifjes. De pagina beweegt de
 * kant op waar je heen tikt: naar een schuifje links schuift het scherm naar
 * links, naar rechts naar rechts. Daarvoor moet de nieuwe pagina aan de
 * tegenoverliggende kant beginnen en die kant op bewegen.
 */
export const useSchuifRichting = create<RichtingState>((set, get) => ({
  richting: 1,
  vorigeIndex: 0,
  zetRichting: (nieuweIndex) =>
    set({ richting: nieuweIndex >= get().vorigeIndex ? -1 : 1, vorigeIndex: nieuweIndex }),
  meldActief: (index) =>
    set((state) => (state.vorigeIndex === index ? state : { vorigeIndex: index })),
}));

const DUUR = 240;
/** Hoe ver de pagina begint, als deel van de schermbreedte. */
const AFSTAND = 0.14;

/**
 * De inhoud van een pagina binnen een pad. Schuift bij binnenkomst de kant op
 * die past bij het schuifje dat je aantikte.
 *
 * Bewust met een eigen translateX en niet met een `entering`-animatie van
 * Reanimated: die rekent vanaf de rand van het scherm, waardoor de inhoud
 * tijdens de overgang over de header heen kon lopen. Deze variant raakt de
 * layout niet aan, dus de pagina blijft altijd netjes onder de schuifjes.
 */
export function PadPagina({ children }: { children: ReactNode }) {
  const richting = useSchuifRichting((state) => state.richting);
  const { width } = useWindowDimensions();
  const verschuiving = useSharedValue(richting * width * AFSTAND);
  // De pagina komt tegelijk in beeld terwijl hij schuift. Zonder die fade
  // zie je vooral de sprong naar de startpositie en niet de beweging zelf
  // (feedback Jelle 11-08).
  const zichtbaar = useSharedValue(0);

  useEffect(() => {
    verschuiving.value = withTiming(0, { duration: DUUR, easing: Easing.out(Easing.cubic) });
    zichtbaar.value = withTiming(1, { duration: DUUR * 0.8 });
  }, [verschuiving, zichtbaar]);

  const beweging = useAnimatedStyle(() => ({
    opacity: zichtbaar.value,
    transform: [{ translateX: verschuiving.value }],
  }));

  return <Animated.View style={[styles.vlak, beweging]}>{children}</Animated.View>;
}

const styles = StyleSheet.create({
  vlak: {
    flex: 1,
    backgroundColor: colors.bg,
    // De pagina beweegt binnen zijn eigen vlak; niets steekt eroverheen.
    overflow: 'hidden',
  },
});

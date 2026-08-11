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
 * Onthoudt welke kant je op gaat tussen de schuifjes. De inhoud beweegt mee
 * met de richting van je tik: tik je een schuifje links aan, dan schuift het
 * scherm naar links; tik je rechts, dan schuift het naar rechts. Andersom
 * voelt tegennatuurlijk (feedback Jelle 11-08).
 */
export const useSchuifRichting = create<RichtingState>((set, get) => ({
  richting: 1,
  vorigeIndex: 0,
  zetRichting: (nieuweIndex) =>
    set({ richting: nieuweIndex >= get().vorigeIndex ? -1 : 1, vorigeIndex: nieuweIndex }),
  meldActief: (index) =>
    set((state) => (state.vorigeIndex === index ? state : { vorigeIndex: index })),
}));

const DUUR = 220;

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
  const verschuiving = useSharedValue(richting * width * 0.25);

  useEffect(() => {
    verschuiving.value = withTiming(0, { duration: DUUR, easing: Easing.out(Easing.cubic) });
  }, [verschuiving]);

  const beweging = useAnimatedStyle(() => ({
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

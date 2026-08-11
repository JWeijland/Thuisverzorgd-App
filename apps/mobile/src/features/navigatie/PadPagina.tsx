import type { ReactNode } from 'react';
import { StyleSheet } from 'react-native';
import Animated, { SlideInLeft, SlideInRight } from 'react-native-reanimated';
import { create } from 'zustand';

import { colors } from '@/theme';

type RichtingState = {
  /** 1 = het volgende schuifje (van rechts), -1 = het vorige (van links). */
  richting: 1 | -1;
  /** Index van het schuifje waar je vandaan komt. */
  vorigeIndex: number;
  zetRichting: (nieuweIndex: number) => void;
  /** Bij binnenkomst van buiten de schuifbalk: onthoud waar je staat. */
  meldActief: (index: number) => void;
};

/**
 * Onthoudt welke kant je op gaat tussen de schuifjes, zodat de pagina
 * meebeweegt met de beweging die je maakt: naar een schuifje rechts komt de
 * pagina van rechts binnen, naar links van links.
 */
export const useSchuifRichting = create<RichtingState>((set, get) => ({
  richting: 1,
  vorigeIndex: 0,
  zetRichting: (nieuweIndex) =>
    set({ richting: nieuweIndex >= get().vorigeIndex ? 1 : -1, vorigeIndex: nieuweIndex }),
  meldActief: (index) =>
    set((state) => (state.vorigeIndex === index ? state : { vorigeIndex: index })),
}));

const DUUR = 220;

/**
 * De inhoud van een pagina binnen een pad. Schuift bij binnenkomst de kant op
 * die past bij het schuifje dat je aantikte.
 */
export function PadPagina({ children }: { children: ReactNode }) {
  const richting = useSchuifRichting((state) => state.richting);
  return (
    <Animated.View
      key={`pad-${richting}`}
      entering={(richting === 1 ? SlideInRight : SlideInLeft).duration(DUUR)}
      style={styles.vlak}
    >
      {children}
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  vlak: {
    flex: 1,
    backgroundColor: colors.bg,
  },
});

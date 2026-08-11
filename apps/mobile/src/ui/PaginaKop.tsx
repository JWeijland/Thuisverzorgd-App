import type { ReactNode } from 'react';
import { StyleSheet, View } from 'react-native';

import { colors, spacing } from '@/theme';
import { TvzText } from '@/ui/TvzText';

type Props = {
  titel: string;
  sub?: string;
  /** Rechts naast de titel, bijv. de inbox-bel. */
  rechts?: ReactNode;
};

/**
 * Lichte paginakop binnen een pad (handoff, scherm 05: "Goedemorgen, Jelle").
 * De gekleurde balk is nu de PadHeader; de pagina zelf begint met een rustige
 * begroeting op wit, zonder tweede gradient.
 */
export function PaginaKop({ titel, sub, rechts }: Props) {
  return (
    <View style={styles.rij}>
      <View style={styles.tekst}>
        <TvzText preset="screenTitle">{titel}</TvzText>
        {sub ? (
          <TvzText preset="secondary" style={styles.sub}>
            {sub}
          </TvzText>
        ) : null}
      </View>
      {rechts ? <View style={styles.acties}>{rechts}</View> : null}
    </View>
  );
}

const styles = StyleSheet.create({
  rij: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
    paddingHorizontal: spacing.screen,
    paddingTop: spacing.lg,
    paddingBottom: spacing.sm,
    backgroundColor: colors.bg,
  },
  tekst: {
    flex: 1,
  },
  sub: {
    marginTop: 2,
  },
  acties: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
  },
});

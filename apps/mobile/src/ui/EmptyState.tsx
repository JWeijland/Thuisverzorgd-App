import { StyleSheet, View } from 'react-native';

import { colors, radius, spacing } from '@/theme';
import { Bo } from '@/ui/Bo';
import { Kringel } from '@/ui/getekend/Getekend';
import { TvzText } from '@/ui/TvzText';

type Props = {
  title: string;
  body?: string;
  /** Mascotte Bo in plaats van de pillen (max één Bo per scherm!). */
  bo?: boolean;
};

/**
 * Lege staat volgens het brandbook: de losse pillen als vriendelijke illustratie
 * ("de pillen zoeken elkaar nog even"), nooit sombere iconen. Op een paar
 * plekken uit de handoff staat mascotte Bo er in plaats van de pillen.
 */
export function EmptyState({ title, body, bo }: Props) {
  return (
    <View style={styles.container}>
      {bo ? (
        <View style={styles.boWrap}>
          <Bo width={96} />
        </View>
      ) : (
        <View style={styles.pills}>
          <View style={[styles.pill, { backgroundColor: colors.primaryMid }]} />
          <View style={[styles.pill, { backgroundColor: colors.accent, marginLeft: 14 }]} />
        </View>
      )}
      <TvzText preset="cardTitle" style={styles.title}>
        {title}
      </TvzText>
      {/* Leeg scherm volgens de huisstijl: kringel plus Bo. */}
      {bo ? <Kringel variant="kort" width={64} style={styles.kringel} /> : null}
      {body ? (
        <TvzText preset="secondary" style={styles.body}>
          {body}
        </TvzText>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    alignItems: 'center',
    paddingVertical: spacing.xxl,
    paddingHorizontal: spacing.xl,
  },
  pills: {
    flexDirection: 'row',
    marginBottom: spacing.lg,
  },
  boWrap: {
    marginBottom: spacing.lg,
  },
  pill: {
    width: 30,
    height: 14,
    borderRadius: radius.pill,
  },
  title: {
    textAlign: 'center',
  },
  kringel: {
    marginTop: spacing.xs,
  },
  body: {
    textAlign: 'center',
    marginTop: spacing.xs,
  },
});

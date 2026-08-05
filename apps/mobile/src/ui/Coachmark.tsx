import { Pressable, StyleSheet, View, type StyleProp, type ViewStyle } from 'react-native';

import { colors, radius, shadows, spacing } from '@/theme';
import { Bo } from '@/ui/Bo';
import { Button } from '@/ui/Button';
import { TvzText } from '@/ui/TvzText';

type Props = {
  /** Handgeschreven titel in Caveat, bijv. "Plan hier taken in!". */
  title: string;
  body: string;
  step: number;
  totalSteps: number;
  onNext: () => void;
  onSkip: () => void;
  /** Waar het pijltje naartoe wijst: naar een knop boven of onder het wolkje. */
  arrow?: 'up' | 'down';
  /** Horizontale positie van het pijltje, vanaf links. */
  arrowOffset?: number;
  /** Mascotte Bo zit bovenop het wolkje (rondleiding, handoff). */
  bo?: boolean;
  style?: StyleProp<ViewStyle>;
};

/**
 * Rondleiding-wolkje: Caveat-titel met pijltje naar een echte knop.
 * Beheerder 4 stappen, vrijwilliger 3, hulpvrager 2; overslaan kan altijd.
 */
export function Coachmark({
  title,
  body,
  step,
  totalSteps,
  onNext,
  onSkip,
  arrow,
  arrowOffset = 32,
  bo,
  style,
}: Props) {
  const isLast = step >= totalSteps;
  return (
    <View style={style}>
      {bo ? (
        <View pointerEvents="none" style={styles.bo}>
          <Bo width={92} />
        </View>
      ) : null}
      {arrow === 'up' ? (
        <View style={[styles.arrow, styles.arrowUp, { marginLeft: arrowOffset }]} />
      ) : null}
      <View style={[styles.card, shadows.floating]}>
        <TvzText preset="hand">{title}</TvzText>
        <TvzText preset="secondary" style={styles.body}>
          {body}
        </TvzText>
        <View style={styles.footer}>
          <View style={styles.dots}>
            {Array.from({ length: totalSteps }, (_, i) => (
              <View key={i} style={[styles.dot, i === step - 1 && styles.dotActive]} />
            ))}
          </View>
          <View style={styles.actions}>
            <Pressable accessibilityRole="button" onPress={onSkip} hitSlop={8}>
              <TvzText preset="meta">Overslaan</TvzText>
            </Pressable>
            <Button
              label={isLast ? 'Klaar' : 'Volgende'}
              variant="cta"
              onPress={onNext}
              style={styles.nextButton}
            />
          </View>
        </View>
      </View>
      {arrow === 'down' ? (
        <View style={[styles.arrow, styles.arrowDown, { marginLeft: arrowOffset }]} />
      ) : null}
    </View>
  );
}

const ARROW = 10;

const styles = StyleSheet.create({
  // Bo zit óp het wolkje: zijn voetjes overlappen de bovenrand van de kaart.
  bo: {
    alignSelf: 'flex-end',
    marginRight: 18,
    marginBottom: -26,
    zIndex: 1,
  },
  card: {
    backgroundColor: colors.white,
    borderRadius: radius.card,
    padding: spacing.lg,
  },
  body: {
    marginTop: spacing.xs,
  },
  footer: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginTop: spacing.md,
  },
  dots: {
    flexDirection: 'row',
    gap: 5,
  },
  dot: {
    width: 7,
    height: 7,
    borderRadius: 999,
    backgroundColor: colors.line,
  },
  dotActive: {
    width: 18,
    backgroundColor: colors.primary,
  },
  actions: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
  },
  nextButton: {
    minHeight: 36,
    paddingVertical: 6,
    paddingHorizontal: 18,
  },
  arrow: {
    width: 0,
    height: 0,
    borderLeftWidth: ARROW,
    borderRightWidth: ARROW,
    borderLeftColor: 'transparent',
    borderRightColor: 'transparent',
  },
  arrowUp: {
    borderBottomWidth: ARROW + 2,
    borderBottomColor: colors.white,
  },
  arrowDown: {
    borderTopWidth: ARROW + 2,
    borderTopColor: colors.white,
  },
});

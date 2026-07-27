import { Pressable, StyleSheet, View } from 'react-native';

import { colors, radius, spacing } from '@/theme';
import { TvzText } from '@/ui/TvzText';

type Props = {
  title: string;
  /** Optionele actielink rechts, bijv. "Hele week plannen →". */
  actionLabel?: string;
  onActionPress?: () => void;
};

/** Sectiekop met het groene merkstreepje, bijv. "Rooster · week 31". */
export function SectionHeader({ title, actionLabel, onActionPress }: Props) {
  return (
    <View style={styles.row}>
      <View style={styles.left}>
        <View style={styles.dash} />
        <TvzText preset="sectionTitle">{title}</TvzText>
      </View>
      {actionLabel ? (
        <Pressable accessibilityRole="link" onPress={onActionPress} hitSlop={8}>
          <TvzText preset="meta" style={styles.action}>
            {actionLabel}
          </TvzText>
        </Pressable>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginTop: spacing.xl + 3,
    marginBottom: spacing.md - 1,
  },
  left: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
  },
  dash: {
    width: 18,
    height: 5,
    borderRadius: radius.pill,
    backgroundColor: colors.accent,
  },
  action: {
    color: colors.primaryMid,
  },
});

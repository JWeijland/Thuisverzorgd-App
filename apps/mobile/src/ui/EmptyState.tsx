import { StyleSheet, View } from 'react-native';

import { colors, radius, spacing } from '@/theme';
import { TvzText } from '@/ui/TvzText';

type Props = {
  title: string;
  body?: string;
};

/**
 * Lege staat volgens het brandbook: de losse pillen als vriendelijke illustratie
 * ("de pillen zoeken elkaar nog even"), nooit sombere iconen.
 */
export function EmptyState({ title, body }: Props) {
  return (
    <View style={styles.container}>
      <View style={styles.pills}>
        <View style={[styles.pill, { backgroundColor: colors.primaryMid }]} />
        <View style={[styles.pill, { backgroundColor: colors.accent, marginLeft: 14 }]} />
      </View>
      <TvzText preset="cardTitle" style={styles.title}>
        {title}
      </TvzText>
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
  pill: {
    width: 30,
    height: 14,
    borderRadius: radius.pill,
  },
  title: {
    textAlign: 'center',
  },
  body: {
    textAlign: 'center',
    marginTop: spacing.xs,
  },
});

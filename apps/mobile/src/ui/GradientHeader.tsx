import { LinearGradient } from 'expo-linear-gradient';
import type { ReactNode } from 'react';
import { StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { colors, gradient, spacing } from '@/theme';
import { TvzText } from '@/ui/TvzText';

type Props = {
  title: string;
  subtitle?: string;
  /** Rechts naast de titel, bijv. de inbox-bel. */
  right?: ReactNode;
  /** Onder de subtitel, bijv. een subnav met pillen. */
  children?: ReactNode;
};

/**
 * De blauwe gradient-balk zoals op de kring- en steunpagina, met exact
 * dezelfde afmetingen (schermpadding, titel 24, subtitel), voor alle tabs.
 */
export function GradientHeader({ title, subtitle, right, children }: Props) {
  return (
    <LinearGradient {...gradient} style={styles.header}>
      <SafeAreaView edges={['top']}>
        <View style={styles.titleRow}>
          <TvzText preset="screenTitle" style={styles.title}>
            {title}
          </TvzText>
          {right}
        </View>
        {subtitle ? (
          <TvzText preset="secondary" style={styles.sub}>
            {subtitle}
          </TvzText>
        ) : null}
        {children}
      </SafeAreaView>
    </LinearGradient>
  );
}

const styles = StyleSheet.create({
  header: {
    paddingHorizontal: spacing.screen,
    paddingBottom: spacing.lg,
  },
  titleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: spacing.md,
  },
  title: {
    color: colors.white,
    fontSize: 24,
    marginTop: spacing.sm,
    flex: 1,
  },
  sub: {
    color: 'rgba(255,255,255,0.8)',
  },
});

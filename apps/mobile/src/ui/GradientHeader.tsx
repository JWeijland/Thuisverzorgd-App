import { LinearGradient } from 'expo-linear-gradient';
import type { ReactNode } from 'react';
import { StyleSheet, View, useWindowDimensions } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import Svg, { Path } from 'react-native-svg';

import { colors, gradient, spacing } from '@/theme';
import { TvzText } from '@/ui/TvzText';

type Props = {
  title: string;
  subtitle?: string;
  /** Rechts naast de titel, bijv. de inbox-bel. */
  right?: ReactNode;
  /** Onder de subtitel, bijv. een subnav met pillen of de kringbalk. */
  children?: ReactNode;
  /** Golvende onderrand + groene streep onder de titel (ontwerp 1a). */
  wobbel?: boolean;
};

const WAVE_HEIGHT = 18;

/**
 * De blauwe gradient-balk zoals op de kring- en steunpagina, met exact
 * dezelfde afmetingen (schermpadding, titel 24, subtitel). Met `wobbel` krijgt
 * hij de getekende onderrand en het groene streepje uit ontwerp 1a.
 */
export function GradientHeader({ title, subtitle, right, children, wobbel = false }: Props) {
  const { width } = useWindowDimensions();

  return (
    <LinearGradient {...gradient} style={[styles.header, wobbel && styles.headerWobbel]}>
      <SafeAreaView edges={['top']}>
        <View style={styles.titleRow}>
          <View style={styles.titleWrap}>
            <TvzText preset="screenTitle" style={styles.title}>
              {title}
            </TvzText>
            {wobbel ? (
              <Svg width={92} height={9} viewBox="0 0 92 9" style={styles.streep}>
                <Path
                  d="M2 6.2C16 2.4 30 2 44 4.6c14 2.6 28 2.2 46-2.2"
                  stroke={colors.accent}
                  strokeWidth={3.4}
                  strokeLinecap="round"
                  fill="none"
                />
              </Svg>
            ) : null}
          </View>
          {right}
        </View>
        {subtitle ? (
          <TvzText preset="secondary" style={styles.sub}>
            {subtitle}
          </TvzText>
        ) : null}
        {children}
      </SafeAreaView>

      {wobbel ? (
        <Svg
          width={width}
          height={WAVE_HEIGHT}
          viewBox={`0 0 ${width} ${WAVE_HEIGHT}`}
          style={styles.wave}
          pointerEvents="none"
        >
          <Path
            d={`M0 ${WAVE_HEIGHT * 0.55} C ${width * 0.2} -2, ${width * 0.35} ${WAVE_HEIGHT}, ${width * 0.55} ${WAVE_HEIGHT * 0.5} C ${width * 0.75} 0, ${width * 0.9} ${WAVE_HEIGHT * 0.9} ${width} ${WAVE_HEIGHT * 0.35} L ${width} ${WAVE_HEIGHT} L 0 ${WAVE_HEIGHT} Z`}
            fill={colors.bg}
          />
        </Svg>
      ) : null}
    </LinearGradient>
  );
}

const styles = StyleSheet.create({
  header: {
    paddingHorizontal: spacing.screen,
    paddingBottom: spacing.lg,
  },
  headerWobbel: {
    paddingBottom: spacing.lg + WAVE_HEIGHT,
  },
  titleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: spacing.md,
  },
  titleWrap: {
    flex: 1,
  },
  title: {
    color: colors.white,
    fontSize: 24,
    marginTop: spacing.sm,
  },
  streep: {
    marginTop: 2,
    marginBottom: 2,
  },
  sub: {
    color: 'rgba(255,255,255,0.8)',
  },
  wave: {
    position: 'absolute',
    left: 0,
    right: 0,
    bottom: -1,
  },
});

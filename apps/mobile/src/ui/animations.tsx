import { useEffect, type ReactNode } from 'react';
import { StyleSheet, View, type StyleProp, type ViewStyle } from 'react-native';
import Animated, {
  Easing,
  FadeInDown,
  useAnimatedStyle,
  useSharedValue,
  withDelay,
  withRepeat,
  withSequence,
  withTiming,
} from 'react-native-reanimated';

import { colors } from '@/theme';

/** tvzIn: kaarten die verschijnen (0.25–0.3s, opacity 0→1 + translateY 14→0). */
export const tvzIn = FadeInDown.duration(280);

type BounceProps = {
  children: ReactNode;
  /** Vertraging zodat elementen om en om stuiteren (zoals de twee logo-balkjes). */
  delay?: number;
  style?: StyleProp<ViewStyle>;
};

/** tvzBounce: 2.6s-lus, translateY 0 → −7 → 0 (logo-balkjes, typ-indicator). */
export function TvzBounce({ children, delay = 0, style }: BounceProps) {
  const y = useSharedValue(0);

  useEffect(() => {
    y.value = withDelay(
      delay,
      withRepeat(
        withSequence(
          withTiming(-7, { duration: 600, easing: Easing.out(Easing.quad) }),
          withTiming(0, { duration: 600, easing: Easing.in(Easing.quad) }),
          withTiming(0, { duration: 1400 }),
        ),
        -1,
      ),
    );
  }, [delay, y]);

  const animatedStyle = useAnimatedStyle(() => ({ transform: [{ translateY: y.value }] }));
  return <Animated.View style={[animatedStyle, style]}>{children}</Animated.View>;
}

type PulseDotProps = {
  size?: number;
  color?: string;
};

/** tvzPulse: pulserende groene stip (directe hulp, "is nu bij je", makelaars online). */
export function PulseDot({ size = 10, color = colors.accent }: PulseDotProps) {
  const progress = useSharedValue(0);

  useEffect(() => {
    progress.value = withRepeat(withTiming(1, { duration: 1800 }), -1);
  }, [progress]);

  const ringStyle = useAnimatedStyle(() => ({
    transform: [{ scale: 1 + progress.value * 1.4 }],
    opacity: 0.7 * (1 - progress.value),
  }));

  const round = { width: size, height: size, borderRadius: size / 2 };
  return (
    <View style={[styles.pulseContainer, { width: size * 2.6, height: size * 2.6 }]}>
      <Animated.View style={[round, { backgroundColor: color }, styles.ring, ringStyle]} />
      <View style={[round, { backgroundColor: color }]} />
    </View>
  );
}

const styles = StyleSheet.create({
  pulseContainer: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  ring: {
    position: 'absolute',
  },
});

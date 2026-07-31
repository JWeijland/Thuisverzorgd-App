import { useEffect } from 'react';
import { StyleSheet, View } from 'react-native';
import Animated, {
  Easing,
  useAnimatedStyle,
  useSharedValue,
  withDelay,
  withSequence,
  withSpring,
  withTiming,
} from 'react-native-reanimated';

import { colors, shadows } from '@/theme';

/**
 * "De kring als beeld" uit het brandbook: buddy's (blauw en groen) rondom één
 * hulpvrager (navy). Dit motief keert terug in illustraties en decoratie, dus
 * gebruiken we het hier als het beeld bij het aanmaken van een hulpkring.
 *
 * De buddy's komen één voor één binnenvliegen. Zodra de kring echt is
 * gemaakt (`gevierd`) draait de ring een slag rond en wippen de stippen op:
 * klein feestje, zonder confetti-geweld.
 */

const BUDDIES = 6;
/** Afstand van het midden tot de buddy-stippen. */
const STRAAL = 54;
const STIP = 20;
const VLAK = (STRAAL + STIP / 2) * 2 + 8;

export function KringMotief({ gevierd = false }: { gevierd?: boolean }) {
  const draai = useSharedValue(0);
  const wip = useSharedValue(1);

  useEffect(() => {
    if (!gevierd) return;
    // Eén rustige slag rond, met een lichte veer erop.
    draai.value = withTiming(1, { duration: 900, easing: Easing.out(Easing.cubic) });
    wip.value = withSequence(
      withTiming(1.12, { duration: 220, easing: Easing.out(Easing.quad) }),
      withSpring(1, { damping: 7, stiffness: 140 }),
    );
  }, [gevierd, draai, wip]);

  const ringStyle = useAnimatedStyle(() => ({
    transform: [{ rotate: `${draai.value * 360}deg` }, { scale: wip.value }],
  }));

  return (
    <View style={styles.vlak}>
      <Animated.View style={[styles.ring, ringStyle]}>
        {Array.from({ length: BUDDIES }, (_, i) => (
          <Buddy key={i} index={i} />
        ))}
      </Animated.View>

      {/* De hulpvrager in het midden: het beeldmerk in het klein. */}
      <View style={[styles.midden, shadows.card]}>
        <View style={styles.balkjes}>
          <View style={[styles.balkje, { backgroundColor: colors.primaryMid }]} />
          <View style={[styles.balkje, { backgroundColor: colors.accent }]} />
        </View>
        <View style={styles.stam} />
      </View>
    </View>
  );
}

/** Eén buddy: komt met een veer op zijn plek in de kring. */
function Buddy({ index }: { index: number }) {
  const groei = useSharedValue(0);
  const hoek = (index / BUDDIES) * Math.PI * 2 - Math.PI / 2;
  const x = Math.cos(hoek) * STRAAL;
  const y = Math.sin(hoek) * STRAAL;

  useEffect(() => {
    groei.value = withDelay(120 + index * 90, withSpring(1, { damping: 9, stiffness: 130 }));
  }, [groei, index]);

  const style = useAnimatedStyle(() => ({
    // Van het midden naar buiten toe: de kring vormt zich om de hulpvrager heen.
    transform: [
      { translateX: x * groei.value },
      { translateY: y * groei.value },
      { scale: groei.value },
    ],
    opacity: groei.value,
  }));

  // Om en om blauw en groen, zoals het motief in het brandbook.
  const kleur = index % 2 === 0 ? colors.primaryMid : colors.accent;

  return <Animated.View style={[styles.buddy, { backgroundColor: kleur }, style]} />;
}

const styles = StyleSheet.create({
  vlak: {
    width: VLAK,
    height: VLAK,
    alignItems: 'center',
    justifyContent: 'center',
    alignSelf: 'center',
  },
  ring: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    alignItems: 'center',
    justifyContent: 'center',
  },
  buddy: {
    position: 'absolute',
    width: STIP,
    height: STIP,
    borderRadius: STIP / 2,
  },
  midden: {
    width: 54,
    height: 54,
    borderRadius: 27,
    backgroundColor: colors.primaryDark,
    alignItems: 'center',
    justifyContent: 'center',
  },
  balkjes: {
    flexDirection: 'row',
    gap: 3,
    marginBottom: 3,
  },
  balkje: {
    width: 11,
    height: 7,
    borderRadius: 4,
  },
  stam: {
    width: 7,
    height: 17,
    borderRadius: 4,
    backgroundColor: colors.white,
  },
});

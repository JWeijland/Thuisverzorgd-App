import { useEffect } from 'react';
import { Image, StyleSheet, View } from 'react-native';
import Animated, {
  Easing,
  useAnimatedStyle,
  useSharedValue,
  withDelay,
  withSequence,
  withSpring,
  withTiming,
  type SharedValue,
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

/**
 * De gezichten in de kring. Demo-portretten onder de Pexels-licentie (gratis,
 * ook commercieel, zonder naamsvermelding); ze staan hier als illustratie van
 * "een kring van mensen om je heen", niet als echte gebruikers.
 */
const GEZICHTEN = [
  require('../../../assets/images/buddies/30004322.jpg'),
  require('../../../assets/images/buddies/2421934.jpg'),
  require('../../../assets/images/buddies/10347162.jpg'),
  require('../../../assets/images/buddies/8450208.jpg'),
  require('../../../assets/images/buddies/12644996.jpg'),
  require('../../../assets/images/buddies/30450838.jpg'),
];

const BUDDIES = GEZICHTEN.length;
/** Afstand van het midden tot de buddy-stippen. */
const STRAAL = 58;
const STIP = 34;
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
          <Buddy key={i} index={i} draai={draai} />
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
function Buddy({ index, draai }: { index: number; draai: SharedValue<number> }) {
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
      // Tegen de draai van de ring in, zodat de gezichten rechtop blijven
      // terwijl ze om het beeldmerk heen draaien.
      { rotate: `${-draai.value * 360}deg` },
    ],
    opacity: groei.value,
  }));

  // De rand om en om blauw en groen, zoals het motief in het brandbook; in het
  // rondje zelf een gezicht, want dit gaat over mensen.
  const rand = index % 2 === 0 ? colors.primaryMid : colors.accent;

  return (
    <Animated.View style={[styles.buddy, { borderColor: rand }, style]}>
      <Image source={GEZICHTEN[index]} style={styles.gezicht} />
    </Animated.View>
  );
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
    borderWidth: 2.5,
    backgroundColor: colors.white,
    overflow: 'hidden',
  },
  gezicht: {
    width: '100%',
    height: '100%',
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

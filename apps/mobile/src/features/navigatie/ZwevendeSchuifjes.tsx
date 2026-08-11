import { router, usePathname } from 'expo-router';
import { Pressable, StyleSheet, View } from 'react-native';

import { actiefSchuifje, PADEN, type PadId } from '@/features/navigatie/paden';
import { useWalkthrough } from '@/features/onboarding/walkthrough';
import { t } from '@/i18n';
import { haptics } from '@/lib/haptics';
import { colors, radius, shadows, spacing } from '@/theme';
import { TvzText } from '@/ui/TvzText';

type Props = {
  pad: PadId;
  /** Forceer welk schuifje gevuld is (voor pagina's buiten de padmap). */
  actiefRoute?: string;
};

/**
 * De schuifjes als losse zwevende pillen, zonder gekleurde balk eronder.
 * Zo staan ze op de vrijwilligerskaart (handoff, scherm 08): de kaart loopt
 * door tot bovenaan het scherm, de navigatie zweeft eroverheen.
 */
export function ZwevendeSchuifjes({ pad, actiefRoute }: Props) {
  const padConfig = PADEN[pad];
  const pathname = usePathname();
  const actief = actiefSchuifje(padConfig, actiefRoute ?? pathname);
  const meetSchuifje = useWalkthrough((state) => state.meetSchuifje);
  const meetHeader = useWalkthrough((state) => state.meetHeader);

  return (
    // De rondleiding wijst ook hier naar het juiste pilletje: dit scherm heeft
    // geen gekleurde balk, dus meet het zelf op waar de pillen staan.
    <View
      style={styles.rij}
      onLayout={(event) => meetHeader(event.nativeEvent.layout.y + event.nativeEvent.layout.height)}
    >
      {padConfig.schuifjes.map((schuifje) => {
        const isActief = schuifje.route === actief?.route;
        return (
          <Pressable
            key={schuifje.route}
            onLayout={(event) => {
              const { x, width } = event.nativeEvent.layout;
              meetSchuifje(schuifje.route, spacing.screen + x + width / 2);
            }}
            accessibilityRole="tab"
            accessibilityState={{ selected: isActief }}
            accessibilityLabel={t(schuifje.labelKey)}
            onPress={() => {
              if (isActief) return;
              void haptics.selectie();
              router.navigate(schuifje.route as never);
            }}
            style={[styles.pil, shadows.card, isActief && styles.pilActief]}
          >
            <TvzText preset="meta" style={isActief ? styles.tekstActief : styles.tekst}>
              {t(schuifje.labelKey)}
            </TvzText>
          </Pressable>
        );
      })}
    </View>
  );
}

const styles = StyleSheet.create({
  rij: {
    flexDirection: 'row',
    gap: spacing.chipGap,
    paddingHorizontal: spacing.screen,
  },
  pil: {
    borderRadius: radius.pill,
    backgroundColor: colors.white,
    paddingHorizontal: 16,
    minHeight: 40,
    justifyContent: 'center',
  },
  pilActief: {
    backgroundColor: colors.primary,
  },
  tekst: {
    color: colors.ink,
    fontSize: 13,
  },
  tekstActief: {
    color: colors.white,
    fontSize: 13,
  },
});

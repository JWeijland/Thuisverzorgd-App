import { useLocalSearchParams, router } from 'expo-router';
import { StyleSheet, View } from 'react-native';
import Animated from 'react-native-reanimated';

import { TvzMap } from '@/features/map/TvzMap';
import { useBuurtScan } from '@/features/map/useBuurtScan';
import { PadHeader } from '@/features/navigatie/PadHeader';
import { t } from '@/i18n';
import { DEFAULT_REGION } from '@/lib/geo';
import { colors, radius, shadows, spacing } from '@/theme';
import { Bo, Button, TvzBounce, TvzText, tvzIn } from '@/ui';
import { TvzLoader } from '@/ui/TvzLoader';

/**
 * Buurt-scan (handoff §3b): na de keuze wekelijks of eenmalig gaat de app
 * zelf naar de kaart en kijkt Bo hoeveel hulp er in de buurt is. Dat is geen
 * technische stap maar een gevoelsstap: je ziet dat je er niet alleen voor
 * staat. Daarna kies je pas of je een kring opbouwt of een hulpvraag plaatst.
 */
export default function BuurtScan() {
  const { soort } = useLocalSearchParams<{ soort?: string }>();
  const wekelijks = soort !== 'eenmalig';
  const scan = useBuurtScan();

  return (
    <View style={styles.safe}>
      <PadHeader
        pad="regelen"
        actiefRoute="/regelen/voorzieningen"
        kruimels={[t('voorzien.buddyTegelTitel'), t('buurtScan.kruimel')]}
      />

      <View style={styles.kaartWrap}>
        <View style={styles.kaart}>
          <TvzMap initialRegion={DEFAULT_REGION} />
        </View>
        <View pointerEvents="box-none" style={styles.overlay}>
          {scan.bezig ? (
            <View style={[styles.kaartje, shadows.floating]}>
              <TvzBounce>
                <Bo width={82} />
              </TvzBounce>
              <TvzText preset="cardTitle" style={styles.midden}>
                {t('buurtScan.bezig')}
              </TvzText>
              <TvzLoader />
            </View>
          ) : (
            <Animated.View entering={tvzIn} style={[styles.kaartje, shadows.floating]}>
              <TvzText preset="cardTitle" style={styles.midden}>
                {scan.buddys === 0
                  ? t('buurtScan.geenBuddys')
                  : t('buurtScan.gevonden', {
                      buddys: scan.buddys,
                      kringen: scan.kringen,
                    })}
              </TvzText>
              <TvzText preset="secondary" style={styles.midden}>
                {wekelijks ? t('buurtScan.uitlegWekelijks') : t('buurtScan.uitlegEenmalig')}
              </TvzText>
              <Button
                label={wekelijks ? t('buurtScan.bouwKring') : t('buurtScan.zetOpKaart')}
                variant="cta"
                size="lg"
                onPress={() =>
                  router.replace(
                    (wekelijks ? '/regelen/kring-opbouwen' : '/buurt?hulpvraag=1') as never,
                  )
                }
              />
            </Animated.View>
          )}
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: colors.bg,
  },
  kaartWrap: {
    flex: 1,
  },
  kaart: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
  },
  overlay: {
    flex: 1,
    justifyContent: 'flex-end',
    padding: spacing.screen,
  },
  kaartje: {
    backgroundColor: colors.white,
    borderRadius: radius.card,
    padding: spacing.cardPadding,
    alignItems: 'center',
    gap: spacing.md,
  },
  midden: {
    textAlign: 'center',
  },
});

import { useLocalSearchParams, router } from 'expo-router';
import { useEffect, useRef } from 'react';
import { StyleSheet, View } from 'react-native';
import Animated from 'react-native-reanimated';

import { BuddyMetFoto } from '@/features/map/BuddyMetFoto';
import {
  KringMarker,
  OwnLocationMarker,
  TvzMap,
  type TvzMapHandle,
} from '@/features/map/TvzMap';
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
  const kaart = useRef<TvzMapHandle>(null);

  // Zodra de locatie binnen is, schuift de kaart naar je eigen buurt; anders
  // kijk je naar het midden van het land en zie je de markers niet. Eén keer,
  // daarna mag je zelf rondkijken.
  const gericht = useRef(false);
  useEffect(() => {
    if (gericht.current || !scan.locatie) return;
    gericht.current = true;
    kaart.current?.animateToRegion(
      {
        latitude: scan.locatie.lat,
        longitude: scan.locatie.lon,
        latitudeDelta: 0.08,
        longitudeDelta: 0.06,
      },
      600,
    );
  }, [scan.locatie]);

  return (
    <View style={styles.safe}>
      <PadHeader
        pad="regelen"
        actiefRoute="/regelen/voorzieningen"
        kruimels={[t('voorzien.buddyTegelTitel'), t('buurtScan.kruimel')]}
      />

      <View style={styles.kaartWrap}>
        <View style={styles.kaart}>
          {/* De buddy's en kringen die Bo vindt staan ook echt op de kaart:
              de telling zegt hoeveel, de kaart laat zien waar (wens Jelle
              11-08). Zodra we de locatie hebben, kijkt de kaart daarheen. */}
          <TvzMap ref={kaart} initialRegion={DEFAULT_REGION}>
            {scan.kringLijst.map((kring) => (
              <KringMarker
                key={kring.id}
                lat={kring.lat}
                lon={kring.lon}
                naam={kring.name}
                plekkenVrij={kring.plekken_vrij}
              />
            ))}
            {scan.buddyLijst.map((buddy) => (
              <BuddyMetFoto key={buddy.id} buddy={buddy} />
            ))}
            {scan.locatie ? (
              <OwnLocationMarker lat={scan.locatie.lat} lon={scan.locatie.lon} />
            ) : null}
          </TvzMap>
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

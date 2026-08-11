import { LinearGradient } from 'expo-linear-gradient';
import { router } from 'expo-router';
import { Image, Pressable, ScrollView, StyleSheet, View } from 'react-native';
import {
  Car,
  Dog,
  Flower2,
  Hammer,
  HeartPulse,
  Scissors,
  ShoppingBasket,
  Soup,
  Sparkles,
  type LucideIcon,
} from 'lucide-react-native';

import { useDiensten, type Dienst } from '@/features/voorzieningen/api';
import { euro } from '@/features/voorzieningen/slots';
import { t } from '@/i18n';
import { colors, radius, spacing } from '@/theme';
import { TvzText, tvzIn } from '@/ui';
import Animated from 'react-native-reanimated';

/** Foto van de buddy-tegel: twee mensen die samen wandelen. */
const BUDDY_FOTO = require('../../../assets/images/diensten/buddy.jpg');

/** Foto per dienst (Pexels, zie assets/images/diensten/BRONNEN.md). */
const DIENST_FOTOS: Record<string, number> = {
  kapper: require('../../../assets/images/diensten/kapper.jpg'),
  boodschappen: require('../../../assets/images/diensten/boodschappen.jpg'),
  maaltijden: require('../../../assets/images/diensten/maaltijden.jpg'),
  schoonmaak: require('../../../assets/images/diensten/schoonmaak.jpg'),
  tuinman: require('../../../assets/images/diensten/tuinman.jpg'),
  'massage-fysio': require('../../../assets/images/diensten/massage-fysio.jpg'),
  vervoer: require('../../../assets/images/diensten/vervoer.jpg'),
  'hond-uitlaten': require('../../../assets/images/diensten/hond-uitlaten.jpg'),
  klusjesman: require('../../../assets/images/diensten/klusjesman.jpg'),
};

/** Elke dienst een eigen herkenbaar icoon op de tegel. */
const DIENST_ICONS: Record<string, LucideIcon> = {
  kapper: Scissors,
  boodschappen: ShoppingBasket,
  maaltijden: Soup,
  schoonmaak: Sparkles,
  tuinman: Flower2,
  'massage-fysio': HeartPulse,
  vervoer: Car,
  'hond-uitlaten': Dog,
  klusjesman: Hammer,
};

/**
 * Voorzieningen (handoff, scherm 03): het raster met bijna vierkante blokjes.
 * De kop is nu de PadHeader van het hulp-pad, dus dit scherm begint direct
 * met de tegels: Buddy uitgelicht en gratis, daarna de betaalde diensten.
 */
export function Marktplaats() {
  const diensten = useDiensten();
  // Geen zoekbalk meer (feedback Jelle 11-08): met tien tegels zoek je met je
  // ogen, niet met een toetsenbord.
  const lijst = diensten.data ?? [];

  return (
    <View style={styles.safe}>

      <ScrollView contentContainerStyle={styles.lijst}>
        <Animated.View entering={tvzIn}>
            <Pressable
              accessibilityRole="button"
              accessibilityLabel={t('voorzien.buddyTegelTitel')}
              onPress={() => router.push('/dienst/buddy')}
            >
              {/* Een echte foto in plaats van een blauw vlak: je ziet meteen
                  waar een buddy voor is (feedback Jelle 11-08). */}
              <View style={styles.buddyTegel}>
                <Image source={BUDDY_FOTO} style={styles.buddyFoto} resizeMode="cover" />
                <LinearGradient
                  colors={['transparent', 'rgba(17,38,64,0.15)', 'rgba(17,38,64,0.82)']}
                  style={styles.buddySluier}
                />
                <View style={styles.buddyTekst}>
                  <View style={styles.buddyKop}>
                    <TvzText preset="cardTitle" style={styles.buddyTitel}>
                      {t('voorzien.buddyTegelTitel')}
                    </TvzText>
                    <View style={styles.gratisPill}>
                      <TvzText preset="meta" style={styles.gratisTekst}>
                        {t('voorzien.gratisPill')}
                      </TvzText>
                    </View>
                  </View>
                  <TvzText preset="secondary" style={styles.buddySub}>
                    {t('voorzien.buddyTegelTekst')}
                  </TvzText>
                </View>
              </View>
            </Pressable>
        </Animated.View>

        <View style={styles.grid}>
          {lijst.map((dienst) => (
            <DienstTegel key={dienst.id} dienst={dienst} />
          ))}
        </View>

      </ScrollView>
    </View>
  );
}

function DienstTegel({ dienst }: { dienst: Dienst }) {
  const Icon = DIENST_ICONS[dienst.slug] ?? Sparkles;
  const foto = DIENST_FOTOS[dienst.slug];
  const prijs =
    dienst.unit === 'uur'
      ? `${euro(dienst.price_cents)}${t('voorzien.uurKort')}`
      : euro(dienst.price_cents);
  return (
    <Animated.View entering={tvzIn} style={styles.tegelWrap}>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel={`${dienst.name}, ${prijs}, ${dienst.provider.business}`}
        onPress={() => router.push({ pathname: '/dienst/[slug]', params: { slug: dienst.slug } })}
        style={styles.tegel}
      >
        {foto ? (
          <Image source={foto} style={styles.tegelFoto} resizeMode="cover" />
        ) : (
          <View style={styles.ikoonTegel}>
            <Icon color={colors.primaryMid} size={24} strokeWidth={2.2} />
          </View>
        )}
        <View style={styles.tegelTekst}>
          <TvzText preset="cardTitle" numberOfLines={1} style={styles.tegelNaam}>
            {dienst.name}
          </TvzText>
          <TvzText preset="meta" style={styles.tegelPrijs}>
            {prijs}
          </TvzText>
          <TvzText preset="secondary" numberOfLines={1} style={styles.tegelAanbieder}>
            {dienst.provider.business}
          </TvzText>
        </View>
      </Pressable>
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: colors.bg,
  },
  lijst: {
    padding: spacing.screen,
    paddingBottom: spacing.xxl,
    gap: spacing.cardGap,
  },
  buddyTegel: {
    height: 168,
    borderRadius: radius.tile,
    overflow: 'hidden',
    justifyContent: 'flex-end',
  },
  buddyFoto: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
  },
  buddySluier: {
    position: 'absolute',
    left: 0,
    right: 0,
    bottom: 0,
    height: '72%',
  },
  buddyTekst: {
    flex: 1,
  },
  buddyKop: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
  },
  buddyTitel: {
    color: colors.white,
  },
  buddySub: {
    color: 'rgba(255,255,255,0.85)',
    marginTop: 2,
  },
  gratisPill: {
    backgroundColor: colors.white,
    borderRadius: radius.pill,
    paddingHorizontal: 10,
    paddingVertical: 3,
  },
  gratisTekst: {
    color: colors.successText,
  },
  grid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing.cardGap,
  },
  tegelWrap: {
    flexBasis: '48%',
    flexGrow: 1,
  },
  tegel: {
    backgroundColor: colors.white,
    borderRadius: radius.tile,
    // Bijna vierkant blokje, zoals de vormregel voorschrijft; de foto loopt
    // tot de rand, dus de tegel zelf knipt de hoeken bij.
    overflow: 'hidden',
    minHeight: 168,
  },
  tegelFoto: {
    width: '100%',
    height: 96,
  },
  tegelTekst: {
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.md,
  },
  ikoonTegel: {
    width: 44,
    height: 44,
    borderRadius: radius.card,
    backgroundColor: colors.surfaceAlt,
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: spacing.lg,
    marginLeft: spacing.lg,
  },
  tegelNaam: {
    fontSize: 16,
  },
  tegelPrijs: {
    color: colors.primary,
    marginTop: 2,
  },
  tegelAanbieder: {
    marginTop: 2,
  },
});

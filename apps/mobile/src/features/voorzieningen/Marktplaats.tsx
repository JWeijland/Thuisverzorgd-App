import { LinearGradient } from 'expo-linear-gradient';
import { router } from 'expo-router';
import { useState } from 'react';
import { Image, Pressable, ScrollView, StyleSheet, TextInput, View } from 'react-native';
import {
  Car,
  ChevronRight,
  Dog,
  Flower2,
  Hammer,
  HeartHandshake,
  HeartPulse,
  Scissors,
  Search,
  ShoppingBasket,
  Soup,
  Sparkles,
  type LucideIcon,
} from 'lucide-react-native';

import { useDiensten, type Dienst } from '@/features/voorzieningen/api';
import { euro } from '@/features/voorzieningen/slots';
import { t } from '@/i18n';
import { colors, gradient, radius, spacing } from '@/theme';
import { EmptyState, TvzText, tvzIn } from '@/ui';
import Animated from 'react-native-reanimated';

/** Warme foto per dienst (Pexels, zie assets/images/diensten/BRONNEN.md). */
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
  const [zoek, setZoek] = useState('');

  const term = zoek.trim().toLowerCase();
  const lijst = (diensten.data ?? []).filter(
    (dienst) =>
      !term ||
      dienst.name.toLowerCase().includes(term) ||
      dienst.provider.business.toLowerCase().includes(term) ||
      dienst.provider.name.toLowerCase().includes(term),
  );
  // Buddy hoort ook bij de zoekresultaten: gratis hulp is het eerste antwoord.
  const buddyZichtbaar = !term || t('voorzien.buddyTegelTitel').toLowerCase().includes(term);

  const zoekVeld = (
    <View style={[styles.zoekVeld, styles.zoekVeldLicht]}>
      <Search color={colors.inkFaint} size={18} strokeWidth={2.2} />
      <TextInput
        value={zoek}
        onChangeText={setZoek}
        placeholder={t('voorzien.zoeken')}
        placeholderTextColor={colors.inkFaint}
        style={styles.zoekInput}
        autoCorrect={false}
        accessibilityLabel={t('voorzien.zoeken')}
      />
    </View>
  );

  return (
    <View style={styles.safe}>
      <View style={styles.zoekLos}>{zoekVeld}</View>

      <ScrollView contentContainerStyle={styles.lijst}>
        {buddyZichtbaar ? (
          <Animated.View entering={tvzIn}>
            <Pressable
              accessibilityRole="button"
              accessibilityLabel={t('voorzien.buddyTegelTitel')}
              onPress={() => router.push('/dienst/buddy')}
            >
              <LinearGradient {...gradient} style={styles.buddyTegel}>
                <View style={styles.buddyIkoon}>
                  <HeartHandshake color={colors.white} size={26} strokeWidth={2.2} />
                </View>
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
                <ChevronRight color={colors.white} size={22} strokeWidth={2.2} />
              </LinearGradient>
            </Pressable>
          </Animated.View>
        ) : null}

        <View style={styles.grid}>
          {lijst.map((dienst) => (
            <DienstTegel key={dienst.id} dienst={dienst} />
          ))}
        </View>

        {!diensten.isLoading && lijst.length === 0 && !buddyZichtbaar ? (
          <EmptyState title={t('voorzien.geenResultaat')} />
        ) : null}
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
  zoekVeld: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    backgroundColor: colors.white,
    borderRadius: radius.pill,
    paddingHorizontal: 14,
    marginTop: spacing.md,
    minHeight: 46,
    // Ruimte laten voor Bo, die rechts over de rand piept.
    marginRight: 96,
  },
  zoekVeldLicht: {
    marginTop: 0,
    marginRight: 0,
    borderWidth: 1.5,
    borderColor: colors.line,
  },
  zoekLos: {
    paddingHorizontal: spacing.screen,
    paddingBottom: spacing.xs,
  },
  zoekInput: {
    flex: 1,
    fontFamily: 'ComicNeue_400Regular',
    fontSize: 15,
    color: colors.ink,
    paddingVertical: 10,
  },
  lijst: {
    padding: spacing.screen,
    paddingBottom: spacing.xxl,
    gap: spacing.cardGap,
  },
  buddyTegel: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
    borderRadius: radius.tile,
    padding: spacing.cardPadding,
  },
  buddyIkoon: {
    width: 48,
    height: 48,
    borderRadius: radius.card,
    backgroundColor: 'rgba(255,255,255,0.18)',
    alignItems: 'center',
    justifyContent: 'center',
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

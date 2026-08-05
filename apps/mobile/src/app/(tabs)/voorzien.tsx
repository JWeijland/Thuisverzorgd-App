import { LinearGradient } from 'expo-linear-gradient';
import { router } from 'expo-router';
import { useState } from 'react';
import { Pressable, ScrollView, StyleSheet, TextInput, View } from 'react-native';
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
import { EmptyState, GradientHeader, TvzText, tvzIn } from '@/ui';
import Animated from 'react-native-reanimated';

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

/** Voorzieningen: de marktplaats met hulp aan huis (handoff aug 2026). */
export default function VoorzienScreen() {
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

  return (
    <View style={styles.safe}>
      <GradientHeader title={t('voorzien.titel')} subtitle={t('voorzien.subtitel')} wobbel bo>
        <View style={styles.zoekVeld}>
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
      </GradientHeader>

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
        <View style={styles.ikoonTegel}>
          <Icon color={colors.primaryMid} size={24} strokeWidth={2.2} />
        </View>
        <TvzText preset="cardTitle" numberOfLines={1} style={styles.tegelNaam}>
          {dienst.name}
        </TvzText>
        <TvzText preset="meta" style={styles.tegelPrijs}>
          {prijs}
        </TvzText>
        <TvzText preset="secondary" numberOfLines={1} style={styles.tegelAanbieder}>
          {dienst.provider.business}
        </TvzText>
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
  zoekInput: {
    flex: 1,
    fontFamily: 'ComicNeue_400Regular',
    fontSize: 15,
    color: colors.ink,
    paddingVertical: 10,
  },
  lijst: {
    padding: spacing.screen,
    paddingBottom: 110,
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
    padding: spacing.lg,
    // Bijna vierkant blokje, zoals de vormregel voorschrijft.
    minHeight: 148,
  },
  ikoonTegel: {
    width: 44,
    height: 44,
    borderRadius: radius.card,
    backgroundColor: colors.surfaceAlt,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing.md,
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

import { router } from 'expo-router';
import { CalendarClock, ChevronRight, Zap } from 'lucide-react-native';
import { Pressable, ScrollView, StyleSheet, View } from 'react-native';

import { PadHeader } from '@/features/navigatie/PadHeader';
import { t } from '@/i18n';
import { haptics } from '@/lib/haptics';
import { colors, radius, spacing } from '@/theme';
import { Bo, TvzBounce, TvzText } from '@/ui';

/**
 * Buddy (handoff §3b): gratis, vrijwillige hulp. De vraag is niet meer "via
 * je kring of via de kaart" maar "hoe vaak heb je hulp nodig". Bij allebei de
 * antwoorden gaat de app daarna zelf kijken hoeveel hulp er in de buurt is
 * (de buurt-scan), en pas daarna kies je hoe je verder gaat.
 */
export default function BuddyScreen() {
  const opties = [
    {
      soort: 'wekelijks',
      icoon: CalendarClock,
      titel: t('voorzien.buddyWekelijks'),
      uitleg: t('voorzien.buddyWekelijksUitleg'),
    },
    {
      soort: 'eenmalig',
      icoon: Zap,
      titel: t('voorzien.buddyEenmalig'),
      uitleg: t('voorzien.buddyEenmaligUitleg'),
    },
  ] as const;

  return (
    <View style={styles.safe}>
      <PadHeader
        pad="regelen"
        actiefRoute="/regelen/voorzieningen"
        kruimels={[t('voorzien.buddyTegelTitel')]}
      />

      <ScrollView contentContainerStyle={styles.inhoud}>
        <View style={styles.hero}>
          <TvzBounce>
            <Bo width={104} />
          </TvzBounce>
          <TvzText preset="screenTitle" style={styles.titel}>
            {t('voorzien.buddyTitel')}
          </TvzText>
          <View style={styles.gratisPill}>
            <TvzText preset="meta" style={styles.gratisTekst}>
              {t('voorzien.gratisPill')}
            </TvzText>
          </View>
          <TvzText preset="body" style={styles.uitleg}>
            {t('voorzien.buddyUitleg')}
          </TvzText>
        </View>

        {opties.map(({ soort, icoon: Icoon, titel, uitleg }) => (
          <Pressable
            key={soort}
            accessibilityRole="button"
            accessibilityLabel={titel}
            onPress={() => {
              void haptics.stevig();
              router.push(`/regelen/buurt-scan?soort=${soort}`);
            }}
            style={styles.optie}
          >
            <View style={styles.optieIkoon}>
              <Icoon color={colors.primaryMid} size={24} strokeWidth={2.2} />
            </View>
            <View style={styles.optieTekst}>
              <TvzText preset="cardTitle">{titel}</TvzText>
              <TvzText preset="secondary">{uitleg}</TvzText>
            </View>
            <ChevronRight color={colors.inkFaint} size={22} strokeWidth={2.2} />
          </Pressable>
        ))}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: colors.bg,
  },
  inhoud: {
    padding: spacing.screen,
    gap: spacing.cardGap,
    paddingBottom: spacing.xxl,
  },
  hero: {
    alignItems: 'center',
    marginBottom: spacing.sm,
  },
  titel: {
    marginTop: spacing.sm,
  },
  gratisPill: {
    backgroundColor: colors.successBg,
    borderRadius: radius.pill,
    paddingHorizontal: 12,
    paddingVertical: 4,
    marginTop: spacing.sm,
  },
  gratisTekst: {
    color: colors.successText,
  },
  uitleg: {
    textAlign: 'center',
    marginTop: spacing.md,
  },
  optie: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
    backgroundColor: colors.white,
    borderRadius: radius.tile,
    padding: spacing.cardPadding,
  },
  optieIkoon: {
    width: 48,
    height: 48,
    borderRadius: radius.card,
    backgroundColor: colors.surfaceAlt,
    alignItems: 'center',
    justifyContent: 'center',
  },
  optieTekst: {
    flex: 1,
  },
});

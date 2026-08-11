import { LinearGradient } from 'expo-linear-gradient';
import { router } from 'expo-router';
import { Pressable, ScrollView, StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { ChevronLeft, ChevronRight, MapPin, Users } from 'lucide-react-native';

import { useProfile } from '@/features/onboarding/useAuth';
import { t } from '@/i18n';
import { useStatusBalk } from '@/lib/statusbalk';
import { colors, gradient, radius, spacing } from '@/theme';
import { Bo, TvzBounce, TvzText } from '@/ui';

/**
 * Buddy (handoff voorzieningen): gratis, vrijwillige hulp. Twee wegen:
 * via je eigen hulpkring of met een oproep op de buurtkaart.
 */
export default function BuddyScreen() {
  const profile = useProfile();
  useStatusBalk('licht');
  // De beheerder plant kringtaken op de planning-tab; de hulpvrager heeft
  // een eigen kring-tab.
  const kringRoute = profile.data?.role === 'hulpvrager' ? '/regelen/kring' : '/regelen/planning';

  return (
    <View style={styles.safe}>
      <ScrollView contentContainerStyle={styles.scroll}>
        <LinearGradient {...gradient} style={styles.hero}>
          <SafeAreaView edges={['top']}>
            <Pressable
              accessibilityRole="button"
              accessibilityLabel={t('algemeen.terug')}
              onPress={() => router.back()}
              style={styles.terug}
            >
              <ChevronLeft color={colors.white} size={26} strokeWidth={2.4} />
            </Pressable>
            <View style={styles.heroInhoud}>
              <TvzBounce>
                <Bo width={130} />
              </TvzBounce>
              <TvzText preset="screenTitle" style={styles.titel}>
                {t('voorzien.buddyTitel')}
              </TvzText>
              <View style={styles.gratisPill}>
                <TvzText preset="meta" style={styles.gratisTekst}>
                  {t('voorzien.gratisPill')}
                </TvzText>
              </View>
            </View>
          </SafeAreaView>
        </LinearGradient>

        <View style={styles.inhoud}>
          <TvzText preset="body" style={styles.uitleg}>
            {t('voorzien.buddyUitleg')}
          </TvzText>

          {(
            [
              [Users, t('voorzien.buddyKring'), t('voorzien.buddyKringUitleg'), kringRoute],
              [
                MapPin,
                t('voorzien.buddyKaart'),
                t('voorzien.buddyKaartUitleg'),
                '/buurt',
              ],
            ] as const
          ).map(([Icon, titel, uitleg, route]) => (
            <Pressable
              key={titel}
              accessibilityRole="button"
              accessibilityLabel={titel}
              onPress={() => router.replace(route)}
              style={styles.optie}
            >
              <View style={styles.optieIkoon}>
                <Icon color={colors.primaryMid} size={24} strokeWidth={2.2} />
              </View>
              <View style={styles.optieTekst}>
                <TvzText preset="cardTitle">{titel}</TvzText>
                <TvzText preset="secondary">{uitleg}</TvzText>
              </View>
              <ChevronRight color={colors.inkFaint} size={22} strokeWidth={2.2} />
            </Pressable>
          ))}
        </View>
      </ScrollView>
    </View>
  );
}

const HERO_RADIUS = 28;

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: colors.bg,
  },
  scroll: {
    paddingBottom: spacing.xxl,
  },
  hero: {
    borderBottomLeftRadius: HERO_RADIUS,
    borderBottomRightRadius: HERO_RADIUS,
    paddingHorizontal: spacing.screen,
    paddingBottom: spacing.xxl,
  },
  terug: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: 'rgba(255,255,255,0.18)',
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: spacing.sm,
  },
  heroInhoud: {
    alignItems: 'center',
    marginTop: spacing.sm,
  },
  titel: {
    color: colors.white,
    fontSize: 24,
    marginTop: spacing.md,
  },
  gratisPill: {
    backgroundColor: colors.white,
    borderRadius: radius.pill,
    paddingHorizontal: 12,
    paddingVertical: 4,
    marginTop: spacing.sm,
  },
  gratisTekst: {
    color: colors.successText,
  },
  inhoud: {
    padding: spacing.screen,
    gap: spacing.cardGap,
  },
  uitleg: {
    marginBottom: spacing.sm,
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

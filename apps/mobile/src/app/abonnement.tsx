import { LinearGradient } from 'expo-linear-gradient';
import { router } from 'expo-router';
import { Pressable, ScrollView, StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { useActivateSubscription, useSubscription } from '@/features/subscription/api';
import { t } from '@/i18n';
import { colors, gradient, radius, spacing } from '@/theme';
import { Button, Card, TvzText } from '@/ui';

const VOORDELEN = [
  'abonnement.voordeel1',
  'abonnement.voordeel2',
  'abonnement.voordeel3',
  'abonnement.voordeel4',
];

/** Abonnement (screen 12): €4,99-kaart met vier voordelen; pilot-stub activeert de proefmaand. */
export default function AbonnementScreen() {
  const subscription = useSubscription();
  const activate = useActivateSubscription();
  const active = subscription.data?.status === 'proef' || subscription.data?.status === 'actief';

  return (
    <SafeAreaView style={styles.safe}>
      <ScrollView contentContainerStyle={styles.container}>
        <Pressable accessibilityRole="button" onPress={() => router.back()} style={styles.back}>
          <TvzText preset="cardTitle">←</TvzText>
        </Pressable>
        <TvzText preset="screenTitle">
          {t('abonnement.titel')}
          <TvzText preset="screenTitle" style={styles.greenDot}>
            {' '}
          </TvzText>
        </TvzText>
        <TvzText preset="secondary" style={styles.uitleg}>
          {t('abonnement.uitleg')}
        </TvzText>

        <LinearGradient {...gradient} style={styles.priceCard}>
          <View style={styles.priceRow}>
            <TvzText preset="screenTitle" style={styles.price}>
              {t('abonnement.prijs')}
            </TvzText>
            <TvzText preset="secondary" style={styles.perMaand}>
              {t('abonnement.perMaand')}
            </TvzText>
          </View>
          <View style={styles.priceDash} />
          {VOORDELEN.map((key) => (
            <View key={key} style={styles.voordeelRow}>
              <View style={styles.voordeelDash} />
              <TvzText preset="secondary" style={styles.voordeelText}>
                {t(key)}
              </TvzText>
            </View>
          ))}
        </LinearGradient>

        {active ? (
          <Card style={styles.activeCard}>
            <TvzText preset="cardTitle" style={styles.activeTitle}>
              {t('abonnement.actiefTitel')}
            </TvzText>
            <TvzText preset="secondary">{t('abonnement.actiefTekst')}</TvzText>
          </Card>
        ) : (
          <>
            <Button
              label={activate.isPending ? t('algemeen.laden') : t('abonnement.start')}
              variant="cta"
              size="lg"
              disabled={activate.isPending}
              onPress={() => activate.mutate()}
              style={styles.cta}
            />
            <TvzText preset="secondary" style={styles.kleineLettertjes}>
              {t('abonnement.kleineLettertjes')}
            </TvzText>
            <TvzText preset="secondary" style={styles.pilotNote}>
              {t('abonnement.pilotNote')}
            </TvzText>
            <Pressable accessibilityRole="button" onPress={() => router.back()} hitSlop={8}>
              <TvzText preset="meta" style={styles.later}>
                {t('abonnement.later')}
              </TvzText>
            </Pressable>
          </>
        )}
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: colors.bg,
  },
  container: {
    padding: spacing.screen,
    paddingBottom: 60,
  },
  back: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: colors.surfaceAlt,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing.lg,
  },
  greenDot: {
    color: colors.accent,
  },
  uitleg: {
    marginTop: spacing.xs,
    marginBottom: spacing.xl,
  },
  priceCard: {
    borderRadius: radius.card,
    padding: spacing.cardPadding + 4,
  },
  priceRow: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    gap: spacing.sm,
  },
  price: {
    color: colors.white,
    fontSize: 32,
  },
  perMaand: {
    color: 'rgba(255,255,255,0.8)',
    marginBottom: 6,
  },
  priceDash: {
    width: 44,
    height: 5,
    borderRadius: radius.pill,
    backgroundColor: colors.accent,
    marginVertical: spacing.md,
  },
  voordeelRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    marginBottom: spacing.sm,
  },
  voordeelDash: {
    width: 14,
    height: 5,
    borderRadius: radius.pill,
    backgroundColor: colors.accent,
  },
  voordeelText: {
    color: colors.white,
    flex: 1,
  },
  cta: {
    marginTop: spacing.xl,
  },
  kleineLettertjes: {
    textAlign: 'center',
    marginTop: spacing.md,
    color: colors.inkFaint,
    fontSize: 12.5,
  },
  pilotNote: {
    textAlign: 'center',
    marginTop: spacing.xs,
    color: colors.successText,
    fontSize: 12.5,
  },
  later: {
    textAlign: 'center',
    marginTop: spacing.lg,
    color: colors.inkSoft,
  },
  activeCard: {
    marginTop: spacing.xl,
    borderWidth: 1.5,
    borderColor: colors.accent,
  },
  activeTitle: {
    color: colors.successText,
  },
});

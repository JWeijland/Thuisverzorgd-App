import { LinearGradient } from 'expo-linear-gradient';
import { router } from 'expo-router';
import { StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { t } from '@/i18n';
import { colors, gradient, radius, spacing } from '@/theme';
import { Button, TvzBounce, TvzText } from '@/ui';

/** Welkom (screen 01): navy gradient, logo met stuiterende balkjes, twee knoppen. */
export default function WelkomScreen() {
  return (
    <LinearGradient {...gradient} style={styles.fill}>
      <SafeAreaView style={styles.safe}>
        <View style={styles.logoBlock}>
          <View style={styles.logoRow}>
            <TvzBounce>
              <View style={[styles.bar, { backgroundColor: colors.primaryMid }]} />
            </TvzBounce>
            <TvzBounce delay={200}>
              <View style={[styles.bar, { backgroundColor: colors.accent }]} />
            </TvzBounce>
          </View>
          <View style={styles.stem} />
          <TvzText preset="screenTitle" style={styles.wordmark}>
            Thuisverzorgd
          </TvzText>
          <TvzText preset="body" style={styles.tagline}>
            {t('welkom.tagline')}
          </TvzText>
        </View>
        <View style={styles.buttons}>
          <Button
            label={t('welkom.accountAanmaken')}
            variant="cta"
            size="lg"
            onPress={() => router.push({ pathname: '/account', params: { modus: 'nieuw' } })}
          />
          <Button
            label={t('welkom.inloggen')}
            variant="outlineOnDark"
            onPress={() => router.push({ pathname: '/account', params: { modus: 'inloggen' } })}
          />
        </View>
      </SafeAreaView>
    </LinearGradient>
  );
}

const styles = StyleSheet.create({
  fill: { flex: 1 },
  safe: {
    flex: 1,
    justifyContent: 'space-between',
    padding: spacing.screen,
  },
  logoBlock: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  logoRow: {
    flexDirection: 'row',
    gap: 6,
  },
  bar: {
    width: 34,
    height: 16,
    borderRadius: radius.pill,
  },
  stem: {
    width: 16,
    height: 40,
    borderRadius: radius.pill,
    backgroundColor: colors.white,
    marginTop: 4,
  },
  wordmark: {
    color: colors.white,
    marginTop: spacing.xl,
  },
  tagline: {
    color: 'rgba(255,255,255,0.85)',
    marginTop: spacing.xs,
  },
  buttons: {
    gap: spacing.cardGap,
    paddingBottom: spacing.md,
  },
});

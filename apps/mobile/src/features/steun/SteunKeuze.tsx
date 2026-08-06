import { router } from 'expo-router';
import { Pressable, ScrollView, StyleSheet, View } from 'react-native';
import { BookOpen, ChevronRight } from 'lucide-react-native';

import { t } from '@/i18n';
import { colors, radius, spacing } from '@/theme';
import { Card, GradientHeader, PulseDot, TvzText } from '@/ui';

/**
 * Steun voor de hulpvrager: één keuze per scherm, op ouderen-maat.
 * Praten met de hulpmakelaar, of rustig zelf lezen in de wegwijzer.
 */
export function SteunKeuze() {
  return (
    <View style={styles.safe}>
      <GradientHeader
        title={t('steunKeuze.titel')}
        subtitle={t('steunKeuze.uitleg')}
        wobbel
        bo
        boRol="hulpvrager"
      />
      <ScrollView contentContainerStyle={styles.lijst}>
        <Pressable accessibilityRole="button" onPress={() => router.push('/hulpmakelaar')}>
          <Card style={styles.kaart}>
            <View style={styles.kop}>
              <TvzText preset="screenTitle" style={styles.kaartTitel}>
                {t('steunKeuze.praatTitel')}
              </TvzText>
              <ChevronRight color={colors.inkFaint} size={22} strokeWidth={2.2} />
            </View>
            <View style={styles.online}>
              <PulseDot size={9} />
              <TvzText preset="secondary" style={styles.onlineTekst}>
                {t('steunKeuze.praatOnline')}
              </TvzText>
            </View>
            <TvzText preset="body" style={styles.tekst}>
              {t('steunKeuze.praatTekst')}
            </TvzText>
          </Card>
        </Pressable>

        <Pressable accessibilityRole="button" onPress={() => router.push('/wegwijzer-lijst')}>
          <Card style={styles.kaart}>
            <View style={styles.kop}>
              <View style={styles.icoon}>
                <BookOpen color={colors.primaryMid} size={24} strokeWidth={2.2} />
              </View>
              <TvzText preset="screenTitle" style={[styles.kaartTitel, styles.kaartTitelIcoon]}>
                {t('steunKeuze.lezenTitel')}
              </TvzText>
              <ChevronRight color={colors.inkFaint} size={22} strokeWidth={2.2} />
            </View>
            <TvzText preset="body" style={styles.tekst}>
              {t('steunKeuze.lezenTekst')}
            </TvzText>
          </Card>
        </Pressable>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: colors.bg,
  },
  lijst: {
    padding: spacing.screen,
    paddingBottom: 110,
    gap: spacing.md,
  },
  kaart: {
    paddingVertical: spacing.xl,
  },
  kop: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
  },
  icoon: {
    width: 48,
    height: 48,
    borderRadius: radius.tile,
    backgroundColor: colors.tintBlue,
    alignItems: 'center',
    justifyContent: 'center',
  },
  kaartTitel: {
    flex: 1,
    fontSize: 22,
  },
  kaartTitelIcoon: {
    marginLeft: 0,
  },
  online: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginTop: spacing.sm,
  },
  onlineTekst: {
    color: colors.successText,
  },
  tekst: {
    marginTop: spacing.sm,
  },
});

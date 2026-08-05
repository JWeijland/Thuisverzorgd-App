import { router, useLocalSearchParams } from 'expo-router';
import { StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Check } from 'lucide-react-native';

import { t } from '@/i18n';
import { useStatusBalk } from '@/lib/statusbalk';
import { colors, spacing } from '@/theme';
import { Bo, Button, TvzBounce, TvzText } from '@/ui';

/** Boekingsbevestiging: Bo met een groen vinkje-badge (handoff voorzieningen). */
export default function BevestigdScreen() {
  const { naam, moment } = useLocalSearchParams<{ naam: string; moment: string }>();
  useStatusBalk('donker');

  return (
    <SafeAreaView style={styles.safe} edges={['top', 'bottom']}>
      <View style={styles.midden}>
        <View style={styles.boWrap}>
          <TvzBounce>
            <Bo width={150} />
          </TvzBounce>
          <View style={styles.vinkBadge}>
            <Check color={colors.white} size={26} strokeWidth={3} />
          </View>
        </View>
        <TvzText preset="screenTitle" style={styles.titel}>
          {t('voorzien.bevestigdTitel')}
        </TvzText>
        <TvzText preset="body" style={styles.tekst}>
          {t('voorzien.bevestigdTekst', { naam: naam ?? '', moment: moment ?? '' })}
        </TvzText>
      </View>
      <View style={styles.knoppen}>
        <Button
          label={t('voorzien.naarRooster')}
          variant="cta"
          size="lg"
          onPress={() => router.replace('/(tabs)/rooster')}
        />
        <Button
          label={t('voorzien.verderKijken')}
          variant="outline"
          onPress={() => router.replace('/(tabs)/voorzien')}
        />
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: colors.bg,
    padding: spacing.screen,
  },
  midden: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  boWrap: {
    position: 'relative',
  },
  vinkBadge: {
    position: 'absolute',
    right: -6,
    top: 10,
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: colors.accentDark,
    borderWidth: 3,
    borderColor: colors.white,
    alignItems: 'center',
    justifyContent: 'center',
  },
  titel: {
    marginTop: spacing.xl,
  },
  tekst: {
    textAlign: 'center',
    marginTop: spacing.sm,
    paddingHorizontal: spacing.lg,
  },
  knoppen: {
    gap: spacing.cardGap,
    paddingBottom: spacing.md,
  },
});

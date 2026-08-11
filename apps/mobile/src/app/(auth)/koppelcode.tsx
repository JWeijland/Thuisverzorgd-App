import { router } from 'expo-router';
import { ScrollView, StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { MijnCode } from '@/features/circles/MijnCode';
import { t } from '@/i18n';
import { useStatusBalk } from '@/lib/statusbalk';
import { colors, spacing } from '@/theme';
import { Bo, Button, TvzBounce, TvzText } from '@/ui';

/**
 * De code van de oudere, direct na de rolkeuze (feedback Jelle 11-08).
 *
 * Hiervoor moest de oudere zelf een code van de beheerder overtikken. Dat is
 * omgedraaid: hij ziet nu zijn eigen code en geeft die door. Overtikken doet
 * degene die de hulp regelt, want die zit toch al in de app te regelen.
 */
export default function KoppelcodeScreen() {
  useStatusBalk('donker');

  return (
    <SafeAreaView style={styles.safe} edges={['top']}>
      <ScrollView contentContainerStyle={styles.container}>
        <View style={styles.kop}>
          <TvzBounce>
            <Bo width={92} rol="hulpvrager" />
          </TvzBounce>
          <TvzText preset="screenTitle" style={styles.titel}>
            {t('mijnCode.onboardingTitel')}
          </TvzText>
          <TvzText preset="body" style={styles.uitleg}>
            {t('mijnCode.onboardingUitleg')}
          </TvzText>
        </View>

        <MijnCode />

        <View style={styles.voet}>
          <Button
            label={t('algemeen.verder')}
            variant="cta"
            size="lg"
            onPress={() =>
              router.replace({ pathname: '/kringuitleg', params: { rol: 'hulpvrager' } })
            }
          />
        </View>
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
    paddingBottom: spacing.xxl,
    gap: spacing.lg,
    flexGrow: 1,
  },
  kop: {
    alignItems: 'center',
    gap: spacing.sm,
    marginTop: spacing.lg,
  },
  titel: {
    textAlign: 'center',
  },
  uitleg: {
    textAlign: 'center',
  },
  voet: {
    marginTop: 'auto',
  },
});

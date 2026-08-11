import { router } from 'expo-router';
import { StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { t } from '@/i18n';
import { useStatusBalk } from '@/lib/statusbalk';
import { colors, radius, spacing } from '@/theme';
import { Bo, Button, TvzBounce, TvzText } from '@/ui';

/**
 * Het verhaal van de app, eenmalig vóór de rolkeuze. Drie regels, meer niet:
 * hulp vragen, iemand komt langs, je ziet wie. Alles wat daar niet in past is
 * eruit gehaald, want dit scherm werd te druk (feedback Jelle 11-08). Geen
 * uitleg over gratis of betaald: het heet gewoon hulp.
 */
export default function VerhaalScreen() {
  useStatusBalk('donker');

  const stappen = [1, 2, 3] as const;

  return (
    <SafeAreaView style={styles.safe} edges={['top']}>
      <View style={styles.container}>
        <View style={styles.kop}>
          <TvzBounce>
            <Bo width={96} />
          </TvzBounce>
          <TvzText preset="screenTitle" style={styles.titel}>
            {t('verhaal.titel')}
          </TvzText>
        </View>

        <View style={styles.stappen}>
          {stappen.map((nummer) => (
            <View key={nummer} style={styles.stap}>
              <View style={styles.stapNr}>
                <TvzText preset="cardTitle" style={styles.stapNrTekst}>
                  {nummer}
                </TvzText>
              </View>
              <View style={styles.stapTekst}>
                <TvzText preset="cardTitle" style={styles.stapTitel}>
                  {t(`verhaal.stap${nummer}Titel`)}
                </TvzText>
                <TvzText preset="body" style={styles.stapUitleg}>
                  {t(`verhaal.stap${nummer}Tekst`)}
                </TvzText>
              </View>
            </View>
          ))}
        </View>

        <Button
          label={t('algemeen.verder')}
          variant="cta"
          size="lg"
          style={styles.knop}
          onPress={() => router.replace('/rolkeuze')}
        />
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: colors.bg,
  },
  container: {
    flex: 1,
    padding: spacing.screen,
    paddingBottom: spacing.xl,
  },
  kop: {
    alignItems: 'center',
    marginTop: spacing.lg,
  },
  titel: {
    marginTop: spacing.md,
    fontSize: 30,
    textAlign: 'center',
  },
  // De drie stappen vullen het midden van het scherm; ruim uit elkaar, zodat
  // je ze los van elkaar leest.
  stappen: {
    flex: 1,
    justifyContent: 'center',
    gap: spacing.xl,
  },
  stap: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.lg,
  },
  stapNr: {
    width: 40,
    height: 40,
    borderRadius: radius.pill,
    backgroundColor: colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
  },
  stapNrTekst: {
    color: colors.white,
    fontSize: 19,
  },
  stapTekst: {
    flex: 1,
  },
  stapTitel: {
    fontSize: 21,
  },
  stapUitleg: {
    fontSize: 17,
    lineHeight: 25,
    marginTop: 2,
  },
  knop: {
    borderRadius: radius.card,
  },
});

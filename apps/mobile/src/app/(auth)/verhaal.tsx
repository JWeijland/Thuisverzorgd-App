import { router } from 'expo-router';
import { ScrollView, StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { WeekStrip } from '@/features/tasks/WeekStrip';
import { t } from '@/i18n';
import { useStatusBalk } from '@/lib/statusbalk';
import { colors, radius, spacing } from '@/theme';
import { Button, Card, TvzText } from '@/ui';

/**
 * Het verhaal van de app in drie stappen (ontwerp 4.0), eenmalig vóór de
 * rolkeuze: weten, regelen, er is iemand. De week is de rode draad en komt
 * hier voor het eerst in beeld.
 */
export default function VerhaalScreen() {
  useStatusBalk('donker');

  const stappen = [1, 2, 3] as const;

  return (
    <SafeAreaView style={styles.safe} edges={['top']}>
      <ScrollView contentContainerStyle={styles.container}>
        <TvzText preset="screenTitle" style={styles.titel}>
          {t('verhaal.titel')}
        </TvzText>
        <TvzText preset="secondary" style={styles.uitleg}>
          {t('verhaal.uitleg')}
        </TvzText>

        <Card style={styles.stappenKaart}>
          {stappen.map((nummer) => (
            <View key={nummer} style={styles.stap}>
              <View style={styles.stapNr}>
                <TvzText preset="meta" style={styles.stapNrTekst}>
                  {nummer}
                </TvzText>
              </View>
              <View style={styles.stapTekst}>
                <TvzText preset="cardTitle" style={styles.stapTitel}>
                  {t(`verhaal.stap${nummer}Titel`)}
                </TvzText>
                <TvzText preset="secondary">{t(`verhaal.stap${nummer}Tekst`)}</TvzText>
              </View>
            </View>
          ))}
        </Card>

        <Card>
          <TvzText preset="cardTitle" style={styles.weekTitel}>
            {t('verhaal.weekTitel')}
          </TvzText>
          <WeekStrip anchor={new Date()} tasks={[]} legenda />
        </Card>

        <View style={styles.voet}>
          <Button
            label={t('algemeen.verder')}
            variant="cta"
            size="lg"
            onPress={() => router.replace('/rolkeuze')}
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
    gap: spacing.cardGap,
    flexGrow: 1,
  },
  titel: {
    marginTop: spacing.md,
  },
  uitleg: {
    marginBottom: spacing.md,
  },
  stappenKaart: {
    gap: spacing.lg,
    paddingVertical: spacing.xl,
  },
  stap: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: spacing.md,
  },
  stapNr: {
    width: 26,
    height: 26,
    borderRadius: radius.pill,
    backgroundColor: colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
  },
  stapNrTekst: {
    color: colors.white,
  },
  stapTekst: {
    flex: 1,
  },
  stapTitel: {
    marginBottom: 2,
  },
  weekTitel: {
    marginBottom: spacing.md,
  },
  voet: {
    marginTop: 'auto',
    paddingTop: spacing.lg,
  },
});

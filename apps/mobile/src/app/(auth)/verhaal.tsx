import { router } from 'expo-router';
import { ScrollView, StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import type { Task } from '@/features/tasks/api';
import { WeekStrip } from '@/features/tasks/WeekStrip';
import { t } from '@/i18n';
import { isoWeekDays, toDateString } from '@/lib/dates';
import { useStatusBalk } from '@/lib/statusbalk';
import { colors, radius, spacing } from '@/theme';
import { Button, Card, TvzText } from '@/ui';

/**
 * Het verhaal van de app in drie stappen (ontwerp 4.0), eenmalig vóór de
 * rolkeuze: weten, regelen, er is iemand. De week is de rode draad en komt
 * hier voor het eerst in beeld.
 */
/**
 * Twee voorbeeldtaken zodat de weekstrip in de onboarding laat zien wat de
 * legenda belooft: een groene dag waar iemand komt en een oranje dag die nog
 * open staat.
 */
function voorbeeldWeek(anker: Date): Task[] {
  const dagen = isoWeekDays(anker);
  const leeg = {
    circle_id: '',
    custom_label: null,
    recurrence: 'eenmalig' as const,
    claimed_by: null,
    claimer: null,
    circle: null,
  };
  return [
    {
      ...leeg,
      id: 'voorbeeld-1',
      type: 'boodschappen' as const,
      date: toDateString(dagen[1]!),
      time: '10:00',
      status: 'ingepland' as const,
    },
    {
      ...leeg,
      id: 'voorbeeld-2',
      type: 'wandelen' as const,
      date: toDateString(dagen[4]!),
      time: '14:00',
      status: 'open' as const,
    },
  ];
}

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
          {/* Een voorbeeldweek met echte stipjes: een lege strip met een
              legenda beloofde bolletjes die je nergens zag. */}
          <WeekStrip anchor={new Date()} tasks={voorbeeldWeek(new Date())} legenda />
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

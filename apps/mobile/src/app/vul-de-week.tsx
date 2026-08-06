import { router } from 'expo-router';
import { ScrollView, StyleSheet, View } from 'react-native';

import { useMyCircle } from '@/features/circles/api';
import { useTasks } from '@/features/tasks/api';
import { t } from '@/i18n';
import { isoWeekDays } from '@/lib/dates';
import { useStatusBalk } from '@/lib/statusbalk';
import { colors, radius, spacing } from '@/theme';
import { Button, Card, Pill, TvzText } from '@/ui';
import { TerugKop } from '@/ui/TerugKop';

/**
 * Vul de week: het knooppunt van de rode draad. Eén vraag (wie komt er?)
 * met drie routes in laagvolgorde: de kring (gratis), een oproep in de
 * buurt (gratis) of een geboekte dienst (betaald). Alles eindigt als een
 * afspraak in dezelfde week.
 */
export default function VulDeWeekScreen() {
  useStatusBalk('donker');
  const circle = useMyCircle();
  const now = new Date();
  const week = isoWeekDays(now);
  const tasks = useTasks(circle.data?.id, week[0]!, week[6]!);
  const openTaken = (tasks.data ?? []).filter((taak) => taak.status === 'open').length;

  return (
    <View style={styles.safe}>
      <TerugKop titel={t('vulWeek.titel')} sub={t('vulWeek.uitleg')} />
      <ScrollView contentContainerStyle={styles.lijst}>
        {openTaken > 0 ? (
          <TvzText preset="secondary" style={styles.openTekst}>
            {openTaken === 1 ? t('vulWeek.open1') : t('vulWeek.open', { aantal: openTaken })}
          </TvzText>
        ) : null}

        <Card style={[styles.kaart, styles.kaartKring]}>
          <View style={styles.kop}>
            <TvzText preset="cardTitle" style={styles.kaartTitel}>
              {t('vulWeek.kringTitel')}
            </TvzText>
            <Pill label={t('voorzien.gratisPill')} color={colors.successText} backgroundColor={colors.successBg} />
          </View>
          <TvzText preset="secondary" style={styles.tekst}>
            {t('vulWeek.kringTekst')}
          </TvzText>
          <Button
            label={t('vulWeek.kringKnop')}
            variant="cta"
            onPress={() => router.push('/taak-plannen')}
            style={styles.knop}
          />
        </Card>

        <Card style={[styles.kaart, styles.kaartBuurt]}>
          <View style={styles.kop}>
            <TvzText preset="cardTitle" style={styles.kaartTitel}>
              {t('vulWeek.buurtTitel')}
            </TvzText>
            <Pill label={t('voorzien.gratisPill')} color={colors.successText} backgroundColor={colors.successBg} />
          </View>
          <TvzText preset="secondary" style={styles.tekst}>
            {t('vulWeek.buurtTekst')}
          </TvzText>
          <Button
            label={t('vulWeek.buurtKnop')}
            variant="outline"
            onPress={() => router.navigate('/buurt')}
            style={styles.knop}
          />
        </Card>

        <Card style={[styles.kaart, styles.kaartDienst]}>
          <View style={styles.kop}>
            <TvzText preset="cardTitle" style={styles.kaartTitel}>
              {t('vulWeek.dienstTitel')}
            </TvzText>
            <Pill label={t('vulWeek.dienstPill')} />
          </View>
          <TvzText preset="secondary" style={styles.tekst}>
            {t('vulWeek.dienstTekst')}
          </TvzText>
          <Button
            label={t('vulWeek.dienstKnop')}
            variant="outline"
            onPress={() => router.navigate('/voorzien')}
            style={styles.knop}
          />
        </Card>

        <TvzText preset="secondary" style={styles.slotzin}>
          {t('vulWeek.slotzin')}
        </TvzText>
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
    paddingTop: spacing.sm,
    paddingBottom: 110,
    gap: spacing.cardGap,
  },
  openTekst: {
    marginBottom: spacing.xs,
  },
  kaart: {
    borderLeftWidth: 5,
    borderRadius: radius.card,
  },
  kaartKring: {
    borderLeftColor: colors.accentDark,
  },
  kaartBuurt: {
    borderLeftColor: colors.primary,
  },
  kaartDienst: {
    borderLeftColor: colors.primaryMid,
  },
  kop: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
  },
  kaartTitel: {
    flex: 1,
  },
  tekst: {
    marginTop: spacing.xs,
  },
  knop: {
    marginTop: spacing.md,
  },
  slotzin: {
    textAlign: 'center',
    marginTop: spacing.sm,
    color: colors.inkFaint,
  },
});

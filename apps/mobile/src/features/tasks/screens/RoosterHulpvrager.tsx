import { router } from 'expo-router';
import { Linking, ScrollView, StyleSheet, View } from 'react-native';

import { useCircleMembers, useMyCircle } from '@/features/circles/api';
import { useTasks } from '@/features/tasks/api';
import { taskLabel } from '@/features/tasks/logic';
import { useProfile } from '@/features/onboarding/useAuth';
import { t } from '@/i18n';
import { formatHumanDate, formatTime, greetingKey, isoWeekDays, toDateString } from '@/lib/dates';
import { colors, radius, shadows, spacing } from '@/theme';
import { Avatar, Button, Card, EmptyState, GradientHeader, PulseDot, TvzText } from '@/ui';

/**
 * Rooster · hulpvrager (screen 24): grote weergave. "Anna is nu bij je" met
 * pulserende stip en grote belknop, daaronder "Straks", plus herkenningstip.
 * Grotere tekst (17–29) en 62px-knoppen volgens de handoff.
 */
export function RoosterHulpvrager() {
  const profile = useProfile();
  const circle = useMyCircle();
  const now = new Date();
  const week = isoWeekDays(now);
  const tasks = useTasks(circle.data?.id, week[0]!, week[6]!);
  const members = useCircleMembers(circle.data?.id);

  const firstName = profile.data?.name.split(' ')[0] ?? '';
  const todayKey = toDateString(now);
  const nowMinutes = now.getHours() * 60 + now.getMinutes();

  const claimedToday = (tasks.data ?? []).filter(
    (task) => task.date === todayKey && task.status === 'ingepland' && task.claimer,
  );
  const current = claimedToday.find((task) => {
    const [h, m] = task.time.split(':').map(Number);
    const start = h! * 60 + m!;
    return start <= nowMinutes && nowMinutes < start + 90;
  });
  const upcoming = (tasks.data ?? []).filter(
    (task) =>
      task.status === 'ingepland' &&
      task.claimer &&
      task.id !== current?.id &&
      (task.date > todayKey ||
        (task.date === todayKey &&
          Number(task.time.slice(0, 2)) * 60 + Number(task.time.slice(3, 5)) > nowMinutes)),
  );
  const nextTask = upcoming[0];
  const beheerder = (members.data ?? []).find((member) => member.member_role === 'beheerder');

  return (
    <View style={styles.safe}>
      <GradientHeader
        title={t(`rooster.${greetingKey(now.getHours())}`, { naam: firstName })}
        subtitle={formatHumanDate(now)}
      />
      <ScrollView contentContainerStyle={styles.container}>
        {current?.claimer ? (
          <View style={[styles.nowCard, shadows.card]}>
            <View style={styles.nowRow}>
              <Avatar name={current.claimer.name} size={52} />
              <View style={styles.nowInfo}>
                <TvzText preset="cardTitle" style={styles.nowTitle}>
                  {t('rooster.isNuBijJe', { naam: current.claimer.name.split(' ')[0]! })}
                </TvzText>
                <TvzText preset="body">{taskLabel(current)}</TvzText>
              </View>
              <PulseDot />
            </View>
            {current.claimer.phone ? (
              <View style={styles.callWrap}>
                <TvzText
                  preset="cardTitle"
                  style={styles.callButton}
                  onPress={() => Linking.openURL(`tel:${current.claimer!.phone}`)}
                  accessibilityRole="button"
                >
                  📞 {t('rooster.belKort', { naam: current.claimer.name.split(' ')[0]! })}
                </TvzText>
              </View>
            ) : null}
          </View>
        ) : circle.data ? (
          <Card style={styles.restCard}>
            <EmptyState title={t('rooster.rustigVandaag')} body={t('rooster.rustigTekst')} />
          </Card>
        ) : (
          // Nog geen kring: alleen de koppelcode is nog nodig.
          <Card style={styles.restCard}>
            <EmptyState title={t('koppelcode.nodigTitel')} body={t('koppelcode.nodigTekst')} />
            <Button
              label={t('koppelcode.invullen')}
              variant="cta"
              size="lg"
              onPress={() => router.push('/koppelcode')}
            />
          </Card>
        )}

        {nextTask?.claimer ? (
          <>
            <TvzText preset="cardTitle" style={styles.straks}>
              {t('rooster.straks')}
            </TvzText>
            <Card>
              <View style={styles.nowRow}>
                <Avatar name={nextTask.claimer.name} size={44} />
                <View style={styles.nowInfo}>
                  <TvzText preset="cardTitle">
                    {t('rooster.komtOm', {
                      naam: nextTask.claimer.name.split(' ')[0]!,
                      tijd: formatTime(nextTask.time),
                    })}
                  </TvzText>
                  <TvzText preset="secondary" style={styles.bigSecondary}>
                    {taskLabel(nextTask)}
                  </TvzText>
                </View>
              </View>
            </Card>
            <TvzText preset="secondary" style={styles.tip}>
              {t('rooster.herkenningstip', {
                naam: nextTask.claimer.name.split(' ')[0]!,
                beheerder: beheerder?.profile?.name.split(' ')[0] ?? 'de beheerder',
              })}
            </TvzText>
          </>
        ) : null}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: colors.bg },
  container: {
    padding: spacing.screen,
    paddingBottom: 110,
  },
  nowCard: {
    backgroundColor: colors.white,
    borderRadius: radius.card,
    borderWidth: 1.5,
    borderColor: colors.accent,
    padding: spacing.cardPadding,
  },
  nowRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
  },
  nowInfo: { flex: 1 },
  nowTitle: {
    fontSize: 19,
  },
  callWrap: {
    marginTop: spacing.md,
  },
  callButton: {
    backgroundColor: colors.primary,
    color: colors.white,
    borderRadius: radius.pill,
    textAlign: 'center',
    paddingVertical: 18,
    minHeight: 62,
    overflow: 'hidden',
    fontSize: 18,
  },
  restCard: {},
  straks: {
    marginTop: spacing.xl,
    marginBottom: spacing.sm,
  },
  bigSecondary: {
    fontSize: 15,
  },
  tip: {
    marginTop: spacing.md,
    fontSize: 14.5,
  },
});

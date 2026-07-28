import { LinearGradient } from 'expo-linear-gradient';
import { useState } from 'react';
import { ScrollView, StyleSheet, TextInput, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { useMyCircle } from '@/features/circles/api';
import { InboxBell } from '@/features/notifications/InboxBell';
import { cancelTaskReminder, scheduleTaskReminder } from '@/features/notifications/push';
import { useTaskRpc, useTasks, type Task } from '@/features/tasks/api';
import { TaskRow } from '@/features/tasks/TaskRow';
import { WeekStrip } from '@/features/tasks/WeekStrip';
import { useProfile } from '@/features/onboarding/useAuth';
import { t } from '@/i18n';
import { MONTH_FULL, isoWeekDays, isoWeekNumber } from '@/lib/dates';
import { colors, gradient, radius, spacing } from '@/theme';
import { BottomSheet, Button, Card, EmptyState, SectionHeader, TvzText } from '@/ui';

/** Rooster · vrijwilliger (screen 19): teller, weekstrip, aannemen en afronden met logboekje. */
export function RoosterVrijwilliger() {
  const profile = useProfile();
  const circle = useMyCircle();
  const now = new Date();
  const week = isoWeekDays(now);
  const tasks = useTasks(circle.data?.id, week[0]!, week[6]!);
  const { claim, complete, release } = useTaskRpc(circle.data?.id);
  const [completing, setCompleting] = useState<Task | null>(null);
  const [note, setNote] = useState('');

  const firstName = profile.data?.name.split(' ')[0] ?? '';
  const helped = profile.data?.helped_count ?? 0;

  function closeSheet() {
    setCompleting(null);
    setNote('');
  }

  return (
    <SafeAreaView style={styles.safe} edges={['top']}>
      <ScrollView contentContainerStyle={styles.container}>
        <View style={styles.headerRow}>
          <TvzText preset="screenTitle">Hoi {firstName}.</TvzText>
          <InboxBell />
        </View>

        <LinearGradient {...gradient} style={styles.counter}>
          <TvzText preset="cardTitle" style={styles.counterTitle}>
            {t('rooster.mensenGeholpen', { aantal: helped })}
          </TvzText>
          <View style={styles.counterBar} />
          <TvzText preset="secondary" style={styles.counterText}>
            {t('rooster.goedBezig', { maand: MONTH_FULL[now.getMonth()]! })}
          </TvzText>
        </LinearGradient>

        {circle.data ? (
          <>
            <SectionHeader title={t('rooster.weekTitel', { week: isoWeekNumber(now) })} />
            <WeekStrip anchor={now} tasks={tasks.data ?? []} />
            <View style={styles.list}>
              {(tasks.data ?? []).map((task) => (
                <TaskRow
                  key={task.id}
                  task={task}
                  myId={profile.data?.id}
                  isBeheerder={false}
                  onClaim={(item) =>
                    claim.mutate(item.id, {
                      onSuccess: (won) => {
                        if (won) scheduleTaskReminder(item);
                      },
                    })
                  }
                  onComplete={(item) => setCompleting(item)}
                />
              ))}
              {!tasks.isLoading && (tasks.data ?? []).length === 0 ? (
                <Card>
                  <EmptyState title={t('rooster.geenTaken')} body={t('rooster.openTakenTip')} />
                </Card>
              ) : null}
            </View>
            <TvzText preset="secondary" style={styles.tip}>
              {t('rooster.openTakenTip')}
            </TvzText>
          </>
        ) : (
          <Card style={styles.emptyCircle}>
            <EmptyState title={t('kring.legeStaatTitel')} body={t('kring.legeStaatTekst')} />
          </Card>
        )}
      </ScrollView>

      <BottomSheet visible={!!completing} onClose={closeSheet} title={t('rooster.logboekTitel')}>
        <TvzText preset="secondary">{t('rooster.logboekUitleg')}</TvzText>
        <TextInput
          value={note}
          onChangeText={setNote}
          placeholder={t('rooster.logboekPlaceholder')}
          placeholderTextColor={colors.inkFaint}
          multiline
          style={styles.noteInput}
        />
        <Button
          label={t('rooster.logboekVerstuur')}
          variant="cta"
          size="lg"
          disabled={complete.isPending || note.trim().length === 0}
          onPress={() => {
            if (!completing) return;
            cancelTaskReminder(completing.id);
            complete.mutate(
              { taskId: completing.id, note: note.trim() },
              { onSuccess: closeSheet },
            );
          }}
        />
        <Button
          label={t('rooster.logboekZonder')}
          variant="outline"
          style={styles.sheetSecondary}
          disabled={complete.isPending}
          onPress={() => {
            if (!completing) return;
            complete.mutate({ taskId: completing.id }, { onSuccess: closeSheet });
          }}
        />
        <Button
          label={t('rooster.teruggeven')}
          variant="danger"
          style={styles.sheetSecondary}
          disabled={release.isPending}
          onPress={() => {
            if (!completing) return;
            cancelTaskReminder(completing.id);
            release.mutate(completing.id, { onSuccess: closeSheet });
          }}
        />
      </BottomSheet>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1 },
  container: {
    padding: spacing.screen,
    paddingBottom: 110,
  },
  headerRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  counter: {
    borderRadius: radius.card,
    padding: spacing.cardPadding,
    marginTop: spacing.lg,
  },
  counterTitle: {
    color: colors.white,
  },
  counterBar: {
    width: 44,
    height: 5,
    borderRadius: radius.pill,
    backgroundColor: colors.accent,
    marginVertical: spacing.sm,
  },
  counterText: {
    color: 'rgba(255,255,255,0.85)',
  },
  list: {
    marginTop: spacing.md,
    gap: spacing.cardGap,
  },
  tip: {
    textAlign: 'center',
    marginTop: spacing.lg,
    color: colors.inkFaint,
  },
  emptyCircle: {
    marginTop: spacing.lg,
  },
  noteInput: {
    backgroundColor: colors.bg,
    borderWidth: 1.5,
    borderColor: colors.line,
    borderRadius: radius.input,
    padding: spacing.md,
    minHeight: 88,
    textAlignVertical: 'top',
    marginVertical: spacing.md,
    fontFamily: 'ComicNeue_400Regular',
    fontSize: 15.5,
    color: colors.ink,
  },
  sheetSecondary: {
    marginTop: spacing.sm,
  },
});

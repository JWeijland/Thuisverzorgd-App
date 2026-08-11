import { useState } from 'react';
import { ScrollView, StyleSheet, TextInput, View } from 'react-native';

import { useMyCircle } from '@/features/circles/api';
import { KringBalk } from '@/features/circles/KringBalk';
import { KringBerichtenKnop } from '@/features/circles/KringBerichtenKnop';
import { InboxBell } from '@/features/notifications/InboxBell';
import { cancelTaskReminder, scheduleTaskReminder } from '@/features/notifications/push';
import { useTaskRpc, useTasks, type Task } from '@/features/tasks/api';
import { TaskRow } from '@/features/tasks/TaskRow';
import { WeekStrip } from '@/features/tasks/WeekStrip';
import { useProfile } from '@/features/onboarding/useAuth';
import { useBoekingen } from '@/features/voorzieningen/api';
import { t } from '@/i18n';
import { formatHumanDate, isoWeekDays, isoWeekNumber, toDateString } from '@/lib/dates';
import { colors, radius, spacing } from '@/theme';
import {
  BottomSheet,
  Button,
  Card,
  EmptyState,
  SectionHeader,
  TvzText,
} from '@/ui';
import { PaginaKop } from '@/ui/PaginaKop';

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
  const [selectedDay, setSelectedDay] = useState<string | undefined>();

  const firstName = profile.data?.name.split(' ')[0] ?? '';
  // Tik op Ma/Di/Wo in de weekstrip = alleen de taken van die dag bekijken.
  const visibleTasks = (tasks.data ?? []).filter(
    (task) => !selectedDay || task.date === selectedDay,
  );

  // Geboekte diensten als blauwe stipjes: de buddy ziet dezelfde week als
  // de beheerder en de hulpvrager (rode draad).
  const boekingen = useBoekingen();
  const weekKeys = week.map((day) => toDateString(day));
  const boekingDagen = (boekingen.data ?? [])
    .map((boeking) => toDateString(new Date(boeking.slot_at)))
    .filter((dag) => weekKeys.includes(dag));

  // Kleine teller: hoe vaak hielp je deze maand al? Waardering is persoonlijk
  // en gemeend, nooit opgeklopt (brandbook 1.4).
  const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
  const monthEnd = new Date(now.getFullYear(), now.getMonth() + 1, 0);
  const monthTasks = useTasks(circle.data?.id, monthStart, monthEnd);
  const geholpen = (monthTasks.data ?? []).filter(
    (task) => task.claimed_by === profile.data?.id && task.status === 'gedaan',
  ).length;

  function closeSheet() {
    setCompleting(null);
    setNote('');
  }

  return (
    <View style={styles.safe}>
      <PaginaKop
        titel={`Hoi ${firstName}.`}
        sub={formatHumanDate(now)}
        rechts={
          <>
            {circle.data ? <KringBerichtenKnop circleId={circle.data.id} /> : null}
            <InboxBell />
          </>
        }
      />
      <ScrollView contentContainerStyle={styles.container}>
        {circle.data ? (
          <>
            <View style={styles.kringBalkWrap}>
              <KringBalk circleId={circle.data.id} name={circle.data.name} />
            </View>
            {geholpen > 0 ? (
              <Card style={styles.teller}>
                <TvzText preset="secondary" style={styles.tellerTekst}>
                  {geholpen === 1
                    ? t('rooster.geholpen1')
                    : t('rooster.geholpen', { aantal: geholpen })}
                </TvzText>
              </Card>
            ) : null}
            <SectionHeader title={t('rooster.weekTitel', { week: isoWeekNumber(now) })} />
            <WeekStrip
              anchor={now}
              tasks={tasks.data ?? []}
              boekingDagen={boekingDagen}
              legenda
              selected={selectedDay}
              onSelectDay={(key) => setSelectedDay(key === selectedDay ? undefined : key)}
            />
            <View style={styles.list}>
              {visibleTasks.map((task) => (
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
              {!tasks.isLoading && visibleTasks.length === 0 ? (
                <Card>
                  <EmptyState title={t('rooster.geenTaken')} body={t('rooster.openTakenTip')} bo />
                </Card>
              ) : null}
            </View>
            <TvzText preset="secondary" style={styles.tip}>
              {t('rooster.openTakenTip')}
            </TvzText>
          </>
        ) : (
          <Card style={styles.emptyCircle}>
            <EmptyState title={t('kring.legeStaatTitel')} body={t('kring.legeStaatTekst')} bo />
          </Card>
        )}
      </ScrollView>

      <BottomSheet visible={!!completing} onClose={closeSheet} title={t('rooster.logboekTitel')}>
        <TvzText preset="secondary">{t('rooster.logboekUitleg')}</TvzText>
        <TextInput
          textContentType="none"
          autoComplete="off"
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
    </View>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: colors.bg },
  container: {
    padding: spacing.screen,
    paddingBottom: spacing.xxl,
  },
  kringBalkWrap: {
    marginBottom: spacing.md,
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
  teller: {
    backgroundColor: colors.successBg,
    marginBottom: spacing.sm,
  },
  tellerTekst: {
    color: colors.successText,
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

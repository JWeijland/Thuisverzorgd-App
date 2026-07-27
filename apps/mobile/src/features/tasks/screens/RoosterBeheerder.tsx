import { router } from 'expo-router';
import { useState } from 'react';
import { Linking, ScrollView, StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { useMyCircle } from '@/features/circles/api';
import { InboxBell } from '@/features/notifications/InboxBell';
import { useCreateTask, useTaskLogs, useTaskRpc, useTasks } from '@/features/tasks/api';
import { taskLabel } from '@/features/tasks/logic';
import { TaskPlanner } from '@/features/tasks/TaskPlanner';
import { TaskRow } from '@/features/tasks/TaskRow';
import { WeekStrip } from '@/features/tasks/WeekStrip';
import { useProfile } from '@/features/onboarding/useAuth';
import { t } from '@/i18n';
import {
  formatHumanDate,
  formatTime,
  greetingKey,
  isoWeekDays,
  isoWeekNumber,
  toDateString,
} from '@/lib/dates';
import { colors, spacing } from '@/theme';
import { Avatar, Button, Card, EmptyState, PulseDot, SectionHeader, TvzText } from '@/ui';

/** Rooster · beheerder (screen 05/06): begroeting, taak van vandaag, planner, weekstrip, lijst, Uit de kring. */
export function RoosterBeheerder() {
  const profile = useProfile();
  const circle = useMyCircle();
  const now = new Date();
  const week = isoWeekDays(now);
  const tasks = useTasks(circle.data?.id, week[0]!, week[6]!);
  const logs = useTaskLogs(circle.data?.id);
  const createTask = useCreateTask(circle.data?.id);
  const { cancel } = useTaskRpc(circle.data?.id);
  const [plannerOpen, setPlannerOpen] = useState(false);

  const firstName = profile.data?.name.split(' ')[0] ?? '';
  const todayKey = toDateString(now);
  const todayTask = (tasks.data ?? []).find(
    (task) => task.date === todayKey && task.status === 'ingepland' && task.claimer,
  );

  return (
    <SafeAreaView style={styles.safe} edges={['top']}>
      <ScrollView contentContainerStyle={styles.container}>
        <View style={styles.headerRow}>
          <View style={styles.headerText}>
            <TvzText preset="screenTitle">
              {t(`rooster.${greetingKey(now.getHours())}`, { naam: firstName })}
            </TvzText>
            <TvzText preset="secondary">{formatHumanDate(now)}</TvzText>
          </View>
          <InboxBell />
        </View>

        {!circle.isLoading && !circle.data ? (
          <Card style={styles.section}>
            <EmptyState title={t('rooster.geenKring')} body={t('rooster.geenKringTekst')} />
            <Button
              label={t('tabs.kring')}
              variant="cta"
              onPress={() => router.navigate('/kring')}
            />
          </Card>
        ) : null}

        {todayTask?.claimer ? (
          <Card style={styles.section}>
            <View style={styles.todayRow}>
              <Avatar name={todayTask.claimer.name} />
              <View style={styles.todayInfo}>
                <TvzText preset="cardTitle">{todayTask.claimer.name}</TvzText>
                <TvzText preset="secondary">
                  {t('rooster.komtVandaagOm', { tijd: formatTime(todayTask.time) })}
                </TvzText>
              </View>
              <PulseDot size={8} />
            </View>
            <TvzText preset="secondary" style={styles.todayTask}>
              {taskLabel(todayTask)} · {t('rooster.duurIndicatie')}
            </TvzText>
            {todayTask.claimer.phone ? (
              <Button
                label={t('rooster.bel', {
                  naam: todayTask.claimer.name.split(' ')[0]!,
                  telefoon: todayTask.claimer.phone,
                })}
                variant="outline"
                onPress={() => Linking.openURL(`tel:${todayTask.claimer!.phone}`)}
                style={styles.callButton}
              />
            ) : null}
          </Card>
        ) : null}

        {circle.data ? (
          <>
            <SectionHeader
              title={t('rooster.weekTitel', { week: isoWeekNumber(now) })}
              actionLabel={t('planner.heleWeek')}
              onActionPress={() => router.push('/weekplanning')}
            />
            <Button
              label={plannerOpen ? t('rooster.sluitTaakplanner') : t('rooster.taakInplannen')}
              variant="cta"
              size="lg"
              onPress={() => setPlannerOpen((open) => !open)}
            />
            {plannerOpen ? (
              <Card style={styles.plannerCard}>
                <TaskPlanner
                  anchor={now}
                  submitLabel={t('planner.zetInRooster')}
                  busy={createTask.isPending}
                  onSubmit={(task) => {
                    createTask.mutate(task, { onSuccess: () => setPlannerOpen(false) });
                  }}
                />
              </Card>
            ) : null}

            <View style={styles.weekStrip}>
              <WeekStrip anchor={now} tasks={tasks.data ?? []} />
            </View>

            <View style={styles.list}>
              {(tasks.data ?? []).map((task) => (
                <TaskRow
                  key={task.id}
                  task={task}
                  myId={profile.data?.id}
                  isBeheerder
                  onCancelTask={(item) => cancel.mutate(item.id)}
                />
              ))}
              {!tasks.isLoading && (tasks.data ?? []).length === 0 ? (
                <Card>
                  <EmptyState title={t('rooster.geenTaken')} body={t('rooster.geenTakenTekst')} />
                </Card>
              ) : null}
            </View>

            {(logs.data ?? []).length > 0 ? (
              <>
                <SectionHeader title={t('rooster.uitDeKring')} />
                <View style={styles.list}>
                  {(logs.data ?? []).map((log) => (
                    <Card key={log.id} style={styles.logCard}>
                      <TvzText preset="body" style={styles.logNote}>
                        “{log.note}”
                      </TvzText>
                      <TvzText preset="secondary">{log.author?.name?.split(' ')[0] ?? ''}</TvzText>
                    </Card>
                  ))}
                </View>
              </>
            ) : null}
          </>
        ) : null}
      </ScrollView>
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
    alignItems: 'flex-start',
    justifyContent: 'space-between',
  },
  headerText: {
    flex: 1,
  },
  section: {
    marginTop: spacing.lg,
  },
  todayRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
  },
  todayInfo: { flex: 1 },
  todayTask: {
    marginTop: spacing.sm,
    color: colors.successText,
  },
  callButton: {
    marginTop: spacing.md,
    backgroundColor: colors.tintBlue,
    borderWidth: 0,
  },
  plannerCard: {
    marginTop: spacing.cardGap,
  },
  weekStrip: {
    marginTop: spacing.md,
  },
  list: {
    marginTop: spacing.md,
    gap: spacing.cardGap,
  },
  logCard: {
    paddingVertical: spacing.md,
  },
  logNote: {
    fontStyle: 'italic',
  },
});

import { router } from 'expo-router';
import { useState } from 'react';
import {
  KeyboardAvoidingView,
  Linking,
  Platform,
  ScrollView,
  StyleSheet,
  View,
} from 'react-native';

import { useMyCircle } from '@/features/circles/api';
import { KringBalk } from '@/features/circles/KringBalk';
import { KringBerichtenKnop } from '@/features/circles/KringBerichtenKnop';
import { InboxBell } from '@/features/notifications/InboxBell';
import { useCreateTask, useTaskLogs, useTaskRpc, useTasks } from '@/features/tasks/api';
import { computeWorkload, taskLabel } from '@/features/tasks/logic';
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
import { colors, radius, spacing } from '@/theme';
import {
  Avatar,
  Button,
  Card,
  EmptyState,
  GradientHeader,
  PulseDot,
  SectionHeader,
  TvzText,
} from '@/ui';

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
  const [selectedDay, setSelectedDay] = useState<string | undefined>();

  const firstName = profile.data?.name.split(' ')[0] ?? '';
  const todayKey = toDateString(now);
  const todayTask = (tasks.data ?? []).find(
    (task) => task.date === todayKey && task.status === 'ingepland' && task.claimer,
  );
  // Tik op Ma/Di/Wo in de weekstrip = alleen de taken van die dag bekijken.
  const visibleTasks = (tasks.data ?? []).filter(
    (task) => !selectedDay || task.date === selectedDay,
  );

  // Belastingverdeling van deze maand (stond eerder op de kring-tab).
  const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
  const monthEnd = new Date(now.getFullYear(), now.getMonth() + 1, 0);
  const monthTasks = useTasks(circle.data?.id, monthStart, monthEnd);
  const workload = computeWorkload(monthTasks.data ?? [], now);
  const maxCount = workload[0]?.count ?? 0;

  return (
    <View style={styles.safe}>
      <GradientHeader
        title={t(`rooster.${greetingKey(now.getHours())}`, { naam: firstName })}
        subtitle={formatHumanDate(now)}
        wobbel
        right={
          <View style={styles.headerActies}>
            {circle.data ? <KringBerichtenKnop circleId={circle.data.id} /> : null}
            <InboxBell />
          </View>
        }
      >
        {circle.data ? (
          <View style={styles.kringBalkWrap}>
            <KringBalk
              circleId={circle.data.id}
              name={circle.data.name}
              linkCode={circle.data.link_code}
              isBeheerder
              onDark
            />
          </View>
        ) : null}
      </GradientHeader>
      <KeyboardAvoidingView
        style={styles.fill}
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      >
        <ScrollView contentContainerStyle={styles.container} keyboardShouldPersistTaps="handled">
          {!circle.isLoading && !circle.data ? (
            <Card style={styles.section}>
              <EmptyState title={t('rooster.geenKring')} body={t('rooster.geenKringTekst')} />
              <Button
                label={t('kring.maakKnop')}
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
                <WeekStrip
                  anchor={now}
                  tasks={tasks.data ?? []}
                  selected={selectedDay}
                  onSelectDay={(key) => setSelectedDay(key === selectedDay ? undefined : key)}
                />
              </View>

              <View style={styles.list}>
                {visibleTasks.map((task) => (
                  <TaskRow
                    key={task.id}
                    task={task}
                    myId={profile.data?.id}
                    isBeheerder
                    onCancelTask={(item) => cancel.mutate(item.id)}
                  />
                ))}
                {!tasks.isLoading && visibleTasks.length === 0 ? (
                  <Card>
                    <EmptyState title={t('rooster.geenTaken')} body={t('rooster.geenTakenTekst')} />
                  </Card>
                ) : null}
              </View>

              {workload.length > 0 ? (
                <>
                  <SectionHeader title={t('kring.wieDoetWat')} />
                  <Card style={styles.workloadCard}>
                    {workload.map((row) => (
                      <View key={row.profileId} style={styles.workloadRow}>
                        <TvzText preset="secondary" style={styles.workloadName}>
                          {row.name}
                        </TvzText>
                        <View style={styles.workloadTrack}>
                          <View
                            style={[
                              styles.workloadBar,
                              {
                                width: `${Math.max(8, (row.count / Math.max(maxCount, 1)) * 100)}%`,
                                backgroundColor:
                                  row.count === maxCount ? colors.primary : colors.accent,
                              },
                            ]}
                          />
                        </View>
                        <TvzText preset="meta" style={styles.workloadCount}>
                          {row.count === 1
                            ? t('kring.taak1')
                            : t('kring.taken', { aantal: row.count })}
                        </TvzText>
                      </View>
                    ))}
                    {workload.length > 1 ? (
                      <TvzText preset="secondary" style={styles.advies}>
                        {t('kring.spreidAdvies', { naam: workload[0]!.name })}
                      </TvzText>
                    ) : null}
                  </Card>
                </>
              ) : null}

              {(logs.data ?? []).length > 0 ? (
                <>
                  <SectionHeader title={t('rooster.uitDeKring')} />
                  <View style={styles.list}>
                    {(logs.data ?? []).map((log) => (
                      <Card key={log.id} style={styles.logCard}>
                        <TvzText preset="body" style={styles.logNote}>
                          “{log.note}”
                        </TvzText>
                        <TvzText preset="secondary">
                          {log.author?.name?.split(' ')[0] ?? ''}
                        </TvzText>
                      </Card>
                    ))}
                  </View>
                </>
              ) : null}
            </>
          ) : null}
        </ScrollView>
      </KeyboardAvoidingView>
    </View>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: colors.bg },
  fill: { flex: 1 },
  container: {
    padding: spacing.screen,
    paddingBottom: 110,
  },
  section: {
    marginBottom: spacing.lg,
  },
  headerActies: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
  },
  kringBalkWrap: {
    marginTop: spacing.md,
  },
  workloadCard: {
    gap: spacing.sm,
  },
  workloadRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
  },
  workloadName: {
    width: 56,
  },
  workloadTrack: {
    flex: 1,
    height: 8,
    borderRadius: radius.pill,
    backgroundColor: colors.surfaceAlt,
    overflow: 'hidden',
  },
  workloadBar: {
    height: 8,
    borderRadius: radius.pill,
  },
  workloadCount: {
    width: 64,
    textAlign: 'right',
  },
  advies: {
    marginTop: spacing.sm,
    fontStyle: 'italic',
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

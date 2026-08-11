import { router, useLocalSearchParams } from 'expo-router';
import { useState } from 'react';
import {
  KeyboardAvoidingView,
  Linking,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  View,
} from 'react-native';
import { X } from 'lucide-react-native';

import { ProfileAvatar } from '@/features/avatars/ProfileAvatar';
import { useMyCircle } from '@/features/circles/api';
import { ProefweekTerugblik } from '@/features/circles/ProefweekTerugblik';
import { KringBerichtenKnop } from '@/features/circles/KringBerichtenKnop';
import { InboxBell } from '@/features/notifications/InboxBell';
import { useTaskLogs, useTaskRpc, useTasks } from '@/features/tasks/api';
import { taskLabel } from '@/features/tasks/logic';
import { TaskRow } from '@/features/tasks/TaskRow';
import { WeekStrip } from '@/features/tasks/WeekStrip';
import { useProfile } from '@/features/onboarding/useAuth';
import { GeboekteDiensten } from '@/features/voorzieningen/GeboekteDiensten';
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
import { Button, Card, EmptyState, PulseDot, SectionHeader, TvzText } from '@/ui';
import { PaginaKop } from '@/ui/PaginaKop';

/**
 * Kring-tab · beheerder (ontwerp 4.0): de week van de kring. Eén functie:
 * zien wie er wanneer komt en open plekken vullen. Plannen, leden en
 * berichten zijn eigen pagina's (/taak-plannen en /regelen/kring).
 */
export function RoosterBeheerder() {
  const profile = useProfile();
  const circle = useMyCircle();
  const now = new Date();
  const week = isoWeekDays(now);
  const tasks = useTasks(circle.data?.id, week[0]!, week[6]!);
  const logs = useTaskLogs(circle.data?.id);
  const { cancel } = useTaskRpc(circle.data?.id);
  // Na het inplannen springt de agenda naar die dag en verschijnt de groene
  // bevestiging (handoff, scherm 06 stap 8).
  const { ingepland } = useLocalSearchParams<{ ingepland?: string }>();
  const [selectedDay, setSelectedDay] = useState<string | undefined>(ingepland);
  const [bevestiging, setBevestiging] = useState<string | undefined>(ingepland);

  const voornaam = profile.data?.name.split(' ')[0] ?? '';

  const todayKey = toDateString(now);
  const todayTask = (tasks.data ?? []).find(
    (task) => task.date === todayKey && task.status === 'ingepland' && task.claimer,
  );
  // Tik op Ma/Di/Wo in de weekstrip = alleen de taken van die dag bekijken.
  const visibleTasks = (tasks.data ?? []).filter(
    (task) => !selectedDay || task.date === selectedDay,
  );


  return (
    <View style={styles.safe}>
      {/* Handoff, scherm 05: de planning begint met een begroeting en de datum
          van vandaag; de gekleurde balk erboven is de PadHeader. */}
      <PaginaKop
        titel={t(`rooster.${greetingKey(new Date().getHours())}`, { naam: voornaam })}
        sub={formatHumanDate(new Date())}
        rechts={
          <>
            {circle.data ? <KringBerichtenKnop circleId={circle.data.id} /> : null}
            <InboxBell />
          </>
        }
      />
      {bevestiging ? (
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={t('algemeen.sluiten')}
          onPress={() => setBevestiging(undefined)}
          style={styles.bevestiging}
        >
          <TvzText preset="bodyBold" style={styles.bevestigingTekst}>
            {t('planner.ingeplandKort')}
          </TvzText>
          <X color={colors.successText} size={18} strokeWidth={2.4} />
        </Pressable>
      ) : null}

      <KeyboardAvoidingView
        style={styles.fill}
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      >
        <ScrollView contentContainerStyle={styles.container} keyboardShouldPersistTaps="handled">
          {circle.data ? (
            <ProefweekTerugblik
              circleId={circle.data.id}
              gestartOp={circle.data.trial_started_at ?? null}
              bevestigdOp={circle.data.trial_confirmed_at ?? null}
              nu={now}
            />
          ) : null}

          {/* Zonder kring kun je geen kringtaak inplannen, maar wel spontane
              hulp vragen: die pakt een vrijwilliger uit de buurt op, ook
              zonder kring (feedback Jelle 11-08). */}
          {!circle.isLoading && !circle.data ? (
            <Card style={styles.section}>
              <EmptyState
                title={t('planner.geenKringTitel')}
                body={t('planner.geenKringTekst')}
                bo
              />
              <Button
                label={t('planner.vraagSpontaan')}
                variant="cta"
                size="lg"
                onPress={() => router.navigate('/buurt?hulpvraag=1' as never)}
              />
              <Button
                label={t('planner.maakKring')}
                variant="outline"
                style={styles.tweedeKnop}
                onPress={() => router.navigate('/regelen/kring')}
              />
            </Card>
          ) : null}

          {todayTask?.claimer ? (
            <Card style={styles.section}>
              <View style={styles.todayRow}>
                <ProfileAvatar
                  name={todayTask.claimer.name}
                  avatarPath={todayTask.claimer.avatar_path}
                />
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
                label={t('rooster.taakInplannen')}
                variant="cta"
                size="lg"
                onPress={() => router.push('/taak-plannen')}
              />

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

          <GeboekteDiensten />
        </ScrollView>
      </KeyboardAvoidingView>
    </View>
  );
}

const styles = StyleSheet.create({
  tweedeKnop: {
    marginTop: spacing.sm,
  },
  bevestiging: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
    marginHorizontal: spacing.screen,
    marginBottom: spacing.sm,
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.md,
    borderRadius: 12,
    backgroundColor: colors.successBg,
  },
  bevestigingTekst: {
    flex: 1,
    color: colors.successText,
  },
  safe: { flex: 1, backgroundColor: colors.bg },
  fill: { flex: 1 },
  container: {
    padding: spacing.screen,
    paddingBottom: spacing.xxl,
  },
  section: {
    marginBottom: spacing.lg,
  },
  vulKaart: {
    marginTop: spacing.md,
  },
  vulTekst: {
    marginBottom: spacing.md,
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

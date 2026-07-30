import { LinearGradient } from 'expo-linear-gradient';
import { router } from 'expo-router';
import { useState } from 'react';
import { Pressable, ScrollView, StyleSheet, TextInput, View } from 'react-native';
import { MessagesSquare } from 'lucide-react-native';

import { useMyCircle } from '@/features/circles/api';
import { KringBalk } from '@/features/circles/KringBalk';
import { InboxBell } from '@/features/notifications/InboxBell';
import { cancelTaskReminder, scheduleTaskReminder } from '@/features/notifications/push';
import { useTaskRpc, useTasks, type Task } from '@/features/tasks/api';
import { TaskRow } from '@/features/tasks/TaskRow';
import { WeekStrip } from '@/features/tasks/WeekStrip';
import { useProfile } from '@/features/onboarding/useAuth';
import { t } from '@/i18n';
import { MONTH_FULL, formatHumanDate, isoWeekDays, isoWeekNumber } from '@/lib/dates';
import { colors, gradient, radius, spacing } from '@/theme';
import {
  BottomSheet,
  Button,
  Card,
  EmptyState,
  GradientHeader,
  ProgressRing,
  SectionHeader,
  TvzText,
} from '@/ui';

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
  const helped = profile.data?.helped_count ?? 0;
  // Tik op Ma/Di/Wo in de weekstrip = alleen de taken van die dag bekijken.
  const visibleTasks = (tasks.data ?? []).filter(
    (task) => !selectedDay || task.date === selectedDay,
  );

  // Voortgangsring: hoeveel van jouw taken deze maand zijn al afgerond?
  const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
  const monthEnd = new Date(now.getFullYear(), now.getMonth() + 1, 0);
  const monthTasks = useTasks(circle.data?.id, monthStart, monthEnd);
  const mine = (monthTasks.data ?? []).filter((task) => task.claimed_by === profile.data?.id);
  const mineDone = mine.filter((task) => task.status === 'gedaan').length;
  const ringValue = mine.length > 0 ? mineDone / mine.length : 0;

  function closeSheet() {
    setCompleting(null);
    setNote('');
  }

  return (
    <View style={styles.safe}>
      <GradientHeader
        title={`Hoi ${firstName}.`}
        subtitle={formatHumanDate(now)}
        wobbel
        right={
          <View style={styles.headerActies}>
            {circle.data ? (
              <Pressable
                accessibilityRole="button"
                accessibilityLabel={t('kring.berichtenTitel')}
                onPress={() => router.push('/kringchat')}
                style={styles.berichtenKnop}
              >
                <MessagesSquare color={colors.primary} size={20} strokeWidth={2.2} />
              </Pressable>
            ) : null}
            <InboxBell />
          </View>
        }
      >
        {circle.data ? (
          <View style={styles.kringBalkWrap}>
            <KringBalk circleId={circle.data.id} name={circle.data.name} onDark />
          </View>
        ) : null}
      </GradientHeader>
      <ScrollView contentContainerStyle={styles.container}>
        <LinearGradient {...gradient} style={styles.counter}>
          <TvzText preset="cardTitle" style={styles.counterTitle}>
            {helped === 1
              ? t('rooster.mensGeholpen')
              : t('rooster.mensenGeholpen', { aantal: helped })}
          </TvzText>
          <View style={styles.counterRij}>
            <ProgressRing value={ringValue} label={`${mineDone}`} onDark />
            <TvzText preset="secondary" style={styles.counterText}>
              {mine.length > 0
                ? t('rooster.maandVoortgang', {
                    gedaan: mineDone,
                    totaal: mine.length,
                    maand: MONTH_FULL[now.getMonth()]!,
                  })
                : t('rooster.goedBezig', { maand: MONTH_FULL[now.getMonth()]! })}
            </TvzText>
          </View>
        </LinearGradient>

        {circle.data ? (
          <>
            <SectionHeader title={t('rooster.weekTitel', { week: isoWeekNumber(now) })} />
            <WeekStrip
              anchor={now}
              tasks={tasks.data ?? []}
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
    </View>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: colors.bg },
  container: {
    padding: spacing.screen,
    paddingBottom: 110,
  },
  headerActies: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
  },
  berichtenKnop: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: colors.white,
    alignItems: 'center',
    justifyContent: 'center',
  },
  kringBalkWrap: {
    marginTop: spacing.md,
  },
  // Vlakken bijna vierkant (brandbook): radius 12, ook voor deze tellerkaart.
  counter: {
    borderRadius: radius.card,
    padding: spacing.cardPadding,
  },
  counterTitle: {
    color: colors.white,
  },
  counterRij: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.lg,
    marginTop: spacing.md,
  },
  counterText: {
    flex: 1,
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

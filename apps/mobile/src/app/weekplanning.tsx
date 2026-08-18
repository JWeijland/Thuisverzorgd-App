import { router } from 'expo-router';
import { useMemo, useState } from 'react';
import {
  KeyboardAvoidingView,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  View,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { useMyCircle } from '@/features/circles/api';
import { useDraftMutations, useDrafts, useTasks } from '@/features/tasks/api';
import { taskLabel } from '@/features/tasks/logic';
import { TaskPlanner } from '@/features/tasks/TaskPlanner';
import { t } from '@/i18n';
import {
  WEEKDAY_SHORT,
  formatShortDate,
  formatTime,
  isoWeekNumber,
  parseDateString,
  startOfIsoWeek,
} from '@/lib/dates';
import { colors, spacing } from '@/theme';
import { Button, Card, SectionHeader, TvzText } from '@/ui';
import { useStatusBalk } from '@/lib/statusbalk';

const PERIODS = [
  { key: 'periode1w', weeks: 1 },
  { key: 'periode2w', weeks: 2 },
  { key: 'periode1m', weeks: 4 },
  { key: 'periode2m', weeks: 9 },
] as const;

/**
 * Weekplanning / conceptplanner (screen 07): puzzel in concept, de kring ziet
 * niets tot "Publiceren"; daarna staat alles in één keer live.
 */
export default function WeekplanningScreen() {
  useStatusBalk('donker');
  const circle = useMyCircle();
  const drafts = useDrafts(circle.data?.id);
  const { add, remove, publish } = useDraftMutations(circle.data?.id);
  const [periodIndex, setPeriodIndex] = useState(0);
  const [weekOffset, setWeekOffset] = useState(0);
  const [published, setPublished] = useState<number | null>(null);

  const now = new Date();
  const weeks = PERIODS[periodIndex]!.weeks;
  const anchor = useMemo(() => {
    const monday = startOfIsoWeek(now);
    monday.setDate(monday.getDate() + weekOffset * 7);
    return monday;
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [weekOffset]);

  // Al gepubliceerde taken van de huidige week (ter referentie onderaan).
  const thisWeekEnd = useMemo(() => {
    const end = startOfIsoWeek(now);
    end.setDate(end.getDate() + 6);
    return end;
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);
  const publishedTasks = useTasks(circle.data?.id, startOfIsoWeek(now), thisWeekEnd);

  const draftList = drafts.data ?? [];

  return (
    <SafeAreaView style={styles.safe}>
      <KeyboardAvoidingView
        style={styles.fill}
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      >
        <ScrollView contentContainerStyle={styles.container} keyboardShouldPersistTaps="handled">
          <View style={styles.headerRow}>
            <Pressable accessibilityRole="button" onPress={() => router.back()} style={styles.back}>
              <TvzText preset="cardTitle">←</TvzText>
            </Pressable>
            <TvzText preset="screenTitle" style={styles.title}>
              {t('weekplanning.titel')}
            </TvzText>
          </View>
          <TvzText preset="secondary" style={styles.uitleg}>
            {t('weekplanning.uitleg')}
          </TvzText>

          <TvzText preset="meta" style={styles.label}>
            {t('weekplanning.periode')}
          </TvzText>
          <View style={styles.chips}>
            {PERIODS.map((period, i) => (
              <Pressable
                key={period.key}
                accessibilityRole="button"
                accessibilityState={{ selected: periodIndex === i }}
                onPress={() => {
                  setPeriodIndex(i);
                  setWeekOffset(0);
                }}
                style={[styles.periodChip, periodIndex === i && styles.periodChipActive]}
              >
                <TvzText
                  preset="meta"
                  style={periodIndex === i ? styles.periodTextActive : undefined}
                >
                  {t(`weekplanning.${period.key}`)}
                </TvzText>
              </Pressable>
            ))}
          </View>

          {weeks > 1 ? (
            <>
              <TvzText preset="meta" style={styles.label}>
                {t('weekplanning.welkeWeek')}
              </TvzText>
              <View style={styles.chips}>
                {Array.from({ length: weeks }, (_, i) => {
                  const monday = startOfIsoWeek(now);
                  monday.setDate(monday.getDate() + i * 7);
                  const num = isoWeekNumber(monday);
                  return (
                    <Pressable
                      key={i}
                      accessibilityRole="button"
                      accessibilityState={{ selected: weekOffset === i }}
                      onPress={() => setWeekOffset(i)}
                      style={[styles.weekChip, weekOffset === i && styles.weekChipActive]}
                    >
                      <TvzText
                        preset="meta"
                        style={weekOffset === i ? styles.periodTextActive : undefined}
                      >
                        Wk {num}
                      </TvzText>
                    </Pressable>
                  );
                })}
              </View>
            </>
          ) : null}

          <Card style={styles.plannerCard}>
            <TaskPlanner
              anchor={anchor}
              submitLabel={`+ Zet in concept · wk ${isoWeekNumber(anchor)}`}
              busy={add.isPending}
              onSubmit={(task) => add.mutate(task)}
            />
          </Card>

          <SectionHeader title={t('weekplanning.conceptKop', { aantal: draftList.length })} />
          {draftList.length === 0 ? (
            <Card dashed style={styles.emptyDraft}>
              <TvzText preset="secondary" style={styles.emptyDraftText}>
                {t('weekplanning.conceptLeeg')}
              </TvzText>
            </Card>
          ) : (
            <View style={styles.draftList}>
              {draftList.map((draft) => {
                const date = parseDateString(draft.date);
                return (
                  <Card key={draft.id} dashed style={styles.draftCard}>
                    <View style={styles.draftRow}>
                      <View style={styles.draftInfo}>
                        <TvzText preset="cardTitle" style={styles.draftTitle}>
                          {taskLabel(draft)}
                        </TvzText>
                        <TvzText preset="secondary">
                          {WEEKDAY_SHORT[(date.getDay() + 6) % 7]} {formatShortDate(date)} ·{' '}
                          {formatTime(draft.time)}
                          {draft.recurrence === 'wekelijks' ? ` · ${t('planner.elkeWeek')}` : ''}
                        </TvzText>
                      </View>
                      <Pressable
                        accessibilityRole="button"
                        accessibilityLabel={t('algemeen.sluiten')}
                        onPress={() => remove.mutate(draft.id)}
                        hitSlop={10}
                      >
                        <TvzText preset="cardTitle" style={styles.remove}>
                          ✕
                        </TvzText>
                      </Pressable>
                    </View>
                  </Card>
                );
              })}
            </View>
          )}

          {published !== null ? (
            <Card style={styles.publishedCard}>
              <TvzText preset="cardTitle" style={styles.publishedTitle}>
                {t('weekplanning.bevestigTitel')}
              </TvzText>
              <TvzText preset="secondary">{t('weekplanning.bevestigTekst')}</TvzText>
            </Card>
          ) : null}
          {draftList.length > 0 ? (
            <Button
              label={t('weekplanning.publiceer', { aantal: draftList.length })}
              variant="cta"
              size="lg"
              disabled={publish.isPending}
              onPress={() =>
                publish.mutate(undefined, { onSuccess: (count) => setPublished(count) })
              }
              style={styles.publishButton}
            />
          ) : null}

          {(publishedTasks.data ?? []).length > 0 ? (
            <>
              <SectionHeader
                title={t('weekplanning.gepubliceerdKop', { week: isoWeekNumber(now) })}
              />
              <View style={styles.draftList}>
                {(publishedTasks.data ?? []).map((task) => {
                  const date = parseDateString(task.date);
                  return (
                    <Card key={task.id} style={styles.publishedRow}>
                      <TvzText preset="secondary">
                        {WEEKDAY_SHORT[(date.getDay() + 6) % 7]} {formatTime(task.time)} ·{' '}
                        {taskLabel(task)}
                      </TvzText>
                    </Card>
                  );
                })}
              </View>
            </>
          ) : null}
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: colors.bg,
  },
  fill: { flex: 1 },
  container: {
    padding: spacing.screen,
    paddingBottom: 60,
  },
  headerRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
  },
  back: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: colors.surfaceAlt,
    alignItems: 'center',
    justifyContent: 'center',
  },
  title: {
    fontSize: 24,
  },
  uitleg: {
    marginTop: spacing.sm,
  },
  label: {
    marginTop: spacing.lg,
    marginBottom: spacing.sm,
  },
  chips: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing.chipGap,
    marginBottom: spacing.sm,
  },
  periodChip: {
    borderRadius: 999,
    borderWidth: 1.5,
    borderColor: colors.line,
    backgroundColor: colors.white,
    paddingHorizontal: 14,
    paddingVertical: 8,
    alignItems: 'center',
  },
  // Weekkeuze bewust vierkant (agenda-blokjes), zodat hij niet op de
  // periode-pillen erboven lijkt.
  weekChip: {
    borderRadius: 10,
    borderWidth: 1.5,
    borderColor: colors.line,
    backgroundColor: colors.white,
    paddingHorizontal: 14,
    paddingVertical: 8,
  },
  weekChipActive: {
    backgroundColor: colors.primaryMid,
    borderColor: colors.primaryMid,
  },
  periodChipActive: {
    backgroundColor: colors.primaryMid,
    borderColor: colors.primaryMid,
  },
  periodTextActive: {
    color: colors.white,
  },
  plannerCard: {
    marginTop: spacing.sm,
  },
  emptyDraft: {
    alignItems: 'center',
    paddingVertical: spacing.xl,
  },
  emptyDraftText: {
    textAlign: 'center',
  },
  draftList: {
    gap: spacing.cardGap,
  },
  draftCard: {
    paddingVertical: spacing.md,
  },
  draftRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  draftInfo: { flex: 1 },
  draftTitle: {
    fontSize: 15.5,
  },
  remove: {
    color: colors.error,
  },
  publishButton: {
    marginTop: spacing.lg,
  },
  publishedCard: {
    marginTop: spacing.lg,
    borderWidth: 1.5,
    borderColor: colors.accent,
  },
  publishedTitle: {
    color: colors.successText,
  },
  publishedRow: {
    paddingVertical: spacing.md,
  },
});

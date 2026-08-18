import { router } from 'expo-router';
import { useState } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { create } from 'zustand';

import { cancelTaskReminder, scheduleTaskReminder } from '@/features/notifications/push';
import { useProfile } from '@/features/onboarding/useAuth';
import { taskStart, useMyClaimedTasks, useTaskRpc, type Task } from '@/features/tasks/api';
import { taskLabel } from '@/features/tasks/logic';
import {
  WEEKDAY_FULL,
  WEEKDAY_SHORT,
  formatShortDate,
  formatTime,
  parseDateString,
} from '@/lib/dates';
import { t } from '@/i18n';
import { useNow } from '@/lib/useNow';
import { colors, radius, shadows, spacing } from '@/theme';
import { Button, TvzText } from '@/ui';

// Weggedrukt per taak; komt terug bij heropenen van de app (state is niet persistent
// over app-starts heen, precies zoals de handoff vraagt).
const useDismissed = create<{ ids: string[]; dismiss: (id: string) => void }>((set) => ({
  ids: [],
  dismiss: (id) => set((s) => ({ ids: [...s.ids, id] })),
}));

/**
 * Persistente taakbanner: dunne Diepbaksteen-pill met de eerstvolgende geclaimde taak.
 * Tik = uitklappen naar een detailkaart met afronden (pas vanaf de afgesproken
 * tijd) en terugdraaien zolang de banner open staat.
 */
export function TaskBanner() {
  const insets = useSafeAreaInsets();
  const profile = useProfile();
  const tasks = useMyClaimedTasks();
  const { ids, dismiss } = useDismissed();
  const [expanded, setExpanded] = useState(false);
  const [justCompleted, setJustCompleted] = useState<Task | null>(null);
  // Ververst elke halve minuut, zodat "Rond af" vanzelf actief wordt.
  const now = useNow();

  // "jij gaat" hoort bij wie de taak zelf uitvoert. Een hulpvrager voert geen
  // taken uit; ziet hij hier toch iets, dan is dat een restant van een eerdere
  // rol. Server-side wordt dat rechtgezet, hier tonen we het sowieso niet.
  const doetZelfTaken = profile.data?.role !== 'hulpvrager';
  const next = doetZelfTaken
    ? (tasks.data ?? []).find((task) => !ids.includes(task.id))
    : undefined;
  const shown = justCompleted ?? next;
  const start = shown ? taskStart(shown) : null;
  const canComplete = !!start && now >= start.getTime();
  const rpc = useTaskRpc(shown?.circle_id);

  if (!shown) return null;

  const date = parseDateString(shown.date);
  const dayFull = WEEKDAY_FULL[(date.getDay() + 6) % 7]!;
  const label = t('rooster.banner', {
    dag: WEEKDAY_SHORT[(date.getDay() + 6) % 7]!,
    tijd: formatTime(shown.time),
    taak: taskLabel(shown),
  });

  function close() {
    setExpanded(false);
    setJustCompleted(null);
  }

  if (!expanded) {
    return (
      <View pointerEvents="box-none" style={[styles.wrap, { top: insets.top + 6 }]}>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={label}
          onPress={() => setExpanded(true)}
          style={[styles.banner, shadows.floating]}
        >
          <TvzText preset="meta" style={styles.text} numberOfLines={1}>
            {label}
          </TvzText>
          <Pressable
            accessibilityRole="button"
            accessibilityLabel={t('algemeen.sluiten')}
            onPress={() => dismiss(shown.id)}
            hitSlop={10}
          >
            <TvzText preset="meta" style={styles.close}>
              ✕
            </TvzText>
          </Pressable>
        </Pressable>
      </View>
    );
  }

  return (
    <View pointerEvents="box-none" style={[styles.wrap, { top: insets.top + 6 }]}>
      <View style={[styles.card, shadows.floating]}>
        <View style={styles.cardHeader}>
          <TvzText preset="meta" style={styles.cardKicker}>
            {t('rooster.bannerDetailTitel')}
          </TvzText>
          <Pressable
            accessibilityRole="button"
            accessibilityLabel={t('algemeen.sluiten')}
            onPress={close}
            hitSlop={10}
          >
            <TvzText preset="cardTitle" style={styles.cardClose}>
              ✕
            </TvzText>
          </Pressable>
        </View>

        <TvzText preset="cardTitle" style={styles.cardTitle}>
          {taskLabel(shown)}
        </TvzText>
        <TvzText preset="secondary">
          {`${dayFull.charAt(0).toUpperCase()}${dayFull.slice(1)} ${formatShortDate(date)} · ${formatTime(shown.time)} · ${t('rooster.duurIndicatie')}`}
        </TvzText>
        {shown.circle?.name ? <TvzText preset="secondary">{shown.circle.name}</TvzText> : null}

        {justCompleted ? (
          <>
            <View style={styles.doneNote}>
              <TvzText preset="secondary" style={styles.doneText}>
                {t('rooster.bannerAfgerond')}
              </TvzText>
            </View>
            <Button
              label={t('rooster.terugdraaien')}
              variant="outline"
              disabled={rpc.uncomplete.isPending}
              style={styles.cardButton}
              onPress={() =>
                rpc.uncomplete.mutate(justCompleted.id, {
                  onSuccess: () => {
                    scheduleTaskReminder(justCompleted);
                    setJustCompleted(null);
                  },
                })
              }
            />
          </>
        ) : (
          <>
            <Button
              label={t('rooster.rondAf')}
              variant="primary"
              disabled={!canComplete || rpc.complete.isPending}
              style={styles.cardButton}
              onPress={() => {
                cancelTaskReminder(shown.id);
                rpc.complete.mutate(
                  { taskId: shown.id },
                  { onSuccess: () => setJustCompleted(shown) },
                );
              }}
            />
            {!canComplete ? (
              <TvzText preset="meta" style={styles.tooEarly}>
                {t('rooster.bannerTeVroeg', { dag: dayFull, tijd: formatTime(shown.time) })}
              </TvzText>
            ) : null}
          </>
        )}

        <Pressable
          accessibilityRole="button"
          onPress={() => {
            close();
            router.navigate('/regelen/planning');
          }}
          hitSlop={8}
          style={styles.roosterLink}
        >
          <TvzText preset="meta" style={styles.roosterLinkText}>
            {t('rooster.bekijkInRooster')}
          </TvzText>
        </Pressable>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    position: 'absolute',
    left: 0,
    right: 0,
    alignItems: 'center',
    zIndex: 10,
  },
  banner: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
    backgroundColor: colors.primaryDark,
    borderRadius: radius.pill,
    paddingHorizontal: spacing.lg,
    paddingVertical: 8,
    maxWidth: '92%',
  },
  text: {
    color: colors.white,
  },
  close: {
    color: 'rgba(255,255,255,0.7)',
  },
  card: {
    width: '92%',
    backgroundColor: colors.white,
    borderRadius: radius.card,
    padding: spacing.cardPadding,
    borderWidth: 1.5,
    borderColor: colors.primaryDark,
  },
  cardHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: spacing.xs,
  },
  cardKicker: {
    color: colors.primaryMid,
  },
  cardClose: {
    color: colors.inkFaint,
  },
  cardTitle: {
    marginBottom: 2,
  },
  cardButton: {
    marginTop: spacing.md,
  },
  tooEarly: {
    marginTop: spacing.sm,
    color: colors.warnText,
    textAlign: 'center',
  },
  doneNote: {
    backgroundColor: colors.successBg,
    borderRadius: radius.row,
    padding: spacing.md,
    marginTop: spacing.md,
  },
  doneText: {
    color: colors.successText,
  },
  roosterLink: {
    alignSelf: 'center',
    marginTop: spacing.md,
  },
  roosterLinkText: {
    color: colors.primaryMid,
  },
});

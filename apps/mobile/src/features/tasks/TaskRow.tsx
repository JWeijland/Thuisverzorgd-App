import { Pressable, StyleSheet, View } from 'react-native';
import { AlertTriangle } from 'lucide-react-native';

import { taskStart, type Task } from '@/features/tasks/api';
import { useNow } from '@/lib/useNow';
import { taskLabel } from '@/features/tasks/logic';
import { WEEKDAY_SHORT, formatShortDate, formatTime, parseDateString } from '@/lib/dates';
import { t } from '@/i18n';
import { colors, radius, spacing } from '@/theme';
import { Button, StatusPill, TvzText } from '@/ui';

type Props = {
  task: Task;
  myId: string | undefined;
  isBeheerder: boolean;
  onClaim?: (task: Task) => void;
  onComplete?: (task: Task) => void;
  onBuddyPool?: (task: Task) => void;
  /** Beheerder: taak intrekken (de aannemer krijgt automatisch een melding). */
  onCancelTask?: (task: Task) => void;
  /** Deze taak valt samen met iets anders op dezelfde dag. */
  overlapt?: boolean;
};

/** Eén roosterrij: daglabel links, taak + tijd + wie, status of actie rechts. */
export function TaskRow({
  task,
  myId,
  isBeheerder,
  onClaim,
  onComplete,
  onBuddyPool,
  onCancelTask,
  overlapt = false,
}: Props) {
  const now = useNow();
  const date = parseDateString(task.date);
  const mine = !!myId && task.claimed_by === myId;
  const who = task.claimer
    ? mine
      ? t('rooster.jijGaat')
      : task.claimer.name.split(' ')[0]
    : t('rooster.nogNiemand');

  let right: React.ReactNode;
  if (task.status === 'gedaan') {
    right = <StatusPill label={t('rooster.gedaan')} kind="success" />;
  } else if (task.status === 'open') {
    if (!isBeheerder && onClaim) {
      right = (
        <Button
          label={t('rooster.aannemen')}
          variant="cta"
          style={styles.smallButton}
          onPress={() => onClaim(task)}
        />
      );
    } else if (isBeheerder && onBuddyPool) {
      right = (
        <Button
          label={t('rooster.buddyPool')}
          variant="outline"
          style={styles.smallButton}
          onPress={() => onBuddyPool(task)}
        />
      );
    } else {
      right = <StatusPill label={t('rooster.open')} kind="warn" />;
    }
  } else if (mine && onComplete) {
    // Afronden kan pas vanaf de afgesproken tijd (de server dwingt dit ook af).
    const started = now >= taskStart(task).getTime();
    right = (
      <Button
        label={t('rooster.rondAf')}
        variant="primary"
        style={styles.smallButton}
        disabled={!started}
        onPress={() => onComplete(task)}
      />
    );
  } else {
    right = <StatusPill label={t('rooster.ingepland')} kind="success" />;
  }

  return (
    <View style={[styles.row, mine && task.status === 'ingepland' && styles.mine]}>
      <View style={styles.dayCol}>
        <TvzText preset="meta" style={styles.dayName}>
          {WEEKDAY_SHORT[(date.getDay() + 6) % 7]}
        </TvzText>
        <TvzText preset="secondary" style={styles.dayDate}>
          {formatShortDate(date)}
        </TvzText>
      </View>
      <View style={styles.info}>
        <TvzText preset="cardTitle" style={styles.title}>
          {taskLabel(task)}
        </TvzText>
        <TvzText preset="secondary">
          {formatTime(task.time)} · {who}
        </TvzText>
        {/* Twee dingen tegelijk gepland: dat zie je anders pas op de dag zelf
            (wens Jelle 11-08). */}
        {overlapt ? (
          <View style={styles.overlap}>
            <AlertTriangle color={colors.warnText} size={12} strokeWidth={2.4} />
            <TvzText preset="meta" style={styles.overlapTekst}>
              {t('rooster.overlapPill')}
            </TvzText>
          </View>
        ) : null}
      </View>
      {right}
      {isBeheerder && onCancelTask && task.status !== 'gedaan' ? (
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={t('rooster.intrekken')}
          onPress={() => onCancelTask(task)}
          hitSlop={10}
        >
          <TvzText preset="meta" style={styles.cancel}>
            ✕
          </TvzText>
        </Pressable>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.white,
    borderRadius: radius.row,
    padding: spacing.lg,
    gap: spacing.md,
  },
  mine: {
    borderWidth: 1.5,
    borderColor: colors.accent,
  },
  dayCol: {
    width: 44,
  },
  dayName: {
    color: colors.primaryDark,
  },
  dayDate: {
    fontSize: 11.5,
  },
  overlap: {
    flexDirection: 'row',
    alignItems: 'center',
    alignSelf: 'flex-start',
    gap: 4,
    backgroundColor: colors.warnBg,
    borderRadius: radius.pill,
    paddingHorizontal: 8,
    paddingVertical: 2,
    marginTop: 4,
  },
  overlapTekst: {
    color: colors.warnText,
  },
  info: {
    flex: 1,
  },
  title: {
    fontSize: 15.5,
  },
  smallButton: {
    minHeight: 38,
    paddingVertical: 6,
    paddingHorizontal: 16,
  },
  cancel: {
    color: colors.inkFaint,
    fontSize: 15,
  },
});

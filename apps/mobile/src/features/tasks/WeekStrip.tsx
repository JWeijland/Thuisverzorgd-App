import { Pressable, StyleSheet, View } from 'react-native';

import type { Task } from '@/features/tasks/api';
import { dayDots } from '@/features/tasks/logic';
import { WEEKDAY_SHORT, isoWeekDays, toDateString } from '@/lib/dates';
import { colors, radius, spacing } from '@/theme';
import { TvzText } from '@/ui';

type Props = {
  anchor: Date;
  tasks: Task[];
  selected?: string;
  onSelectDay?: (dateKey: string) => void;
};

/** Weekstrip Ma–Zo met stipjes per taak (oranje = open, groen = ingepland). */
export function WeekStrip({ anchor, tasks, selected, onSelectDay }: Props) {
  const days = isoWeekDays(anchor);
  const todayKey = toDateString(new Date());

  return (
    <View style={styles.row}>
      {days.map((day, i) => {
        const key = toDateString(day);
        const dots = dayDots(tasks, key);
        const isToday = key === todayKey;
        const isSelected = key === selected;
        return (
          <Pressable
            key={key}
            accessibilityRole="button"
            accessibilityLabel={`${WEEKDAY_SHORT[i]} ${day.getDate()}`}
            onPress={() => onSelectDay?.(key)}
            style={[styles.day, isToday && styles.today, isSelected && styles.selected]}
          >
            <TvzText preset="meta" style={[styles.dayName, isToday && styles.todayText]}>
              {WEEKDAY_SHORT[i]}
            </TvzText>
            <TvzText preset="secondary" style={[styles.dayNum, isToday && styles.todayText]}>
              {day.getDate()}
            </TvzText>
            <View style={styles.dots}>
              {dots.map((dot, j) => (
                <View
                  key={j}
                  style={[
                    styles.dot,
                    { backgroundColor: dot === 'open' ? colors.warnText : colors.accent },
                  ]}
                />
              ))}
            </View>
          </Pressable>
        );
      })}
    </View>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    gap: 6,
  },
  day: {
    flex: 1,
    backgroundColor: colors.white,
    borderWidth: 1.5,
    borderColor: colors.line,
    borderRadius: radius.row,
    alignItems: 'center',
    paddingVertical: spacing.sm,
    minHeight: 58,
  },
  today: {
    borderColor: colors.primary,
  },
  selected: {
    backgroundColor: colors.tintBlue,
  },
  dayName: {
    color: colors.primary,
  },
  dayNum: {
    fontSize: 12,
  },
  todayText: {
    color: colors.primary,
  },
  dots: {
    flexDirection: 'row',
    gap: 3,
    marginTop: 3,
    minHeight: 6,
  },
  dot: {
    width: 6,
    height: 6,
    borderRadius: 3,
  },
});

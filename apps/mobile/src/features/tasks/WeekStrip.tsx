import { useMemo } from 'react';
import { PanResponder, Pressable, StyleSheet, View } from 'react-native';

import type { Task } from '@/features/tasks/api';
import { dayDots, type DayDot } from '@/features/tasks/logic';
import { t } from '@/i18n';
import { WEEKDAY_SHORT, isoWeekDays, toDateString } from '@/lib/dates';
import { colors, radius, spacing } from '@/theme';
import { TvzText } from '@/ui';

type Props = {
  anchor: Date;
  tasks: Task[];
  /** Datumsleutels (yyyy-mm-dd) van geboekte diensten: blauwe stipjes. */
  boekingDagen?: string[];
  /** Toon de vaste stipjes-legenda onder de strip. */
  legenda?: boolean;
  selected?: string;
  onSelectDay?: (dateKey: string) => void;
  /**
   * Veeg over de dagvakjes: -1 is de week terug, 1 is de week vooruit.
   * Zonder deze prop blijft de strip één vaste week tonen.
   */
  onWeekWissel?: (richting: 1 | -1) => void;
};

/** Vanaf hoeveel punten horizontaal we het een veeg noemen. */
const VEEG_DREMPEL = 40;

/** Vaste stipkleuren van de week, in alle drie de apps gelijk (rode draad). */
const DOT_KLEUR: Record<DayDot, string> = {
  ingepland: colors.accent,
  open: colors.warnDot,
  dienst: colors.primaryMid,
};

/**
 * De legenda noemt alleen wat je in de planning ook echt ziet: groen als er
 * iemand komt, oranje als de plek nog open staat. Geboekte diensten hebben
 * geen eigen stipje meer (feedback Jelle 11-08).
 */
const LEGENDA: { dot: DayDot; labelKey: string }[] = [
  { dot: 'ingepland', labelKey: 'week.legendaBuddy' },
  { dot: 'open', labelKey: 'week.legendaOpen' },
];

/**
 * Weekstrip Ma–Zo met stipjes per dag: groen = er komt iemand, oranje = de
 * plek staat nog open. Dezelfde strip staat bij beheerder, buddy en
 * hulpvrager, zodat iedereen naar dezelfde week kijkt.
 */
export function WeekStrip({
  anchor,
  tasks,
  boekingDagen,
  legenda,
  selected,
  onSelectDay,
  onWeekWissel,
}: Props) {
  const days = isoWeekDays(anchor);
  const todayKey = toDateString(new Date());

  // Veeg naar links = volgende week, naar rechts = vorige week (wens Jelle
  // 11-08). We claimen het gebaar pas als de beweging duidelijk horizontaal
  // is, zodat verticaal scrollen door de planning gewoon blijft werken.
  const veeg = useMemo(
    () =>
      PanResponder.create({
        onMoveShouldSetPanResponder: (_e, gebaar) =>
          !!onWeekWissel && Math.abs(gebaar.dx) > 12 && Math.abs(gebaar.dx) > Math.abs(gebaar.dy) * 2,
        onPanResponderRelease: (_e, gebaar) => {
          if (!onWeekWissel || Math.abs(gebaar.dx) < VEEG_DREMPEL) return;
          onWeekWissel(gebaar.dx < 0 ? 1 : -1);
        },
      }),
    [onWeekWissel],
  );

  return (
    <View>
      <View style={styles.row} {...veeg.panHandlers}>
        {days.map((day, i) => {
          const key = toDateString(day);
          const dots = dayDots(tasks, key, boekingDagen ?? []);
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
                  <View key={j} style={[styles.dot, { backgroundColor: DOT_KLEUR[dot] }]} />
                ))}
              </View>
            </Pressable>
          );
        })}
      </View>
      {legenda ? (
        <View style={styles.legenda}>
          {LEGENDA.map(({ dot, labelKey }) => (
            <View key={dot} style={styles.legendaItem}>
              <View style={[styles.dot, { backgroundColor: DOT_KLEUR[dot] }]} />
              <TvzText preset="meta" style={styles.legendaText}>
                {t(labelKey)}
              </TvzText>
            </View>
          ))}
        </View>
      ) : null}
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
    color: colors.primaryDark,
  },
  dayNum: {
    fontSize: 12,
  },
  todayText: {
    color: colors.primaryDark,
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
  legenda: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing.md,
    marginTop: spacing.sm,
  },
  legendaItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
  },
  legendaText: {
    color: colors.inkFaint,
  },
});

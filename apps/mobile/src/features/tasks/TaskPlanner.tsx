import { useState } from 'react';
import { StyleSheet, View } from 'react-native';

import type { NewTask, Task } from '@/features/tasks/api';
import { WEEKDAY_SHORT, isoWeekDays, toDateString } from '@/lib/dates';
import { t } from '@/i18n';
import { spacing } from '@/theme';
import { Button, Chip, TextField, TvzText } from '@/ui';

const TYPES: Task['type'][] = ['boodschappen', 'wandelen', 'vervoer', 'gezelschap', 'anders'];
const QUICK_TIMES = ['09:00', '12:00', '14:00', '16:00'];

type Props = {
  /** Week waarin gepland wordt (maandag-anker). */
  anchor: Date;
  submitLabel: string;
  onSubmit: (task: NewTask) => void;
  busy?: boolean;
};

/**
 * De inline taakplanner (screens 05/06): Wat is er nodig? · Welke dag? ·
 * Hoe laat? · Herhalen? — plannen in drie tikken.
 */
export function TaskPlanner({ anchor, submitLabel, onSubmit, busy }: Props) {
  const days = isoWeekDays(anchor);
  const [type, setType] = useState<Task['type']>('boodschappen');
  const [customLabel, setCustomLabel] = useState('');
  const [dayIndex, setDayIndex] = useState(() => Math.min((new Date().getDay() + 6) % 7, 6));
  const [time, setTime] = useState('14:00');
  const [customTime, setCustomTime] = useState(false);
  const [recurrence, setRecurrence] = useState<Task['recurrence']>('eenmalig');

  const timeValid = /^([01]?\d|2[0-3]):[0-5]\d$/.test(time.trim());

  function submit() {
    if (!timeValid) return;
    onSubmit({
      type,
      custom_label: type === 'anders' ? customLabel.trim() || null : null,
      date: toDateString(days[dayIndex]!),
      time: time.trim(),
      recurrence,
    });
  }

  const typeLabels: Record<Task['type'], string> = {
    boodschappen: t('planner.typeBoodschappen'),
    wandelen: t('planner.typeWandelen'),
    vervoer: t('planner.typeVervoer'),
    gezelschap: t('planner.typeGezelschap'),
    anders: t('planner.typeAnders'),
  };

  return (
    <View>
      <TvzText preset="meta" style={styles.label}>
        {t('planner.watNodig')}
      </TvzText>
      <View style={styles.chips}>
        {TYPES.map((option) => (
          <Chip
            key={option}
            label={typeLabels[option]}
            selected={type === option}
            onPress={() => setType(option)}
          />
        ))}
      </View>
      {type === 'anders' ? (
        <TextField
          label={t('planner.typeAnders')}
          placeholder={t('planner.andersPlaceholder')}
          value={customLabel}
          onChangeText={setCustomLabel}
        />
      ) : null}

      <TvzText preset="meta" style={styles.label}>
        {t('planner.welkeDag')}
      </TvzText>
      <View style={styles.chips}>
        {WEEKDAY_SHORT.map((day, i) => (
          <Chip key={day} label={day} selected={dayIndex === i} onPress={() => setDayIndex(i)} />
        ))}
      </View>

      <TvzText preset="meta" style={styles.label}>
        {t('planner.hoeLaat')}
      </TvzText>
      <View style={styles.chips}>
        {QUICK_TIMES.map((option) => (
          <Chip
            key={option}
            label={option}
            selected={!customTime && time === option}
            onPress={() => {
              setCustomTime(false);
              setTime(option);
            }}
          />
        ))}
        <Chip
          label={customTime ? time : '…'}
          selected={customTime}
          onPress={() => setCustomTime(true)}
        />
      </View>
      {customTime ? (
        <TextField
          label={t('planner.hoeLaat')}
          placeholder="14:30"
          value={time}
          onChangeText={setTime}
          keyboardType="numbers-and-punctuation"
        />
      ) : null}

      <TvzText preset="meta" style={styles.label}>
        {t('planner.herhalen')}
      </TvzText>
      <View style={styles.chips}>
        <Chip
          label={t('planner.eenmalig')}
          selected={recurrence === 'eenmalig'}
          onPress={() => setRecurrence('eenmalig')}
        />
        <Chip
          label={t('planner.elkeWeek')}
          selected={recurrence === 'wekelijks'}
          onPress={() => setRecurrence('wekelijks')}
        />
      </View>

      <Button
        label={submitLabel}
        variant="cta"
        size="lg"
        disabled={busy || !timeValid || (type === 'anders' && customLabel.trim().length === 0)}
        onPress={submit}
        style={styles.submit}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  label: {
    marginTop: spacing.md,
    marginBottom: spacing.sm,
  },
  chips: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing.chipGap,
  },
  submit: {
    marginTop: spacing.lg,
  },
});

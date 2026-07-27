import { router } from 'expo-router';
import { Pressable, StyleSheet, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { create } from 'zustand';

import { useMyClaimedTasks } from '@/features/tasks/api';
import { taskLabel } from '@/features/tasks/logic';
import { WEEKDAY_SHORT, formatTime, parseDateString } from '@/lib/dates';
import { t } from '@/i18n';
import { colors, radius, shadows, spacing } from '@/theme';
import { TvzText } from '@/ui';

// Weggedrukt per taak; komt terug bij heropenen van de app (state is niet persistent
// over app-starts heen, precies zoals de handoff vraagt).
const useDismissed = create<{ ids: string[]; dismiss: (id: string) => void }>((set) => ({
  ids: [],
  dismiss: (id) => set((s) => ({ ids: [...s.ids, id] })),
}));

/**
 * Persistente taakbanner (handoff "Interacties & gedrag"): dunne navy pill met de
 * eerstvolgende geclaimde taak. Blijft staan bij tabwissel, wegdrukbaar met ✕,
 * tik = naar het rooster.
 */
export function TaskBanner() {
  const insets = useSafeAreaInsets();
  const tasks = useMyClaimedTasks();
  const { ids, dismiss } = useDismissed();

  const next = (tasks.data ?? []).find((task) => !ids.includes(task.id));
  if (!next) return null;

  const date = parseDateString(next.date);
  const label = t('rooster.banner', {
    dag: WEEKDAY_SHORT[(date.getDay() + 6) % 7]!,
    tijd: formatTime(next.time),
    taak: taskLabel(next),
  });

  return (
    <View pointerEvents="box-none" style={[styles.wrap, { top: insets.top + 6 }]}>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel={label}
        onPress={() => router.navigate('/rooster')}
        style={[styles.banner, shadows.floating]}
      >
        <TvzText preset="meta" style={styles.text} numberOfLines={1}>
          {label}
        </TvzText>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={t('algemeen.sluiten')}
          onPress={() => dismiss(next.id)}
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
});

import { router } from 'expo-router';
import { Pressable, StyleSheet, View } from 'react-native';
import { Bell } from 'lucide-react-native';

import { useUnreadCount } from '@/features/notifications/api';
import { t } from '@/i18n';
import { colors } from '@/theme';

/** Belknop rechtsboven op het rooster, met groene ongelezen-stip. */
export function InboxBell() {
  const unread = useUnreadCount();
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={t('inbox.titel')}
      onPress={() => router.push('/inbox')}
      style={styles.button}
    >
      <Bell color={colors.primary} size={20} strokeWidth={2.2} />
      {unread > 0 ? <View style={styles.dot} /> : null}
    </Pressable>
  );
}

const styles = StyleSheet.create({
  button: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: colors.white,
    alignItems: 'center',
    justifyContent: 'center',
  },
  dot: {
    position: 'absolute',
    top: 9,
    right: 10,
    width: 9,
    height: 9,
    borderRadius: 5,
    backgroundColor: colors.accent,
    borderWidth: 1.5,
    borderColor: colors.white,
  },
});

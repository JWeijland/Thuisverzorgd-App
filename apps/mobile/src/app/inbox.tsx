import { router } from 'expo-router';
import { Pressable, ScrollView, StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { useNotificationActions, useNotifications } from '@/features/notifications/api';
import { deeplinkToPath } from '@/features/notifications/push';
import { t } from '@/i18n';
import { colors, radius, spacing } from '@/theme';
import { Card, EmptyState, TvzText } from '@/ui';

/** Inbox (screen 15): meldingen uit de notifications-tabel, klikbaar naar hun doel. */
export default function InboxScreen() {
  const notifications = useNotifications();
  const { markRead, markAllRead, remove } = useNotificationActions();
  const items = notifications.data ?? [];
  const hasUnread = items.some((item) => !item.read);

  return (
    <SafeAreaView style={styles.safe}>
      <View style={styles.header}>
        <Pressable accessibilityRole="button" onPress={() => router.back()} style={styles.back}>
          <TvzText preset="cardTitle">←</TvzText>
        </Pressable>
        <TvzText preset="screenTitle" style={styles.title}>
          {t('inbox.titel')}
        </TvzText>
        {hasUnread ? (
          <Pressable accessibilityRole="button" onPress={() => markAllRead.mutate()} hitSlop={8}>
            <TvzText preset="meta" style={styles.markAll}>
              {t('inbox.allesGelezen')}
            </TvzText>
          </Pressable>
        ) : null}
      </View>

      <ScrollView contentContainerStyle={styles.list}>
        {items.length === 0 && !notifications.isLoading ? (
          <Card>
            <EmptyState title={t('inbox.leegTitel')} body={t('inbox.leegTekst')} />
          </Card>
        ) : null}
        {items.map((item) => (
          <Pressable
            key={item.id}
            accessibilityRole="button"
            onPress={() => {
              markRead.mutate(item.id);
              router.navigate(deeplinkToPath(item.deeplink) as never);
            }}
            onLongPress={() => remove.mutate(item.id)}
            style={[styles.item, !item.read && styles.itemUnread]}
          >
            <View style={styles.itemHeader}>
              {!item.read ? <View style={styles.unreadDot} /> : null}
              <TvzText preset="cardTitle" style={styles.itemTitle}>
                {item.title}
              </TvzText>
              <TvzText preset="meta" style={styles.time}>
                {new Date(item.created_at).toLocaleTimeString('nl-NL', {
                  hour: '2-digit',
                  minute: '2-digit',
                })}
              </TvzText>
            </View>
            {item.body ? <TvzText preset="secondary">{item.body}</TvzText> : null}
          </Pressable>
        ))}
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: colors.bg,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
    padding: spacing.screen,
    paddingBottom: spacing.sm,
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
    flex: 1,
    fontSize: 24,
  },
  markAll: {
    color: colors.primaryMid,
  },
  list: {
    padding: spacing.screen,
    paddingTop: spacing.sm,
    gap: spacing.cardGap,
  },
  item: {
    backgroundColor: colors.white,
    borderRadius: radius.card,
    padding: spacing.lg,
  },
  itemUnread: {
    borderWidth: 1.5,
    borderColor: colors.primaryMid,
  },
  itemHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    marginBottom: 2,
  },
  unreadDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: colors.accent,
  },
  itemTitle: {
    flex: 1,
    fontSize: 15.5,
  },
  time: {
    color: colors.inkFaint,
  },
});

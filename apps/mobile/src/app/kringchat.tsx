import { useQueryClient } from '@tanstack/react-query';
import { router } from 'expo-router';
import { useEffect } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { markCircleChatRead, useCircleMembers, useMyCircle } from '@/features/circles/api';
import { ChatView } from '@/features/circles/ChatView';
import { t } from '@/i18n';
import { colors, spacing } from '@/theme';
import { EmptyState, TvzText } from '@/ui';
import { useStatusBalk } from '@/lib/statusbalk';

/**
 * Kringberichten als eigen pagina (feedback 30-07): de vrijwilliger opent dit
 * via het berichten-icoon rechtsboven op de planning-tab.
 */
export default function KringChatScreen() {
  useStatusBalk('donker');
  const circle = useMyCircle();
  const members = useCircleMembers(circle.data?.id);
  const queryClient = useQueryClient();
  const circleId = circle.data?.id;

  // Bij het verlaten van de chat is alles gelezen; de badge verdwijnt dan.
  useEffect(() => {
    if (!circleId) return;
    return () => {
      markCircleChatRead(circleId).then(() =>
        queryClient.invalidateQueries({ queryKey: ['messages-unread', circleId] }),
      );
    };
  }, [circleId, queryClient]);

  const roleSuffix = (senderId: string) => {
    const member = (members.data ?? []).find((item) => item.profile_id === senderId);
    return member?.member_role === 'beheerder' ? ` (${t('kring.rolBeheerder')})` : '';
  };

  return (
    <SafeAreaView style={styles.safe} edges={['top']}>
      <View style={styles.headerRow}>
        <Pressable accessibilityRole="button" onPress={() => router.back()} style={styles.back}>
          <TvzText preset="cardTitle">←</TvzText>
        </Pressable>
        <View style={styles.headerText}>
          <TvzText preset="cardTitle" numberOfLines={1}>
            {t('kring.berichtenTitel')}
          </TvzText>
          {circle.data ? (
            <TvzText preset="secondary" numberOfLines={1}>
              {circle.data.name}
            </TvzText>
          ) : null}
        </View>
      </View>
      {circle.data ? (
        <ChatView circleId={circle.data.id} roleSuffix={roleSuffix} />
      ) : (
        <View style={styles.leeg}>
          <EmptyState title={t('kring.legeStaatTitel')} body={t('kring.legeStaatTekst')} />
        </View>
      )}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: colors.bg,
  },
  headerRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
    paddingHorizontal: spacing.screen,
    paddingVertical: spacing.sm,
  },
  back: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: colors.surfaceAlt,
    alignItems: 'center',
    justifyContent: 'center',
  },
  headerText: { flex: 1 },
  leeg: {
    flex: 1,
    justifyContent: 'center',
    padding: spacing.screen,
  },
});

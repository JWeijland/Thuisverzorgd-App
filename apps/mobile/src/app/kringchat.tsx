import { router } from 'expo-router';
import { Pressable, StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { useCircleMembers, useMyCircle } from '@/features/circles/api';
import { ChatView } from '@/features/circles/ChatView';
import { t } from '@/i18n';
import { colors, spacing } from '@/theme';
import { EmptyState, TvzText } from '@/ui';

/**
 * Kringberichten als eigen pagina (feedback 30-07): de vrijwilliger opent dit
 * via het berichten-icoon rechtsboven op de planning-tab.
 */
export default function KringChatScreen() {
  const circle = useMyCircle();
  const members = useCircleMembers(circle.data?.id);

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

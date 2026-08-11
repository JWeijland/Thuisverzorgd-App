import { router } from 'expo-router';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { MessagesSquare } from 'lucide-react-native';

import { useUnreadCircleMessages } from '@/features/circles/api';
import { kringRoute } from '@/features/circles/kringRoute';
import { useProfile } from '@/features/onboarding/useAuth';
import { t } from '@/i18n';
import { colors, scaleText, useTextScale } from '@/theme';
import { fonts } from '@/theme/typography';

/** Berichten-icoon met het aantal nieuwe kringberichten erboven. */
export function KringBerichtenKnop({ circleId }: { circleId: string }) {
  const nieuw = useUnreadCircleMessages(circleId);
  const { factor } = useTextScale();
  const profile = useProfile();

  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={
        nieuw > 0 ? t('kring.berichtenNieuw', { aantal: nieuw }) : t('kring.berichtenTitel')
      }
      // Berichten zijn geen aparte pagina meer: ze zitten onder Mijn kring
      // (handoff scherm 07). De knop opent die tab meteen op Berichten.
      onPress={() => router.push(kringRoute(profile.data?.role, 'berichten') as never)}
      style={styles.knop}
    >
      <MessagesSquare color={colors.primary} size={20} strokeWidth={2.2} />
      {nieuw > 0 ? (
        <View style={styles.badge}>
          <Text
            style={[
              scaleText({ fontFamily: fonts.headingBold, fontSize: 11 }, factor),
              styles.badgeText,
            ]}
          >
            {nieuw > 9 ? '9+' : `${nieuw}`}
          </Text>
        </View>
      ) : null}
    </Pressable>
  );
}

const styles = StyleSheet.create({
  knop: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: colors.white,
    alignItems: 'center',
    justifyContent: 'center',
  },
  badge: {
    position: 'absolute',
    top: -2,
    right: -2,
    minWidth: 20,
    height: 20,
    borderRadius: 10,
    paddingHorizontal: 5,
    backgroundColor: colors.accentDark,
    borderWidth: 2,
    borderColor: colors.white,
    alignItems: 'center',
    justifyContent: 'center',
  },
  badgeText: {
    color: colors.white,
  },
});

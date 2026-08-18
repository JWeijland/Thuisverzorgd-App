import { router } from 'expo-router';
import { Pressable, StyleSheet, View } from 'react-native';

import { ProfileAvatar } from '@/features/avatars/ProfileAvatar';
import { useCircleMembers, useMyCircles } from '@/features/circles/api';
import { t } from '@/i18n';
import { haptics } from '@/lib/haptics';
import { colors, radius, shadows, spacing } from '@/theme';
import { TvzText } from '@/ui/TvzText';

/**
 * De kringen van de vrijwilliger als ronde knoppen rechtsonder op de kaart
 * (handoff, scherm 08). Eén rondje per kring; word je lid van nog een kring,
 * dan komt er een rondje bij. Tikken opent die kring.
 */
export function KringRondjes() {
  const kringen = useMyCircles();
  const lijst = kringen.data ?? [];
  if (lijst.length === 0) return null;

  return (
    <View style={styles.stapel}>
      <View style={styles.labelWrap}>
        <TvzText preset="meta" style={styles.label}>
          {t('buurt.mijnKringen')}
        </TvzText>
      </View>
      {lijst.map((kring) => (
        <Rondje key={kring.id} circleId={kring.id} naam={kring.name} />
      ))}
    </View>
  );
}

function Rondje({ circleId, naam }: { circleId: string; naam: string }) {
  const leden = useCircleMembers(circleId);
  // Het gezicht van de kring is de hulpvrager: om hem draait het.
  const hulpvrager = (leden.data ?? []).find((lid) => lid.member_role === 'hulpvrager');

  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={naam}
      onPress={() => {
        void haptics.tik();
        router.push('/vrijwilliger/kring');
      }}
      style={[styles.rondje, shadows.floating]}
    >
      <ProfileAvatar
        name={hulpvrager?.profile?.name ?? naam}
        avatarPath={hulpvrager?.profile?.avatar_path}
        size={48}
        backgroundColor={colors.primaryMid}
      />
    </Pressable>
  );
}

const styles = StyleSheet.create({
  stapel: {
    position: 'absolute',
    right: spacing.screen,
    bottom: spacing.xl,
    alignItems: 'center',
    gap: spacing.sm,
  },
  labelWrap: {
    backgroundColor: colors.white,
    borderRadius: radius.pill,
    paddingHorizontal: 10,
    paddingVertical: 3,
  },
  label: {
    color: colors.inkSoft,
  },
  rondje: {
    borderRadius: 26,
    borderWidth: 2,
    borderColor: colors.white,
  },
});

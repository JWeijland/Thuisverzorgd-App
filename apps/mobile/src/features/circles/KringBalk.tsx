import { router } from 'expo-router';
import { Pressable, StyleSheet, View } from 'react-native';
import { Users } from 'lucide-react-native';

import { ProfileAvatar } from '@/features/avatars/ProfileAvatar';
import { useCircleMembers } from '@/features/circles/api';
import { t } from '@/i18n';
import { colors, radius, spacing } from '@/theme';
import { TvzText } from '@/ui';

type Props = {
  circleId: string;
  name: string;
  /** Op donkere achtergrond (in de gradient-header) of op de lichte pagina. */
  onDark?: boolean;
  /** Alleen voor typecompatibiliteit met oudere aanroepen; leden staan op /kring. */
  isBeheerder?: boolean;
  linkCode?: string;
};

/**
 * Kringbalk in de kop van de kring-tab: foto van de kring, kringnaam en het
 * aantal leden. Eén functie: tikken opent de ledenpagina (/kring), waar ook
 * uitnodigen en de koppelcode wonen (ontwerp 4.0).
 */
export function KringBalk({ circleId, name, onDark = false }: Props) {
  const members = useCircleMembers(circleId);

  const list = members.data ?? [];
  // De foto van de hulpvrager staat voorop: dat is het gezicht van de kring.
  const hulpvrager = list.find((member) => member.member_role === 'hulpvrager');
  const gezicht = hulpvrager ?? list.find((member) => member.member_role === 'beheerder');

  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={t('kring.bekijkLeden')}
      onPress={() => router.push('/kring')}
      style={[styles.balk, onDark ? styles.balkDark : styles.balkLight]}
    >
      {gezicht?.profile ? (
        <ProfileAvatar
          name={gezicht.profile.name}
          avatarPath={gezicht.profile.avatar_path}
          size={38}
        />
      ) : (
        <View style={styles.iconAvatar}>
          <Users color={colors.white} size={19} strokeWidth={2.2} />
        </View>
      )}
      <View style={styles.balkText}>
        <TvzText preset="cardTitle" numberOfLines={1} style={onDark ? styles.textDark : undefined}>
          {name}
        </TvzText>
        <TvzText preset="meta" style={onDark ? styles.subDark : styles.subLight}>
          {list.length === 1
            ? t('kring.lid1Bekijk')
            : t('kring.ledenBekijk', { aantal: list.length })}
        </TvzText>
      </View>
      <TvzText preset="cardTitle" style={onDark ? styles.subDark : styles.subLight}>
        ›
      </TvzText>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  balk: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
    borderRadius: radius.card,
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.sm,
    minHeight: 56,
  },
  balkDark: {
    backgroundColor: 'rgba(255,255,255,0.14)',
  },
  balkLight: {
    backgroundColor: colors.white,
  },
  iconAvatar: {
    width: 38,
    height: 38,
    borderRadius: 19,
    backgroundColor: colors.primaryMid,
    alignItems: 'center',
    justifyContent: 'center',
  },
  balkText: { flex: 1 },
  textDark: {
    color: colors.white,
  },
  subDark: {
    color: 'rgba(255,255,255,0.75)',
  },
  subLight: {
    color: colors.inkSoft,
  },
});

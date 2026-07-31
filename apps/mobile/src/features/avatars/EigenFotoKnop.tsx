import { router } from 'expo-router';
import { Pressable, StyleSheet } from 'react-native';

import { ProfileAvatar } from '@/features/avatars/ProfileAvatar';
import { useProfile } from '@/features/onboarding/useAuth';
import { t } from '@/i18n';

/**
 * Je eigen profielfoto rechtsboven in de kop, naast de inbox-bel. Eén tik en
 * je bent bij je profiel. Zonder foto zie je je initiaal, zoals overal.
 */
export function EigenFotoKnop() {
  const profile = useProfile();

  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={t('tabs.profiel')}
      onPress={() => router.navigate('/profiel')}
      hitSlop={8}
      style={styles.ring}
    >
      <ProfileAvatar
        name={profile.data?.name ?? ''}
        avatarPath={profile.data?.avatar_path ?? null}
        size={34}
      />
    </Pressable>
  );
}

const styles = StyleSheet.create({
  ring: {
    borderWidth: 2,
    borderColor: 'rgba(255,255,255,0.55)',
    borderRadius: 21,
    padding: 1,
  },
});

import { StyleSheet, View } from 'react-native';

import { PadHeader } from '@/features/navigatie/PadHeader';
import { useProfile } from '@/features/onboarding/useAuth';
import { RoosterBeheerder } from '@/features/tasks/screens/RoosterBeheerder';
import { RoosterHulpvrager } from '@/features/tasks/screens/RoosterHulpvrager';
import { colors } from '@/theme';

/**
 * Mijn planning (handoff, scherm 05): wie er vandaag komt, de dagbalk over de
 * volle breedte en de taken per dag. De hulpvrager krijgt hier zijn eigen,
 * rustiger versie van dezelfde week.
 */
export default function Planning() {
  const profile = useProfile();
  return (
    <View style={styles.safe}>
      <PadHeader pad="regelen" />
      {profile.data?.role === 'hulpvrager' ? <RoosterHulpvrager /> : <RoosterBeheerder />}
    </View>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: colors.bg,
  },
});

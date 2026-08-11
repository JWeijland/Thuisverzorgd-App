import { StyleSheet, View } from 'react-native';

import { KringScreen } from '@/features/circles/screens/KringScreen';
import { MijnKring } from '@/features/circles/screens/MijnKring';
import { PadHeader } from '@/features/navigatie/PadHeader';
import { useProfile } from '@/features/onboarding/useAuth';
import { colors } from '@/theme';

/**
 * Mijn kring (handoff, scherm 07): kringkop met Leden en Berichten, de
 * ledenlijst, "wie doet wat deze maand" en de twee knoppen (uitnodigen en
 * Bo een buddy laten zoeken). De hulpvrager ziet de wie-is-wie-versie.
 */
export default function Kring() {
  const profile = useProfile();
  return (
    <View style={styles.safe}>
      <PadHeader pad="regelen" />
      {profile.data?.role === 'hulpvrager' ? <MijnKring /> : <KringScreen />}
    </View>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: colors.bg,
  },
});

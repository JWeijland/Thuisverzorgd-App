import { StyleSheet, View } from 'react-native';

import { useProfile } from '@/features/onboarding/useAuth';
import { LerenScherm } from '@/features/steun/LerenScherm';
import { SteunHub } from '@/features/steun/SteunHub';
import { SteunKeuze } from '@/features/steun/SteunKeuze';
import { colors } from '@/theme';

/**
 * Steun-tab (ontwerp 4.0), per rol een eigen invulling met één functie:
 * de beheerder krijgt de hub van laag 1 (kiezen: wegwijzer, makelaar,
 * forum), de buddy krijgt Leren (opleidingen) en de hulpvrager een
 * eenvoudige keuze tussen praten en lezen. De losse functies zijn eigen
 * pagina's: /wegwijzer-lijst, /hulpmakelaar en /forum.
 */
export default function SteunScreen() {
  const profile = useProfile();
  switch (profile.data?.role) {
    case 'vrijwilliger':
      return <LerenScherm />;
    case 'hulpvrager':
      return <SteunKeuze />;
    case 'beheerder':
      return <SteunHub />;
    default:
      return <View style={styles.laden} />;
  }
}

const styles = StyleSheet.create({
  laden: {
    flex: 1,
    backgroundColor: colors.bg,
  },
});

import { Redirect } from 'expo-router';
import { ActivityIndicator, StyleSheet, View } from 'react-native';

import { getStartRoute } from '@/features/onboarding/startRoute';
import { useProfile, useSession } from '@/features/onboarding/useAuth';
import { colors } from '@/theme';

/** Startpunt: stuurt door naar welkom, rolkeuze, ID-check of de app zelf. */
export default function Index() {
  const { session, loading } = useSession();
  const profile = useProfile();

  if (loading || (session && profile.isLoading)) {
    return (
      <View style={styles.loading}>
        <ActivityIndicator color={colors.white} />
      </View>
    );
  }

  const target = getStartRoute(
    !!session,
    profile.data ? { role: profile.data.role, id_verified: profile.data.id_verified } : null,
  );
  return <Redirect href={target as never} />;
}

const styles = StyleSheet.create({
  loading: {
    flex: 1,
    backgroundColor: colors.primaryDark,
    alignItems: 'center',
    justifyContent: 'center',
  },
});

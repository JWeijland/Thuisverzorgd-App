import { useQueryClient } from '@tanstack/react-query';
import { router } from 'expo-router';
import { useState } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { useSession } from '@/features/onboarding/useAuth';
import { t } from '@/i18n';
import { supabase } from '@/lib/supabase';
import { colors, radius, shadows, spacing } from '@/theme';
import { TvzText } from '@/ui';

/** Rolkeuze (screen 03): twee grote kaarten + koppelcode-link voor de hulpvrager. */
export default function RolkeuzeScreen() {
  const { session } = useSession();
  const queryClient = useQueryClient();
  const [busy, setBusy] = useState(false);

  async function chooseRole(role: 'beheerder' | 'vrijwilliger') {
    if (!session || busy) return;
    setBusy(true);
    // Via de RPC, zodat ook iemand die al een rol koos (en bijv. terugkwam
    // vanaf het ID-scherm) hier alsnog van rol kan wisselen.
    const { error } = await supabase.rpc('change_role', { p_role: role });
    if (!error) {
      // Direct naar het doel navigeren (niet via '/'): voorkomt dat het
      // rolkeuzescherm nogmaals verschijnt terwijl het profiel nog herlaadt.
      await queryClient.invalidateQueries({ queryKey: ['profile'] });
      router.replace(role === 'vrijwilliger' ? '/id-en-foto' : '/rooster');
      return;
    }
    setBusy(false);
  }

  return (
    <SafeAreaView style={styles.safe}>
      <View style={styles.container}>
        <TvzText preset="screenTitle">{t('rolkeuze.titel')}</TvzText>
        <TvzText preset="secondary" style={styles.uitleg}>
          {t('rolkeuze.uitleg')}
        </TvzText>

        <Pressable
          accessibilityRole="button"
          disabled={busy}
          onPress={() => chooseRole('beheerder')}
          style={({ pressed }) => [styles.card, shadows.card, pressed && styles.pressed]}
        >
          <View style={[styles.rolePill, { backgroundColor: colors.primaryMid }]} />
          <TvzText preset="cardTitle" style={styles.cardTitle}>
            {t('rolkeuze.beheerderTitel')}
          </TvzText>
          <TvzText preset="secondary">{t('rolkeuze.beheerderUitleg')}</TvzText>
        </Pressable>

        <Pressable
          accessibilityRole="button"
          disabled={busy}
          onPress={() => chooseRole('vrijwilliger')}
          style={({ pressed }) => [styles.card, shadows.card, pressed && styles.pressed]}
        >
          <View style={[styles.rolePill, { backgroundColor: colors.accent }]} />
          <TvzText preset="cardTitle" style={styles.cardTitle}>
            {t('rolkeuze.vrijwilligerTitel')}
          </TvzText>
          <TvzText preset="secondary">{t('rolkeuze.vrijwilligerUitleg')}</TvzText>
        </Pressable>

        <Pressable
          accessibilityRole="button"
          disabled={busy}
          onPress={() => router.push('/koppelcode')}
          style={({ pressed }) => [styles.card, shadows.card, pressed && styles.pressed]}
        >
          <View style={[styles.rolePill, { backgroundColor: colors.primaryDark }]} />
          <TvzText preset="cardTitle" style={styles.cardTitle}>
            {t('rolkeuze.hulpvragerTitel')}
          </TvzText>
          <TvzText preset="secondary">{t('rolkeuze.hulpvragerUitleg')}</TvzText>
        </Pressable>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: colors.bg,
  },
  container: {
    flex: 1,
    padding: spacing.screen,
  },
  uitleg: {
    marginTop: spacing.xs,
    marginBottom: spacing.xl,
  },
  card: {
    backgroundColor: colors.white,
    borderRadius: radius.card,
    padding: spacing.cardPadding,
    marginBottom: spacing.md,
  },
  pressed: {
    opacity: 0.85,
  },
  rolePill: {
    width: 30,
    height: 18,
    borderRadius: radius.pill,
    marginBottom: spacing.md,
  },
  cardTitle: {
    marginBottom: 4,
  },
});

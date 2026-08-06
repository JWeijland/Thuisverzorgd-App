import { useQueryClient } from '@tanstack/react-query';
import { router } from 'expo-router';
import { useState } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { useSession } from '@/features/onboarding/useAuth';
import { t } from '@/i18n';
import { supabase } from '@/lib/supabase';
import { colors, radius, rolTints, shadows, spacing } from '@/theme';
import { Bo, RolChip, TvzText } from '@/ui';
import { useStatusBalk } from '@/lib/statusbalk';

/**
 * Rolkeuze (ontwerp 4.0): drie kaarten met de rol-Bo's in de vaste
 * rolkleuren. Na de keuze volgt de kringuitleg, zodat iedereen weet hoe de
 * rollen samenwerken.
 */
export default function RolkeuzeScreen() {
  useStatusBalk('donker');
  const { session } = useSession();
  const queryClient = useQueryClient();
  const [busy, setBusy] = useState(false);

  /** Hulpvrager: rol vastzetten en daarna alleen de koppelcode invullen. */
  async function chooseHulpvrager() {
    if (!session || busy) return;
    setBusy(true);
    await supabase.rpc('change_role', { p_role: 'hulpvrager' });
    await queryClient.invalidateQueries({ queryKey: ['profile'] });
    setBusy(false);
    router.replace('/koppelcode');
  }

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
      router.replace(
        role === 'vrijwilliger'
          ? '/id-en-foto'
          : { pathname: '/kringuitleg', params: { rol: 'beheerder' } },
      );
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
          style={({ pressed }) => [
            styles.card,
            shadows.card,
            { borderLeftColor: rolTints.beheerder.stip },
            pressed && styles.pressed,
          ]}
        >
          <View style={styles.cardRij}>
            <Bo width={56} rol="beheerder" />
            <View style={styles.cardTekst}>
              <TvzText preset="cardTitle" style={styles.cardTitle}>
                {t('rolkeuze.beheerderTitel')}
              </TvzText>
              <TvzText preset="secondary">{t('rolkeuze.beheerderUitleg')}</TvzText>
            </View>
          </View>
          <View style={styles.chipWrap}>
            <RolChip rol="beheerder" />
          </View>
        </Pressable>

        <Pressable
          accessibilityRole="button"
          disabled={busy}
          onPress={() => chooseRole('vrijwilliger')}
          style={({ pressed }) => [
            styles.card,
            shadows.card,
            { borderLeftColor: rolTints.vrijwilliger.stip },
            pressed && styles.pressed,
          ]}
        >
          <View style={styles.cardRij}>
            <Bo width={56} rol="vrijwilliger" />
            <View style={styles.cardTekst}>
              <TvzText preset="cardTitle" style={styles.cardTitle}>
                {t('rolkeuze.vrijwilligerTitel')}
              </TvzText>
              <TvzText preset="secondary">{t('rolkeuze.vrijwilligerUitleg')}</TvzText>
            </View>
          </View>
          <View style={styles.chipWrap}>
            <RolChip rol="vrijwilliger" />
          </View>
        </Pressable>

        <Pressable
          accessibilityRole="button"
          disabled={busy}
          onPress={chooseHulpvrager}
          style={({ pressed }) => [
            styles.card,
            shadows.card,
            { borderLeftColor: rolTints.hulpvrager.stip },
            pressed && styles.pressed,
          ]}
        >
          <View style={styles.cardRij}>
            <Bo width={56} rol="hulpvrager" />
            <View style={styles.cardTekst}>
              <TvzText preset="cardTitle" style={styles.cardTitle}>
                {t('rolkeuze.hulpvragerTitel')}
              </TvzText>
              <TvzText preset="secondary">{t('rolkeuze.hulpvragerUitleg')}</TvzText>
            </View>
          </View>
          <View style={styles.chipWrap}>
            <RolChip rol="hulpvrager" />
          </View>
        </Pressable>

        <TvzText preset="secondary" style={styles.samenZin}>
          {t('rolkeuze.samenZin')}
        </TvzText>
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
    borderLeftWidth: 5,
    padding: spacing.cardPadding,
    marginBottom: spacing.md,
  },
  pressed: {
    opacity: 0.85,
  },
  cardRij: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
  },
  cardTekst: {
    flex: 1,
  },
  cardTitle: {
    marginBottom: 4,
  },
  chipWrap: {
    marginTop: spacing.sm,
  },
  samenZin: {
    textAlign: 'center',
    marginTop: spacing.xs,
  },
});

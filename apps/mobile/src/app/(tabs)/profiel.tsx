import { ScrollView, StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { NotificationSettings } from '@/features/notifications/NotificationSettings';
import { removePushToken } from '@/features/notifications/push';
import { useProfile } from '@/features/onboarding/useAuth';
import { t } from '@/i18n';
import { supabase } from '@/lib/supabase';
import { colors, spacing, useTextScale } from '@/theme';
import { Avatar, Button, Card, Pill, Toggle, TvzText } from '@/ui';

const ROLE_LABELS: Record<string, string> = {
  beheerder: 'Beheerder van de kring',
  vrijwilliger: 'Buddy',
  hulpvrager: 'Hulpvrager',
  admin: 'Admin',
  makelaar: 'Hulpmakelaar',
};

// Basisprofiel — de volledige profielsecties (buddy-pool, beschikbaarheid,
// abonnement, meldingen) volgen in Fase 5 t/m 9.
export default function ProfielScreen() {
  const profile = useProfile();
  const { largeText, setLargeText } = useTextScale();
  const p = profile.data;

  return (
    <SafeAreaView style={styles.safe} edges={['top']}>
      <ScrollView contentContainerStyle={styles.container}>
        <View style={styles.header}>
          <Avatar name={p?.name ?? '?'} size={72} />
          <TvzText preset="screenTitle" style={styles.name}>
            {p?.name ?? ''}
          </TvzText>
          {p?.role ? <Pill label={ROLE_LABELS[p.role] ?? p.role} /> : null}
        </View>

        <Card style={styles.card}>
          <View style={styles.row}>
            <View style={styles.rowText}>
              <TvzText preset="cardTitle">Grotere letters</TvzText>
              <TvzText preset="secondary">Ouderen-modus, alles 1,3× groter</TvzText>
            </View>
            <Toggle
              value={largeText}
              onValueChange={setLargeText}
              accessibilityLabel="Grotere letters"
            />
          </View>
          <View style={[styles.row, styles.rowBorder]}>
            <TvzText preset="cardTitle">Mijn TVZ-ID</TvzText>
            <TvzText preset="secondary">{p?.tvz_id ?? ''}</TvzText>
          </View>
        </Card>

        <NotificationSettings />

        <Button
          label="Uitloggen"
          variant="danger"
          style={styles.logout}
          onPress={async () => {
            await removePushToken();
            supabase.auth.signOut();
          }}
        />
        <TvzText preset="secondary" style={styles.note}>
          {t('placeholder.tekst')}
        </TvzText>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1 },
  container: {
    padding: spacing.screen,
    paddingBottom: 110,
  },
  header: {
    alignItems: 'center',
    gap: spacing.sm,
    marginBottom: spacing.xl,
  },
  name: {
    fontSize: 22,
  },
  card: {
    marginBottom: spacing.md,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: spacing.sm,
  },
  rowBorder: {
    borderTopWidth: 1,
    borderTopColor: colors.line,
    marginTop: spacing.sm,
    paddingTop: spacing.md,
  },
  rowText: {
    flex: 1,
    paddingRight: spacing.md,
  },
  logout: {
    marginTop: spacing.md,
  },
  note: {
    textAlign: 'center',
    marginTop: spacing.lg,
    color: colors.inkFaint,
  },
});

import { useQueryClient } from '@tanstack/react-query';
import { router } from 'expo-router';
import { useState } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { useSession } from '@/features/onboarding/useAuth';
import { t } from '@/i18n';
import { supabase } from '@/lib/supabase';
import { colors, spacing } from '@/theme';
import { Button, Card, TextField, TvzText } from '@/ui';

/** Koppelcode: de hulpvrager koppelt zich aan een bestaande kring ("kijkt mee"). */
export default function KoppelcodeScreen() {
  const { session } = useSession();
  const queryClient = useQueryClient();
  const [code, setCode] = useState('');
  const [error, setError] = useState<string | undefined>();
  const [busy, setBusy] = useState(false);

  async function redeem() {
    if (!session || busy) return;
    setBusy(true);
    setError(undefined);
    // De RPC koppelt aan de kring én zet de rol op hulpvrager.
    const { error: rpcError } = await supabase.rpc('redeem_circle_code', {
      p_code: code.trim().toUpperCase(),
    });
    setBusy(false);
    if (rpcError) {
      setError(t('koppelcode.onbekend'));
      return;
    }
    await queryClient.invalidateQueries();
    router.replace('/rooster');
  }

  /** Nog geen code? Dan alvast naar de app; de code kan later alsnog. */
  async function later() {
    if (!session || busy) return;
    setBusy(true);
    await supabase.rpc('change_role', { p_role: 'hulpvrager' });
    await queryClient.invalidateQueries({ queryKey: ['profile'] });
    setBusy(false);
    router.replace('/rooster');
  }

  return (
    <SafeAreaView style={styles.safe}>
      <View style={styles.container}>
        <Pressable accessibilityRole="button" onPress={() => router.back()} style={styles.back}>
          <TvzText preset="cardTitle">←</TvzText>
        </Pressable>
        <TvzText preset="screenTitle">{t('koppelcode.titel')}</TvzText>
        <TvzText preset="secondary" style={styles.uitleg}>
          {t('koppelcode.uitleg')}
        </TvzText>
        <Card dashed style={styles.codeCard}>
          <TextField
            label={t('koppelcode.titel')}
            placeholder={t('koppelcode.placeholder')}
            value={code}
            onChangeText={(v) => setCode(v.toUpperCase())}
            autoCapitalize="characters"
            autoCorrect={false}
            error={error}
            style={styles.codeInput}
          />
        </Card>
        <Button
          label={busy ? t('algemeen.laden') : t('koppelcode.verstuur')}
          variant="cta"
          size="lg"
          disabled={busy || code.trim().length < 4}
          onPress={redeem}
        />
        <Pressable
          accessibilityRole="button"
          onPress={later}
          disabled={busy}
          hitSlop={8}
          style={styles.laterLink}
        >
          <TvzText preset="secondary" style={styles.laterText}>
            {t('koppelcode.later')}
          </TvzText>
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
  back: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: colors.surfaceAlt,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing.lg,
  },
  uitleg: {
    marginTop: spacing.xs,
    marginBottom: spacing.xl,
  },
  codeCard: {
    marginBottom: spacing.xl,
  },
  codeInput: {
    textAlign: 'center',
    fontSize: 22,
    letterSpacing: 2,
  },
  laterLink: {
    alignSelf: 'center',
    marginTop: spacing.lg,
    padding: spacing.sm,
  },
  laterText: {
    color: colors.primaryMid,
    textDecorationLine: 'underline',
  },
});

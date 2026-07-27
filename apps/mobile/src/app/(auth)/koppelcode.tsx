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
    // Rol wordt hulpvrager; daarna koppelen aan de kring.
    await supabase.from('profiles').update({ role: 'hulpvrager' }).eq('id', session.user.id);
    const { error: rpcError } = await supabase.rpc('redeem_circle_code', {
      p_code: code.trim().toUpperCase(),
    });
    setBusy(false);
    if (rpcError) {
      setError(t('koppelcode.onbekend'));
      return;
    }
    await queryClient.invalidateQueries({ queryKey: ['profile'] });
    router.replace('/');
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
});

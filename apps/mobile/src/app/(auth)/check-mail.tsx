import { router, useLocalSearchParams } from 'expo-router';
import { useState } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { t } from '@/i18n';
import { supabase } from '@/lib/supabase';
import { colors, spacing } from '@/theme';
import { Button, Card, EmptyState, TextField, TvzText } from '@/ui';
import { useStatusBalk } from '@/lib/statusbalk';

/**
 * Kijk in je mail (screen 02b): magic-link bevestiging + invoer van de
 * 6-cijferige code uit dezelfde mail (robuuster dan de link: geen deeplink
 * of verlopen-link-gedoe, en werkt ook als de mail op een ander apparaat staat).
 */
export default function CheckMailScreen() {
  useStatusBalk('donker');
  const { email } = useLocalSearchParams<{ email: string }>();
  const [resent, setResent] = useState(false);
  const [code, setCode] = useState('');
  const [error, setError] = useState<string | undefined>();
  const [busy, setBusy] = useState(false);

  async function verifyCode() {
    if (!email || busy) return;
    setBusy(true);
    setError(undefined);
    const { error: verifyError } = await supabase.auth.verifyOtp({
      email,
      token: code.trim(),
      type: 'email',
    });
    setBusy(false);
    if (verifyError) {
      setError(t('checkMail.codeFout'));
      return;
    }
    router.replace('/');
  }

  async function resend() {
    if (!email) return;
    setResent(true);
    setError(undefined);
    await supabase.auth.signInWithOtp({
      email,
      options: { emailRedirectTo: 'tvz://auth/callback' },
    });
  }

  return (
    <SafeAreaView style={styles.safe}>
      <View style={styles.container}>
        <Pressable accessibilityRole="button" onPress={() => router.back()} style={styles.back}>
          <TvzText preset="cardTitle">←</TvzText>
        </Pressable>
        <Card>
          <EmptyState
            title={t('checkMail.titel')}
            body={t('checkMail.uitleg', { email: email ?? '' })}
          />
          <TextField
            label={t('checkMail.codeLabel')}
            placeholder="123456"
            value={code}
            onChangeText={(value) => setCode(value.replace(/\D/g, ''))}
            keyboardType="number-pad"
            maxLength={6}
            error={error}
            style={styles.codeInput}
          />
          <Button
            label={busy ? t('algemeen.laden') : t('checkMail.codeKnop')}
            variant="cta"
            size="lg"
            disabled={busy || code.trim().length !== 6}
            onPress={verifyCode}
          />
          <View style={styles.resendRow}>
            {resent ? (
              <TvzText preset="secondary" style={styles.resent}>
                {t('checkMail.opnieuwVerstuurd')}
              </TvzText>
            ) : (
              <TvzText preset="secondary" style={styles.center}>
                {t('checkMail.nietOntvangen')}{' '}
                <TvzText preset="secondary" style={styles.link} onPress={resend}>
                  {t('checkMail.opnieuw')}
                </TvzText>
              </TvzText>
            )}
          </View>
        </Card>
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
  codeInput: {
    textAlign: 'center',
    fontSize: 24,
    letterSpacing: 6,
  },
  resendRow: {
    paddingTop: spacing.lg,
    paddingBottom: spacing.sm,
    paddingHorizontal: spacing.md,
  },
  center: {
    textAlign: 'center',
  },
  resent: {
    textAlign: 'center',
    color: colors.successText,
  },
  link: {
    color: colors.primaryMid,
    textDecorationLine: 'underline',
  },
});

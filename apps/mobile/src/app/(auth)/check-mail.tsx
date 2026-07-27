import { router, useLocalSearchParams } from 'expo-router';
import { useState } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { t } from '@/i18n';
import { supabase } from '@/lib/supabase';
import { colors, spacing } from '@/theme';
import { Card, EmptyState, TvzText } from '@/ui';

/** Kijk in je mail (screen 02b): magic-link bevestiging. */
export default function CheckMailScreen() {
  const { email } = useLocalSearchParams<{ email: string }>();
  const [resent, setResent] = useState(false);

  async function resend() {
    if (!email) return;
    await supabase.auth.signInWithOtp({
      email,
      options: { emailRedirectTo: 'tvz://auth/callback' },
    });
    setResent(true);
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
  resendRow: {
    paddingBottom: spacing.md,
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

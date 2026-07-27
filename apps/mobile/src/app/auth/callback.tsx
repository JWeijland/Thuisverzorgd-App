import * as Linking from 'expo-linking';
import { router } from 'expo-router';
import { useEffect, useState } from 'react';
import { ActivityIndicator, StyleSheet, View } from 'react-native';

import { t } from '@/i18n';
import { supabase } from '@/lib/supabase';
import { colors, spacing } from '@/theme';
import { Button, TvzText } from '@/ui';

/** Vangt de magic-link deep link (tvz://auth/callback) op en zet de sessie. */
async function sessionFromUrl(url: string): Promise<boolean> {
  const fragment = url.split('#')[1] ?? '';
  const query = url.split('?')[1]?.split('#')[0] ?? '';
  const params = new URLSearchParams(fragment.length > 0 ? fragment : query);

  const accessToken = params.get('access_token');
  const refreshToken = params.get('refresh_token');
  if (accessToken && refreshToken) {
    const { error } = await supabase.auth.setSession({
      access_token: accessToken,
      refresh_token: refreshToken,
    });
    return !error;
  }
  const code = params.get('code');
  if (code) {
    const { error } = await supabase.auth.exchangeCodeForSession(code);
    return !error;
  }
  return false;
}

export default function AuthCallbackScreen() {
  const url = Linking.useURL();
  const [failed, setFailed] = useState(false);

  useEffect(() => {
    if (!url) return;
    sessionFromUrl(url).then((ok) => {
      if (ok) {
        router.replace('/');
      } else {
        setFailed(true);
      }
    });
  }, [url]);

  return (
    <View style={styles.container}>
      {failed ? (
        <View style={styles.failedBlock}>
          <TvzText preset="cardTitle" style={styles.onDark}>
            {t('callback.mislukt')}
          </TvzText>
          <Button
            label={t('callback.terugNaarStart')}
            variant="outlineOnDark"
            onPress={() => router.replace('/welkom')}
          />
        </View>
      ) : (
        <>
          <ActivityIndicator color={colors.white} />
          <TvzText preset="body" style={[styles.onDark, styles.busy]}>
            {t('callback.bezig')}
          </TvzText>
        </>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.primaryDark,
    alignItems: 'center',
    justifyContent: 'center',
    padding: spacing.screen,
  },
  onDark: {
    color: colors.white,
    textAlign: 'center',
  },
  busy: {
    marginTop: spacing.md,
  },
  failedBlock: {
    gap: spacing.lg,
    alignSelf: 'stretch',
  },
});

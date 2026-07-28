import * as Linking from 'expo-linking';
import { router } from 'expo-router';
import { useEffect, useRef, useState } from 'react';
import { StyleSheet, View } from 'react-native';

import { t } from '@/i18n';
import { supabase } from '@/lib/supabase';
import { colors, spacing } from '@/theme';
import { Button, TvzText } from '@/ui';
import { TvzLoader } from '@/ui/TvzLoader';

/**
 * Vangt de magic-link deep link (tvz://auth/callback) op en zet de sessie.
 * Robuust tegen de koude-start-race in productiebuilds: de URL wordt via de
 * hook, getInitialURL én het url-event opgehaald, met een sessie-fallback
 * en een nette time-out.
 */
function parseParams(url: string): URLSearchParams {
  const fragment = url.split('#')[1] ?? '';
  const query = url.split('?')[1]?.split('#')[0] ?? '';
  // Fragment heeft voorrang (implicit flow), query als fallback (PKCE/fouten).
  return new URLSearchParams(fragment.length > 0 ? fragment : query);
}

async function sessionFromUrl(url: string): Promise<'ok' | 'geen' | 'fout'> {
  const params = parseParams(url);
  if (params.get('error') || params.get('error_description')) return 'fout';

  const accessToken = params.get('access_token');
  const refreshToken = params.get('refresh_token');
  if (accessToken && refreshToken) {
    const { error } = await supabase.auth.setSession({
      access_token: accessToken,
      refresh_token: refreshToken,
    });
    return error ? 'fout' : 'ok';
  }
  const code = params.get('code');
  if (code) {
    const { error } = await supabase.auth.exchangeCodeForSession(code);
    return error ? 'fout' : 'ok';
  }
  return 'geen';
}

export default function AuthCallbackScreen() {
  const hookUrl = Linking.useURL();
  const [failed, setFailed] = useState(false);
  const done = useRef(false);

  function finish() {
    if (done.current) return;
    done.current = true;
    router.replace('/');
  }

  async function handle(url: string | null) {
    if (!url || done.current) return;
    const result = await sessionFromUrl(url);
    if (result === 'ok') {
      finish();
    } else if (result === 'fout') {
      setFailed(true);
    }
  }

  // 1. URL via de hook (updates) …
  useEffect(() => {
    const id = setTimeout(() => handle(hookUrl), 0);
    return () => clearTimeout(id);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [hookUrl]);

  // 2. … én imperatief bij koude start, plus het url-event als vangnet.
  useEffect(() => {
    Linking.getInitialURL().then(handle);
    const subscription = Linking.addEventListener('url', (event) => handle(event.url));

    // 3. Sessie-fallback: is de sessie al (elders) gezet, ga dan gewoon door.
    const poll = setInterval(async () => {
      const { data } = await supabase.auth.getSession();
      if (data.session) {
        clearInterval(poll);
        finish();
      }
    }, 1000);

    // 4. Na 15 seconden zonder resultaat: nette foutmelding met uitweg.
    const timeout = setTimeout(() => {
      clearInterval(poll);
      if (!done.current) setFailed(true);
    }, 15000);

    return () => {
      subscription.remove();
      clearInterval(poll);
      clearTimeout(timeout);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

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
          <TvzLoader onDark />
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
    marginTop: spacing.lg,
  },
  failedBlock: {
    gap: spacing.lg,
    alignSelf: 'stretch',
  },
});

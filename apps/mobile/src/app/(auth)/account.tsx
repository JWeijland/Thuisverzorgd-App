import { router, useLocalSearchParams } from 'expo-router';
import { useState } from 'react';
import {
  KeyboardAvoidingView,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  View,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import {
  gebruikersnaamFout,
  inlogEmail,
  internEmail,
  normaliseerGebruikersnaam,
} from '@/features/onboarding/username';
import { t } from '@/i18n';
import { supabase } from '@/lib/supabase';
import { colors, radius, spacing } from '@/theme';
import { Button, Chip, TextField, TvzText } from '@/ui';
import { useStatusBalk } from '@/lib/statusbalk';

const REDIRECT_URL = 'tvz://auth/callback';
const MIN_WACHTWOORD = 8;

/**
 * Account (screen 02). Aanmelden kan met een e-mailadres (inlogcode per mail)
 * of met alleen een gebruikersnaam en wachtwoord. Inloggen kan met een mailcode
 * of met wachtwoord, waarbij je zowel je e-mailadres als je gebruikersnaam mag
 * invullen.
 */
export default function AccountScreen() {
  useStatusBalk('donker');
  const { modus } = useLocalSearchParams<{ modus?: string }>();
  const isLogin = modus === 'inloggen';

  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  // Inloggen: mailcode of wachtwoord. Aanmelden: e-mail of gebruikersnaam.
  const [method, setMethod] = useState<'code' | 'wachtwoord'>('code');
  const metWachtwoord = method === 'wachtwoord';
  const [errors, setErrors] = useState<{
    name?: string;
    email?: string;
    username?: string;
    password?: string;
    general?: string;
  }>({});
  const [busy, setBusy] = useState(false);

  /** Nieuw account met alleen een gebruikersnaam. */
  async function meldAanMetGebruikersnaam() {
    const next: typeof errors = {};
    if (name.trim().length < 2) next.name = t('account.naamVerplicht');
    const naamFout = gebruikersnaamFout(username);
    if (naamFout === 'kort') next.username = t('account.gebruikersnaamKort');
    if (naamFout === 'tekens') next.username = t('account.gebruikersnaamTekens');
    if (password.length < MIN_WACHTWOORD) next.password = t('account.wachtwoordKort');
    setErrors(next);
    if (Object.keys(next).length > 0) return;

    setBusy(true);
    const naam = normaliseerGebruikersnaam(username);

    const { data: vrij, error: checkError } = await supabase.rpc('username_beschikbaar', {
      p_username: naam,
    });
    if (checkError) {
      setBusy(false);
      setErrors({ general: `${t('algemeen.foutTitel')}. ${t('algemeen.foutOpnieuw')}.` });
      return;
    }
    if (vrij === false) {
      setBusy(false);
      setErrors({ username: t('account.gebruikersnaamBezet') });
      return;
    }

    const { error } = await supabase.auth.signUp({
      email: internEmail(naam),
      password,
      options: { data: { name: name.trim() } },
    });
    setBusy(false);
    if (error) {
      setErrors({
        general: error.message.toLowerCase().includes('already')
          ? t('account.gebruikersnaamBezet')
          : `${t('algemeen.foutTitel')}. ${t('algemeen.foutOpnieuw')}.`,
      });
      return;
    }
    router.replace('/');
  }

  async function submit() {
    if (!isLogin && metWachtwoord) {
      await meldAanMetGebruikersnaam();
      return;
    }

    const next: typeof errors = {};
    if (!isLogin && name.trim().length < 2) next.name = t('account.naamVerplicht');
    // Bij inloggen met wachtwoord mag het veld ook een gebruikersnaam zijn.
    const inlognaamOk = metWachtwoord
      ? email.trim().length >= 3
      : /^\S+@\S+\.\S+$/.test(email.trim());
    if (!inlognaamOk) {
      next.email = metWachtwoord ? t('account.inlognaamVerplicht') : t('account.emailOngeldig');
    }
    if (metWachtwoord && password.length === 0) next.password = t('account.wachtwoordVerplicht');
    setErrors(next);
    if (Object.keys(next).length > 0) return;

    setBusy(true);

    if (metWachtwoord) {
      const { error } = await supabase.auth.signInWithPassword({
        email: inlogEmail(email),
        password,
      });
      setBusy(false);
      if (error) {
        setErrors({ general: t('account.wachtwoordFout') });
        return;
      }
      router.replace('/');
      return;
    }

    const cleanEmail = email.trim().toLowerCase();

    // Demo-accounts (@thuisverzorgd.dev) hebben geen echte mailbox en loggen
    // direct in met het vaste demo-wachtwoord, zonder mailcode.
    if (cleanEmail.endsWith('@thuisverzorgd.dev')) {
      const { error: demoError } = await supabase.auth.signInWithPassword({
        email: cleanEmail,
        password: 'DemoThuisverzorgd1!',
      });
      setBusy(false);
      if (demoError) {
        setErrors({ general: `${t('algemeen.foutTitel')}. ${t('algemeen.foutOpnieuw')}.` });
        return;
      }
      router.replace('/');
      return;
    }

    const { error } = await supabase.auth.signInWithOtp({
      email: cleanEmail,
      options: {
        emailRedirectTo: REDIRECT_URL,
        data: isLogin ? undefined : { name: name.trim() },
      },
    });
    setBusy(false);
    if (error) {
      setErrors({ general: `${t('algemeen.foutTitel')}. ${t('algemeen.foutOpnieuw')}.` });
      return;
    }
    router.push({ pathname: '/check-mail', params: { email: cleanEmail } });
  }

  const knopLabel = busy
    ? t('algemeen.laden')
    : isLogin
      ? metWachtwoord
        ? t('account.logIn')
        : t('account.verstuur')
      : metWachtwoord
        ? t('account.maakAccount')
        : t('account.verstuur');

  return (
    <SafeAreaView style={styles.safe}>
      <KeyboardAvoidingView
        style={styles.fill}
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      >
        <ScrollView contentContainerStyle={styles.container} keyboardShouldPersistTaps="handled">
          <Pressable accessibilityRole="button" onPress={() => router.back()} style={styles.back}>
            <TvzText preset="cardTitle">←</TvzText>
          </Pressable>
          <TvzText preset="screenTitle">
            {isLogin ? t('account.titelInloggen') : t('account.titelNieuw')}
          </TvzText>
          <TvzText preset="secondary" style={styles.uitleg}>
            {isLogin
              ? metWachtwoord
                ? t('account.uitlegWachtwoord')
                : t('account.uitlegInloggen')
              : metWachtwoord
                ? t('account.uitlegGebruikersnaam')
                : t('account.uitleg')}
          </TvzText>

          <View style={styles.methodRow}>
            <Chip
              label={isLogin ? t('account.metCode') : t('account.metEmail')}
              selected={!metWachtwoord}
              onPress={() => {
                setMethod('code');
                setErrors({});
              }}
            />
            <Chip
              label={isLogin ? t('account.metWachtwoord') : t('account.metGebruikersnaam')}
              selected={metWachtwoord}
              onPress={() => {
                setMethod('wachtwoord');
                setErrors({});
              }}
            />
          </View>

          {!isLogin ? (
            <TextField
              label={t('account.naamLabel')}
              placeholder={t('account.naamPlaceholder')}
              value={name}
              onChangeText={setName}
              autoComplete="name"
              error={errors.name}
            />
          ) : null}

          {!isLogin && metWachtwoord ? (
            <TextField
              label={t('account.gebruikersnaamLabel')}
              placeholder={t('account.gebruikersnaamPlaceholder')}
              value={username}
              onChangeText={setUsername}
              autoCapitalize="none"
              autoCorrect={false}
              autoComplete="username-new"
              error={errors.username}
            />
          ) : (
            <TextField
              label={
                isLogin && metWachtwoord ? t('account.inlognaamLabel') : t('account.emailLabel')
              }
              placeholder={
                isLogin && metWachtwoord
                  ? t('account.inlognaamPlaceholder')
                  : t('account.emailPlaceholder')
              }
              value={email}
              onChangeText={setEmail}
              autoCapitalize="none"
              autoCorrect={false}
              autoComplete={isLogin && metWachtwoord ? 'username' : 'email'}
              keyboardType={isLogin && metWachtwoord ? 'default' : 'email-address'}
              error={errors.email}
            />
          )}

          {metWachtwoord ? (
            <TextField
              label={isLogin ? t('account.wachtwoordLabel') : t('account.wachtwoordNieuwLabel')}
              placeholder={isLogin ? t('account.wachtwoordPlaceholder') : '••••••••'}
              value={password}
              onChangeText={setPassword}
              secureTextEntry
              autoCapitalize="none"
              autoComplete={isLogin ? 'current-password' : 'new-password'}
              error={errors.password}
            />
          ) : null}

          {!isLogin && metWachtwoord ? (
            <View style={styles.waarschuwing}>
              <TvzText preset="secondary" style={styles.waarschuwingText}>
                {t('account.geenMailWaarschuwing')}
              </TvzText>
            </View>
          ) : null}

          {errors.general ? (
            <TvzText preset="secondary" style={styles.generalError}>
              {errors.general}
            </TvzText>
          ) : null}
        </ScrollView>
        <View style={styles.footer}>
          <TvzText preset="secondary" style={styles.voorwaarden}>
            {t('account.voorwaarden')}
          </TvzText>
          <Button label={knopLabel} variant="primary" size="lg" disabled={busy} onPress={submit} />
        </View>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: colors.bg,
  },
  fill: { flex: 1 },
  container: {
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
    marginBottom: spacing.lg,
  },
  methodRow: {
    flexDirection: 'row',
    gap: spacing.chipGap,
    marginBottom: spacing.xl,
  },
  waarschuwing: {
    backgroundColor: colors.warnBg,
    borderRadius: radius.row,
    padding: spacing.md,
    marginBottom: spacing.md,
  },
  waarschuwingText: {
    color: colors.warnText,
  },
  generalError: {
    color: colors.error,
  },
  footer: {
    padding: spacing.screen,
    gap: spacing.md,
  },
  voorwaarden: {
    textAlign: 'center',
    color: colors.inkFaint,
  },
});

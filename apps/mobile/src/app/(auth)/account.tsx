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

import { t } from '@/i18n';
import { supabase } from '@/lib/supabase';
import { colors, spacing } from '@/theme';
import { Button, Chip, TextField, TvzText } from '@/ui';

const REDIRECT_URL = 'tvz://auth/callback';

/** Account (screen 02): naam + e-mail; inloggen kan met mailcode of wachtwoord. */
export default function AccountScreen() {
  const { modus } = useLocalSearchParams<{ modus?: string }>();
  const isLogin = modus === 'inloggen';
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [method, setMethod] = useState<'code' | 'wachtwoord'>('code');
  const withPassword = isLogin && method === 'wachtwoord';
  const [errors, setErrors] = useState<{
    name?: string;
    email?: string;
    password?: string;
    general?: string;
  }>({});
  const [busy, setBusy] = useState(false);

  async function submit() {
    const next: typeof errors = {};
    if (!isLogin && name.trim().length < 2) next.name = t('account.naamVerplicht');
    if (!/^\S+@\S+\.\S+$/.test(email.trim())) next.email = t('account.emailOngeldig');
    if (withPassword && password.length === 0) next.password = t('account.wachtwoordVerplicht');
    setErrors(next);
    if (Object.keys(next).length > 0) return;

    setBusy(true);
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

    if (withPassword) {
      const { error } = await supabase.auth.signInWithPassword({
        email: cleanEmail,
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
              ? withPassword
                ? t('account.uitlegWachtwoord')
                : t('account.uitlegInloggen')
              : t('account.uitleg')}
          </TvzText>

          {isLogin ? (
            <View style={styles.methodRow}>
              <Chip
                label={t('account.metCode')}
                selected={method === 'code'}
                onPress={() => setMethod('code')}
              />
              <Chip
                label={t('account.metWachtwoord')}
                selected={method === 'wachtwoord'}
                onPress={() => setMethod('wachtwoord')}
              />
            </View>
          ) : null}

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
          <TextField
            label={t('account.emailLabel')}
            placeholder={t('account.emailPlaceholder')}
            value={email}
            onChangeText={setEmail}
            autoCapitalize="none"
            autoComplete="email"
            keyboardType="email-address"
            error={errors.email}
          />
          {withPassword ? (
            <TextField
              label={t('account.wachtwoordLabel')}
              placeholder={t('account.wachtwoordPlaceholder')}
              value={password}
              onChangeText={setPassword}
              secureTextEntry
              autoCapitalize="none"
              autoComplete="current-password"
              error={errors.password}
            />
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
          <Button
            label={
              busy ? t('algemeen.laden') : withPassword ? t('account.logIn') : t('account.verstuur')
            }
            variant="primary"
            size="lg"
            disabled={busy}
            onPress={submit}
          />
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

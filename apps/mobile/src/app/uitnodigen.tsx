import { router } from 'expo-router';
import { useState } from 'react';
import { Pressable, ScrollView, StyleSheet } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { useInvite, useMyCircle } from '@/features/circles/api';
import { t } from '@/i18n';
import { colors, spacing } from '@/theme';
import { Button, TextField, TvzText } from '@/ui';
import { useStatusBalk } from '@/lib/statusbalk';

/**
 * Buddy uitnodigen die je al kent: op e-mailadres of TVZ-ID. Onbekende
 * buddy's uit de buurt stelt Bo voor op /regelen/buddy-zoeken; die twee
 * dingen stonden eerst door elkaar op deze pagina (feedback Jelle 11-08).
 */
export default function UitnodigenScreen() {
  useStatusBalk('donker');
  const circle = useMyCircle();
  const invite = useInvite(circle.data?.id);
  const [target, setTarget] = useState('');
  const [message, setMessage] = useState('');
  const [feedback, setFeedback] = useState<{ ok: boolean; text: string } | null>(null);

  function errorText(err: unknown): string {
    const msg = err instanceof Error ? err.message : '';
    if (msg.includes('niet_gevonden')) return t('uitnodigen.nietGevonden');
    if (msg.includes('al_lid')) return t('uitnodigen.alLid');
    return `${t('algemeen.foutTitel')}. ${t('algemeen.foutOpnieuw')}.`;
  }

  function sendInvite(value: string) {
    setFeedback(null);
    invite.mutate(
      { target: value, message: message.trim() || undefined },
      {
        onSuccess: () => {
          setFeedback({ ok: true, text: t('uitnodigen.verstuurd') });
          setTarget('');
        },
        onError: (err) => setFeedback({ ok: false, text: errorText(err) }),
      },
    );
  }

  return (
    <SafeAreaView style={styles.safe}>
      <ScrollView contentContainerStyle={styles.container} keyboardShouldPersistTaps="handled">
        <Pressable accessibilityRole="button" onPress={() => router.back()} style={styles.back}>
          <TvzText preset="cardTitle">←</TvzText>
        </Pressable>
        <TvzText preset="screenTitle">{t('uitnodigen.titel')}</TvzText>
        <TvzText preset="secondary" style={styles.uitleg}>
          {t('uitnodigen.uitleg')}
        </TvzText>

        <TextField
          label={t('uitnodigen.veldLabel')}
          placeholder={t('uitnodigen.veldPlaceholder')}
          value={target}
          onChangeText={setTarget}
          autoCapitalize="none"
        />
        <TextField
          label={t('uitnodigen.berichtLabel')}
          placeholder={t('uitnodigen.berichtPlaceholder')}
          value={message}
          onChangeText={setMessage}
          multiline
        />
        {feedback ? (
          <TvzText
            preset="secondary"
            style={feedback.ok ? styles.feedbackOk : styles.feedbackError}
          >
            {feedback.text}
          </TvzText>
        ) : null}
        <Button
          label={invite.isPending ? t('algemeen.laden') : t('uitnodigen.verstuur')}
          variant="cta"
          size="lg"
          disabled={invite.isPending || target.trim().length < 4}
          onPress={() => sendInvite(target.trim())}
        />

      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: colors.bg,
  },
  container: {
    padding: spacing.screen,
    paddingBottom: 60,
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
  feedbackOk: {
    color: colors.successText,
    marginBottom: spacing.sm,
  },
  feedbackError: {
    color: colors.error,
    marginBottom: spacing.sm,
  },
});

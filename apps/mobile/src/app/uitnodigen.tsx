import { useState } from 'react';
import { ScrollView, StyleSheet, View } from 'react-native';

import { useInvite, useMyCircle } from '@/features/circles/api';
import { PadHeader } from '@/features/navigatie/PadHeader';
import { t } from '@/i18n';
import { colors, spacing } from '@/theme';
import { Button, TextField, TvzText } from '@/ui';

/**
 * Buddy uitnodigen die je al kent: op e-mailadres of TVZ-ID. Onbekende
 * buddy's uit de buurt stelt Bo voor op /regelen/buddy-zoeken; die twee
 * dingen stonden eerst door elkaar op deze pagina (feedback Jelle 11-08).
 *
 * De pagina hoort bij het hulp-pad en houdt daarom de groene kop; hij sprong
 * eerder uit de kleur van de route (feedback Jelle 11-08).
 */
export default function UitnodigenScreen() {
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
    <View style={styles.safe}>
      <PadHeader
        pad="regelen"
        actiefRoute="/regelen/kring"
        kruimels={[t('uitnodigen.titel')]}
      />
      <ScrollView contentContainerStyle={styles.container} keyboardShouldPersistTaps="handled">
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
    </View>
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
  uitleg: {
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

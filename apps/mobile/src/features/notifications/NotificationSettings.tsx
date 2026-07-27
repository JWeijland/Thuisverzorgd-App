import { useQueryClient } from '@tanstack/react-query';
import { StyleSheet, View } from 'react-native';

import { useProfile, useSession } from '@/features/onboarding/useAuth';
import { t } from '@/i18n';
import { supabase } from '@/lib/supabase';
import { colors, spacing } from '@/theme';
import { Card, Toggle, TvzText } from '@/ui';

import { categoryEnabled, NOTIFICATION_CATEGORIES } from '@/features/notifications/categories';

/** Meldingen per categorie aan/uit; opgeslagen in profiles.notification_prefs. */
export function NotificationSettings() {
  const { session } = useSession();
  const profile = useProfile();
  const queryClient = useQueryClient();
  const prefs = (profile.data as unknown as { notification_prefs?: Record<string, unknown> })
    ?.notification_prefs;

  async function setCategory(kinds: string[], enabled: boolean) {
    const next: Record<string, unknown> = { ...(prefs ?? {}) };
    for (const kind of kinds) {
      next[kind] = enabled;
    }
    await supabase.from('profiles').update({ notification_prefs: next }).eq('id', session!.user.id);
    queryClient.invalidateQueries({ queryKey: ['profile'] });
  }

  return (
    <Card style={styles.card}>
      <TvzText preset="cardTitle">{t('meldingen.titel')}</TvzText>
      <TvzText preset="secondary">{t('meldingen.uitleg')}</TvzText>
      {NOTIFICATION_CATEGORIES.map((category) => {
        const enabled = categoryEnabled(prefs ?? {}, category.kinds);
        return (
          <View key={category.labelKey} style={styles.row}>
            <TvzText preset="body" style={styles.label}>
              {t(category.labelKey)}
            </TvzText>
            <Toggle
              value={enabled}
              onValueChange={(value) => setCategory(category.kinds, value)}
              accessibilityLabel={t(category.labelKey)}
            />
          </View>
        );
      })}
    </Card>
  );
}

const styles = StyleSheet.create({
  card: {
    marginBottom: spacing.md,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingTop: spacing.md,
    borderTopWidth: 1,
    borderTopColor: colors.line,
    marginTop: spacing.md,
  },
  label: {
    flex: 1,
    paddingRight: spacing.md,
  },
});

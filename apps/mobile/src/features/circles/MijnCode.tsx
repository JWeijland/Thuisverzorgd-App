import { Share, StyleSheet, View } from 'react-native';

import { useProfile } from '@/features/onboarding/useAuth';
import { t } from '@/i18n';
import { haptics } from '@/lib/haptics';
import { colors, radius, spacing } from '@/theme';
import { Button, Card, TvzText } from '@/ui';

/**
 * De persoonlijke code van de oudere (feedback Jelle 11-08). De koppeling
 * gaat deze kant op: hij leest zijn code voor aan degene die de hulp regelt,
 * en die vult hem in. Zo hoeft de oudere zelf niets over te tikken.
 *
 * De code is het `tvz_id` dat elk profiel al heeft.
 */
export function MijnCode({ compact = false }: { compact?: boolean }) {
  const profile = useProfile();
  const code = profile.data?.tvz_id ?? '';
  if (!code) return null;

  return (
    <Card dashed style={styles.kaart}>
      <TvzText preset="meta" style={styles.label}>
        {t('mijnCode.label')}
      </TvzText>
      <View style={styles.codeRij}>
        <TvzText preset="screenTitle" style={styles.code}>
          {code}
        </TvzText>
      </View>
      <TvzText preset="secondary" style={styles.uitleg}>
        {t('mijnCode.uitleg')}
      </TvzText>
      {compact ? null : (
        <Button
          label={t('mijnCode.deel')}
          variant="outline"
          onPress={() => {
            void haptics.tik();
            // Delen zit in React Native zelf: geen extra module, dus dit gaat
            // gewoon mee in een EAS-update zonder nieuwe build.
            Share.share({ message: t('mijnCode.deelTekst', { code }) }).catch(() => {});
          }}
        />
      )}
    </Card>
  );
}

const styles = StyleSheet.create({
  kaart: {
    gap: spacing.sm,
    alignItems: 'center',
  },
  label: {
    textTransform: 'uppercase',
    letterSpacing: 0.6,
  },
  codeRij: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.sm,
    borderRadius: radius.card,
    backgroundColor: colors.surfaceAlt,
  },
  code: {
    letterSpacing: 2,
  },
  uitleg: {
    textAlign: 'center',
  },
});

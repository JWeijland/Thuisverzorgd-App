import { useState } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { LogOut } from 'lucide-react-native';

import { logUit } from '@/features/onboarding/uitloggen';
import { t } from '@/i18n';
import { colors, hitTarget, spacing } from '@/theme';
import { BottomSheet, Button, TvzText } from '@/ui';

/**
 * Uitloggen vanaf een scherm zonder profieltab. De hulpvrager ziet alleen de
 * planning en zijn kring (bewust: zo eenvoudig mogelijk), maar moest daardoor
 * ook nergens meer uit kunnen loggen. Deze knop hangt in de kop van dat scherm.
 *
 * Met bevestiging: op de ouderenpagina is per ongeluk uitloggen extra
 * vervelend, want opnieuw inloggen vraagt om de mailcode.
 */
export function UitlogKnop() {
  const [open, setOpen] = useState(false);
  const [bezig, setBezig] = useState(false);

  async function uitloggen() {
    if (bezig) return;
    setBezig(true);
    await logUit();
    // Navigatie regelt de auth-listener; als dit scherm toch blijft staan,
    // moet de knop weer bruikbaar zijn.
    setBezig(false);
    setOpen(false);
  }

  return (
    <>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel={t('profiel.uitloggen')}
        onPress={() => setOpen(true)}
        style={styles.knop}
        hitSlop={8}
      >
        <LogOut color={colors.white} size={22} strokeWidth={2.2} />
      </Pressable>

      <BottomSheet visible={open} onClose={() => setOpen(false)}>
        <TvzText preset="cardTitle" style={styles.titel}>
          {t('profiel.uitloggenTitel')}
        </TvzText>
        <TvzText preset="body" style={styles.tekst}>
          {t('profiel.uitloggenUitleg')}
        </TvzText>
        <View style={styles.knoppen}>
          <Button
            label={t('profiel.uitloggen')}
            variant="danger"
            size="lg"
            disabled={bezig}
            onPress={uitloggen}
          />
          <Button
            label={t('profiel.blijfIngelogd')}
            variant="outline"
            size="lg"
            onPress={() => setOpen(false)}
          />
        </View>
      </BottomSheet>
    </>
  );
}

const styles = StyleSheet.create({
  knop: {
    width: hitTarget.min,
    height: hitTarget.min,
    borderRadius: hitTarget.min / 2,
    backgroundColor: 'rgba(255,255,255,0.18)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  titel: {
    fontSize: 19,
  },
  tekst: {
    marginTop: spacing.sm,
  },
  knoppen: {
    gap: spacing.md,
    marginTop: spacing.xl,
  },
});

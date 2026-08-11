import { router } from 'expo-router';
import { StyleSheet, View } from 'react-native';

import { useBevestigProefweek } from '@/features/circles/kringopbouw';
import { t } from '@/i18n';
import { haptics } from '@/lib/haptics';
import { colors, radius, spacing } from '@/theme';
import { Bo, Button, TvzText } from '@/ui';

/** Zeven dagen; daarna vraagt Bo of het rooster werkte. */
const PROEFWEEK_DAGEN = 7;
const DAG_MS = 24 * 60 * 60 * 1000;

/** Is de proefweek voorbij? Pure functie, los van de klok in de render. */
export function proefweekVoorbij(gestartOp: string, nu: Date): boolean {
  return (nu.getTime() - new Date(gestartOp).getTime()) / DAG_MS >= PROEFWEEK_DAGEN;
}

type Props = {
  circleId: string;
  /** `circles.trial_started_at`; null zolang er geen proefweek loopt. */
  gestartOp: string | null;
  /** `circles.trial_confirmed_at`; gevuld zodra de kring bevestigd heeft. */
  bevestigdOp: string | null;
  /** De huidige datum; het scherm geeft hem door zodat dit component puur blijft. */
  nu: Date;
};

/**
 * De terugblik op de proefweek (handoff §3e, stap 6). Na zeven dagen vraagt
 * Bo of het rooster werkte. Bevestig je, dan blijft de week zoals hij is;
 * wil je schuiven, dan ga je naar de planning. Zolang de week nog loopt of al
 * bevestigd is, staat hier niets.
 */
export function ProefweekTerugblik({ circleId, gestartOp, bevestigdOp, nu }: Props) {
  const bevestig = useBevestigProefweek();

  if (!gestartOp || bevestigdOp || !proefweekVoorbij(gestartOp, nu)) return null;

  return (
    <View style={styles.kaart}>
      <View style={styles.rij}>
        <Bo width={56} />
        <View style={styles.tekst}>
          <TvzText preset="cardTitle">{t('proefweek.titel')}</TvzText>
          <TvzText preset="secondary">{t('proefweek.uitleg')}</TvzText>
        </View>
      </View>
      <View style={styles.knoppen}>
        <Button
          label={t('proefweek.werkte')}
          variant="cta"
          style={styles.knop}
          disabled={bevestig.isPending}
          onPress={() => {
            void haptics.voltooid();
            bevestig.mutate(circleId);
          }}
        />
        <Button
          label={t('proefweek.aanpassen')}
          variant="outline"
          style={styles.knop}
          onPress={() => router.push('/weekplanning')}
        />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  kaart: {
    backgroundColor: colors.successBg,
    borderRadius: radius.card,
    padding: spacing.cardPadding,
    gap: spacing.md,
    marginBottom: spacing.cardGap,
  },
  rij: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
  },
  tekst: {
    flex: 1,
  },
  knoppen: {
    flexDirection: 'row',
    gap: spacing.md,
  },
  knop: {
    flex: 1,
  },
});

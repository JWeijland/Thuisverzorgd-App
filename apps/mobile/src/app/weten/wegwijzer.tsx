import { router } from 'expo-router';
import { Pressable, StyleSheet, View } from 'react-native';

import { useMyCircle } from '@/features/circles/api';
import { PadHeader } from '@/features/navigatie/PadHeader';
import { PadPagina } from '@/features/navigatie/PadPagina';
import { useTasks } from '@/features/tasks/api';
import { taskLabel } from '@/features/tasks/logic';
import { MakelaarHero } from '@/features/wegwijzer/MakelaarHero';
import { WegwijzerLijst } from '@/features/wegwijzer/WegwijzerLijst';
import { t } from '@/i18n';
import { formatTime, toDateString } from '@/lib/dates';
import { colors, radius, spacing } from '@/theme';
import { TvzText } from '@/ui';

/**
 * Wegwijzer: de startpagina van het weet-pad (handoff, scherm 02).
 * Van boven naar onder: de strip met wie er vandaag komt, het
 * hulpmakelaar-blok, en daaronder de kennisbank met zoeken en onderwerpen.
 * Zodra je gaat zoeken verdwijnt de kop en gaat het alleen nog om je vraag.
 */
export default function Wegwijzer() {
  const circle = useMyCircle();
  const vandaag = new Date();
  const taken = useTasks(circle.data?.id, vandaag, vandaag);
  const vandaagKey = toDateString(vandaag);
  const komtVandaag = (taken.data ?? []).find(
    (taak) => taak.date === vandaagKey && taak.status === 'ingepland' && taak.claimer,
  );

  const kop = (
    <View style={styles.kop}>
      {komtVandaag?.claimer ? (
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={t('wegwijzerPad.naarRooster')}
          onPress={() => router.push('/regelen/planning')}
          style={styles.vandaag}
        >
          <View style={styles.stip} />
          <TvzText preset="secondary" style={styles.vandaagTekst} numberOfLines={2}>
            <TvzText preset="bodyBold">{t('wegwijzerPad.vandaag')} </TvzText>
            {t('wegwijzerPad.vandaagRegel', {
              naam: komtVandaag.claimer.name.split(' ')[0]!,
              tijd: formatTime(komtVandaag.time),
              taak: taskLabel(komtVandaag),
            })}
          </TvzText>
          <TvzText preset="meta" style={styles.vandaagLink}>
            {t('wegwijzerPad.naarRooster')}
          </TvzText>
        </Pressable>
      ) : null}
      <MakelaarHero />
    </View>
  );

  return (
    <View style={styles.safe}>
      <PadHeader pad="weten" />
      <PadPagina>
        <WegwijzerLijst kop={kop} />
      </PadPagina>
    </View>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: colors.bg,
  },
  kop: {
    gap: spacing.cardGap,
    marginBottom: spacing.md,
  },
  vandaag: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    backgroundColor: colors.white,
    borderRadius: radius.row,
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.md,
    borderWidth: 1,
    borderColor: colors.line,
  },
  stip: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: colors.accent,
  },
  vandaagTekst: {
    flex: 1,
  },
  vandaagLink: {
    color: colors.primaryMid,
  },
});

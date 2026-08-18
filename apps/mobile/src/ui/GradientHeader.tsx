import { LinearGradient } from 'expo-linear-gradient';
import { router } from 'expo-router';
import { ArrowLeft } from 'lucide-react-native';
import type { ReactNode } from 'react';
import { Pressable, StyleSheet, View, useWindowDimensions } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { t } from '@/i18n';
import { useStatusBalk } from '@/lib/statusbalk';
import { colors, gradient, gradientGroen, paginabalk, spacing } from '@/theme';
import { BoPeek } from '@/ui/Bo';
import { Golfrand, Kringel } from '@/ui/getekend/Getekend';
import { TvzText } from '@/ui/TvzText';

type Props = {
  title: string;
  subtitle?: string;
  /** Rechts naast de titel, bijv. de inbox-bel. */
  right?: ReactNode;
  /** Onder de subtitel, bijv. een subnav met pillen of de kringbalk. */
  children?: ReactNode;
  /** Witte kringelstreep onder de titel: het getekende gebaar van de balk. */
  wobbel?: boolean;
  /** Mascotte Bo piept rechtsonder over de rand van de balk. */
  bo?: boolean;
  /** Terugpijl linksboven; elke pagina hoort een weg terug te hebben. */
  terug?: boolean;
  /** Groene balk, alleen voor bevestiging en het profiel van een buddy. */
  groen?: boolean;
};

/**
 * De paginabalk (huisstijl v4): het Thuisrode verloop met de vaste golfrand
 * eronder. Het groene verloop bestaat alleen nog voor bevestigingen en het
 * buddy-profiel, en draagt dan Nachtbruine tekst: nooit wit op groen.
 */
export function GradientHeader({
  title,
  subtitle,
  right,
  children,
  wobbel = false,
  bo,
  terug = false,
  groen = false,
}: Props) {
  const { width } = useWindowDimensions();
  // Op de rode balk moeten klok, wifi en batterij wit zijn; op de lichtere
  // groene balk juist donker, net als de Nachtbruine tekst.
  useStatusBalk(groen ? 'donker' : 'licht');
  const verloop = groen ? gradientGroen : gradient;
  const golfKleur = verloop.colors[verloop.colors.length - 1]!;
  const tekstKleur = groen ? colors.onAccent : colors.white;

  return (
    <View>
      <LinearGradient {...verloop} style={styles.header}>
        <SafeAreaView edges={['top']}>
          <View style={styles.titleRow}>
            {terug ? (
              <Pressable
                accessibilityRole="button"
                accessibilityLabel={t('algemeen.terug')}
                onPress={() => (router.canGoBack() ? router.back() : router.replace('/pad'))}
                style={[styles.terug, groen && styles.terugOpGroen]}
              >
                <ArrowLeft color={tekstKleur} size={20} strokeWidth={2.4} />
              </Pressable>
            ) : null}
            <View style={styles.titleWrap}>
              <TvzText preset="screenTitle" style={[styles.title, { color: tekstKleur }]}>
                {title}
              </TvzText>
              {wobbel && !groen ? (
                // Eén gebaar per balk: de platte kringelstreep, wit op 50%.
                // Op Hulpgroen komt geen kringel: te weinig contrast.
                <Kringel
                  variant="onder"
                  width={92}
                  kleur={colors.white}
                  dekking={paginabalk.kringelDekking}
                  style={styles.streep}
                />
              ) : null}
            </View>
            {right}
          </View>
          {subtitle ? (
            <TvzText
              preset="secondary"
              style={groen ? { color: colors.onAccent, opacity: 0.85 } : styles.sub}
            >
              {subtitle}
            </TvzText>
          ) : null}
          {children}
        </SafeAreaView>

        {bo ? (
          // Vóór de golfrand getekend: de golf valt over Bo's onderrand,
          // zodat zij echt over de rand lijkt te piepen.
          <View pointerEvents="none" style={styles.boPeek}>
            <BoPeek width={86} />
          </View>
        ) : null}
      </LinearGradient>

      {/* De golfrand uit het brandbook: de vaste onderrand van elke
          paginabalk, in de kleur van de onderkant van het verloop. */}
      <Golfrand
        width={width}
        height={paginabalk.golfHoogte}
        kleur={golfKleur}
        style={styles.golf}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  header: {
    paddingHorizontal: spacing.screen,
    paddingBottom: spacing.lg,
  },
  titleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: spacing.md,
  },
  titleWrap: {
    flex: 1,
  },
  terug: {
    width: 36,
    height: 36,
    borderRadius: 18,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: 'rgba(255,255,255,0.2)',
    marginTop: spacing.sm,
  },
  terugOpGroen: {
    backgroundColor: 'rgba(58,29,22,0.12)',
  },
  title: {
    fontSize: 24,
    marginTop: spacing.sm,
  },
  streep: {
    marginTop: 2,
    marginBottom: 2,
  },
  sub: {
    color: 'rgba(255,255,255,0.85)',
  },
  golf: {
    marginTop: -1,
  },
  boPeek: {
    position: 'absolute',
    right: 18,
    bottom: 4,
  },
});

import { LinearGradient } from 'expo-linear-gradient';
import { router } from 'expo-router';
import { BookOpen, HeartHandshake, Settings } from 'lucide-react-native';
import { Image, Pressable, ScrollView, StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { PADEN, schuifjesVoor, type Pad } from '@/features/navigatie/paden';
import { useProfile } from '@/features/onboarding/useAuth';
import { t } from '@/i18n';
import { haptics } from '@/lib/haptics';
import { useStatusBalk } from '@/lib/statusbalk';
import { colors, radius, shadows, spacing } from '@/theme';
import { Bo } from '@/ui/Bo';
import { TvzText } from '@/ui/TvzText';

/**
 * Het keuzescherm (handoff-voorzieningen, scherm 01). Dit is het startpunt
 * van de app voor beheerders en hulpvragers: twee grote gekleurde kaarten,
 * Bo ernaast, en onderaan een kleine knop naar de eigen gegevens.
 *
 * De tabbalk bestaat niet meer; vanaf hier ga je een pad in en kom je via
 * de Bo-knop in de header altijd hier terug.
 */
export default function PadKeuze() {
  useStatusBalk('donker');

  return (
    <SafeAreaView edges={['top']} style={styles.safe}>
      <ScrollView contentContainerStyle={styles.inhoud}>
        <View style={styles.kop}>
          <View style={styles.kopTekst}>
            <TvzText preset="screenTitle">{t('paden.keuzeTitel')}</TvzText>
            <TvzText preset="secondary" style={styles.kopSub}>
              {t('paden.keuzeSub')}
            </TvzText>
          </View>
          <Bo width={78} />
        </View>

        <PadKaart
          pad={PADEN.weten}
          icoon={<BookOpen color={colors.white} size={20} strokeWidth={2.3} />}
        />
        <PadKaart
          pad={PADEN.regelen}
          icoon={<HeartHandshake color={colors.white} size={20} strokeWidth={2.3} />}
        />

        <Pressable
          accessibilityRole="button"
          onPress={() => {
            void haptics.tik();
            router.push('/profiel');
          }}
          style={styles.gegevens}
        >
          <Settings color={colors.inkSoft} size={17} strokeWidth={2.2} />
          <TvzText preset="cardTitle" style={styles.gegevensTekst}>
            {t('paden.gegevens')}
          </TvzText>
        </Pressable>
      </ScrollView>
    </SafeAreaView>
  );
}

/** Foto per pad: iemand die iets opzoekt, en iemand die iemand helpt. */
const FOTOS = {
  weten: require('../../assets/images/paden/weten.jpg'),
  regelen: require('../../assets/images/paden/regelen.jpg'),
  vrijwilliger: require('../../assets/images/paden/regelen.jpg'),
} as const;

function PadKaart({ pad, icoon }: { pad: Pad; icoon: React.ReactNode }) {
  const profile = useProfile();
  const schuifjes = schuifjesVoor(pad, profile.data?.role);
  const eerste = schuifjes[0];
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={t(pad.titelKey)}
      onPress={() => {
        void haptics.stevig();
        if (eerste) router.replace(eerste.route as never);
      }}
    >
      {/* Tekst links op de padkleur, foto rechts. De foto bedekt bewust maar
          een deel van de kaart: hij vertelt waar het pad over gaat zonder de
          tekst in de weg te zitten (wens Jelle 11-08). */}
      <View style={[styles.kaart, shadows.floating]}>
        <LinearGradient
          colors={pad.gradient}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 1 }}
          style={styles.kaartTekstVlak}
        >
          <View style={styles.kaartKop}>
            <View style={styles.kaartIcoon}>{icoon}</View>
            <TvzText preset="cardTitle" style={styles.kaartTitel}>
              {t(pad.titelKey)}
            </TvzText>
          </View>
          <TvzText preset="secondary" style={styles.kaartUitleg}>
            {t(pad.uitlegKey)}
          </TvzText>
        </LinearGradient>
        <Image source={FOTOS[pad.id]} style={styles.kaartFoto} resizeMode="cover" />
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: colors.bg,
  },
  inhoud: {
    padding: spacing.screen,
    gap: spacing.md,
  },
  kop: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
    marginBottom: spacing.xs,
  },
  kopTekst: {
    flex: 1,
  },
  kopSub: {
    marginTop: spacing.xs,
  },
  kaart: {
    flexDirection: 'row',
    borderRadius: radius.card,
    overflow: 'hidden',
    minHeight: 150,
  },
  kaartTekstVlak: {
    flex: 1.45,
    padding: spacing.cardPadding,
    gap: spacing.sm,
    justifyContent: 'center',
  },
  kaartFoto: {
    flex: 1,
    height: '100%',
  },
  kaartKop: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
  },
  kaartIcoon: {
    width: 34,
    height: 34,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: 'rgba(255,255,255,0.22)',
  },
  kaartTitel: {
    color: colors.white,
    fontSize: 18,
    flex: 1,
  },
  kaartUitleg: {
    color: 'rgba(255,255,255,0.92)',
  },
  gegevens: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing.sm,
    minHeight: 52,
    borderRadius: radius.pill,
    backgroundColor: colors.white,
    borderWidth: 1,
    borderColor: colors.line,
  },
  gegevensTekst: {
    color: colors.inkSoft,
  },
});

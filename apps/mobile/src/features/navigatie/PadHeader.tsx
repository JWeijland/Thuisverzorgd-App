import { LinearGradient } from 'expo-linear-gradient';
import { router, usePathname } from 'expo-router';
import { ArrowLeft } from 'lucide-react-native';
import type { ReactNode } from 'react';
import { Pressable, StyleSheet, useWindowDimensions, View } from 'react-native';
import Svg, { Path } from 'react-native-svg';
import { SafeAreaView } from 'react-native-safe-area-context';

import { ProfileAvatar } from '@/features/avatars/ProfileAvatar';
import {
  actiefSchuifje,
  PADEN,
  heeftPadKeuze,
  schuifjesVoor,
  thuisRoute,
  toontKruimelspoor,
  type PadId,
} from '@/features/navigatie/paden';
import { useSchuifRichting } from '@/features/navigatie/PadPagina';
import { useProfile } from '@/features/onboarding/useAuth';
import { useWalkthrough } from '@/features/onboarding/walkthrough';
import { t } from '@/i18n';
import { haptics } from '@/lib/haptics';
import { useStatusBalk } from '@/lib/statusbalk';
import { colors, hitTarget, radius, spacing } from '@/theme';
import { Bo, BoPeek, type BoRol } from '@/ui/Bo';
import { TvzText } from '@/ui/TvzText';

type Props = {
  pad: PadId;
  /**
   * Extra kruimels achter het actieve schuifje, bijv. de naam van de dienst
   * die je bekijkt. Het eerste bolletje vult de header zelf.
   */
  kruimels?: string[];
  /**
   * Forceer welk schuifje gevuld is. Nodig op de losse detailpagina's die
   * buiten de padmappen staan (bijv. `/dienst/kapper` onder Voorzieningen).
   */
  actiefRoute?: string;
  /** Verberg de schuifjes: je zit in een flow, niet in navigatie (bijv. taak inplannen). */
  verbergSchuifjes?: boolean;
  /** Toon de terugpijl; standaard aan zodra er een extra kruimel is. */
  terug?: boolean;
  /** Extra inhoud onder de schuifjes, binnen de gekleurde balk. */
  children?: ReactNode;
};

/**
 * De vaste header van een pad (handoff-voorzieningen, HERSTRUCTURERING §1).
 * Drie rijen:
 *   1. terugpijl (alleen dieper dan niveau 1) · Bo-knop · titel + subtitel · avatar
 *   2. kruimelspoor met bolletjes
 *   3. schuifjes van dit pad
 *
 * De Bo-knop brengt je altijd terug naar het keuzescherm met de twee paden;
 * dat is de enige vaste weg terug nu de tabbalk weg is.
 */
export function PadHeader({
  pad,
  kruimels = [],
  actiefRoute,
  verbergSchuifjes,
  terug,
  children,
}: Props) {
  const padConfig = PADEN[pad];
  const pathname = usePathname();
  const profile = useProfile();
  const actief = actiefSchuifje(padConfig, actiefRoute ?? pathname);
  const meetSchuifje = useWalkthrough((state) => state.meetSchuifje);
  const meetHeader = useWalkthrough((state) => state.meetHeader);
  const zetRichting = useSchuifRichting((state) => state.zetRichting);
  const meldActief = useSchuifRichting((state) => state.meldActief);
  useStatusBalk('licht');

  const spoor = [actief ? t(actief.labelKey) : t(padConfig.titelKey), ...kruimels];
  // De pijl gaat naar de vorige pagina. Alleen als er echt niets achter je
  // ligt valt hij terug op het keuzescherm, zodat je nooit vastzit.
  const kanTerug = router.canGoBack();
  const toonTerug = terug ?? true;
  const naam = profile.data?.name ?? '';
  const schuifjes = schuifjesVoor(padConfig, profile.data?.role);
  const { width: breedte } = useWindowDimensions();
  const toonSpoor = toontKruimelspoor(profile.data?.role);

  return (
    <LinearGradient
      colors={padConfig.gradient}
      start={{ x: 0, y: 0 }}
      end={{ x: 1, y: 1 }}
      style={styles.balk}
      onLayout={(event) => meetHeader(event.nativeEvent.layout.height)}
    >
      {/* Bo zit zacht in de achtergrond, zodat de balk niet één vlak groen
          is (wens Jelle 11-08). Hij is bewust laag in contrast: het gaat om
          de tekst erboven, niet om Bo. */}
      <View pointerEvents="none" style={styles.boAchtergrond}>
        <Bo width={150} rol={boRolVoor(pad)} />
      </View>

      <SafeAreaView edges={['top']}>
        <View style={styles.rij1}>
          {toonTerug ? (
            <Pressable
              accessibilityRole="button"
              accessibilityLabel={t('algemeen.terug')}
              onPress={() => {
                void haptics.tik();
                if (kanTerug) router.back();
                else router.replace(thuisRoute(profile.data?.role) as never);
              }}
              style={styles.rond}
            >
              <ArrowLeft color={colors.white} size={20} strokeWidth={2.4} />
            </Pressable>
          ) : null}

          {/* De Bo-knop leidt naar het keuzescherm met de twee paden. De
              vrijwilliger heeft dat scherm niet: die verleent hulp en hoort
              daar nooit te komen (feedback Jelle 11-08). */}
          {heeftPadKeuze(profile.data?.role) ? (
            <Pressable
              accessibilityRole="button"
              accessibilityLabel={t('paden.naarKeuze')}
              onPress={() => {
                void haptics.selectie();
                router.replace('/pad');
              }}
              style={styles.boKnop}
            >
              <BoPeek width={40} />
            </Pressable>
          ) : null}

          <View style={styles.tekst}>
            <TvzText preset="cardTitle" numberOfLines={1} style={styles.titel}>
              {t(padConfig.titelKey)}
            </TvzText>
            <TvzText preset="secondary" numberOfLines={1} style={styles.sub}>
              {t(padConfig.subtitelKey)}
            </TvzText>
          </View>

          <Pressable
            accessibilityRole="button"
            accessibilityLabel={t('paden.naarProfiel')}
            onPress={() => router.push('/profiel')}
          >
            <ProfileAvatar
              name={naam}
              avatarPath={profile.data?.avatar_path}
              size={34}
              backgroundColor="rgba(255,255,255,0.25)"
            />
          </Pressable>
        </View>

        <View style={toonSpoor ? styles.spoor : styles.spoorUit}>
          {(toonSpoor ? spoor : []).map((kruimel, i) => (
            <View key={`${kruimel}-${i}`} style={styles.kruimel}>
              {i > 0 ? <View style={styles.streepje} /> : null}
              <View style={[styles.bolletje, i === spoor.length - 1 && styles.bolletjeActief]} />
              <TvzText
                preset="meta"
                numberOfLines={1}
                style={[styles.kruimelTekst, i === spoor.length - 1 && styles.kruimelActief]}
              >
                {kruimel}
              </TvzText>
            </View>
          ))}
        </View>

        {verbergSchuifjes ? null : (
          // Eén balk met even brede vakjes in plaats van losse pillen: het
          // actieve vakje schuift van links naar rechts mee (wens Jelle 11-08).
          <View style={[styles.schuifbalk, { backgroundColor: padConfig.schuifjeVlak }]}>
            {schuifjes.map((schuifje, i) => {
              const isActief = schuifje.route === actief?.route;
              return (
                <Pressable
                  key={schuifje.route}
                  onLayout={(event) => {
                    // x is relatief aan de balk; de balk begint op de
                    // schermpadding van de header.
                    const { x, width } = event.nativeEvent.layout;
                    meetSchuifje(schuifje.route, spacing.screen + x + width / 2);
                    if (isActief) meldActief(i);
                  }}
                  accessibilityRole="tab"
                  accessibilityState={{ selected: isActief }}
                  accessibilityLabel={t(schuifje.labelKey)}
                  onPress={() => {
                    if (isActief) return;
                    void haptics.selectie();
                    zetRichting(i);
                    // replace en niet navigate: de schuifjes zijn geen
                    // geschiedenis. Zo blijft de terugpijl kort (hij eindigt
                    // op het keuzescherm) en is onze eigen overgang de enige
                    // beweging op het scherm.
                    router.replace(schuifje.route as never);
                  }}
                  style={[styles.schuifje, isActief && styles.schuifjeActief]}
                >
                  <TvzText
                    preset="meta"
                    numberOfLines={1}
                    style={[
                      styles.schuifjeTekst,
                      { color: isActief ? padConfig.schuifjeActiefTekst : colors.white },
                    ]}
                  >
                    {t(schuifje.labelKey)}
                  </TvzText>
                </Pressable>
              );
            })}
          </View>
        )}

        {children}
      </SafeAreaView>

      {/* Kleine golf onderaan: dezelfde getekende rand als in het brandbook,
          zodat de balk geen hard vierkant blok is. */}
      <Svg
        width={breedte}
        height={GOLF}
        viewBox={`0 0 ${breedte} ${GOLF}`}
        style={styles.golf}
        pointerEvents="none"
      >
        <Path
          d={`M0 ${GOLF * 0.55} C ${breedte * 0.2} -2, ${breedte * 0.35} ${GOLF}, ${breedte * 0.55} ${GOLF * 0.5} C ${breedte * 0.75} 0, ${breedte * 0.9} ${GOLF * 0.9} ${breedte} ${GOLF * 0.35} L ${breedte} ${GOLF} L 0 ${GOLF} Z`}
          fill={colors.bg}
        />
      </Svg>
    </LinearGradient>
  );
}

/** Hoogte van de golvende onderrand. */
const GOLF = 16;

/** Bo kleurt mee met het pad, zoals overal in de app. */
function boRolVoor(pad: PadId): BoRol {
  if (pad === 'vrijwilliger') return 'vrijwilliger';
  if (pad === 'weten' || pad === 'aanbieder') return 'beheerder';
  return 'vrijwilliger';
}

const styles = StyleSheet.create({
  balk: {
    paddingHorizontal: spacing.screen,
    paddingBottom: spacing.md + GOLF,
    overflow: 'hidden',
  },
  boAchtergrond: {
    position: 'absolute',
    right: -34,
    bottom: -46,
    opacity: 0.14,
  },
  golf: {
    position: 'absolute',
    left: 0,
    right: 0,
    bottom: -1,
  },
  rij1: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    marginTop: spacing.xs,
    minHeight: hitTarget.min,
  },
  rond: {
    width: 34,
    height: 34,
    borderRadius: 17,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: 'rgba(255,255,255,0.2)',
  },
  boKnop: {
    width: 38,
    height: 38,
    borderRadius: 19,
    alignItems: 'center',
    justifyContent: 'flex-end',
    overflow: 'hidden',
    backgroundColor: colors.white,
  },
  tekst: {
    flex: 1,
  },
  titel: {
    color: colors.white,
  },
  sub: {
    color: 'rgba(255,255,255,0.82)',
  },
  spoor: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: spacing.sm,
  },
  spoorUit: {
    height: spacing.xs,
  },
  kruimel: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    flexShrink: 1,
  },
  streepje: {
    width: 12,
    height: 1,
    marginHorizontal: 4,
    backgroundColor: 'rgba(255,255,255,0.45)',
  },
  bolletje: {
    width: 6,
    height: 6,
    borderRadius: 3,
    backgroundColor: 'rgba(255,255,255,0.5)',
  },
  bolletjeActief: {
    backgroundColor: colors.white,
  },
  kruimelTekst: {
    color: 'rgba(255,255,255,0.7)',
    flexShrink: 1,
  },
  kruimelActief: {
    color: colors.white,
  },
  schuifbalk: {
    flexDirection: 'row',
    gap: 3,
    marginTop: spacing.md,
    padding: 3,
    borderRadius: radius.card,
  },
  schuifje: {
    flex: 1,
    minHeight: 38,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 6,
    borderRadius: radius.row,
  },
  schuifjeActief: {
    backgroundColor: colors.white,
  },
  schuifjeTekst: {
    fontSize: 13,
  },
});

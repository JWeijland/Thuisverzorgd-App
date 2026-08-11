import { LinearGradient } from 'expo-linear-gradient';
import { router, usePathname } from 'expo-router';
import { ArrowLeft } from 'lucide-react-native';
import type { ReactNode } from 'react';
import { Pressable, ScrollView, StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { ProfileAvatar } from '@/features/avatars/ProfileAvatar';
import {
  actiefSchuifje,
  PADEN,
  schuifjesVoor,
  toontKruimelspoor,
  type PadId,
} from '@/features/navigatie/paden';
import { useProfile } from '@/features/onboarding/useAuth';
import { useWalkthrough } from '@/features/onboarding/walkthrough';
import { t } from '@/i18n';
import { haptics } from '@/lib/haptics';
import { useStatusBalk } from '@/lib/statusbalk';
import { colors, hitTarget, radius, spacing } from '@/theme';
import { BoPeek } from '@/ui/Bo';
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
  useStatusBalk('licht');

  const spoor = [actief ? t(actief.labelKey) : t(padConfig.titelKey), ...kruimels];
  const toonTerug = terug ?? kruimels.length > 0;
  const naam = profile.data?.name ?? '';
  const schuifjes = schuifjesVoor(padConfig, profile.data?.role);
  const toonSpoor = toontKruimelspoor(profile.data?.role);

  return (
    <LinearGradient
      colors={padConfig.gradient}
      start={{ x: 0, y: 0 }}
      end={{ x: 1, y: 1 }}
      style={styles.balk}
      onLayout={(event) => meetHeader(event.nativeEvent.layout.height)}
    >
      <SafeAreaView edges={['top']}>
        <View style={styles.rij1}>
          {toonTerug ? (
            <Pressable
              accessibilityRole="button"
              accessibilityLabel={t('algemeen.terug')}
              onPress={() => {
                void haptics.tik();
                router.back();
              }}
              style={styles.rond}
            >
              <ArrowLeft color={colors.white} size={20} strokeWidth={2.4} />
            </Pressable>
          ) : null}

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
          <ScrollView
            horizontal
            showsHorizontalScrollIndicator={false}
            contentContainerStyle={styles.schuifjes}
          >
            {schuifjes.map((schuifje) => {
              const isActief = schuifje.route === actief?.route;
              return (
                <Pressable
                  key={schuifje.route}
                  onLayout={(event) => {
                    // x is relatief aan de rij; de rij zelf begint op de
                    // schermpadding van de balk.
                    const { x, width } = event.nativeEvent.layout;
                    meetSchuifje(schuifje.route, spacing.screen + x + width / 2);
                  }}
                  accessibilityRole="tab"
                  accessibilityState={{ selected: isActief }}
                  accessibilityLabel={t(schuifje.labelKey)}
                  onPress={() => {
                    if (isActief) return;
                    void haptics.selectie();
                    router.replace(schuifje.route as never);
                  }}
                  style={[
                    styles.schuifje,
                    { backgroundColor: isActief ? colors.white : padConfig.schuifjeVlak },
                  ]}
                >
                  <TvzText
                    preset="meta"
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
          </ScrollView>
        )}

        {children}
      </SafeAreaView>
    </LinearGradient>
  );
}

const styles = StyleSheet.create({
  balk: {
    paddingHorizontal: spacing.screen,
    paddingBottom: spacing.md,
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
  schuifjes: {
    gap: spacing.chipGap,
    paddingTop: spacing.md,
    paddingRight: spacing.screen,
  },
  schuifje: {
    borderRadius: radius.pill,
    paddingHorizontal: 16,
    paddingVertical: 8,
    minHeight: 34,
    justifyContent: 'center',
  },
  schuifjeTekst: {
    fontSize: 13,
  },
});

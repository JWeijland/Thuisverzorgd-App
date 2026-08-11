import { router, usePathname } from 'expo-router';
import { Pressable, StyleSheet, View } from 'react-native';

import { actiefSchuifje, PADEN, type PadId } from '@/features/navigatie/paden';
import { ProfileAvatar } from '@/features/avatars/ProfileAvatar';
import { useProfile } from '@/features/onboarding/useAuth';
import { useWalkthrough } from '@/features/onboarding/walkthrough';
import { t } from '@/i18n';
import { haptics } from '@/lib/haptics';
import { colors, radius, shadows, spacing } from '@/theme';
import { TvzText } from '@/ui/TvzText';

type Props = {
  pad: PadId;
  /** Forceer welk schuifje gevuld is (voor pagina's buiten de padmap). */
  actiefRoute?: string;
};

/**
 * Dezelfde schuifbalk als in de padheader, maar zwevend over de kaart en op
 * wit (handoff, scherm 08). Eén balk met even brede vakjes, niet drie losse
 * pillen (feedback Jelle 11-08): de kaart loopt door tot bovenaan het
 * scherm, de navigatie zweeft eroverheen.
 */
export function ZwevendeSchuifjes({ pad, actiefRoute }: Props) {
  const padConfig = PADEN[pad];
  const pathname = usePathname();
  const actief = actiefSchuifje(padConfig, actiefRoute ?? pathname);
  const meetSchuifje = useWalkthrough((state) => state.meetSchuifje);
  const meetHeader = useWalkthrough((state) => state.meetHeader);
  const profile = useProfile();

  return (
    // De rondleiding wijst ook hier naar het juiste vakje: dit scherm heeft
    // geen gekleurde balk, dus meet het zelf op waar de balk staat.
    <View
      style={styles.wrap}
      onLayout={(event) => meetHeader(event.nativeEvent.layout.y + event.nativeEvent.layout.height)}
    >
      <View style={[styles.balk, shadows.floating]}>
        {padConfig.schuifjes.map((schuifje) => {
          const isActief = schuifje.route === actief?.route;
          return (
            <Pressable
              key={schuifje.route}
              onLayout={(event) => {
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
              style={[styles.vak, isActief && styles.vakActief]}
            >
              <TvzText
                preset="meta"
                numberOfLines={1}
                style={isActief ? styles.tekstActief : styles.tekst}
              >
                {t(schuifje.labelKey)}
              </TvzText>
            </Pressable>
          );
        })}
      </View>

      {/* Je eigen profiel staat op elke pagina rechtsboven; op de kaart
          hoort hij daar dus ook (feedback Jelle 11-08). */}
      <Pressable
        accessibilityRole="button"
        accessibilityLabel={t('paden.naarProfiel')}
        onPress={() => router.push('/profiel')}
        style={[styles.profiel, shadows.floating]}
      >
        <ProfileAvatar
          name={profile.data?.name ?? ''}
          avatarPath={profile.data?.avatar_path}
          size={38}
        />
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
    paddingHorizontal: spacing.screen,
  },
  profiel: {
    borderRadius: 22,
    borderWidth: 2,
    borderColor: colors.white,
  },
  balk: {
    flex: 1,
    flexDirection: 'row',
    gap: 3,
    padding: 3,
    borderRadius: radius.card,
    backgroundColor: colors.white,
  },
  vak: {
    flex: 1,
    minHeight: 38,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 6,
    borderRadius: radius.row,
  },
  vakActief: {
    backgroundColor: colors.primary,
  },
  tekst: {
    color: colors.inkSoft,
    fontSize: 13,
  },
  tekstActief: {
    color: colors.white,
    fontSize: 13,
  },
});

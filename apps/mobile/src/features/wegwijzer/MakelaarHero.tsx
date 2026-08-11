import { LinearGradient } from 'expo-linear-gradient';
import { router } from 'expo-router';
import { StyleSheet, View } from 'react-native';

import { ProfileAvatar } from '@/features/avatars/ProfileAvatar';
import { useBrokerPresenceIds, useMakelaars } from '@/features/forum/api';
import { t } from '@/i18n';
import { colors, gradient, radius, spacing } from '@/theme';
import { Button, TvzText } from '@/ui';

/**
 * Hulpmakelaar-blok bovenaan de wegwijzer (handoff, scherm 02): "Kom je er
 * even niet uit?", de gezichten van de makelaars die nu online zijn, en twee
 * knoppen: chatten of videobellen.
 */
export function MakelaarHero() {
  const makelaars = useMakelaars();
  const onlineIds = useBrokerPresenceIds();

  const lijst = makelaars.data ?? [];
  const online = lijst.filter((makelaar) => onlineIds.includes(makelaar.id));
  const gezichten = (online.length > 0 ? online : lijst).slice(0, 3);

  return (
    <LinearGradient {...gradient} style={styles.kaart}>
      <View style={styles.rij}>
        <View style={styles.gezichten}>
          {gezichten.map((makelaar, i) => (
            <View key={makelaar.id} style={[styles.gezicht, i > 0 && styles.gezichtOverlap]}>
              <ProfileAvatar
                name={makelaar.voornaam}
                avatarPath={makelaar.avatar_path}
                size={30}
                backgroundColor={colors.primaryMid}
              />
            </View>
          ))}
        </View>
        <View style={styles.tekst}>
          <TvzText preset="cardTitle" style={styles.titel}>
            {t('wegwijzerPad.heroTitel')}
          </TvzText>
          <TvzText preset="meta" style={styles.sub}>
            {online.length === 1
              ? t('wegwijzerPad.heroOnline1')
              : t('wegwijzerPad.heroOnline', { aantal: online.length })}
          </TvzText>
        </View>
      </View>

      <View style={styles.knoppen}>
        <Button
          label={t('wegwijzerPad.chatNu')}
          variant="cta"
          style={styles.knop}
          onPress={() => router.push('/weten/zorgmakelaars')}
        />
        {/* Videobellen zelf (Daily.co) staat nog open, zie docs/PLAN.md. Tot
            die tijd zet deze knop de vraag om terug te bellen in de chat, in
            plaats van een knop die niets doet. */}
        <Button
          label={t('wegwijzerPad.videobel')}
          variant="outline"
          style={[styles.knop, styles.knopLicht]}
          onPress={() =>
            router.push({
              pathname: '/weten/zorgmakelaars',
              params: { vraag: t('wegwijzerPad.videobelVraag') },
            })
          }
        />
      </View>
    </LinearGradient>
  );
}

const styles = StyleSheet.create({
  kaart: {
    borderRadius: radius.card,
    padding: spacing.cardPadding,
    gap: spacing.lg,
  },
  rij: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
  },
  gezichten: {
    flexDirection: 'row',
  },
  gezicht: {
    borderRadius: 17,
    borderWidth: 2,
    borderColor: 'rgba(255,255,255,0.55)',
  },
  gezichtOverlap: {
    marginLeft: -12,
  },
  tekst: {
    flex: 1,
  },
  titel: {
    color: colors.white,
  },
  sub: {
    color: 'rgba(255,255,255,0.8)',
  },
  knoppen: {
    flexDirection: 'row',
    gap: spacing.md,
  },
  knop: {
    flex: 1,
  },
  knopLicht: {
    borderColor: 'rgba(255,255,255,0.7)',
    backgroundColor: 'rgba(255,255,255,0.12)',
  },
});

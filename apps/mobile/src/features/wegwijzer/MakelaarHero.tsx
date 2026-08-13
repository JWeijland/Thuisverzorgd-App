import { LinearGradient } from 'expo-linear-gradient';
import { router } from 'expo-router';
import { Pressable, StyleSheet, View } from 'react-native';

import { ProfileAvatar } from '@/features/avatars/ProfileAvatar';
import { useBrokerPresenceIds, useMakelaars, type Makelaar } from '@/features/forum/api';
import { t } from '@/i18n';
import { colors, gradient, radius, spacing } from '@/theme';
import { Button, TvzText } from '@/ui';

/**
 * Hulpmakelaar-blok bovenaan de wegwijzer (handoff, scherm 02): "Kom je er
 * even niet uit?", de gezichten van de makelaars die nu online zijn, en twee
 * knoppen: chatten of videobellen.
 *
 * De drie gezichten staan groot naast elkaar met hun naam eronder, in plaats
 * van klein en over elkaar heen (wens Jelle 13-08): je praat straks met een
 * mens, dus die mag je eerst zien.
 */
export function MakelaarHero() {
  const makelaars = useMakelaars();
  const onlineIds = useBrokerPresenceIds();

  const lijst = makelaars.data ?? [];
  const online = lijst.filter((makelaar) => onlineIds.includes(makelaar.id));
  // Wie online is staat vooraan; daarna vullen we aan tot drie gezichten.
  const gezichten = [...online, ...lijst.filter((makelaar) => !online.includes(makelaar))].slice(
    0,
    3,
  );

  return (
    <LinearGradient {...gradient} style={styles.kaart}>
      <TvzText preset="cardTitle" style={styles.titel}>
        {t('wegwijzerPad.heroTitel')}
      </TvzText>

      {gezichten.length > 0 ? (
        <View style={styles.gezichten}>
          {gezichten.map((makelaar) => (
            <Gezicht
              key={makelaar.id}
              makelaar={makelaar}
              online={onlineIds.includes(makelaar.id)}
            />
          ))}
        </View>
      ) : null}

      <TvzText preset="meta" style={styles.sub}>
        {online.length === 0
          ? t('wegwijzerPad.heroNiemandOnline')
          : online.length === 1
            ? t('wegwijzerPad.heroOnline1')
            : t('wegwijzerPad.heroOnline', { aantal: online.length })}
      </TvzText>

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

/** Eén makelaar: grote foto, naam eronder, groen stipje als hij nu online is. */
function Gezicht({ makelaar, online }: { makelaar: Makelaar; online: boolean }) {
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={makelaar.voornaam}
      onPress={() =>
        router.push({ pathname: '/weten/zorgmakelaars', params: { makelaar: makelaar.id } })
      }
      style={styles.gezicht}
    >
      <View style={styles.fotoRing}>
        <ProfileAvatar
          name={makelaar.voornaam}
          avatarPath={makelaar.avatar_path}
          size={64}
          backgroundColor={colors.primaryMid}
        />
        {online ? <View style={styles.stip} /> : null}
      </View>
      <TvzText preset="meta" numberOfLines={1} style={styles.naam}>
        {makelaar.voornaam}
      </TvzText>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  kaart: {
    borderRadius: radius.card,
    padding: spacing.cardPadding,
    gap: spacing.md,
  },
  titel: {
    color: colors.white,
    fontSize: 18,
    textAlign: 'center',
  },
  gezichten: {
    flexDirection: 'row',
    justifyContent: 'center',
    gap: spacing.xl,
    marginTop: spacing.xs,
  },
  gezicht: {
    alignItems: 'center',
    gap: 6,
  },
  fotoRing: {
    borderRadius: 36,
    borderWidth: 2,
    borderColor: 'rgba(255,255,255,0.55)',
    padding: 2,
  },
  stip: {
    position: 'absolute',
    right: 2,
    bottom: 2,
    width: 14,
    height: 14,
    borderRadius: 7,
    backgroundColor: colors.accent,
    borderWidth: 2,
    borderColor: colors.primaryDark,
  },
  naam: {
    color: colors.white,
    maxWidth: 84,
    textAlign: 'center',
  },
  sub: {
    color: 'rgba(255,255,255,0.8)',
    textAlign: 'center',
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

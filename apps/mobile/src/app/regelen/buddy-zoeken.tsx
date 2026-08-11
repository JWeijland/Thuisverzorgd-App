import { router } from 'expo-router';
import { ChevronRight, Map } from 'lucide-react-native';
import { useState } from 'react';
import { Pressable, ScrollView, StyleSheet, View } from 'react-native';

import { ProfileAvatar } from '@/features/avatars/ProfileAvatar';
import { useBestMatches, useInvite, useMyCircle } from '@/features/circles/api';
import { PadHeader } from '@/features/navigatie/PadHeader';
import { t } from '@/i18n';
import { haptics } from '@/lib/haptics';
import { colors, radius, spacing } from '@/theme';
import { Bo, Button, Card, EmptyState, TvzBounce, TvzText } from '@/ui';

/**
 * Bo zoekt een buddy in de buurt (handoff §3b, het kleine knopje op de
 * kringpagina). Dit is nadrukkelijk géén directe hulpvraag: hier stelt Bo
 * onbekende buddy's uit de buurt aan je voor, die je kunt uitnodigen voor je
 * kring. Wie je al kent nodig je uit via "Buddy uitnodigen".
 */
export default function BuddyZoeken() {
  const circle = useMyCircle();
  const matches = useBestMatches(circle.data?.id);
  const invite = useInvite(circle.data?.id);
  const [gevraagd, setGevraagd] = useState<string[]>([]);
  const [fout, setFout] = useState<string | null>(null);

  const lijst = matches.data ?? [];

  function nodigUit(id: string) {
    setFout(null);
    void haptics.stevig();
    invite.mutate(
      { target: id },
      {
        onSuccess: () => setGevraagd((vorige) => [...vorige, id]),
        onError: () => setFout(`${t('algemeen.foutTitel')}. ${t('algemeen.foutOpnieuw')}.`),
      },
    );
  }

  return (
    <View style={styles.safe}>
      <PadHeader
        pad="regelen"
        actiefRoute="/regelen/kring"
        kruimels={[t('buddyZoeken.kruimel')]}
      />

      <ScrollView contentContainerStyle={styles.inhoud}>
        {/* De kaart is de leukste manier om te kijken wie er in de buurt
            woont, dus die staat bovenaan als een groot vierkant vlak in
            plaats van een smal knopje onderaan (wens Jelle 11-08). */}
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={t('buddyZoeken.opDeKaart')}
          onPress={() => {
            void haptics.tik();
            router.push('/buurt');
          }}
          style={styles.kaartKnop}
        >
          <View style={styles.kaartIcoon}>
            <Map color={colors.primary} size={24} strokeWidth={2.2} />
          </View>
          <View style={styles.kaartTekst}>
            <TvzText preset="cardTitle">{t('buddyZoeken.opDeKaart')}</TvzText>
            <TvzText preset="secondary">{t('buddyZoeken.opDeKaartUitleg')}</TvzText>
          </View>
          <ChevronRight color={colors.inkFaint} size={22} strokeWidth={2.2} />
        </Pressable>

        <View style={styles.tip}>
          <TvzBounce>
            <Bo width={62} />
          </TvzBounce>
          <TvzText preset="body" style={styles.tipTekst}>
            {lijst.length === 0
              ? t('buddyZoeken.tipLeeg')
              : lijst.length === 1
                ? t('buddyZoeken.tip1')
                : t('buddyZoeken.tip', { aantal: lijst.length })}
          </TvzText>
        </View>

        {fout ? (
          <TvzText preset="secondary" style={styles.fout}>
            {fout}
          </TvzText>
        ) : null}

        {lijst.map((match) => {
          const isGevraagd = gevraagd.includes(match.id);
          return (
            <Card key={match.id} style={styles.kaart}>
              {/* Tik op de naam om zijn profiel te lezen voordat je hem bij
                  iemand thuis uitnodigt (wens Jelle 11-08). */}
              <Pressable
                accessibilityRole="button"
                accessibilityLabel={`${match.voornaam}, ${t('buddyZoeken.bekijkProfiel')}`}
                onPress={() => router.push(`/regelen/buddy/${match.id}`)}
                style={styles.rij}
              >
                <ProfileAvatar name={match.voornaam} avatarPath={match.avatar_path} size={48} />
                <View style={styles.tekst}>
                  <TvzText preset="cardTitle">
                    {match.voornaam}
                    {match.city ? ` · ${match.city}` : ''}
                  </TvzText>
                  <TvzText preset="secondary">
                    {t('uitnodigen.matchMeta', {
                      kringen: match.kringen,
                      taken: match.helped_count,
                    })}
                    {match.waardering ? ` · ★ ${match.waardering}` : ''}
                  </TvzText>
                  <TvzText preset="meta" style={styles.profielLink}>
                    {t('buddyZoeken.bekijkProfiel')}
                  </TvzText>
                </View>
                <ChevronRight color={colors.inkFaint} size={20} strokeWidth={2.2} />
              </Pressable>
              <Button
                label={isGevraagd ? t('buddyZoeken.gevraagd') : t('buddyZoeken.vraagBuddy')}
                variant={isGevraagd ? 'outline' : 'cta'}
                disabled={isGevraagd || invite.isPending}
                onPress={() => nodigUit(match.id)}
              />
            </Card>
          );
        })}

        {!matches.isLoading && lijst.length === 0 ? (
          <Card>
            <EmptyState title={t('buddyZoeken.leegTitel')} body={t('buddyZoeken.leegTekst')} />
          </Card>
        ) : null}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: colors.bg,
  },
  inhoud: {
    padding: spacing.screen,
    gap: spacing.cardGap,
    paddingBottom: spacing.xxl,
  },
  kaartKnop: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
    backgroundColor: colors.white,
    borderRadius: radius.tile,
    padding: spacing.cardPadding,
  },
  kaartIcoon: {
    width: 48,
    height: 48,
    borderRadius: radius.card,
    backgroundColor: colors.tintBlue,
    alignItems: 'center',
    justifyContent: 'center',
  },
  kaartTekst: {
    flex: 1,
  },
  profielLink: {
    color: colors.primaryMid,
    marginTop: 2,
  },
  tip: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
    marginBottom: spacing.xs,
  },
  tipTekst: {
    flex: 1,
  },
  fout: {
    color: colors.error,
  },
  kaart: {
    gap: spacing.md,
  },
  rij: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
  },
  tekst: {
    flex: 1,
  },
});

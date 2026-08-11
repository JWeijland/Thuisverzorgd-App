import { router } from 'expo-router';
import { useState } from 'react';
import { ScrollView, StyleSheet, View } from 'react-native';

import { ProfileAvatar } from '@/features/avatars/ProfileAvatar';
import { useBestMatches, useInvite, useMyCircle } from '@/features/circles/api';
import { PadHeader } from '@/features/navigatie/PadHeader';
import { t } from '@/i18n';
import { haptics } from '@/lib/haptics';
import { colors, spacing } from '@/theme';
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
              <View style={styles.rij}>
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
                </View>
              </View>
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

        <Button
          label={t('buddyZoeken.opDeKaart')}
          variant="outline"
          onPress={() => router.push('/buurt')}
        />
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

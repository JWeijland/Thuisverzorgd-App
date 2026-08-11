import { useLocalSearchParams } from 'expo-router';
import { BadgeCheck, CalendarDays, Star } from 'lucide-react-native';
import { ScrollView, StyleSheet, View } from 'react-native';

import { ProfileAvatar } from '@/features/avatars/ProfileAvatar';
import { useBuddyProfiel, useInvite, useMyCircle } from '@/features/circles/api';
import { PadHeader } from '@/features/navigatie/PadHeader';
import { t } from '@/i18n';
import { WEEKDAY_SHORT } from '@/lib/dates';
import { haptics } from '@/lib/haptics';
import { colors, radius, spacing } from '@/theme';
import { Button, Card, TvzText } from '@/ui';

/** Dagcodes zoals ze in het profiel staan, in dezelfde volgorde als de week. */
const DAGCODES = ['ma', 'di', 'wo', 'do', 'vr', 'za', 'zo'] as const;

/**
 * Het profiel van een buddy die je nog niet kent (wens Jelle 11-08). Je nodigt
 * iemand uit bij een kwetsbaar mens thuis, dus je wilt eerst kunnen kijken:
 * wat schrijft hij zelf, hoe waarderen anderen hem, hoeveel heeft hij al
 * gedaan. Alles wat hier staat is openbaar op zijn kaartje; adres en telefoon
 * blijven achter tot hij de uitnodiging aanneemt.
 */
export default function BuddyProfielScherm() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const profiel = useBuddyProfiel(id);
  const kring = useMyCircle();
  const invite = useInvite(kring.data?.id);

  const buddy = profiel.data;
  const naam = buddy?.voornaam ?? '';

  return (
    <View style={styles.safe}>
      <PadHeader
        pad="regelen"
        actiefRoute="/regelen/kring"
        kruimels={[t('buddyZoeken.kruimel'), naam || t('buddyProfiel.kruimel')]}
      />

      <ScrollView contentContainerStyle={styles.inhoud}>
        {!buddy ? (
          <Card>
            <TvzText preset="secondary">
              {profiel.isLoading ? t('algemeen.laden') : t('buddyProfiel.nietGevonden')}
            </TvzText>
          </Card>
        ) : (
          <>
            <Card style={styles.kop}>
              <ProfileAvatar name={naam} avatarPath={buddy.avatar_path} size={84} />
              <TvzText preset="screenTitle" style={styles.naam}>
                {naam}
              </TvzText>
              {buddy.city ? <TvzText preset="secondary">{buddy.city}</TvzText> : null}
              {buddy.id_verified ? (
                <View style={styles.gecontroleerd}>
                  <BadgeCheck color={colors.successText} size={15} strokeWidth={2.4} />
                  <TvzText preset="meta" style={styles.gecontroleerdTekst}>
                    {t('buddyProfiel.gecontroleerd')}
                  </TvzText>
                </View>
              ) : null}
            </Card>

            {/* Drie cijfers naast elkaar: wat hij deed, waar hij helpt en hoe
                anderen hem waarderen. */}
            <View style={styles.cijfers}>
              <Cijfer
                waarde={String(buddy.helped_count)}
                label={
                  buddy.helped_count === 1
                    ? t('buddyProfiel.taakLabel')
                    : t('buddyProfiel.takenLabel')
                }
              />
              <Cijfer
                waarde={String(buddy.kringen)}
                label={
                  buddy.kringen === 1
                    ? t('buddyProfiel.kringLabel')
                    : t('buddyProfiel.kringenLabel')
                }
              />
              <Cijfer
                waarde={
                  buddy.waardering != null
                    ? String(buddy.waardering).replace('.', ',')
                    : t('buddyProfiel.geenWaardering')
                }
                label={t('buddyProfiel.waarderingLabel')}
                ster={buddy.waardering != null}
              />
            </View>
            <TvzText preset="meta" style={styles.beoordelingen}>
              {buddy.beoordelingen > 0
                ? t('buddyProfiel.beoordelingen', { aantal: buddy.beoordelingen })
                : t('buddyProfiel.geenBeoordelingen')}
            </TvzText>

            <Card>
              <TvzText preset="sectionTitle">{t('buddyProfiel.titel', { naam })}</TvzText>
              <TvzText preset="body" style={styles.bio}>
                {buddy.bio?.trim() || t('buddyProfiel.geenTekst', { naam })}
              </TvzText>
            </Card>

            {buddy.availability.length > 0 ? (
              <Card>
                <View style={styles.dagenKop}>
                  <CalendarDays color={colors.primaryMid} size={18} strokeWidth={2.2} />
                  <TvzText preset="cardTitle">{t('buddyProfiel.beschikbaar')}</TvzText>
                </View>
                <View style={styles.dagen}>
                  {DAGCODES.map((code, index) => {
                    const aan = buddy.availability.includes(code);
                    return (
                      <View key={code} style={[styles.dag, aan && styles.dagAan]}>
                        <TvzText preset="meta" style={aan ? styles.dagTekstAan : styles.dagTekst}>
                          {WEEKDAY_SHORT[index]}
                        </TvzText>
                      </View>
                    );
                  })}
                </View>
              </Card>
            ) : null}

            {kring.data ? (
              <Button
                label={
                  invite.isSuccess ? t('buddyZoeken.gevraagd') : t('buddyZoeken.vraagBuddy')
                }
                variant={invite.isSuccess ? 'outline' : 'cta'}
                size="lg"
                disabled={invite.isPending || invite.isSuccess}
                onPress={() => {
                  void haptics.stevig();
                  invite.mutate({ target: buddy.id });
                }}
              />
            ) : null}
          </>
        )}
      </ScrollView>
    </View>
  );
}

function Cijfer({ waarde, label, ster }: { waarde: string; label: string; ster?: boolean }) {
  return (
    <View style={styles.cijfer}>
      <View style={styles.cijferRij}>
        {ster ? <Star size={15} strokeWidth={2} color={colors.accentDark} fill={colors.accent} /> : null}
        <TvzText preset="cardTitle" style={styles.cijferWaarde}>
          {waarde}
        </TvzText>
      </View>
      <TvzText preset="meta" style={styles.cijferLabel}>
        {label}
      </TvzText>
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
  kop: {
    alignItems: 'center',
  },
  naam: {
    marginTop: spacing.md,
  },
  gecontroleerd: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    backgroundColor: colors.successBg,
    borderRadius: radius.pill,
    paddingHorizontal: 10,
    paddingVertical: 4,
    marginTop: spacing.sm,
  },
  gecontroleerdTekst: {
    color: colors.successText,
  },
  cijfers: {
    flexDirection: 'row',
    gap: spacing.cardGap,
  },
  cijfer: {
    flex: 1,
    backgroundColor: colors.white,
    borderRadius: radius.tile,
    paddingVertical: spacing.md,
    alignItems: 'center',
  },
  cijferRij: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  cijferWaarde: {
    fontSize: 19,
  },
  cijferLabel: {
    color: colors.inkSoft,
    textAlign: 'center',
  },
  beoordelingen: {
    color: colors.inkFaint,
    textAlign: 'center',
    marginTop: -spacing.xs,
  },
  bio: {
    marginTop: spacing.sm,
  },
  dagenKop: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
  },
  dagen: {
    flexDirection: 'row',
    gap: 6,
    marginTop: spacing.md,
  },
  dag: {
    flex: 1,
    borderRadius: radius.row,
    borderWidth: 1.5,
    borderColor: colors.line,
    alignItems: 'center',
    paddingVertical: 6,
  },
  dagAan: {
    backgroundColor: colors.successBg,
    borderColor: colors.accent,
  },
  dagTekst: {
    color: colors.inkFaint,
  },
  dagTekstAan: {
    color: colors.successText,
  },
});

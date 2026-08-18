import { router, useLocalSearchParams } from 'expo-router';
import { useState } from 'react';
import { Pressable, ScrollView, StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { ChevronLeft, Star } from 'lucide-react-native';

import { AanbiederAvatar } from '@/features/voorzieningen/AanbiederAvatar';
import { useDiensten, useSlots } from '@/features/voorzieningen/api';
import { euro, groepeerSlots } from '@/features/voorzieningen/slots';
import { t } from '@/i18n';
import { useStatusBalk } from '@/lib/statusbalk';
import { colors, radius, shadows, spacing } from '@/theme';
import { fonts } from '@/theme/typography';
import { Button, TvzText } from '@/ui';

/**
 * Dienst-detail (handoff voorzieningen): geen blokjes of pillen maar een
 * zachte, persoonlijke pagina rond de aanbieder.
 *
 * De tijdsloten komen uit de database (werkritme van de aanbieder min
 * afwezigheid en bestaande boekingen): dagschuifjes met daaronder de vrije
 * tijden van die dag als radio-lijst.
 */
export default function DienstDetail() {
  const { slug } = useLocalSearchParams<{ slug: string }>();
  const diensten = useDiensten();
  const dienst = (diensten.data ?? []).find((item) => item.slug === slug);
  const momenten = useSlots(dienst?.id);
  const dagen = groepeerSlots(momenten.data ?? []);
  const [gekozenDag, setGekozenDag] = useState(0);
  const [gekozenIso, setGekozenIso] = useState<string | null>(null);
  useStatusBalk('donker');

  if (!dienst) {
    return <View style={styles.safe} />;
  }

  const dag = dagen[Math.min(gekozenDag, Math.max(dagen.length - 1, 0))];
  // Standaard het eerste vrije moment van de gekozen dag.
  const slot = dag?.tijden.find((optie) => optie.iso === gekozenIso) ?? dag?.tijden[0] ?? null;
  const komma = (waarde: number) => String(waarde).replace('.', ',');
  const sterren = Math.round(Number(dienst.rating));

  return (
    <View style={styles.safe}>
      <ScrollView contentContainerStyle={styles.scroll}>
        {/* Lichtblauw hero-vlak met ronde onderhoeken */}
        <View style={styles.hero}>
          <SafeAreaView edges={['top']}>
            <Pressable
              accessibilityRole="button"
              accessibilityLabel={t('algemeen.terug')}
              onPress={() => router.back()}
              style={styles.terug}
            >
              <ChevronLeft color={colors.primaryMid} size={26} strokeWidth={2.4} />
            </Pressable>
            <View style={styles.heroInhoud}>
              <View style={styles.avatarRing}>
                <AanbiederAvatar
                  slug={dienst.slug}
                  naam={dienst.provider.name}
                  avatarPad={dienst.provider.avatar_path}
                  size={96}
                />
              </View>
              <TvzText preset="screenTitle" style={styles.dienstNaam}>
                {dienst.name}
              </TvzText>
              <TvzText preset="secondary" style={styles.metRegel}>
                {t('voorzien.metAanbieder', {
                  naam: dienst.provider.name,
                  km: komma(dienst.provider.distance_km),
                })}
              </TvzText>
              <View style={styles.sterrenRij}>
                {[0, 1, 2, 3, 4].map((index) => (
                  <Star
                    key={index}
                    size={16}
                    strokeWidth={2}
                    color={index < sterren ? colors.accentDark : colors.inkFaint}
                    fill={index < sterren ? colors.accent : 'transparent'}
                  />
                ))}
                <TvzText preset="meta" style={styles.sterrenTekst}>
                  {t('voorzien.beoordelingen', {
                    rating: komma(dienst.rating),
                    aantal: dienst.rating_count,
                  })}
                </TvzText>
              </View>
              {/* Gewoon leesbare tekst: het handschriftlettertype maakte het
                  onrustig (feedback Jelle 11-08). */}
              <TvzText preset="body" style={styles.notitie}>
                “{dienst.provider.note}”
              </TvzText>
            </View>
          </SafeAreaView>
        </View>

        <View style={styles.inhoud}>
          <TvzText preset="sectionTitle">{t('voorzien.verwachtTitel')}</TvzText>
          <TvzText preset="body" style={styles.omschrijving}>
            {dienst.description}
          </TvzText>
          <TvzText preset="secondary" style={styles.feitjes}>
            {dienst.unit === 'uur'
              ? t('voorzien.verwachtRegelUur')
              : t('voorzien.verwachtRegel', { duur: dienst.duration_min ?? 45 })}
          </TvzText>

          <TvzText preset="sectionTitle" style={styles.wanneerTitel}>
            {t('voorzien.wanneerTitel', { naam: dienst.provider.name })}
          </TvzText>

          {dagen.length === 0 ? (
            <TvzText preset="secondary" style={styles.geenSlots}>
              {momenten.isLoading ? t('algemeen.laden') : t('voorzien.geenSlots')}
            </TvzText>
          ) : (
            <>
              {/* Dagschuifjes: alleen dagen waarop echt iets vrij is. */}
              <ScrollView
                horizontal
                showsHorizontalScrollIndicator={false}
                contentContainerStyle={styles.dagBalk}
                style={styles.dagScroll}
              >
                {dagen.map((optie, index) => {
                  const actief = optie.datum === dag?.datum;
                  return (
                    <Pressable
                      key={optie.datum}
                      accessibilityRole="tab"
                      accessibilityState={{ selected: actief }}
                      accessibilityLabel={optie.label}
                      onPress={() => {
                        setGekozenDag(index);
                        setGekozenIso(null);
                      }}
                      style={[styles.dagPill, actief && styles.dagPillActief]}
                    >
                      <TvzText
                        preset="meta"
                        style={[styles.dagPillTekst, actief && styles.dagPillTekstActief]}
                      >
                        {optie.label}
                      </TvzText>
                    </Pressable>
                  );
                })}
              </ScrollView>

              <View style={styles.slotLijst}>
                {(dag?.tijden ?? []).map((optie, index) => {
                  const actief = optie.iso === slot?.iso;
                  // Het allereerste vrije moment van de hele lijst heet "snelst".
                  const snelst = gekozenDag === 0 && index === 0;
                  return (
                    <Pressable
                      key={optie.iso}
                      accessibilityRole="radio"
                      accessibilityState={{ checked: actief }}
                      accessibilityLabel={optie.label}
                      onPress={() => setGekozenIso(optie.iso)}
                      style={[styles.slotRij, index > 0 && styles.slotRijLijn]}
                    >
                      <View style={[styles.radio, actief && styles.radioActief]}>
                        {actief ? <View style={styles.radioStip} /> : null}
                      </View>
                      <TvzText preset="body" style={styles.slotLabel}>
                        {optie.tijd}
                      </TvzText>
                      {snelst ? (
                        <View style={styles.snelstPill}>
                          <TvzText preset="meta" style={styles.snelstTekst}>
                            {t('voorzien.snelst')}
                          </TvzText>
                        </View>
                      ) : null}
                    </Pressable>
                  );
                })}
              </View>
            </>
          )}
        </View>
      </ScrollView>

      {/* Zwevende prijskaart */}
      <SafeAreaView edges={['bottom']} style={styles.prijsWrap} pointerEvents="box-none">
        <View style={[styles.prijsKaart, shadows.floating]}>
          <View style={styles.prijsRij}>
            <TvzText style={styles.prijs}>{euro(dienst.price_cents)}</TvzText>
            <TvzText preset="meta" style={styles.prijsEenheid}>
              {dienst.unit === 'uur' ? t('voorzien.perUur') : t('voorzien.perBezoek')}
            </TvzText>
          </View>
          <TvzText preset="secondary" style={styles.betaalNa}>
            {t('voorzien.betaalNa')}
          </TvzText>
          {/* Vierkanter dan een gewone pill: dit is de handeling waar de hele
              pagina om draait (wens Jelle 11-08). */}
          <Button
            label={slot ? t('voorzien.boekSlot', { moment: slot.label }) : t('voorzien.geenSlotsKnop')}
            variant="cta"
            size="lg"
            disabled={!slot}
            style={styles.boekKnop}
            onPress={() => {
              if (!slot) return;
              router.push({
                pathname: '/dienst/afrekenen',
                params: { slug: dienst.slug, slot: slot.iso },
              });
            }}
          />
        </View>
      </SafeAreaView>
    </View>
  );
}

const HERO_RADIUS = 28;

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: colors.bg,
  },
  scroll: {
    paddingBottom: 210,
  },
  hero: {
    backgroundColor: colors.heroBlue,
    borderBottomLeftRadius: HERO_RADIUS,
    borderBottomRightRadius: HERO_RADIUS,
    paddingHorizontal: spacing.screen,
    paddingBottom: spacing.xxl,
  },
  terug: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: colors.white,
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: spacing.sm,
  },
  heroInhoud: {
    alignItems: 'center',
    marginTop: spacing.sm,
  },
  avatarRing: {
    borderRadius: 56,
    borderWidth: 4,
    borderColor: colors.white,
    // De witte rand als zachte ring om de grote aanbieder-avatar.
    padding: 2,
    backgroundColor: colors.white,
  },
  dienstNaam: {
    marginTop: spacing.md,
    fontSize: 24,
  },
  metRegel: {
    marginTop: 2,
  },
  sterrenRij: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 3,
    marginTop: spacing.sm,
  },
  sterrenTekst: {
    marginLeft: spacing.xs,
  },
  notitie: {
    marginTop: spacing.md,
    textAlign: 'center',
    color: colors.inkSoft,
    fontStyle: 'italic',
  },
  inhoud: {
    padding: spacing.screen,
  },
  omschrijving: {
    marginTop: spacing.sm,
  },
  feitjes: {
    marginTop: spacing.sm,
  },
  wanneerTitel: {
    marginTop: spacing.xl,
  },
  geenSlots: {
    marginTop: spacing.md,
  },
  dagScroll: {
    marginTop: spacing.md,
    // De pillen mogen tot de schermrand doorlopen.
    marginHorizontal: -spacing.screen,
  },
  dagBalk: {
    flexDirection: 'row',
    gap: spacing.sm,
    paddingHorizontal: spacing.screen,
  },
  dagPill: {
    borderRadius: radius.pill,
    paddingHorizontal: 14,
    minHeight: 36,
    justifyContent: 'center',
    backgroundColor: colors.white,
    borderWidth: 1,
    borderColor: colors.line,
  },
  dagPillActief: {
    backgroundColor: colors.primaryMid,
    borderColor: colors.primaryMid,
  },
  dagPillTekst: {
    color: colors.inkSoft,
  },
  dagPillTekstActief: {
    color: colors.white,
  },
  slotLijst: {
    backgroundColor: colors.white,
    borderRadius: radius.card,
    marginTop: spacing.md,
    paddingHorizontal: spacing.lg,
  },
  slotRij: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
    minHeight: 54,
  },
  slotRijLijn: {
    borderTopWidth: 1,
    borderTopColor: colors.line,
  },
  radio: {
    width: 22,
    height: 22,
    borderRadius: 11,
    borderWidth: 2,
    borderColor: colors.inkFaint,
    alignItems: 'center',
    justifyContent: 'center',
  },
  radioActief: {
    borderColor: colors.primaryMid,
  },
  radioStip: {
    width: 11,
    height: 11,
    borderRadius: 5.5,
    backgroundColor: colors.primaryMid,
  },
  slotLabel: {
    flex: 1,
  },
  snelstPill: {
    backgroundColor: colors.successBg,
    borderRadius: radius.pill,
    paddingHorizontal: 10,
    paddingVertical: 3,
  },
  snelstTekst: {
    color: colors.successText,
  },
  prijsWrap: {
    position: 'absolute',
    left: 0,
    right: 0,
    bottom: 0,
  },
  prijsKaart: {
    backgroundColor: colors.white,
    borderRadius: radius.tile,
    margin: spacing.lg,
    padding: spacing.cardPadding,
  },
  prijsRij: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    gap: spacing.sm,
  },
  // Regelhoogte ruim boven de tekengrootte: anders sneuvelt de bovenkant van
  // de cijfers (feedback Jelle 11-08).
  prijs: {
    fontFamily: fonts.headingExtra,
    fontSize: 28,
    lineHeight: 38,
    color: colors.ink,
  },
  prijsEenheid: {
    color: colors.inkSoft,
  },
  betaalNa: {
    marginTop: 2,
    marginBottom: spacing.md,
  },
  boekKnop: {
    borderRadius: radius.card,
  },
});

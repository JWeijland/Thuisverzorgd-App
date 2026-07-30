import { router, useLocalSearchParams } from 'expo-router';
import * as WebBrowser from 'expo-web-browser';
import { useEffect } from 'react';
import { Pressable, ScrollView, StyleSheet, View } from 'react-native';
import {
  Bookmark,
  BookmarkCheck,
  ExternalLink,
  MessageCircleQuestionMark,
  Quote,
  ScrollText,
  TriangleAlert,
  X,
  type LucideIcon,
} from 'lucide-react-native';

import {
  useGuideActions,
  useGuideLinks,
  useGuideModule,
  useGuideModules,
  useGuideSections,
  type GuideSection,
  type SectieSoort,
} from '@/features/wegwijzer/api';
import {
  MakelaarKaart,
  ModuleKaart,
  themaTint,
  vraagAanMakelaar,
} from '@/features/wegwijzer/WegwijzerLijst';
import { t } from '@/i18n';
import { formatHumanDate, parseDateString } from '@/lib/dates';
import { colors, radius, spacing } from '@/theme';
import { Button, Card, GradientHeader, Pill, SectionHeader, TvzText } from '@/ui';

/**
 * Eén onderwerp uit de Wegwijzer: de kern bovenaan, daarna de onderdelen in
 * blokken die per soort anders zijn getekend (uitleg, stappen, wettekst,
 * let op, voorbeeld, veelgestelde vraag). Onderaan de wettelijke basis, de
 * externe links en de stap naar een hulpmakelaar.
 */
export default function WegwijzerModuleScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const module = useGuideModule(id);
  const alles = useGuideModules();
  const secties = useGuideSections(module?.id);
  const links = useGuideLinks(module?.id);
  const { bewaar, markeerGelezen } = useGuideActions();

  // Onthouden dat je dit onderwerp opende, voor "verder lezen" op het overzicht.
  useEffect(() => {
    if (module?.id) markeerGelezen.mutate(module.id);
    // Eén keer per geopend onderwerp; de mutatie zelf is geen afhankelijkheid.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [module?.id]);

  const tint = themaTint(module?.thema_kleur ?? 'blauw');
  const verwant = (alles.data ?? [])
    .filter((rij) => rij.thema_slug === module?.thema_slug && rij.id !== module?.id)
    .slice(0, 3);

  return (
    <View style={styles.safe}>
      <GradientHeader
        title={module?.titel ?? t('wegwijzer.titel')}
        subtitle={module?.thema}
        wobbel
        right={
          <View style={styles.kopKnoppen}>
            {module ? (
              <Pressable
                accessibilityRole="button"
                accessibilityLabel={
                  module.bewaard ? t('wegwijzer.bewaardAf') : t('wegwijzer.bewaarAan')
                }
                accessibilityState={{ selected: module.bewaard }}
                onPress={() => bewaar.mutate(module.id)}
                style={styles.kopKnop}
                hitSlop={8}
              >
                {module.bewaard ? (
                  <BookmarkCheck color={colors.white} size={20} strokeWidth={2.2} />
                ) : (
                  <Bookmark color={colors.white} size={20} strokeWidth={2.2} />
                )}
              </Pressable>
            ) : null}
            <Pressable
              accessibilityRole="button"
              accessibilityLabel={t('algemeen.sluiten')}
              onPress={() => router.back()}
              style={styles.kopKnop}
              hitSlop={8}
            >
              <X color={colors.white} size={20} strokeWidth={2.4} />
            </Pressable>
          </View>
        }
      />

      <ScrollView contentContainerStyle={styles.list}>
        {module ? (
          <Card style={[styles.kern, { borderColor: tint.vlak }]}>
            <TvzText preset="meta" style={[styles.kernKop, { color: tint.icoon }]}>
              {t('wegwijzer.kortGezegd')}
            </TvzText>
            {module.kern.map((regel) => (
              <View key={regel} style={styles.kernRegel}>
                <View style={[styles.bolletje, { backgroundColor: tint.icoon }]} />
                <TvzText preset="body" style={styles.kernTekst}>
                  {regel}
                </TvzText>
              </View>
            ))}
            <View style={styles.kernMeta}>
              <Pill
                label={t('wegwijzer.leestijd', { minuten: module.leestijd_minuten })}
                color={tint.icoon}
                backgroundColor={tint.vlak}
              />
            </View>
          </Card>
        ) : null}

        {(secties.data ?? []).map((sectie) => (
          <SectieBlok key={sectie.id} sectie={sectie} />
        ))}

        {module && module.wetten.length > 0 ? (
          <>
            <SectionHeader title={t('wegwijzer.wettelijkeBasis')} />
            <View style={styles.wetPillen}>
              {module.wetten.map((wet) => (
                <Pill key={wet} label={wet} />
              ))}
            </View>
          </>
        ) : null}

        {(links.data ?? []).length > 0 ? (
          <>
            <SectionHeader title={t('wegwijzer.verderKijken')} />
            {links.data!.map((link) => (
              <Pressable
                key={link.id}
                accessibilityRole="link"
                onPress={() => WebBrowser.openBrowserAsync(link.url)}
                style={styles.link}
              >
                <ExternalLink color={colors.primaryMid} size={18} strokeWidth={2.2} />
                <TvzText preset="cardTitle" style={styles.linkTekst}>
                  {link.titel}
                </TvzText>
              </Pressable>
            ))}
          </>
        ) : null}

        {module ? (
          <TvzText preset="meta" style={styles.bijgewerkt}>
            {t('wegwijzer.bijgewerkt', {
              datum: formatHumanDate(parseDateString(module.bijgewerkt_op)),
            })}
          </TvzText>
        ) : null}
        <TvzText preset="secondary" style={styles.disclaimer}>
          {t('wegwijzer.disclaimer')}
        </TvzText>

        <Button
          label={t('wegwijzer.stelVraag')}
          variant="cta"
          size="lg"
          style={styles.knop}
          onPress={() =>
            vraagAanMakelaar(
              module ? t('wegwijzer.vraagVoorbeeld', { onderwerp: module.titel }) : undefined,
            )
          }
        />

        {verwant.length > 0 ? (
          <>
            <SectionHeader title={t('wegwijzer.verwant')} />
            {verwant.map((rij) => (
              <ModuleKaart key={rij.id} module={rij} compact />
            ))}
          </>
        ) : null}

        <MakelaarKaart vraag={module?.titel} />
      </ScrollView>
    </View>
  );
}

const SOORT_ICOON: Partial<Record<SectieSoort, LucideIcon>> = {
  wet: ScrollText,
  letop: TriangleAlert,
  voorbeeld: Quote,
  vraag: MessageCircleQuestionMark,
};

/** Eén onderdeel. De soort bepaalt de vorm: opsomming, waarschuwing of citaat. */
function SectieBlok({ sectie }: { sectie: GuideSection }) {
  const Icoon = SOORT_ICOON[sectie.soort];
  const stappen = sectie.soort === 'stappen' ? sectie.body.split('\n').filter(Boolean) : [];

  return (
    <Card
      style={[
        styles.sectie,
        sectie.soort === 'letop' && styles.sectieLetop,
        sectie.soort === 'wet' && styles.sectieWet,
        sectie.soort === 'voorbeeld' && styles.sectieVoorbeeld,
      ]}
    >
      <View style={styles.sectieKop}>
        {Icoon ? (
          <Icoon
            color={
              sectie.soort === 'letop'
                ? colors.warnText
                : sectie.soort === 'wet'
                  ? colors.primaryMid
                  : colors.inkSoft
            }
            size={18}
            strokeWidth={2.2}
          />
        ) : null}
        <TvzText
          preset="cardTitle"
          style={[styles.sectieTitel, sectie.soort === 'letop' && styles.sectieTitelLetop]}
        >
          {sectie.titel}
        </TvzText>
      </View>

      {stappen.length > 0 ? (
        <View style={styles.stappen}>
          {stappen.map((stap, index) => (
            <View key={stap} style={styles.stap}>
              <View style={styles.stapNr}>
                <TvzText preset="meta" style={styles.stapNrTekst}>
                  {index + 1}
                </TvzText>
              </View>
              <TvzText preset="body" style={styles.stapTekst}>
                {stap.trim()}
              </TvzText>
            </View>
          ))}
        </View>
      ) : (
        <TvzText
          preset="body"
          style={[styles.sectieBody, sectie.soort === 'voorbeeld' && styles.sectieBodyCursief]}
        >
          {sectie.body}
        </TvzText>
      )}
    </Card>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: colors.bg,
  },
  kopKnoppen: {
    flexDirection: 'row',
    gap: spacing.sm,
  },
  kopKnop: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: 'rgba(255,255,255,0.18)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  list: {
    padding: spacing.screen,
    paddingBottom: 60,
    gap: spacing.cardGap,
  },
  kern: {
    borderWidth: 2,
    paddingVertical: spacing.lg,
  },
  kernKop: {
    marginBottom: spacing.md,
  },
  kernRegel: {
    flexDirection: 'row',
    gap: spacing.md,
    marginBottom: spacing.sm,
  },
  bolletje: {
    width: 7,
    height: 7,
    borderRadius: 4,
    marginTop: 9,
  },
  kernTekst: {
    flex: 1,
    fontSize: 15,
    lineHeight: 23,
  },
  kernMeta: {
    marginTop: spacing.sm,
  },
  sectie: {
    paddingVertical: spacing.lg,
  },
  sectieLetop: {
    backgroundColor: colors.warnBg,
  },
  sectieWet: {
    borderLeftWidth: 4,
    borderLeftColor: colors.primaryMid,
  },
  sectieVoorbeeld: {
    backgroundColor: colors.surfaceAlt,
  },
  sectieKop: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    marginBottom: spacing.sm,
  },
  sectieTitel: {
    flex: 1,
    fontSize: 16,
  },
  sectieTitelLetop: {
    color: colors.warnText,
  },
  sectieBody: {
    fontSize: 15.5,
    lineHeight: 24,
  },
  sectieBodyCursief: {
    fontStyle: 'italic',
  },
  stappen: {
    gap: spacing.sm,
    marginTop: spacing.xs,
  },
  stap: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: spacing.md,
  },
  stapNr: {
    width: 24,
    height: 24,
    borderRadius: 12,
    backgroundColor: colors.tintBlue,
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: 2,
  },
  stapNrTekst: {
    color: colors.primary,
  },
  stapTekst: {
    flex: 1,
    fontSize: 15,
    lineHeight: 23,
  },
  wetPillen: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing.chipGap,
  },
  link: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
    backgroundColor: colors.white,
    borderRadius: radius.row,
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.md,
    minHeight: 48,
  },
  linkTekst: {
    flex: 1,
    fontSize: 15,
    color: colors.primary,
  },
  bijgewerkt: {
    color: colors.inkFaint,
    marginTop: spacing.md,
  },
  disclaimer: {
    color: colors.inkFaint,
    fontSize: 12.5,
    lineHeight: 18,
  },
  knop: {
    marginTop: spacing.sm,
  },
});

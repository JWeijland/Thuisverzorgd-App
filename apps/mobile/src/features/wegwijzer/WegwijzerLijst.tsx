import { router } from 'expo-router';
import * as WebBrowser from 'expo-web-browser';
import { useEffect, useMemo, useState, type ReactNode } from 'react';
import { Pressable, ScrollView, StyleSheet, TextInput, View } from 'react-native';
import {
  Bookmark,
  ChevronRight,
  ExternalLink,
  MessagesSquare,
  Search,
  Sparkles,
  X,
} from 'lucide-react-native';

import {
  useDebounced,
  useGuideAntwoord,
  useGuideModules,
  useGuideSearch,
  useGuideSuggesties,
  useGuideThemes,
  useLogZoekopdracht,
  type Antwoord,
  type GuideModule,
  type ThemaKleur,
  type Zoektreffer,
} from '@/features/wegwijzer/api';
import { ThemaIcoon } from '@/features/wegwijzer/ThemaIcoon';
import { filterLokaal, knipAntwoord, magZoeken, splitsTreffer } from '@/features/wegwijzer/zoekterm';
import { t } from '@/i18n';
import { colors, radius, spacing, themaTints } from '@/theme';
import { Card, Chip, EmptyState, Pill, SectionHeader, TvzText } from '@/ui';

export function themaTint(kleur: ThemaKleur) {
  return themaTints[kleur] ?? themaTints.blauw;
}

function openModule(id: string) {
  router.push({ pathname: '/wegwijzer/[id]', params: { id } });
}

/**
 * Naar de hulpmakelaar-chat (eigen pagina sinds ontwerp 4.0), met de vraag
 * alvast in het tekstvak.
 */
export function vraagAanMakelaar(vraag?: string) {
  router.push({
    pathname: '/weten/zorgmakelaars',
    params: vraag ? { vraag } : {},
  });
}

/**
 * Wegwijzer: de kennisbank over de wetten en regelingen rond mantelzorg.
 * Zoeken staat bovenaan, want dat is waarvoor mensen hier komen: je typt
 * "mantelwoning" en krijgt het onderwerp dat daarover gaat. Vind je het
 * antwoord niet, dan stap je onderaan door naar een hulpmakelaar.
 */
export function WegwijzerLijst({ kop }: { kop?: ReactNode }) {
  const [term, setTerm] = useState('');
  const [thema, setThema] = useState<string | null>(null);
  const zoekterm = useDebounced(term);
  const zoekt = magZoeken(term);

  const themas = useGuideThemes();
  const modules = useGuideModules();
  const treffers = useGuideSearch(zoekterm);
  const antwoorden = useGuideAntwoord(zoekterm);
  const suggesties = useGuideSuggesties(zoekterm);
  const logZoekopdracht = useLogZoekopdracht();

  // Terwijl de server nog antwoordt, filteren we lokaal op wat er al binnen is.
  const lokaal = useMemo(
    () => filterLokaal(modules.data ?? [], zoekterm),
    [modules.data, zoekterm],
  );
  const resultaten: Zoektreffer[] = treffers.data ?? lokaal.map(alsTreffer);
  const wachtOpServer = zoekt && treffers.isFetching && !treffers.data;

  // Anoniem bijhouden waar mensen op zoeken, om gaten in de kennisbank te zien.
  useEffect(() => {
    if (!zoekt || !treffers.data) return;
    logZoekopdracht.mutate({ term: zoekterm, resultaten: treffers.data.length });
    // Alleen bij een nieuw serverantwoord, niet bij elke render van de mutatie.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [zoekterm, treffers.data]);

  const alleModules = modules.data ?? [];
  const populair = alleModules.filter((module) => module.populair).slice(0, 6);
  const bewaard = alleModules.filter((module) => module.bewaard);
  const verderLezen = alleModules
    .filter((module) => !!module.gelezen_op)
    .sort((a, b) => (b.gelezen_op ?? '').localeCompare(a.gelezen_op ?? ''))
    .slice(0, 3);
  const themaModules = thema ? alleModules.filter((module) => module.thema_slug === thema) : [];
  const gekozenThema = themas.data?.find((rij) => rij.slug === thema);

  return (
    <View style={styles.fill}>
      <ScrollView contentContainerStyle={styles.list} keyboardShouldPersistTaps="handled">
        {/* Alles boven de kennisbank (vandaag-strip, makelaar-blok) scrolt mee,
            zodat de pagina één doorlopend geheel blijft. */}
        {!zoekt && kop ? kop : null}
        <View style={styles.zoekbalk}>
          <Search color={colors.inkFaint} size={19} strokeWidth={2.2} />
          <TextInput
            textContentType="none"
            autoComplete="off"
            value={term}
            onChangeText={setTerm}
            placeholder={t('wegwijzer.zoekPlaceholder')}
            placeholderTextColor={colors.inkFaint}
            style={styles.zoekveld}
            autoCorrect={false}
            returnKeyType="search"
            accessibilityLabel={t('wegwijzer.zoekPlaceholder')}
          />
          {term.length > 0 ? (
            <Pressable
              accessibilityRole="button"
              accessibilityLabel={t('wegwijzer.wissen')}
              onPress={() => setTerm('')}
              hitSlop={10}
            >
              <X color={colors.inkSoft} size={18} strokeWidth={2.4} />
            </Pressable>
          ) : null}
        </View>
        {zoekt ? (
          <>
            {(suggesties.data ?? []).length > 0 ? (
              <ScrollView
                horizontal
                showsHorizontalScrollIndicator={false}
                contentContainerStyle={styles.suggestieRij}
              >
                {suggesties.data!.map((suggestie) => (
                  <Chip
                    key={`${suggestie.slug}-${suggestie.term}`}
                    label={suggestie.term}
                    onPress={() => setTerm(suggestie.term)}
                  />
                ))}
              </ScrollView>
            ) : null}

            {(antwoorden.data ?? []).length > 0 ? (
              <AntwoordKaart antwoorden={antwoorden.data!} />
            ) : null}

            <TvzText preset="meta" style={styles.telling}>
              {wachtOpServer
                ? t('algemeen.laden')
                : resultaten.length === 0
                  ? t('wegwijzer.geenResultaten', { term: zoekterm })
                  : resultaten.length === 1
                    ? t('wegwijzer.resultaat1', { term: zoekterm })
                    : t('wegwijzer.resultaten', { aantal: resultaten.length, term: zoekterm })}
            </TvzText>

            {resultaten.map((rij) => (
              <TrefferKaart key={rij.id} treffer={rij} />
            ))}

            {!wachtOpServer && resultaten.length === 0 ? (
              <Card>
                <EmptyState
                  title={t('wegwijzer.nietsGevondenTitel')}
                  body={t('wegwijzer.nietsGevondenTekst')}
                />
              </Card>
            ) : null}

            <MakelaarKaart vraag={zoekterm} />
          </>
        ) : thema ? (
          <>
            <Pressable
              accessibilityRole="button"
              onPress={() => setThema(null)}
              style={styles.terugRij}
              hitSlop={8}
            >
              <TvzText preset="meta" style={styles.terugText}>
                {t('wegwijzer.alleThemas')}
              </TvzText>
            </Pressable>
            <SectionHeader title={gekozenThema?.titel ?? t('wegwijzer.titel')} />
            {gekozenThema?.omschrijving ? (
              <TvzText preset="secondary" style={styles.uitleg}>
                {gekozenThema.omschrijving}
              </TvzText>
            ) : null}
            {themaModules.map((module) => (
              <ModuleKaart key={module.id} module={module} />
            ))}
            <MakelaarKaart />
          </>
        ) : (
          <>
            <TvzText preset="secondary" style={styles.intro}>
              {t('wegwijzer.intro')}
            </TvzText>

            {populair.length > 0 ? (
              <>
                <SectionHeader title={t('wegwijzer.veelGezocht')} />
                <View style={styles.chips}>
                  {populair.map((module) => (
                    <Chip
                      key={module.id}
                      label={module.titel}
                      onPress={() => openModule(module.id)}
                    />
                  ))}
                </View>
              </>
            ) : null}

            {verderLezen.length > 0 ? (
              <>
                <SectionHeader title={t('wegwijzer.verderLezen')} />
                {verderLezen.map((module) => (
                  <ModuleKaart key={module.id} module={module} compact />
                ))}
              </>
            ) : null}

            <SectionHeader title={t('wegwijzer.themas')} />
            <View style={styles.raster}>
              {(themas.data ?? []).map((rij) => {
                const tint = themaTint(rij.kleur);
                return (
                  <Pressable
                    key={rij.id}
                    accessibilityRole="button"
                    onPress={() => setThema(rij.slug)}
                    style={styles.tegelWrap}
                  >
                    <Card style={styles.tegel}>
                      <View style={[styles.tegelIcoon, { backgroundColor: tint.vlak }]}>
                        <ThemaIcoon thema={rij.slug} size={24} />
                      </View>
                      <TvzText preset="cardTitle" style={styles.tegelTitel}>
                        {rij.titel}
                      </TvzText>
                      <TvzText preset="meta" style={styles.tegelMeta}>
                        {rij.onderwerpen === 1
                          ? t('wegwijzer.onderwerp1')
                          : t('wegwijzer.onderwerpen', { aantal: rij.onderwerpen })}
                      </TvzText>
                    </Card>
                  </Pressable>
                );
              })}
            </View>

            {bewaard.length > 0 ? (
              <>
                <SectionHeader title={t('wegwijzer.bewaard')} />
                {bewaard.map((module) => (
                  <ModuleKaart key={module.id} module={module} compact />
                ))}
              </>
            ) : null}

            <MakelaarKaart />
          </>
        )}
      </ScrollView>
    </View>
  );
}

/**
 * Direct antwoord op een getypte vraag: het onderdeel uit de kennisbank dat
 * alle inhoudswoorden van de vraag bevat, met daaronder het onderwerp waar het
 * uit komt en de bronnen die het onderbouwen. Vinden we niets met voldoende
 * zekerheid, dan verschijnt deze kaart niet en blijft de gewone lijst over.
 */
function AntwoordKaart({ antwoorden }: { antwoorden: Antwoord[] }) {
  const beste = antwoorden[0];
  if (!beste) return null;
  const tint = themaTint(beste.thema_kleur);
  const { tekst, geknipt } = knipAntwoord(beste.antwoord);
  const stappen = beste.soort === 'stappen' ? tekst.split('\n').filter(Boolean) : [];
  const overige = antwoorden.slice(1).filter((rij) => rij.module_id !== beste.module_id);

  return (
    <Card style={[styles.antwoord, { borderColor: tint.vlak }]}>
      <View style={styles.antwoordKop}>
        <Sparkles color={tint.icoon} size={16} strokeWidth={2.4} />
        <TvzText preset="meta" style={[styles.antwoordLabel, { color: tint.icoon }]}>
          {t('wegwijzer.antwoordKop')}
        </TvzText>
        <Pill label={beste.thema} color={tint.icoon} backgroundColor={tint.vlak} />
      </View>
      <TvzText preset="cardTitle" style={styles.kaartTitel}>
        {beste.titel}
      </TvzText>
      {stappen.length > 0 ? (
        <View style={styles.antwoordStappen}>
          {stappen.map((stap, index) => (
            <TvzText key={stap} preset="body" style={styles.antwoordTekst}>
              {index + 1}. {stap.trim()}
            </TvzText>
          ))}
        </View>
      ) : (
        <TvzText preset="body" style={styles.antwoordTekst}>
          {tekst}
        </TvzText>
      )}
      <Pressable
        accessibilityRole="button"
        onPress={() => openModule(beste.module_id)}
        style={styles.antwoordUit}
        hitSlop={6}
      >
        <TvzText preset="meta" style={styles.antwoordUitTekst}>
          {t('wegwijzer.antwoordUit', { onderwerp: beste.module_titel })}
          {geknipt ? ` · ${t('wegwijzer.antwoordLees')}` : ''}
        </TvzText>
        <ChevronRight color={colors.primaryMid} size={16} strokeWidth={2.4} />
      </Pressable>

      {beste.bronnen.length > 0 ? (
        <>
          <TvzText preset="meta" style={styles.antwoordBronKop}>
            {t('wegwijzer.antwoordBronnen')}
          </TvzText>
          {beste.bronnen.map((bron) => (
            <Pressable
              key={bron.url}
              accessibilityRole="link"
              onPress={() => WebBrowser.openBrowserAsync(bron.url)}
              style={styles.antwoordBron}
              hitSlop={4}
            >
              <ExternalLink color={colors.primaryMid} size={15} strokeWidth={2.2} />
              <TvzText preset="meta" style={styles.antwoordBronTekst}>
                {bron.titel}
              </TvzText>
            </Pressable>
          ))}
        </>
      ) : null}

      {overige.length > 0 ? (
        <View style={styles.antwoordOverige}>
          <TvzText preset="meta" style={styles.antwoordBronKop}>
            {t('wegwijzer.antwoordMeer')}
          </TvzText>
          <View style={styles.chips}>
            {overige.map((rij) => (
              <Chip
                key={rij.sectie_id}
                label={rij.module_titel}
                onPress={() => openModule(rij.module_id)}
              />
            ))}
          </View>
        </View>
      ) : null}
    </Card>
  );
}

/** Een module als zoektreffer tonen zolang het serverantwoord onderweg is. */
function alsTreffer(module: GuideModule): Zoektreffer {
  return {
    id: module.id,
    slug: module.slug,
    titel: module.titel,
    samenvatting: module.samenvatting,
    thema: module.thema,
    thema_slug: module.thema_slug,
    thema_kleur: module.thema_kleur,
    leestijd_minuten: module.leestijd_minuten,
    treffer: module.samenvatting,
    score: 0,
  };
}

/** Zoekresultaat: thema, titel en het stukje tekst waarin het antwoord staat. */
function TrefferKaart({ treffer }: { treffer: Zoektreffer }) {
  const tint = themaTint(treffer.thema_kleur);
  const delen = splitsTreffer(treffer.treffer);

  return (
    <Pressable accessibilityRole="button" onPress={() => openModule(treffer.id)}>
      <Card style={styles.kaart}>
        <View style={styles.kaartKop}>
          <Pill label={treffer.thema} color={tint.icoon} backgroundColor={tint.vlak} />
          <TvzText preset="meta" style={styles.meta}>
            {t('wegwijzer.leestijd', { minuten: treffer.leestijd_minuten })}
          </TvzText>
        </View>
        <TvzText preset="cardTitle" style={styles.kaartTitel}>
          {treffer.titel}
        </TvzText>
        <TvzText preset="secondary">
          {delen.length > 0
            ? delen.map((deel, index) => (
                <TvzText
                  key={`${deel.text}-${index}`}
                  preset={deel.raak ? 'bodyBold' : 'secondary'}
                  style={deel.raak ? styles.raak : undefined}
                >
                  {deel.text}
                </TvzText>
              ))
            : treffer.samenvatting}
        </TvzText>
      </Card>
    </Pressable>
  );
}

/** Eén onderwerp in een themalijst of in "verder lezen". */
export function ModuleKaart({
  module,
  compact = false,
}: {
  module: GuideModule;
  compact?: boolean;
}) {
  const tint = themaTint(module.thema_kleur);

  return (
    <Pressable accessibilityRole="button" onPress={() => openModule(module.id)}>
      <Card style={styles.kaart}>
        <View style={styles.moduleKop}>
          <View style={[styles.moduleIcoon, { backgroundColor: tint.vlak }]}>
            <ThemaIcoon thema={module.thema_slug} size={20} />
          </View>
          <View style={styles.fill}>
            <TvzText preset="cardTitle" style={styles.kaartTitel}>
              {module.titel}
            </TvzText>
            <TvzText preset="meta" style={styles.meta}>
              {t('wegwijzer.leestijd', { minuten: module.leestijd_minuten })}
              {compact ? ` · ${module.thema}` : ''}
            </TvzText>
          </View>
          {module.bewaard ? (
            <Bookmark
              color={colors.primaryMid}
              size={17}
              strokeWidth={2.4}
              fill={colors.tintBlue}
            />
          ) : (
            <ChevronRight color={colors.inkFaint} size={18} strokeWidth={2.2} />
          )}
        </View>
        {!compact ? (
          <TvzText preset="secondary" style={styles.moduleTekst}>
            {module.samenvatting}
          </TvzText>
        ) : null}
      </Card>
    </Pressable>
  );
}

/** Vast slot onderaan: kom je er niet uit, dan praat je met een mens. */
export function MakelaarKaart({ vraag }: { vraag?: string }) {
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={t('wegwijzer.makelaarKnop')}
      onPress={() => vraagAanMakelaar(vraag)}
      style={styles.makelaarWrap}
    >
      <Card style={styles.makelaar}>
        <View style={styles.makelaarIcoon}>
          <MessagesSquare color={colors.primary} size={20} strokeWidth={2.2} />
        </View>
        <View style={styles.fill}>
          <TvzText preset="cardTitle">{t('wegwijzer.makelaarTitel')}</TvzText>
          <TvzText preset="secondary" style={styles.makelaarTekst}>
            {t('wegwijzer.makelaarTekst')}
          </TvzText>
        </View>
        <ChevronRight color={colors.inkFaint} size={18} strokeWidth={2.2} />
      </Card>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  fill: { flex: 1 },
  zoekbalk: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    backgroundColor: colors.white,
    borderWidth: 1.5,
    borderColor: colors.line,
    borderRadius: radius.pill,
    paddingHorizontal: 16,
    minHeight: 48,
    marginBottom: spacing.md,
  },
  zoekveld: {
    flex: 1,
    fontFamily: 'ComicNeue_400Regular',
    fontSize: 15.5,
    color: colors.ink,
    paddingVertical: 12,
  },
  list: {
    padding: spacing.screen,
    paddingBottom: 110,
    gap: spacing.cardGap,
  },
  intro: {
    marginBottom: -spacing.sm,
  },
  uitleg: {
    marginTop: -spacing.xs,
  },
  suggestieRij: {
    gap: spacing.chipGap,
    paddingBottom: spacing.sm,
  },
  telling: {
    color: colors.inkFaint,
    marginBottom: spacing.xs,
  },
  chips: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing.chipGap,
  },
  kaart: {
    paddingVertical: spacing.lg,
  },
  antwoord: {
    borderWidth: 2,
    paddingVertical: spacing.lg,
  },
  antwoordKop: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    marginBottom: spacing.sm,
  },
  antwoordLabel: {
    flex: 1,
  },
  antwoordStappen: {
    gap: spacing.xs,
  },
  antwoordTekst: {
    fontSize: 15,
    lineHeight: 23,
  },
  antwoordUit: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.xs,
    marginTop: spacing.sm,
    minHeight: 32,
  },
  antwoordUitTekst: {
    color: colors.primaryMid,
    flexShrink: 1,
  },
  antwoordBronKop: {
    color: colors.inkFaint,
    marginTop: spacing.md,
    marginBottom: spacing.xs,
  },
  antwoordBron: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    minHeight: 32,
  },
  antwoordBronTekst: {
    color: colors.primary,
    flexShrink: 1,
  },
  antwoordOverige: {
    marginTop: spacing.xs,
  },
  kaartKop: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: spacing.sm,
  },
  kaartTitel: {
    marginBottom: 2,
  },
  meta: {
    color: colors.inkFaint,
  },
  raak: {
    color: colors.primary,
    fontSize: 13.5,
    lineHeight: 20,
  },
  moduleKop: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
  },
  moduleIcoon: {
    width: 34,
    height: 34,
    borderRadius: 17,
    alignItems: 'center',
    justifyContent: 'center',
  },
  moduleTekst: {
    marginTop: spacing.sm,
  },
  raster: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing.cardGap,
  },
  tegelWrap: {
    // twee tegels naast elkaar, met de kaartgap ertussen
    width: '48.5%',
  },
  tegel: {
    minHeight: 132,
    paddingVertical: spacing.lg,
  },
  tegelIcoon: {
    width: 38,
    height: 38,
    borderRadius: radius.tile,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing.md,
  },
  tegelTitel: {
    fontSize: 15,
  },
  tegelMeta: {
    color: colors.inkFaint,
    marginTop: spacing.xs,
  },
  terugRij: {
    alignSelf: 'flex-start',
    borderRadius: radius.pill,
    backgroundColor: colors.surfaceAlt,
    paddingHorizontal: 14,
    paddingVertical: 7,
    minHeight: 34,
    justifyContent: 'center',
  },
  terugText: {
    color: colors.primary,
  },
  makelaarWrap: {
    marginTop: spacing.md,
  },
  makelaar: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
    borderWidth: 1.5,
    borderColor: colors.tintBlue,
  },
  makelaarIcoon: {
    width: 40,
    height: 40,
    borderRadius: radius.tile,
    backgroundColor: colors.tintBlue,
    alignItems: 'center',
    justifyContent: 'center',
  },
  makelaarTekst: {
    marginTop: 2,
  },
});

import { router } from 'expo-router';
import { useState } from 'react';
import {
  KeyboardAvoidingView,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  TextInput,
  View,
} from 'react-native';

import { useCreateCircle } from '@/features/circles/api';
import {
  KRINGOPBOUW_STAPPEN,
  useBewaarKringConcept,
  useKoppelNaaste,
  useKringConcept,
  useWisKringConcept,
  type KringAntwoorden,
  type TaakSoort,
} from '@/features/circles/kringopbouw';
import { AdresVeld } from '@/features/circles/AdresVeld';
import { PadHeader } from '@/features/navigatie/PadHeader';
import { useCreateTask } from '@/features/tasks/api';
import { taakSoortLabel } from '@/features/tasks/logic';
import { t } from '@/i18n';
import { toDateString } from '@/lib/dates';
import { haptics } from '@/lib/haptics';
import { colors, radius, spacing } from '@/theme';
import { Bo, Button, Card, TextField, TvzText } from '@/ui';

const TAKEN: TaakSoort[] = ['boodschappen', 'wandelen', 'vervoer', 'koken', 'gezelschap', 'anders'];

/**
 * Kring opbouwen in zes stappen met Bo (handoff §3e). Elke stap is één vraag,
 * met een tip van Bo erboven en de voortgang in het kruimelspoor. De
 * antwoorden gaan na elke stap naar het concept, zodat je kunt stoppen en
 * later verder kunt. Stap 6 is de proefweek: Bo zet een voorstel-rooster
 * klaar dat de kring een week uitprobeert.
 */
export default function KringOpbouwen() {
  const concept = useKringConcept();

  // Wachten tot we weten of er al een concept ligt; de wizard start daarna
  // met die waarden en werkt vanaf dat moment op eigen schermstaat.
  if (concept.isLoading) {
    return (
      <View style={styles.safe}>
        <PadHeader
          pad="regelen"
          actiefRoute="/regelen/kring"
          kruimels={[t('kringopbouw.kruimel')]}
        />
      </View>
    );
  }
  return (
    <Wizard beginStap={concept.data?.stap ?? 1} beginAntwoorden={concept.data?.antwoorden ?? {}} />
  );
}

function Wizard({
  beginStap,
  beginAntwoorden,
}: {
  beginStap: number;
  beginAntwoorden: KringAntwoorden;
}) {
  const bewaar = useBewaarKringConcept();
  const wis = useWisKringConcept();
  const maakKring = useCreateCircle();
  const koppelNaaste = useKoppelNaaste();
  const maakTaak = useCreateTask(undefined);
  const [stap, setStap] = useState(beginStap);
  const [antwoorden, setAntwoorden] = useState<KringAntwoorden>(beginAntwoorden);

  function zet(velden: Partial<KringAntwoorden>) {
    setAntwoorden((vorige) => ({ ...vorige, ...velden }));
  }

  function toggle<T>(lijst: T[] | undefined, waarde: T): T[] {
    const huidig = lijst ?? [];
    return huidig.includes(waarde) ? huidig.filter((item) => item !== waarde) : [...huidig, waarde];
  }

  function verder() {
    void haptics.tik();
    const volgende = Math.min(stap + 1, KRINGOPBOUW_STAPPEN);
    setStap(volgende);
    bewaar.mutate({ stap: volgende, antwoorden });
  }

  function vorige() {
    void haptics.tik();
    setStap((huidig) => Math.max(1, huidig - 1));
  }

  /**
   * De kring aanmaken. Eén eerste taak is optioneel: soms weet je al wat er
   * moet gebeuren, vaak nog niet. Zonder taak is de kring net zo goed af
   * (wens Jelle 11-08).
   */
  async function afronden(metTaak: boolean) {
    const naam = antwoorden.naam?.trim();
    if (!naam || maakKring.isPending) return;
    void haptics.voltooid();
    const kring = await maakKring.mutateAsync(
      t('kringopbouw.kringnaam', { naam: naam.split(' ')[0]! }),
    );

    if (metTaak && antwoorden.eersteTaak) {
      const morgen = new Date();
      morgen.setDate(morgen.getDate() + 1);
      await maakTaak
        .mutateAsync({
          circleId: kring.id,
          type: antwoorden.eersteTaak,
          date: toDateString(morgen),
          time: '10:00',
          recurrence: 'eenmalig',
        })
        .catch(() => {});
    }

    // De code is optioneel: heeft de naaste de app nog niet, dan koppelt de
    // beheerder hem later vanaf de kringpagina.
    const code = antwoorden.code?.trim();
    if (code) {
      await koppelNaaste.mutateAsync({ circleId: kring.id, code }).catch(() => {});
    }

    wis.mutate();
    router.replace('/regelen/planning');
  }

  const magVerder =
    stap === 1
      ? !!antwoorden.naam?.trim()
      : stap === 3
        ? (antwoorden.taken ?? []).length > 0
        : true;

  return (
    <View style={styles.safe}>
      <PadHeader
        pad="regelen"
        actiefRoute="/regelen/kring"
        kruimels={[
          t('kringopbouw.kruimel'),
          t('kringopbouw.stapVan', { stap, totaal: KRINGOPBOUW_STAPPEN }),
        ]}
      />

      <KeyboardAvoidingView
        style={styles.fill}
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      >
        <ScrollView
          contentContainerStyle={styles.inhoud}
          keyboardShouldPersistTaps="handled"
          keyboardDismissMode="interactive"
        >
          <View style={styles.tip}>
            <Bo width={54} />
            <TvzText preset="body" style={styles.tipTekst}>
              {t(`kringopbouw.tip${stap}`)}
            </TvzText>
          </View>

          <TvzText preset="screenTitle">
            {t(`kringopbouw.titel${stap}`, {
              naam: antwoorden.naam?.split(' ')[0] ?? t('kringopbouw.diegene'),
            })}
          </TvzText>

          {stap === 1 ? (
            <Card style={styles.kaart}>
              <TextField
                label={t('kringopbouw.naamLabel')}
                value={antwoorden.naam ?? ''}
                onChangeText={(naam) => zet({ naam })}
                placeholder={t('kringopbouw.naamPlaceholder')}
              />
              <TextField
                label={t('kringopbouw.relatieLabel')}
                value={antwoorden.relatie ?? ''}
                onChangeText={(relatie) => zet({ relatie })}
                placeholder={t('kringopbouw.relatiePlaceholder')}
              />
            </Card>
          ) : null}

          {stap === 2 ? (
            <Card style={styles.kaart}>
              <AdresVeld
                label={t('kringopbouw.adresLabel')}
                waarde={antwoorden.adres ?? ''}
                onChange={(adres) => zet({ adres })}
                placeholder={t('kringopbouw.adresPlaceholder')}
              />
              <View style={styles.privacy}>
                <TvzText preset="secondary">{t('kringopbouw.privacy')}</TvzText>
              </View>
            </Card>
          ) : null}

          {stap === 3 ? (
            <>
              <View style={styles.raster}>
                {TAKEN.map((taak) => {
                  const aan = (antwoorden.taken ?? []).includes(taak);
                  return (
                    <Pressable
                      key={taak}
                      accessibilityRole="checkbox"
                      accessibilityState={{ checked: aan }}
                      accessibilityLabel={taakSoortLabel(taak)}
                      onPress={() => {
                        void haptics.selectie();
                        zet({ taken: toggle(antwoorden.taken, taak) });
                      }}
                      style={[styles.blokje, aan && styles.blokjeAan]}
                    >
                      <TvzText preset="cardTitle">{taakSoortLabel(taak)}</TvzText>
                    </Pressable>
                  );
                })}
              </View>
              {(antwoorden.taken ?? []).includes('anders') ? (
                <Card style={styles.kaart}>
                  <TvzText preset="cardTitle">{t('kringopbouw.andersTitel')}</TvzText>
                  <TvzText preset="secondary">{t('kringopbouw.andersUitleg')}</TvzText>
                  <TextInput
                    value={antwoorden.andereTaken ?? ''}
                    onChangeText={(andereTaken) => zet({ andereTaken })}
                    placeholder={t('kringopbouw.andersPlaceholder')}
                    placeholderTextColor={colors.inkFaint}
                    multiline
                    style={styles.vrijVeld}
                  />
                </Card>
              ) : null}
            </>
          ) : null}

          {stap === 4 ? (
            <Card style={styles.kaart}>
              <TvzText preset="secondary">{t('kringopbouw.goedOmTeWetenUitleg')}</TvzText>
              <TextInput
                value={antwoorden.goedOmTeWeten ?? ''}
                onChangeText={(goedOmTeWeten) => zet({ goedOmTeWeten })}
                placeholder={t('kringopbouw.goedOmTeWetenPlaceholder')}
                placeholderTextColor={colors.inkFaint}
                multiline
                style={styles.vrijVeld}
              />
            </Card>
          ) : null}

          {stap === 5 ? (
            <>
              <Card style={styles.kaart}>
                <TvzText preset="cardTitle">
                  {t('mijnCode.koppelTitel', {
                    naam: antwoorden.naam?.split(' ')[0] ?? t('kringopbouw.diegene'),
                  })}
                </TvzText>
                <TvzText preset="secondary">{t('mijnCode.koppelUitleg')}</TvzText>
                <TextField
                  label={t('mijnCode.koppelLabel')}
                  value={antwoorden.code ?? ''}
                  onChangeText={(code) => zet({ code: code.toUpperCase() })}
                  placeholder="TVZ-XXXX"
                  autoCapitalize="characters"
                  autoCorrect={false}
                />
                <TvzText preset="meta" style={styles.codeTip}>
                  {t('mijnCode.koppelLater')}
                </TvzText>
              </Card>
              <Card style={styles.kaart}>
              <TvzText preset="body">{t('kringopbouw.uitnodigenUitleg')}</TvzText>
              <Button
                label={t('kring.uitnodigen')}
                variant="outline"
                onPress={() => router.push('/uitnodigen')}
              />
              <Button
                label={t('kring.boZoektBuddy')}
                variant="outline"
                onPress={() => router.push('/regelen/buddy-zoeken')}
              />
              </Card>
            </>
          ) : null}

          {stap === 6 ? (
            <EersteTaak
              gekozen={antwoorden.eersteTaak}
              onKies={(eersteTaak) => zet({ eersteTaak })}
              bezig={maakKring.isPending}
              onKlaar={afronden}
            />
          ) : null}

        </ScrollView>

        <View style={styles.balk}>
          {stap > 1 ? (
            <Button
              label={t('algemeen.terug')}
              variant="outline"
              style={styles.balkKnop}
              onPress={vorige}
            />
          ) : null}
          {stap < KRINGOPBOUW_STAPPEN ? (
            <Button
              label={t('algemeen.volgende')}
              variant="cta"
              size="lg"
              disabled={!magVerder}
              style={styles.balkKnop}
              onPress={verder}
            />
          ) : null}
        </View>
      </KeyboardAvoidingView>
    </View>
  );
}

/**
 * Stap 6: hoogstens één eerste taak. Geen voorgesteld rooster meer: dat vulde
 * de week met dingen die niemand had gevraagd (feedback Jelle 11-08). Weet je
 * al wat er morgen moet gebeuren, zet het erin; zo niet, dan ga je gewoon
 * door en plan je later vanuit de planning.
 */
function EersteTaak({
  gekozen,
  onKies,
  bezig,
  onKlaar,
}: {
  gekozen?: TaakSoort;
  onKies: (taak: TaakSoort | undefined) => void;
  bezig: boolean;
  onKlaar: (metTaak: boolean) => void;
}) {
  return (
    <>
      <View style={styles.raster}>
        {TAKEN.map((taak) => {
          const aan = gekozen === taak;
          return (
            <Pressable
              key={taak}
              accessibilityRole="radio"
              accessibilityState={{ selected: aan }}
              accessibilityLabel={taakSoortLabel(taak)}
              onPress={() => {
                void haptics.selectie();
                onKies(aan ? undefined : taak);
              }}
              style={[styles.blokje, aan && styles.blokjeAan]}
            >
              <TvzText preset="cardTitle">{taakSoortLabel(taak)}</TvzText>
            </Pressable>
          );
        })}
      </View>

      <TvzText preset="secondary" style={styles.eersteTaakUitleg}>
        {gekozen ? t('kringopbouw.eersteTaakWanneer') : t('kringopbouw.eersteTaakUitleg')}
      </TvzText>

      <Button
        label={t('kringopbouw.kringAanmaken')}
        variant="cta"
        size="lg"
        disabled={bezig || !gekozen}
        onPress={() => onKlaar(true)}
      />
      <Button
        label={t('kringopbouw.zonderTaak')}
        variant="outline"
        disabled={bezig}
        onPress={() => onKlaar(false)}
      />
    </>
  );
}
const styles = StyleSheet.create({
  codeTip: {
    color: colors.inkFaint,
  },
  fill: {
    flex: 1,
  },
  safe: {
    flex: 1,
    backgroundColor: colors.bg,
  },
  inhoud: {
    padding: spacing.screen,
    gap: spacing.md,
    paddingBottom: spacing.xxl,
  },
  tip: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
    backgroundColor: colors.successBg,
    borderRadius: radius.card,
    padding: spacing.md,
  },
  tipTekst: {
    flex: 1,
  },
  kaart: {
    gap: spacing.md,
  },
  privacy: {
    backgroundColor: colors.tintBlue,
    borderRadius: radius.row,
    padding: spacing.md,
  },
  eersteTaakUitleg: {
    marginBottom: spacing.sm,
  },
  raster: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing.cardGap,
  },
  blokje: {
    flexGrow: 1,
    flexBasis: '46%',
    minHeight: 64,
    justifyContent: 'center',
    paddingHorizontal: spacing.lg,
    backgroundColor: colors.white,
    borderRadius: radius.card,
    borderWidth: 1.5,
    borderColor: colors.line,
  },
  blokjeAan: {
    borderColor: colors.accent,
    backgroundColor: colors.successBg,
  },
  pillenRij: {
    flexDirection: 'row',
    gap: spacing.chipGap,
  },
  pil: {
    borderRadius: radius.pill,
    paddingHorizontal: 16,
    minHeight: 40,
    justifyContent: 'center',
    backgroundColor: colors.surfaceAlt,
  },
  pilAan: {
    backgroundColor: colors.primary,
  },
  pilTekstAan: {
    color: colors.white,
  },
  blokKop: {
    marginTop: spacing.sm,
  },
  vrijVeld: {
    minHeight: 88,
    borderRadius: radius.input,
    borderWidth: 1,
    borderColor: colors.line,
    padding: spacing.md,
    textAlignVertical: 'top',
    color: colors.ink,
  },
  rooster: {
    gap: spacing.sm,
  },
  roosterRij: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: spacing.md,
    paddingVertical: spacing.sm,
    borderBottomWidth: 1,
    borderBottomColor: colors.line,
  },
  roosterTaak: {
    flex: 1,
  },
  balk: {
    flexDirection: 'row',
    gap: spacing.md,
    padding: spacing.screen,
    borderTopWidth: 1,
    borderTopColor: colors.line,
    backgroundColor: colors.white,
  },
  balkKnop: {
    flex: 1,
  },
});

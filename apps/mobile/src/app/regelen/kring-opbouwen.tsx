import { router } from 'expo-router';
import { useState } from 'react';
import { Pressable, ScrollView, StyleSheet, TextInput, View } from 'react-native';

import { useCreateCircle } from '@/features/circles/api';
import {
  KRINGOPBOUW_STAPPEN,
  useBewaarKringConcept,
  useKringConcept,
  useStartProefweek,
  useWisKringConcept,
  type Dagdeel,
  type KringAntwoorden,
  type TaakSoort,
} from '@/features/circles/kringopbouw';
import { voorstelRooster } from '@/features/circles/voorstelRooster';
import { PadHeader } from '@/features/navigatie/PadHeader';
import { taakSoortLabel } from '@/features/tasks/logic';
import { t } from '@/i18n';
import { formatHumanDate, formatTime } from '@/lib/dates';
import { haptics } from '@/lib/haptics';
import { colors, radius, spacing } from '@/theme';
import { Bo, Button, Card, TextField, TvzText } from '@/ui';

const TAKEN: TaakSoort[] = ['boodschappen', 'wandelen', 'vervoer', 'koken', 'gezelschap', 'anders'];
const DAGDELEN: Dagdeel[] = ['ochtend', 'middag', 'avond'];

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
        <PadHeader pad="regelen" actiefRoute="/regelen/kring" kruimels={[t('kringopbouw.kruimel')]} />
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
  const startProefweek = useStartProefweek();
  const [stap, setStap] = useState(beginStap);
  const [antwoorden, setAntwoorden] = useState<KringAntwoorden>(beginAntwoorden);

  function zet(velden: Partial<KringAntwoorden>) {
    setAntwoorden((vorige) => ({ ...vorige, ...velden }));
  }

  function toggle<T>(lijst: T[] | undefined, waarde: T): T[] {
    const huidig = lijst ?? [];
    return huidig.includes(waarde)
      ? huidig.filter((item) => item !== waarde)
      : [...huidig, waarde];
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

  const magVerder =
    stap === 1 ? !!antwoorden.naam?.trim() : stap === 3 ? (antwoorden.taken ?? []).length > 0 : true;

  return (
    <View style={styles.safe}>
      <PadHeader
        pad="regelen"
        actiefRoute="/regelen/kring"
        kruimels={[t('kringopbouw.kruimel'), t('kringopbouw.stapVan', { stap, totaal: KRINGOPBOUW_STAPPEN })]}
        terug={false}
      />

      <ScrollView contentContainerStyle={styles.inhoud} keyboardShouldPersistTaps="handled">
        <View style={styles.tip}>
          <Bo width={54} />
          <TvzText preset="body" style={styles.tipTekst}>
            {t(`kringopbouw.tip${stap}`)}
          </TvzText>
        </View>

        <TvzText preset="screenTitle">{t(`kringopbouw.titel${stap}`, { naam: antwoorden.naam?.split(' ')[0] ?? t('kringopbouw.diegene') })}</TvzText>

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
            <TextField
              label={t('kringopbouw.adresLabel')}
              value={antwoorden.adres ?? ''}
              onChangeText={(adres) => zet({ adres })}
              placeholder={t('kringopbouw.adresPlaceholder')}
            />
            <TextField
              label={t('kringopbouw.thuisLabel')}
              value={antwoorden.thuissituatie ?? ''}
              onChangeText={(thuissituatie) => zet({ thuissituatie })}
              placeholder={t('kringopbouw.thuisPlaceholder')}
            />
            <View style={styles.privacy}>
              <TvzText preset="secondary">{t('kringopbouw.privacy')}</TvzText>
            </View>
          </Card>
        ) : null}

        {stap === 3 ? (
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
        ) : null}

        {stap === 4 ? (
          <Card style={styles.kaart}>
            <TvzText preset="cardTitle">{t('kringopbouw.dagdelen')}</TvzText>
            <View style={styles.pillenRij}>
              {DAGDELEN.map((dagdeel) => {
                const aan = (antwoorden.dagdelen ?? []).includes(dagdeel);
                return (
                  <Pressable
                    key={dagdeel}
                    accessibilityRole="checkbox"
                    accessibilityState={{ checked: aan }}
                    accessibilityLabel={t(`kringopbouw.dagdeel${dagdeel}`)}
                    onPress={() => {
                      void haptics.selectie();
                      zet({ dagdelen: toggle(antwoorden.dagdelen, dagdeel) });
                    }}
                    style={[styles.pil, aan && styles.pilAan]}
                  >
                    <TvzText preset="meta" style={aan ? styles.pilTekstAan : undefined}>
                      {t(`kringopbouw.dagdeel${dagdeel}`)}
                    </TvzText>
                  </Pressable>
                );
              })}
            </View>
            <TvzText preset="cardTitle" style={styles.blokKop}>
              {t('kringopbouw.goedOmTeWeten')}
            </TvzText>
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
              onPress={() => router.push('/buurt')}
            />
          </Card>
        ) : null}

        {stap === 6 ? (
          <Proefweek
            antwoorden={antwoorden}
            bezig={maakKring.isPending || startProefweek.isPending}
            onStart={async (rooster) => {
              const naam = antwoorden.naam?.trim();
              if (!naam) return;
              void haptics.voltooid();
              const kring = await maakKring.mutateAsync(
                t('kringopbouw.kringnaam', { naam: naam.split(' ')[0]! }),
              );
              await startProefweek.mutateAsync({ circleId: kring.id, taken: rooster });
              wis.mutate();
              router.replace('/regelen/planning');
            }}
          />
        ) : null}
      </ScrollView>

      <View style={styles.balk}>
        {stap > 1 ? (
          <Button label={t('algemeen.terug')} variant="outline" style={styles.balkKnop} onPress={vorige} />
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
    </View>
  );
}

/**
 * Stap 6: het voorstel van Bo, zodat je ziet wat je start voordat je start.
 * De taken gaan als concept naar de kring en worden pas echt zichtbaar als
 * de proefweek begint.
 */
function Proefweek({
  antwoorden,
  bezig,
  onStart,
}: {
  antwoorden: KringAntwoorden;
  bezig: boolean;
  onStart: (rooster: ReturnType<typeof voorstelRooster>) => void;
}) {
  const rooster = voorstelRooster(antwoorden, new Date());

  return (
    <Card style={styles.kaart}>
      <TvzText preset="body">{t('kringopbouw.proefweekUitleg')}</TvzText>
      <View style={styles.rooster}>
        {rooster.map((taak) => (
          <View key={`${taak.type}-${taak.date}`} style={styles.roosterRij}>
            <TvzText preset="cardTitle" style={styles.roosterTaak}>
              {taakSoortLabel(taak.type)}
            </TvzText>
            <TvzText preset="secondary">
              {formatHumanDate(new Date(taak.date))} · {formatTime(taak.time)}
            </TvzText>
          </View>
        ))}
      </View>
      <Button
        label={t('kringopbouw.startProefweek')}
        variant="cta"
        size="lg"
        disabled={bezig || rooster.length === 0}
        onPress={() => onStart(rooster)}
      />
    </Card>
  );
}

const styles = StyleSheet.create({
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

import { useState } from 'react';
import { Pressable, ScrollView, StyleSheet, View } from 'react-native';
import { ChevronLeft, ChevronRight, X } from 'lucide-react-native';

import {
  blokLabel,
  dagLabel,
  geldigBlok,
  periodeLabel,
  ritmeVoorDag,
  schuifDag,
  WEEKDAGEN,
} from '@/features/aanbieder/agenda';
import {
  useAfwezigheid,
  useMeldAfwezig,
  useMijnAanbieder,
  useSluitDag,
  useVerwijderAfwezig,
  useWerkritme,
  useZetDag,
} from '@/features/aanbieder/api';
import { TijdPicker } from '@/features/tasks/TijdPicker';
import { t } from '@/i18n';
import { formatTime, toDateString } from '@/lib/dates';
import { haptics } from '@/lib/haptics';
import { colors, hitTarget, radius, spacing } from '@/theme';
import { BottomSheet, Button, Card, EmptyState, SectionHeader, Toggle, TvzText } from '@/ui';

/** Standaardtijden voor een dag die net opengaat. */
const STANDAARD_START = '09:00';
const STANDAARD_EIND = '17:00';

/**
 * Beschikbaarheid van de aanbieder: het vaste werkritme (één blok per
 * weekdag) en "ik ben er even niet"-periodes. De boekbare tijdsloten op de
 * dienstpagina volgen hier automatisch uit; geboekte afspraken gaan er
 * server-side vanaf.
 */
export function BeschikbaarheidScherm() {
  const aanbieder = useMijnAanbieder();
  const providerId = aanbieder.data?.id;
  const ritme = useWerkritme(providerId);
  const afwezig = useAfwezigheid(providerId);
  const zetDag = useZetDag(providerId);
  const sluitDag = useSluitDag(providerId);
  const meldAfwezig = useMeldAfwezig(providerId);
  const verwijderAfwezig = useVerwijderAfwezig(providerId);

  // Sheet voor de tijden van één dag.
  const [tijdenDag, setTijdenDag] = useState<number | null>(null);
  const [start, setStart] = useState(STANDAARD_START);
  const [eind, setEind] = useState(STANDAARD_EIND);

  // Sheet voor een nieuwe afwezigheidsperiode.
  const [afwezigOpen, setAfwezigOpen] = useState(false);
  const morgen = schuifDag(toDateString(new Date()), 1);
  const [afwezigVan, setAfwezigVan] = useState(morgen);
  const [afwezigTot, setAfwezigTot] = useState(morgen);

  if (aanbieder.isSuccess && aanbieder.data === null) {
    return (
      <EmptyState
        title={t('aanbieder.geenKoppeling')}
        body={t('aanbieder.geenKoppelingUitleg')}
      />
    );
  }

  const dagInfo = WEEKDAGEN.find((dag) => dag.weekday === tijdenDag);
  const tijdenGeldig = geldigBlok(start, eind);

  function openTijden(weekday: number) {
    const rij = ritmeVoorDag(ritme.data ?? [], weekday);
    setStart(rij ? formatTime(rij.start_time) : STANDAARD_START);
    setEind(rij ? formatTime(rij.end_time) : STANDAARD_EIND);
    setTijdenDag(weekday);
  }

  function bewaarTijden() {
    if (tijdenDag === null || !tijdenGeldig || zetDag.isPending) return;
    zetDag.mutate(
      { weekday: tijdenDag, start, eind },
      { onSuccess: () => setTijdenDag(null) },
    );
  }

  function openAfwezig() {
    setAfwezigVan(morgen);
    setAfwezigTot(morgen);
    setAfwezigOpen(true);
  }

  function bewaarAfwezig() {
    if (meldAfwezig.isPending) return;
    meldAfwezig.mutate(
      { start: afwezigVan, eind: afwezigTot },
      { onSuccess: () => setAfwezigOpen(false) },
    );
  }

  return (
    <ScrollView contentContainerStyle={styles.scroll}>
      <SectionHeader title={t('aanbieder.ritmeTitel')} />
      <TvzText preset="secondary" style={styles.uitleg}>
        {t('aanbieder.ritmeUitleg')}
      </TvzText>
      <Card style={styles.kaart}>
        {WEEKDAGEN.map((dag, index) => {
          const rij = ritmeVoorDag(ritme.data ?? [], dag.weekday);
          return (
            <View key={dag.weekday} style={[styles.dagRij, index > 0 && styles.rijLijn]}>
              <Toggle
                value={!!rij}
                accessibilityLabel={dag.vol}
                onValueChange={(open) => {
                  if (open) zetDag.mutate({ weekday: dag.weekday, start: STANDAARD_START, eind: STANDAARD_EIND });
                  else sluitDag.mutate(dag.weekday);
                }}
              />
              <TvzText preset="body" style={styles.dagNaam}>
                {dag.vol}
              </TvzText>
              {rij ? (
                <Pressable
                  accessibilityRole="button"
                  accessibilityLabel={`${dag.vol}, ${blokLabel(rij)}`}
                  onPress={() => openTijden(dag.weekday)}
                  style={styles.tijdKnop}
                >
                  <TvzText preset="body" style={styles.tijdTekst}>
                    {blokLabel(rij)}
                  </TvzText>
                </Pressable>
              ) : (
                <TvzText preset="secondary" style={styles.geslotenTekst}>
                  {t('aanbieder.gesloten')}
                </TvzText>
              )}
            </View>
          );
        })}
      </Card>

      <View style={styles.afwezigKop}>
        <SectionHeader title={t('aanbieder.afwezigTitel')} />
      </View>
      <TvzText preset="secondary" style={styles.uitleg}>
        {t('aanbieder.afwezigUitleg')}
      </TvzText>
      <Card style={styles.kaart}>
        {(afwezig.data ?? []).length === 0 ? (
          <TvzText preset="secondary" style={styles.afwezigLeeg}>
            {t('aanbieder.afwezigLeeg')}
          </TvzText>
        ) : (
          (afwezig.data ?? []).map((periode, index) => (
            <View key={periode.id} style={[styles.afwezigRij, index > 0 && styles.rijLijn]}>
              <TvzText preset="body" style={styles.afwezigTekst}>
                {periodeLabel(periode.start_date, periode.end_date)}
              </TvzText>
              <Pressable
                accessibilityRole="button"
                accessibilityLabel={t('aanbieder.afwezigVerwijder')}
                onPress={() => {
                  void haptics.tik();
                  verwijderAfwezig.mutate(periode.id);
                }}
                style={styles.verwijderKnop}
              >
                <X color={colors.inkSoft} size={18} strokeWidth={2.4} />
              </Pressable>
            </View>
          ))
        )}
      </Card>
      <Button
        label={t('aanbieder.afwezigKnop')}
        variant="outline"
        style={styles.afwezigActie}
        onPress={openAfwezig}
      />

      {/* Tijden van één dag aanpassen */}
      <BottomSheet
        visible={tijdenDag !== null}
        onClose={() => setTijdenDag(null)}
        title={dagInfo?.vol}
      >
        <TvzText preset="secondary" style={styles.sheetLabel}>
          {t('aanbieder.van')}
        </TvzText>
        <TijdPicker waarde={start} onChange={setStart} />
        <TvzText preset="secondary" style={styles.sheetLabel}>
          {t('aanbieder.tot')}
        </TvzText>
        <TijdPicker waarde={eind} onChange={setEind} />
        {!tijdenGeldig ? (
          <TvzText preset="secondary" style={styles.foutTekst}>
            {t('aanbieder.tijdFout')}
          </TvzText>
        ) : null}
        <Button
          label={zetDag.isPending ? t('algemeen.laden') : t('aanbieder.opslaan')}
          variant="cta"
          size="lg"
          disabled={!tijdenGeldig || zetDag.isPending}
          style={styles.sheetKnop}
          onPress={bewaarTijden}
        />
      </BottomSheet>

      {/* Nieuwe afwezigheidsperiode */}
      <BottomSheet
        visible={afwezigOpen}
        onClose={() => setAfwezigOpen(false)}
        title={t('aanbieder.afwezigKnop')}
      >
        <DatumStepper
          label={t('aanbieder.van')}
          waarde={afwezigVan}
          minimum={toDateString(new Date())}
          onChange={(datum) => {
            setAfwezigVan(datum);
            if (datum > afwezigTot) setAfwezigTot(datum);
          }}
        />
        <DatumStepper
          label={t('aanbieder.totEnMet')}
          waarde={afwezigTot}
          minimum={afwezigVan}
          onChange={setAfwezigTot}
        />
        <Button
          label={meldAfwezig.isPending ? t('algemeen.laden') : t('aanbieder.opslaan')}
          variant="cta"
          size="lg"
          disabled={meldAfwezig.isPending}
          style={styles.sheetKnop}
          onPress={bewaarAfwezig}
        />
      </BottomSheet>
    </ScrollView>
  );
}

/** Datum kiezen zonder kalender: één rij met pijltjes, per dag. */
function DatumStepper({
  label,
  waarde,
  minimum,
  onChange,
}: {
  label: string;
  waarde: string;
  /** yyyy-mm-dd; eerder dan dit kan niet. */
  minimum: string;
  onChange: (datum: string) => void;
}) {
  const kanTerug = schuifDag(waarde, -1) >= minimum;
  return (
    <View style={styles.stepperBlok}>
      <TvzText preset="secondary">{label}</TvzText>
      <View style={styles.stepperRij}>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={`${label}: dag eerder`}
          disabled={!kanTerug}
          onPress={() => {
            void haptics.tik();
            onChange(schuifDag(waarde, -1));
          }}
          style={[styles.stepperKnop, !kanTerug && styles.stepperKnopUit]}
        >
          <ChevronLeft color={kanTerug ? colors.primaryMid : colors.inkFaint} size={22} strokeWidth={2.4} />
        </Pressable>
        <TvzText preset="cardTitle" style={styles.stepperDatum}>
          {dagLabel(waarde)}
        </TvzText>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={`${label}: dag later`}
          onPress={() => {
            void haptics.tik();
            onChange(schuifDag(waarde, 1));
          }}
          style={styles.stepperKnop}
        >
          <ChevronRight color={colors.primaryMid} size={22} strokeWidth={2.4} />
        </Pressable>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  scroll: {
    padding: spacing.screen,
    paddingBottom: spacing.xxl,
  },
  uitleg: {
    marginTop: spacing.xs,
  },
  kaart: {
    marginTop: spacing.md,
    paddingVertical: spacing.xs,
  },
  dagRij: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
    minHeight: 54,
  },
  rijLijn: {
    borderTopWidth: 1,
    borderTopColor: colors.line,
  },
  dagNaam: {
    flex: 1,
  },
  tijdKnop: {
    minHeight: hitTarget.min,
    justifyContent: 'center',
    paddingHorizontal: spacing.sm,
    borderRadius: radius.row,
    backgroundColor: colors.surfaceAlt,
  },
  tijdTekst: {
    color: colors.primaryDark,
  },
  geslotenTekst: {
    paddingHorizontal: spacing.sm,
  },
  afwezigKop: {
    marginTop: spacing.xl,
  },
  afwezigLeeg: {
    paddingVertical: spacing.sm,
  },
  afwezigRij: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
    minHeight: 50,
  },
  afwezigTekst: {
    flex: 1,
  },
  verwijderKnop: {
    width: hitTarget.min,
    height: hitTarget.min,
    alignItems: 'center',
    justifyContent: 'center',
  },
  afwezigActie: {
    marginTop: spacing.md,
    alignSelf: 'flex-start',
  },
  sheetLabel: {
    marginTop: spacing.md,
    marginBottom: spacing.xs,
  },
  foutTekst: {
    color: colors.error,
    marginTop: spacing.sm,
  },
  sheetKnop: {
    marginTop: spacing.lg,
  },
  stepperBlok: {
    marginTop: spacing.md,
  },
  stepperRij: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
    marginTop: spacing.xs,
  },
  stepperKnop: {
    width: hitTarget.min,
    height: hitTarget.min,
    borderRadius: radius.row,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.surfaceAlt,
  },
  stepperKnopUit: {
    opacity: 0.5,
  },
  stepperDatum: {
    flex: 1,
    textAlign: 'center',
  },
});

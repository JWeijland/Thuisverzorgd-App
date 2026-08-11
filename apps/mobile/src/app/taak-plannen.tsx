import { router } from 'expo-router';
import { ChevronLeft, ChevronRight, X } from 'lucide-react-native';
import { useState } from 'react';
import { Pressable, ScrollView, StyleSheet, TextInput, View } from 'react-native';

import { ProfileAvatar } from '@/features/avatars/ProfileAvatar';
import { useCircleMembers, useMyCircle } from '@/features/circles/api';
import { PadHeader } from '@/features/navigatie/PadHeader';
import { useCreateTask, type NewTask, type Task } from '@/features/tasks/api';
import { taakSoortLabel } from '@/features/tasks/logic';
import { TijdPicker } from '@/features/tasks/TijdPicker';
import { t } from '@/i18n';
import { WEEKDAY_SHORT, formatHumanDate, isoWeekDays, toDateString } from '@/lib/dates';
import { haptics } from '@/lib/haptics';
import { colors, hitTarget, radius, spacing } from '@/theme';
import { Card, EmptyState, TvzText } from '@/ui';
import { KeuzeRij } from '@/ui/KeuzeRij';
import { Button } from '@/ui/Button';

const TYPES: Task['type'][] = [
  'boodschappen',
  'wandelen',
  'vervoer',
  'koken',
  'gezelschap',
  'anders',
];

const SNELKEUZES = [
  { labelKey: 'planner.ochtend', tijd: '09:00' },
  { labelKey: 'planner.middag', tijd: '14:00' },
  { labelKey: 'planner.avond', tijd: '19:00' },
] as const;

const HERHALINGEN: Task['recurrence'][] = ['eenmalig', 'wekelijks', 'tweewekelijks'];

/**
 * Taak inplannen (handoff, scherm 06). Eén doorlopende pagina in plaats van
 * de oude drie-staps-wizard: wat, wanneer, hoe laat, herhaling en wie, met
 * onderaan een vaste balk die samenvat wat je zo inplant.
 */
export default function TaakPlannen() {
  const circle = useMyCircle();
  const leden = useCircleMembers(circle.data?.id);
  const maakTaak = useCreateTask(circle.data?.id);

  const [weekOffset, setWeekOffset] = useState(0);
  const [type, setType] = useState<Task['type']>('boodschappen');
  const [eigenLabel, setEigenLabel] = useState('');
  const [dagIndex, setDagIndex] = useState(() => Math.min((new Date().getDay() + 6) % 7, 6));
  const [tijd, setTijd] = useState('10:00');
  const [herhaling, setHerhaling] = useState<Task['recurrence']>('eenmalig');
  const [wie, setWie] = useState<string | null>(null);

  const anker = new Date();
  anker.setDate(anker.getDate() + weekOffset * 7);
  const dagen = isoWeekDays(anker);
  const dag = dagen[dagIndex]!;

  const hulpvrager = (leden.data ?? []).find((lid) => lid.member_role === 'hulpvrager');
  const buddys = (leden.data ?? []).filter((lid) => lid.member_role === 'vrijwilliger');
  const magOpslaan =
    !!circle.data && !maakTaak.isPending && (type !== 'anders' || eigenLabel.trim().length > 0);

  const samenvatting = `${type === 'anders' && eigenLabel.trim() ? eigenLabel.trim() : taakSoortLabel(type)} · ${formatHumanDate(dag)} · ${tijd}`;

  function opslaan() {
    if (!magOpslaan) return;
    void haptics.voltooid();
    const taak: NewTask = {
      type,
      custom_label: type === 'anders' ? eigenLabel.trim() || null : null,
      date: toDateString(dag),
      time: tijd,
      recurrence: herhaling,
    };
    maakTaak.mutate(wie ? { ...taak, claimed_by: wie, status: 'ingepland' } : taak, {
      onSuccess: () => router.replace(`/regelen/planning?ingepland=${toDateString(dag)}` as never),
    });
  }

  // Een taak inplannen kan alleen binnen een kring: zonder kring is er
  // niemand om hem aan te bieden. Dan is spontane hulp de weg (feedback
  // Jelle 11-08): je vraag komt op de kaart en een vrijwilliger uit de buurt
  // pakt hem op, ook zonder kring.
  if (!circle.isLoading && !circle.data) {
    return (
      <View style={styles.safe}>
        <PadHeader pad="regelen" actiefRoute="/regelen/planning" kruimels={[t('planner.titel')]} />
        <View style={styles.leeg}>
          <Card style={styles.leegKaart}>
            <EmptyState title={t('planner.geenKringTitel')} body={t('planner.geenKringTekst')} bo />
            <Button
              label={t('planner.vraagSpontaan')}
              variant="cta"
              size="lg"
              onPress={() => router.replace('/buurt?hulpvraag=1' as never)}
            />
            <Button
              label={t('planner.maakKring')}
              variant="outline"
              onPress={() => router.replace('/regelen/kring')}
            />
          </Card>
        </View>
      </View>
    );
  }

  return (
    <View style={styles.safe}>
      <PadHeader
        pad="regelen"
        actiefRoute="/regelen/planning"
        kruimels={[t('planner.titel')]}
        verbergSchuifjes
      />

      <View style={styles.voorRij}>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={t('algemeen.sluiten')}
          onPress={() => router.back()}
          style={styles.sluit}
        >
          <X color={colors.inkSoft} size={18} strokeWidth={2.4} />
        </Pressable>
        <TvzText preset="secondary" numberOfLines={1} style={styles.voorTekst}>
          {hulpvrager?.profile?.name
            ? t('planner.voorDeKring', { naam: hulpvrager.profile.name.split(' ')[0]! })
            : (circle.data?.name ?? '')}
        </TvzText>
      </View>

      <ScrollView contentContainerStyle={styles.inhoud} keyboardShouldPersistTaps="handled">
        <TvzText preset="meta" style={styles.kop}>
          {t('planner.watNodig')}
        </TvzText>
        <View style={styles.raster}>
          {TYPES.map((optie) => {
            const aan = type === optie;
            return (
              <Pressable
                key={optie}
                accessibilityRole="radio"
                accessibilityState={{ selected: aan }}
                accessibilityLabel={taakSoortLabel(optie)}
                onPress={() => {
                  void haptics.selectie();
                  setType(optie);
                }}
                style={[styles.blokje, aan && styles.blokjeAan]}
              >
                <TvzText preset="cardTitle">{taakSoortLabel(optie)}</TvzText>
              </Pressable>
            );
          })}
        </View>
        {type === 'anders' ? (
          <TextInput
            value={eigenLabel}
            onChangeText={setEigenLabel}
            placeholder={t('planner.andersPlaceholder')}
            placeholderTextColor={colors.inkFaint}
            style={styles.vrijVeld}
          />
        ) : null}

        <View style={styles.kopRij}>
          <TvzText preset="meta" style={styles.kop}>
            {t('planner.welkeDag')}
          </TvzText>
          <View style={styles.pijlen}>
            <Pressable
              accessibilityRole="button"
              accessibilityLabel={t('planner.weekTerug')}
              onPress={() => setWeekOffset((vorig) => vorig - 1)}
              style={styles.pijl}
            >
              <ChevronLeft color={colors.ink} size={20} strokeWidth={2.4} />
            </Pressable>
            <Pressable
              accessibilityRole="button"
              accessibilityLabel={t('planner.weekVerder')}
              onPress={() => setWeekOffset((vorig) => vorig + 1)}
              style={styles.pijl}
            >
              <ChevronRight color={colors.ink} size={20} strokeWidth={2.4} />
            </Pressable>
          </View>
        </View>
        <View style={styles.dagBalk}>
          {dagen.map((datum, i) => {
            const aan = dagIndex === i;
            return (
              <Pressable
                key={datum.toISOString()}
                accessibilityRole="radio"
                accessibilityState={{ selected: aan }}
                accessibilityLabel={formatHumanDate(datum)}
                onPress={() => {
                  void haptics.selectie();
                  setDagIndex(i);
                }}
                style={[styles.dag, aan && styles.dagAan]}
              >
                <TvzText preset="meta" style={aan ? styles.dagTekstAan : styles.dagTekst}>
                  {WEEKDAY_SHORT[i]}
                </TvzText>
                <TvzText preset="cardTitle" style={aan ? styles.dagNrAan : undefined}>
                  {datum.getDate()}
                </TvzText>
              </Pressable>
            );
          })}
        </View>

        <TvzText preset="meta" style={styles.kop}>
          {t('planner.hoeLaat')}
        </TvzText>
        <TijdPicker waarde={tijd} onChange={setTijd} />
        <View style={styles.keuzes}>
          <KeuzeRij
            opties={SNELKEUZES.map((keuze) => ({
              waarde: keuze.tijd,
              label: `${t(keuze.labelKey)} ${keuze.tijd}`,
            }))}
            gekozen={tijd}
            onKies={setTijd}
          />
        </View>

        <TvzText preset="meta" style={styles.kop}>
          {t('planner.herhalen')}
        </TvzText>
        <View style={styles.keuzes}>
          <KeuzeRij
            opties={HERHALINGEN.map((optie) => ({
              waarde: optie,
              label: t(`planner.herhaling_${optie}`),
            }))}
            gekozen={herhaling}
            onKies={setHerhaling}
          />
        </View>

        <TvzText preset="meta" style={styles.kop}>
          {t('planner.wie')}
        </TvzText>
        <Pressable
          accessibilityRole="radio"
          accessibilityState={{ selected: wie === null }}
          onPress={() => {
            void haptics.selectie();
            setWie(null);
          }}
          style={[styles.wieRij, wie === null && styles.wieRijAan]}
        >
          <View style={styles.wieOpen}>
            <TvzText preset="cardTitle" style={styles.wieOpenTekst}>
              ?
            </TvzText>
          </View>
          <View style={styles.wieTekst}>
            <TvzText preset="cardTitle">{t('planner.wieKan')}</TvzText>
            <TvzText preset="secondary">{t('planner.wieKanUitleg')}</TvzText>
          </View>
        </Pressable>
        {buddys.map((lid) => (
          <Pressable
            key={lid.id}
            accessibilityRole="radio"
            accessibilityState={{ selected: wie === lid.profile_id }}
            accessibilityLabel={lid.profile?.name ?? ''}
            onPress={() => {
              void haptics.selectie();
              setWie(lid.profile_id);
            }}
            style={[styles.wieRij, wie === lid.profile_id && styles.wieRijAan]}
          >
            <ProfileAvatar
              name={lid.profile?.name ?? '?'}
              avatarPath={lid.profile?.avatar_path}
              size={40}
            />
            <View style={styles.wieTekst}>
              <TvzText preset="cardTitle">{lid.profile?.name ?? ''}</TvzText>
              <TvzText preset="secondary">{t('planner.wieVastUitleg')}</TvzText>
            </View>
          </Pressable>
        ))}
      </ScrollView>

      <View style={styles.balk}>
        <View style={styles.balkTekst}>
          <TvzText preset="cardTitle" numberOfLines={1}>
            {samenvatting}
          </TvzText>
          {herhaling !== 'eenmalig' ? (
            <TvzText preset="meta">
              {t(`planner.herhaling_${herhaling}`)} ·{' '}
              {wie ? t('planner.vastPersoon') : t('planner.openVoorKring')}
            </TvzText>
          ) : null}
        </View>
        <Button
          label={t('planner.zetInRooster')}
          variant="cta"
          size="lg"
          disabled={!magOpslaan}
          onPress={opslaan}
        />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: colors.bg,
  },
  leeg: {
    padding: spacing.screen,
  },
  leegKaart: {
    gap: spacing.md,
  },
  voorRij: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
    paddingHorizontal: spacing.screen,
    paddingVertical: spacing.md,
    backgroundColor: colors.white,
    borderBottomWidth: 1,
    borderBottomColor: colors.line,
  },
  sluit: {
    width: 32,
    height: 32,
    borderRadius: 16,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.surfaceAlt,
  },
  voorTekst: {
    flex: 1,
  },
  inhoud: {
    padding: spacing.screen,
    paddingBottom: spacing.xxl,
  },
  kop: {
    textTransform: 'uppercase',
    letterSpacing: 0.6,
    color: colors.inkFaint,
    marginBottom: spacing.sm,
    marginTop: spacing.lg,
  },
  kopRij: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  pijlen: {
    flexDirection: 'row',
    gap: spacing.sm,
    marginTop: spacing.lg,
    marginBottom: spacing.sm,
  },
  pijl: {
    width: hitTarget.min,
    height: hitTarget.min,
    borderRadius: hitTarget.min / 2,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.white,
    borderWidth: 1,
    borderColor: colors.line,
  },
  keuzes: {
    marginTop: spacing.xs,
  },
  raster: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing.cardGap,
  },
  blokje: {
    flexGrow: 1,
    flexBasis: '46%',
    minHeight: 58,
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
  vrijVeld: {
    marginTop: spacing.cardGap,
    minHeight: hitTarget.min,
    borderRadius: radius.input,
    borderWidth: 1,
    borderColor: colors.line,
    backgroundColor: colors.white,
    paddingHorizontal: spacing.md,
    color: colors.ink,
  },
  dagBalk: {
    flexDirection: 'row',
    gap: 6,
  },
  dag: {
    flex: 1,
    minHeight: 58,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 2,
    borderRadius: radius.row,
    backgroundColor: colors.white,
    borderWidth: 1,
    borderColor: colors.line,
  },
  dagAan: {
    backgroundColor: colors.primary,
    borderColor: colors.primary,
  },
  dagTekst: {
    color: colors.inkFaint,
  },
  dagTekstAan: {
    color: 'rgba(255,255,255,0.8)',
  },
  dagNrAan: {
    color: colors.white,
  },
  wieRij: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
    padding: spacing.md,
    marginBottom: spacing.cardGap,
    backgroundColor: colors.white,
    borderRadius: radius.card,
    borderWidth: 1.5,
    borderColor: colors.line,
  },
  wieRijAan: {
    borderColor: colors.accent,
    backgroundColor: colors.successBg,
  },
  wieOpen: {
    width: 40,
    height: 40,
    borderRadius: 20,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.surfaceAlt,
  },
  wieOpenTekst: {
    color: colors.inkSoft,
  },
  wieTekst: {
    flex: 1,
  },
  balk: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
    padding: spacing.screen,
    backgroundColor: colors.white,
    borderTopWidth: 1,
    borderTopColor: colors.line,
  },
  balkTekst: {
    flex: 1,
  },
});

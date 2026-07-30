import { router, useLocalSearchParams } from 'expo-router';
import * as WebBrowser from 'expo-web-browser';
import { useState } from 'react';
import { Pressable, ScrollView, StyleSheet, View } from 'react-native';
import { Check, PlayCircle } from 'lucide-react-native';

import {
  useCourse,
  useCourseActions,
  useCourseAnswers,
  useCourseGroups,
  useCourseModules,
  useCourseQuestions,
  type TestUitslag,
} from '@/features/learning/api';
import { GroepKaart } from '@/features/learning/OpleidingenLijst';
import { t } from '@/i18n';
import { colors, radius, spacing } from '@/theme';
import { Button, Card, GradientHeader, Pill, SectionHeader, TvzText } from '@/ui';

/**
 * Eén cursus: onderdelen met tekst en video, daarna de toets. De toets komt
 * vrij als je alle onderdelen hebt gelezen; nakijken gebeurt server-side.
 */
export default function OpleidingScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const course = useCourse(id);
  const modules = useCourseModules(id);
  const questions = useCourseQuestions(id);
  const groups = useCourseGroups(id);
  const { markRead, submitTest } = useCourseActions(id);

  const [open, setOpen] = useState<string | null>(null);
  const [gelezen, setGelezen] = useState<string[]>([]);
  const [antwoorden, setAntwoorden] = useState<Record<string, number>>({});
  const [uitslag, setUitslag] = useState<TestUitslag | null>(null);
  const answers = useCourseAnswers(id, !!uitslag);

  const moduleList = modules.data ?? [];
  const vragen = questions.data ?? [];
  // Lokaal bijhouden wat je net las, zodat de toets direct vrijkomt.
  const alGelezen = (moduleId: string) => gelezen.includes(moduleId);
  const aantalGelezen = Math.max(course?.gelezen ?? 0, gelezen.length);
  const allesGelezen = moduleList.length > 0 && aantalGelezen >= moduleList.length;
  const alleVragenBeantwoord = vragen.length > 0 && vragen.every((v) => antwoorden[v.id] != null);

  function openModule(moduleId: string) {
    const nieuwOpen = open === moduleId ? null : moduleId;
    setOpen(nieuwOpen);
    if (nieuwOpen && !alGelezen(moduleId)) {
      setGelezen((huidig) => [...huidig, moduleId]);
      markRead.mutate(moduleId);
    }
  }

  return (
    <View style={styles.safe}>
      <GradientHeader
        title={course?.title ?? t('opleiding.titel')}
        subtitle={course?.subtitle ?? undefined}
        wobbel
        right={
          <Pressable
            accessibilityRole="button"
            accessibilityLabel={t('algemeen.terug')}
            onPress={() => router.back()}
            style={styles.terug}
            hitSlop={8}
          >
            <TvzText preset="cardTitle" style={styles.terugText}>
              ✕
            </TvzText>
          </Pressable>
        }
      />

      <ScrollView contentContainerStyle={styles.list}>
        {course?.description ? (
          <Card>
            <TvzText preset="body">{course.description}</TvzText>
            <View style={styles.metaRij}>
              {course.topic ? <Pill label={course.topic} /> : null}
              <TvzText preset="meta" style={styles.meta}>
                {t('opleiding.duur', { minuten: course.duur_minuten })}
              </TvzText>
            </View>
          </Card>
        ) : null}

        <SectionHeader
          title={t('opleiding.onderdelen', {
            gelezen: Math.min(aantalGelezen, moduleList.length),
            totaal: moduleList.length,
          })}
        />
        {moduleList.map((module, index) => {
          const isOpen = open === module.id;
          const klaar = alGelezen(module.id) || (course?.gelezen ?? 0) > index;
          return (
            <Card key={module.id} style={styles.moduleKaart}>
              <Pressable
                accessibilityRole="button"
                accessibilityState={{ expanded: isOpen }}
                onPress={() => openModule(module.id)}
                style={styles.moduleKop}
              >
                <View style={[styles.moduleNr, klaar && styles.moduleNrKlaar]}>
                  {klaar ? (
                    <Check color={colors.white} size={14} strokeWidth={3} />
                  ) : (
                    <TvzText preset="meta" style={styles.moduleNrText}>
                      {index + 1}
                    </TvzText>
                  )}
                </View>
                <TvzText preset="cardTitle" style={styles.moduleTitel}>
                  {module.title}
                </TvzText>
                <TvzText preset="cardTitle" style={styles.chevron}>
                  {isOpen ? '⌃' : '⌄'}
                </TvzText>
              </Pressable>

              {isOpen ? (
                <View style={styles.moduleBody}>
                  {module.body ? <TvzText preset="body">{module.body}</TvzText> : null}
                  {module.video_url ? (
                    <Pressable
                      accessibilityRole="button"
                      onPress={() => WebBrowser.openBrowserAsync(module.video_url!)}
                      style={styles.videoKnop}
                    >
                      <PlayCircle color={colors.primary} size={22} strokeWidth={2.2} />
                      <TvzText preset="cardTitle" style={styles.videoLabel}>
                        {module.video_label ?? t('opleiding.bekijkVideo')}
                      </TvzText>
                    </Pressable>
                  ) : null}
                </View>
              ) : null}
            </Card>
          );
        })}

        {vragen.length > 0 ? (
          <>
            <SectionHeader title={t('opleiding.toetsTitel')} />
            {!allesGelezen ? (
              <Card dashed style={styles.slot}>
                <TvzText preset="secondary" style={styles.slotText}>
                  {t('opleiding.toetsSlot')}
                </TvzText>
              </Card>
            ) : (
              <>
                <TvzText preset="secondary" style={styles.toetsUitleg}>
                  {t('opleiding.toetsUitleg', { drempel: course?.drempel ?? 70 })}
                </TvzText>

                {vragen.map((vraag, vraagIndex) => {
                  const goedIndex = answers.data?.[vraag.id]?.correct;
                  const uitleg = answers.data?.[vraag.id]?.uitleg;
                  return (
                    <Card key={vraag.id} style={styles.vraagKaart}>
                      <TvzText preset="cardTitle" style={styles.vraagTitel}>
                        {vraagIndex + 1}. {vraag.question}
                      </TvzText>
                      {vraag.options.map((optie, optieIndex) => {
                        const gekozen = antwoorden[vraag.id] === optieIndex;
                        const isGoed = uitslag && goedIndex === optieIndex;
                        const isFoutGekozen = uitslag && gekozen && goedIndex !== optieIndex;
                        return (
                          <Pressable
                            key={optie}
                            accessibilityRole="radio"
                            accessibilityState={{ checked: gekozen }}
                            disabled={!!uitslag}
                            onPress={() =>
                              setAntwoorden((huidig) => ({ ...huidig, [vraag.id]: optieIndex }))
                            }
                            style={[
                              styles.optie,
                              gekozen && styles.optieGekozen,
                              isGoed && styles.optieGoed,
                              isFoutGekozen && styles.optieFout,
                            ]}
                          >
                            <View style={[styles.bolletje, gekozen && styles.bolletjeGekozen]} />
                            <TvzText preset="body" style={styles.optieText}>
                              {optie}
                            </TvzText>
                          </Pressable>
                        );
                      })}
                      {uitslag && uitleg ? (
                        <TvzText preset="secondary" style={styles.uitleg}>
                          {uitleg}
                        </TvzText>
                      ) : null}
                    </Card>
                  );
                })}

                {uitslag ? (
                  <Card style={uitslag.gehaald ? styles.uitslagGoed : styles.uitslagFout}>
                    <TvzText
                      preset="cardTitle"
                      style={uitslag.gehaald ? styles.uitslagGoedText : styles.uitslagFoutText}
                    >
                      {uitslag.gehaald
                        ? t('opleiding.gehaaldTitel', { score: uitslag.score })
                        : t('opleiding.nietGehaaldTitel', { score: uitslag.score })}
                    </TvzText>
                    <TvzText preset="secondary">
                      {uitslag.gehaald
                        ? t('opleiding.gehaaldTekst')
                        : t('opleiding.nietGehaaldTekst', { drempel: uitslag.drempel })}
                    </TvzText>
                    {!uitslag.gehaald ? (
                      <Button
                        label={t('opleiding.opnieuw')}
                        variant="primary"
                        style={styles.knop}
                        onPress={() => {
                          setUitslag(null);
                          setAntwoorden({});
                        }}
                      />
                    ) : null}
                  </Card>
                ) : (
                  <Button
                    label={t('opleiding.leverIn')}
                    variant="cta"
                    size="lg"
                    disabled={!alleVragenBeantwoord || submitTest.isPending}
                    style={styles.knop}
                    onPress={() => {
                      const reeks = vragen.map((vraag) => antwoorden[vraag.id] ?? -1);
                      submitTest.mutate(reeks, { onSuccess: setUitslag });
                    }}
                  />
                )}
              </>
            )}
          </>
        ) : null}

        {(groups.data ?? []).length > 0 ? (
          <>
            <SectionHeader title={t('opleiding.groepBijCursus')} />
            {(groups.data ?? []).map((groep) => (
              <GroepKaart key={groep.id} groep={groep} />
            ))}
          </>
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
  terug: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: 'rgba(255,255,255,0.18)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  terugText: {
    color: colors.white,
  },
  list: {
    padding: spacing.screen,
    paddingBottom: 60,
    gap: spacing.cardGap,
  },
  metaRij: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    marginTop: spacing.md,
  },
  meta: {
    color: colors.inkSoft,
  },
  moduleKaart: {
    paddingVertical: spacing.md,
  },
  moduleKop: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
    minHeight: 44,
  },
  moduleNr: {
    width: 26,
    height: 26,
    borderRadius: 13,
    backgroundColor: colors.surfaceAlt,
    alignItems: 'center',
    justifyContent: 'center',
  },
  moduleNrKlaar: {
    backgroundColor: colors.accentDark,
  },
  moduleNrText: {
    color: colors.primary,
  },
  moduleTitel: {
    flex: 1,
    fontSize: 15.5,
  },
  chevron: {
    color: colors.inkFaint,
  },
  moduleBody: {
    marginTop: spacing.md,
    gap: spacing.md,
  },
  videoKnop: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    backgroundColor: colors.tintBlue,
    borderRadius: radius.row,
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.md,
    minHeight: 48,
  },
  videoLabel: {
    flex: 1,
    fontSize: 15,
    color: colors.primary,
  },
  slot: {
    alignItems: 'center',
    paddingVertical: spacing.xl,
  },
  slotText: {
    textAlign: 'center',
  },
  toetsUitleg: {
    marginTop: -spacing.xs,
  },
  vraagKaart: {
    paddingVertical: spacing.lg,
  },
  vraagTitel: {
    fontSize: 15.5,
    marginBottom: spacing.sm,
  },
  optie: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
    borderWidth: 1.5,
    borderColor: colors.line,
    borderRadius: radius.row,
    padding: spacing.md,
    marginTop: spacing.sm,
    minHeight: 48,
  },
  optieGekozen: {
    borderColor: colors.primaryMid,
    backgroundColor: colors.tintBlue,
  },
  optieGoed: {
    borderColor: colors.accentDark,
    backgroundColor: colors.successBg,
  },
  optieFout: {
    borderColor: colors.error,
    backgroundColor: colors.errorBg,
  },
  bolletje: {
    width: 18,
    height: 18,
    borderRadius: 9,
    borderWidth: 2,
    borderColor: colors.inkFaint,
  },
  bolletjeGekozen: {
    borderColor: colors.primary,
    backgroundColor: colors.primary,
  },
  optieText: {
    flex: 1,
    fontSize: 15,
  },
  uitleg: {
    marginTop: spacing.md,
    fontStyle: 'italic',
  },
  uitslagGoed: {
    borderWidth: 1.5,
    borderColor: colors.accent,
    backgroundColor: colors.successBg,
  },
  uitslagFout: {
    borderWidth: 1.5,
    borderColor: colors.warnText,
    backgroundColor: colors.warnBg,
  },
  uitslagGoedText: {
    color: colors.successText,
  },
  uitslagFoutText: {
    color: colors.warnText,
  },
  knop: {
    marginTop: spacing.md,
  },
});

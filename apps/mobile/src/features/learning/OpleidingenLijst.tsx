import { router } from 'expo-router';
import { Pressable, ScrollView, StyleSheet, View } from 'react-native';
import { GraduationCap, MapPin, Users } from 'lucide-react-native';

import {
  useCourseGroups,
  useCourses,
  useGroupActions,
  type Course,
  type CourseGroup,
} from '@/features/learning/api';
import { t } from '@/i18n';
import { formatMoment } from '@/lib/dates';
import { colors, radius, spacing } from '@/theme';
import { Button, Card, EmptyState, Pill, SectionHeader, StatusPill, TvzText } from '@/ui';

/**
 * Opleidingen (feedback 30-07): cursussen die je zelf op de telefoon doet en
 * klassikale bijeenkomsten met een professional in de buurt.
 */
export function OpleidingenLijst() {
  const courses = useCourses();
  const groups = useCourseGroups();

  return (
    <ScrollView contentContainerStyle={styles.list}>
      <SectionHeader title={t('opleiding.zelfTitel')} />
      <TvzText preset="secondary" style={styles.uitleg}>
        {t('opleiding.zelfUitleg')}
      </TvzText>
      {!courses.isLoading && (courses.data ?? []).length === 0 ? (
        <Card>
          <EmptyState title={t('opleiding.leegTitel')} body={t('opleiding.leegTekst')} />
        </Card>
      ) : null}
      {(courses.data ?? []).map((course) => (
        <CursusKaart key={course.id} course={course} />
      ))}

      <SectionHeader title={t('opleiding.groepTitel')} />
      <TvzText preset="secondary" style={styles.uitleg}>
        {t('opleiding.groepUitleg')}
      </TvzText>
      {!groups.isLoading && (groups.data ?? []).length === 0 ? (
        <Card>
          <EmptyState title={t('opleiding.geenGroepen')} body={t('opleiding.geenGroepenTekst')} />
        </Card>
      ) : null}
      {(groups.data ?? []).map((groep) => (
        <GroepKaart key={groep.id} groep={groep} />
      ))}
    </ScrollView>
  );
}

/** Eén cursus: onderwerp, duur, voortgang en of je de toets al haalde. */
export function CursusKaart({ course }: { course: Course }) {
  const klaar = course.onderdelen > 0 && course.gelezen >= course.onderdelen;

  return (
    <Pressable
      accessibilityRole="button"
      onPress={() => router.push({ pathname: '/opleiding/[id]', params: { id: course.id } })}
    >
      <Card style={styles.cursusKaart}>
        <View style={styles.cursusKop}>
          <View style={styles.cursusIcon}>
            <GraduationCap color={colors.primary} size={19} strokeWidth={2.2} />
          </View>
          <View style={styles.flex}>
            <TvzText preset="cardTitle">{course.title}</TvzText>
            {course.subtitle ? (
              <TvzText preset="secondary" style={styles.cursusSub}>
                {course.subtitle}
              </TvzText>
            ) : null}
          </View>
          {course.gehaald ? <StatusPill label={t('opleiding.gehaald')} kind="success" /> : null}
        </View>

        <View style={styles.cursusMeta}>
          {course.topic ? <Pill label={course.topic} /> : null}
          <TvzText preset="meta" style={styles.metaText}>
            {t('opleiding.duur', { minuten: course.duur_minuten })}
          </TvzText>
        </View>

        <View style={styles.voortgangTrack}>
          <View
            style={[
              styles.voortgangBar,
              {
                width: `${course.onderdelen > 0 ? Math.round((course.gelezen / course.onderdelen) * 100) : 0}%`,
              },
            ]}
          />
        </View>
        <TvzText preset="meta" style={styles.metaText}>
          {course.gehaald
            ? t('opleiding.afgerond', { score: course.laatste_score ?? 0 })
            : klaar
              ? t('opleiding.toetsKlaar')
              : t('opleiding.voortgang', {
                  gelezen: course.gelezen,
                  totaal: course.onderdelen,
                })}
        </TvzText>
      </Card>
    </Pressable>
  );
}

/** Eén klassikale bijeenkomst met aanmeldknop. */
export function GroepKaart({ groep }: { groep: CourseGroup }) {
  const { join, leave } = useGroupActions();
  const vrij = Math.max(groep.plekken - groep.aangemeld, 0);
  const vol = vrij === 0 && !groep.ik_ga;

  return (
    <Card style={styles.groepKaart}>
      <View style={styles.cursusKop}>
        <View style={styles.groepIcon}>
          <Users color={colors.white} size={18} strokeWidth={2.2} />
        </View>
        <View style={styles.flex}>
          <TvzText preset="cardTitle">{groep.titel}</TvzText>
          <TvzText preset="secondary" style={styles.cursusSub}>
            {groep.cursus}
          </TvzText>
        </View>
        {groep.ik_ga ? <StatusPill label={t('opleiding.jijGaat')} kind="success" /> : null}
      </View>

      <View style={styles.groepRij}>
        <TvzText preset="body" style={styles.groepMoment}>
          {formatMoment(groep.start_op)}
        </TvzText>
      </View>
      <View style={styles.groepRij}>
        <MapPin color={colors.inkSoft} size={15} strokeWidth={2.2} />
        <TvzText preset="secondary" style={styles.flex}>
          {groep.locatie}
          {groep.city ? ` · ${groep.city}` : ''}
        </TvzText>
      </View>
      <TvzText preset="secondary" style={styles.groepBegeleider}>
        {t('opleiding.begeleider', { naam: groep.begeleider })}
      </TvzText>

      {groep.ik_ga ? (
        <Button
          label={t('opleiding.meldAf')}
          variant="outline"
          disabled={leave.isPending}
          style={styles.groepKnop}
          onPress={() => leave.mutate(groep.id)}
        />
      ) : (
        <>
          <Button
            label={vol ? t('opleiding.vol') : t('opleiding.meldAan')}
            variant="cta"
            disabled={vol || join.isPending}
            style={styles.groepKnop}
            onPress={() => join.mutate(groep.id)}
          />
          {!vol ? (
            <TvzText preset="meta" style={styles.metaCentered}>
              {vrij === 1 ? t('opleiding.plek1') : t('opleiding.plekken', { aantal: vrij })}
            </TvzText>
          ) : null}
        </>
      )}
    </Card>
  );
}

const styles = StyleSheet.create({
  list: {
    padding: spacing.screen,
    paddingBottom: 110,
    gap: spacing.cardGap,
  },
  flex: { flex: 1 },
  uitleg: {
    marginTop: -spacing.xs,
    marginBottom: spacing.xs,
  },
  cursusKaart: {
    paddingVertical: spacing.lg,
  },
  cursusKop: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
  },
  cursusIcon: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: colors.tintBlue,
    alignItems: 'center',
    justifyContent: 'center',
  },
  groepIcon: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: colors.primaryMid,
    alignItems: 'center',
    justifyContent: 'center',
  },
  cursusSub: {
    fontSize: 13.5,
  },
  cursusMeta: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    marginTop: spacing.md,
  },
  metaText: {
    color: colors.inkSoft,
  },
  metaCentered: {
    color: colors.inkFaint,
    textAlign: 'center',
    marginTop: spacing.sm,
  },
  voortgangTrack: {
    height: 8,
    borderRadius: radius.pill,
    backgroundColor: colors.surfaceAlt,
    overflow: 'hidden',
    marginTop: spacing.md,
    marginBottom: 6,
  },
  voortgangBar: {
    height: 8,
    borderRadius: radius.pill,
    backgroundColor: colors.accent,
  },
  groepKaart: {
    paddingVertical: spacing.lg,
  },
  groepRij: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    marginTop: spacing.sm,
  },
  groepMoment: {
    color: colors.primary,
    fontSize: 15.5,
  },
  groepBegeleider: {
    marginTop: spacing.xs,
    fontStyle: 'italic',
  },
  groepKnop: {
    marginTop: spacing.md,
  },
});

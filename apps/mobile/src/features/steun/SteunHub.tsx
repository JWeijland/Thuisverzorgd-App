import { router } from 'expo-router';
import { Pressable, ScrollView, StyleSheet, View } from 'react-native';
import { ChevronRight, Compass, HeartHandshake, MessagesSquare } from 'lucide-react-native';

import { useCircleMembers, useMyCircle } from '@/features/circles/api';
import { EigenFotoKnop } from '@/features/avatars/EigenFotoKnop';
import { InboxBell } from '@/features/notifications/InboxBell';
import { useProfile } from '@/features/onboarding/useAuth';
import { useTasks } from '@/features/tasks/api';
import { WeekStrip } from '@/features/tasks/WeekStrip';
import { useBoekingen } from '@/features/voorzieningen/api';
import { t } from '@/i18n';
import { greetingKey, isoWeekDays, isoWeekNumber, toDateString } from '@/lib/dates';
import { colors, radius, spacing } from '@/theme';
import { Button, Card, GradientHeader, PulseDot, SectionHeader, TvzText } from '@/ui';

/**
 * Steun-hub: het startscherm van de beheerder (laag 1). Eén functie: kiezen
 * waar je heen wilt. Bovenaan de week van de kring (de rode draad), daaronder
 * de tegels naar wegwijzer, hulpmakelaar en forum.
 */
export function SteunHub() {
  const profile = useProfile();
  const circle = useMyCircle();
  const members = useCircleMembers(circle.data?.id);
  const now = new Date();
  const week = isoWeekDays(now);
  const tasks = useTasks(circle.data?.id, week[0]!, week[6]!);
  const boekingen = useBoekingen();

  const firstName = profile.data?.name.split(' ')[0] ?? '';
  const hulpvrager = (members.data ?? []).find((lid) => lid.member_role === 'hulpvrager');
  const hulpvragerNaam = hulpvrager?.profile?.name?.split(' ')[0];

  const weekKeys = week.map((day) => toDateString(day));
  const boekingDagen = (boekingen.data ?? [])
    .map((boeking) => toDateString(new Date(boeking.slot_at)))
    .filter((dag) => weekKeys.includes(dag));
  const openTaken = (tasks.data ?? []).filter((taak) => taak.status === 'open').length;

  return (
    <View style={styles.safe}>
      <GradientHeader
        title={t(`rooster.${greetingKey(now.getHours())}`, { naam: firstName })}
        subtitle={
          hulpvragerNaam
            ? t('steunHub.subtitel', { naam: hulpvragerNaam })
            : t('steunHub.subtitelLeeg')
        }
        wobbel
        bo
        boRol="beheerder"
        right={
          <View style={styles.headerActies}>
            <InboxBell />
            <EigenFotoKnop />
          </View>
        }
      />

      <ScrollView contentContainerStyle={styles.lijst}>
        {circle.data ? (
          <Card>
            <Pressable
              accessibilityRole="button"
              accessibilityLabel={t('steunHub.weekTitel')}
              onPress={() => router.navigate('/regelen/planning')}
              style={styles.weekKop}
            >
              <TvzText preset="cardTitle">{t('steunHub.weekTitel')}</TvzText>
              <TvzText preset="meta" style={styles.weekNr}>
                {t('steunHub.weekNr', { week: isoWeekNumber(now) })}
              </TvzText>
            </Pressable>
            <WeekStrip anchor={now} tasks={tasks.data ?? []} boekingDagen={boekingDagen} legenda />
            <View style={styles.vulRij}>
              <TvzText preset="secondary" style={styles.vulTekst}>
                {openTaken === 0
                  ? t('steunHub.allesGevuld')
                  : openTaken === 1
                    ? t('steunHub.openTaak1')
                    : t('steunHub.openTaken', { aantal: openTaken })}
              </TvzText>
              <Button label={t('steunHub.vulDeWeek')} onPress={() => router.push('/vul-de-week')} />
            </View>
          </Card>
        ) : null}

        <SectionHeader title={t('steunHub.kiesTitel')} />

        <Pressable accessibilityRole="button" onPress={() => router.push('/weten/wegwijzer')}>
          <Card style={styles.tegel}>
            <View style={[styles.tegelIcoon, { backgroundColor: colors.tintBlue }]}>
              <Compass color={colors.primaryMid} size={22} strokeWidth={2.2} />
            </View>
            <View style={styles.tegelTekst}>
              <TvzText preset="cardTitle">{t('steunHub.wegwijzerTitel')}</TvzText>
              <TvzText preset="secondary">{t('steunHub.wegwijzerTekst')}</TvzText>
            </View>
            <ChevronRight color={colors.inkFaint} size={20} strokeWidth={2.2} />
          </Card>
        </Pressable>

        <Pressable accessibilityRole="button" onPress={() => router.push('/weten/zorgmakelaars')}>
          <Card style={styles.tegel}>
            <View style={[styles.tegelIcoon, { backgroundColor: '#EFE6F7' }]}>
              <HeartHandshake color="#6B4E93" size={22} strokeWidth={2.2} />
            </View>
            <View style={styles.tegelTekst}>
              <TvzText preset="cardTitle">{t('steunHub.makelaarTitel')}</TvzText>
              <TvzText preset="secondary">{t('steunHub.makelaarTekst')}</TvzText>
            </View>
            <View style={styles.online}>
              <PulseDot size={8} />
              <TvzText preset="meta" style={styles.onlineTekst}>
                {t('steunHub.makelaarOnline')}
              </TvzText>
            </View>
          </Card>
        </Pressable>

        <Pressable accessibilityRole="button" onPress={() => router.push('/weten/forum')}>
          <Card style={styles.tegel}>
            <View style={[styles.tegelIcoon, { backgroundColor: colors.warnBg }]}>
              <MessagesSquare color={colors.warnText} size={22} strokeWidth={2.2} />
            </View>
            <View style={styles.tegelTekst}>
              <TvzText preset="cardTitle">{t('steunHub.forumTitel')}</TvzText>
              <TvzText preset="secondary">{t('steunHub.forumTekst')}</TvzText>
            </View>
            <ChevronRight color={colors.inkFaint} size={20} strokeWidth={2.2} />
          </Card>
        </Pressable>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: colors.bg,
  },
  headerActies: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
  },
  lijst: {
    padding: spacing.screen,
    paddingBottom: 110,
    gap: spacing.cardGap,
  },
  weekKop: {
    flexDirection: 'row',
    alignItems: 'baseline',
    justifyContent: 'space-between',
    marginBottom: spacing.md,
  },
  weekNr: {
    color: colors.inkFaint,
  },
  vulRij: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
    marginTop: spacing.md,
    borderTopWidth: 1,
    borderTopColor: colors.line,
    paddingTop: spacing.md,
  },
  vulTekst: {
    flex: 1,
  },
  tegel: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
    paddingVertical: spacing.lg,
  },
  tegelIcoon: {
    width: 44,
    height: 44,
    borderRadius: radius.tile,
    alignItems: 'center',
    justifyContent: 'center',
  },
  tegelTekst: {
    flex: 1,
  },
  online: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  onlineTekst: {
    color: colors.successText,
  },
});

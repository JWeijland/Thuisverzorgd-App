import { LinearGradient } from 'expo-linear-gradient';
import { router } from 'expo-router';
import { useState } from 'react';
import { Pressable, ScrollView, StyleSheet, View } from 'react-native';
import Animated from 'react-native-reanimated';
import { SafeAreaView } from 'react-native-safe-area-context';

import {
  useCircleMembers,
  useCreateCircle,
  useMyCircle,
  type Member,
} from '@/features/circles/api';
import { ChatView } from '@/features/circles/ChatView';
import { ProfileAvatar } from '@/features/avatars/ProfileAvatar';
import { useTasks } from '@/features/tasks/api';
import { computeWorkload } from '@/features/tasks/logic';
import { useProfile } from '@/features/onboarding/useAuth';
import { t } from '@/i18n';
import { colors, gradient, radius, spacing } from '@/theme';
import {
  Button,
  Card,
  EmptyState,
  GradientHeader,
  SectionHeader,
  StatusPill,
  TextField,
  TvzText,
} from '@/ui';
import { tvzIn } from '@/ui/animations';
import { KringMotief } from '@/features/circles/KringMotief';
import { useStatusBalk } from '@/lib/statusbalk';

const STATUS_MAP: Record<Member['status'], { key: string; kind: 'success' | 'warn' | 'info' }> = {
  actief: { key: 'kring.statusActief', kind: 'success' },
  uitgenodigd: { key: 'kring.statusUitgenodigd', kind: 'warn' },
  id_check: { key: 'kring.statusIdCheck', kind: 'warn' },
  kijkt_mee: { key: 'kring.statusKijktMee', kind: 'info' },
};

/** Kring-tab (screens 10/11): gradient-header, subnav Leden/Berichten, of de aanmaakflow. */
export function KringScreen() {
  useStatusBalk('donker');
  const profile = useProfile();
  const circle = useMyCircle();
  const isBeheerder = profile.data?.role === 'beheerder';

  if (circle.isLoading) return <View style={styles.safeBg} />;

  if (!circle.data) {
    return isBeheerder ? <KringAanmaken /> : <KringLeeg />;
  }
  return (
    <KringDetail
      circleId={circle.data.id}
      name={circle.data.name}
      linkCode={circle.data.link_code}
    />
  );
}

function KringLeeg() {
  return (
    <SafeAreaView style={styles.safeBg} edges={['top']}>
      <View style={styles.leegWrap}>
        <Card>
          <EmptyState title={t('kring.legeStaatTitel')} body={t('kring.legeStaatTekst')} />
          <Button
            label={t('kring.bekijkKaart')}
            variant="cta"
            onPress={() => router.navigate('/buurt')}
          />
        </Card>
      </View>
    </SafeAreaView>
  );
}

/**
 * Aanmaakflow. Het beeld is het merkmotief uit het brandbook: buddy's rondom
 * één hulpvrager. Zodra de kring er is draait die kring een slag rond, en
 * schuift de koppelcode eronder in beeld.
 */
function KringAanmaken() {
  const createCircle = useCreateCircle();
  const [name, setName] = useState('');
  const [created, setCreated] = useState<{ name: string; code: string } | null>(null);

  return (
    <View style={styles.safeBg}>
      <GradientHeader
        title={t(created ? 'kring.gemaaktTitel' : 'kring.maakTitel')}
        subtitle={t(created ? 'kring.gemaaktTekst' : 'kring.maakUitleg')}
        wobbel
      />

      <ScrollView contentContainerStyle={styles.maakLijst} keyboardShouldPersistTaps="handled">
        <View style={styles.motief}>
          <KringMotief gevierd={!!created} />
        </View>

        {created ? (
          <Animated.View entering={tvzIn} style={styles.maakBlok}>
            <TvzText preset="screenTitle" style={styles.gemaaktNaam}>
              {created.name}
            </TvzText>
            <Card dashed style={styles.codeCard}>
              <TvzText preset="meta" style={styles.codeLabel}>
                {t('kring.koppelTitel')}
              </TvzText>
              <TvzText preset="screenTitle" style={styles.code}>
                {created.code}
              </TvzText>
              <TvzText preset="secondary" style={styles.codeUitleg}>
                {t('kring.koppelUitleg')}
              </TvzText>
            </Card>
            <Button
              label={t('kring.naarKring')}
              variant="cta"
              size="lg"
              onPress={() => setCreated(null)}
            />
          </Animated.View>
        ) : (
          <Animated.View entering={tvzIn} style={styles.maakBlok}>
            <Card style={styles.maakKaart}>
              <TextField
                label={t('kring.naamLabel')}
                placeholder={t('kring.naamPlaceholder')}
                value={name}
                onChangeText={setName}
                returnKeyType="done"
              />
              <Button
                label={createCircle.isPending ? t('algemeen.laden') : t('kring.maakKnop')}
                variant="cta"
                size="lg"
                disabled={createCircle.isPending || name.trim().length < 3}
                onPress={() =>
                  createCircle.mutate(name.trim(), {
                    onSuccess: (result) =>
                      setCreated({ name: result.name, code: result.link_code }),
                  })
                }
              />
            </Card>

            <SectionHeader title={t('kring.zoWerktTitel')} />
            {[1, 2, 3].map((nummer) => (
              <Card key={nummer} style={styles.stapKaart}>
                <View style={styles.stapNr}>
                  <TvzText preset="meta" style={styles.stapNrTekst}>
                    {nummer}
                  </TvzText>
                </View>
                <View style={styles.stapTekst}>
                  <TvzText preset="cardTitle" style={styles.stapTitel}>
                    {t(`kring.stap${nummer}Titel`)}
                  </TvzText>
                  <TvzText preset="secondary">{t(`kring.stap${nummer}Tekst`)}</TvzText>
                </View>
              </Card>
            ))}
          </Animated.View>
        )}
      </ScrollView>
    </View>
  );
}

function KringDetail({
  circleId,
  name,
  linkCode,
}: {
  circleId: string;
  name: string;
  linkCode: string;
}) {
  const profile = useProfile();
  const members = useCircleMembers(circleId);
  const isBeheerder = profile.data?.role === 'beheerder';
  const [tab, setTab] = useState<'leden' | 'berichten'>('leden');

  const now = new Date();
  const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
  const monthEnd = new Date(now.getFullYear(), now.getMonth() + 1, 0);
  const monthTasks = useTasks(circleId, monthStart, monthEnd);
  const workload = computeWorkload(monthTasks.data ?? [], now);
  const maxCount = workload[0]?.count ?? 0;

  const activeVolunteers = (members.data ?? []).filter(
    (member) => member.member_role === 'vrijwilliger' && member.status === 'actief',
  ).length;

  const roleSuffix = (senderId: string) => {
    const member = (members.data ?? []).find((item) => item.profile_id === senderId);
    return member?.member_role === 'beheerder' ? ` (${t('kring.rolBeheerder')})` : '';
  };

  return (
    <View style={styles.safeBg}>
      <LinearGradient {...gradient} style={styles.header}>
        <SafeAreaView edges={['top']}>
          <TvzText preset="screenTitle" style={styles.headerTitle}>
            {name}
          </TvzText>
          <TvzText preset="secondary" style={styles.headerSub}>
            {isBeheerder
              ? t('kring.subtitel', { aantal: (members.data ?? []).length })
              : t('kring.subtitelLid', { aantal: (members.data ?? []).length })}
          </TvzText>
          <View style={styles.subnav}>
            {(['leden', 'berichten'] as const).map((key) => (
              <Pressable
                key={key}
                accessibilityRole="tab"
                accessibilityState={{ selected: tab === key }}
                onPress={() => setTab(key)}
                style={[styles.subnavPill, tab === key && styles.subnavActive]}
              >
                <TvzText
                  preset="meta"
                  style={tab === key ? styles.subnavTextActive : styles.subnavText}
                >
                  {t(`kring.${key}`)}
                </TvzText>
              </Pressable>
            ))}
          </View>
        </SafeAreaView>
      </LinearGradient>

      {tab === 'berichten' ? (
        <ChatView circleId={circleId} roleSuffix={roleSuffix} />
      ) : (
        <ScrollView contentContainerStyle={styles.ledenList}>
          {(members.data ?? []).map((member) => {
            const status = STATUS_MAP[member.status];
            const roleLabel =
              member.member_role === 'hulpvrager'
                ? t('kring.rolHulpvrager')
                : member.member_role === 'beheerder'
                  ? t('kring.rolBeheerder')
                  : t('kring.rolVrijwilliger');
            const isHulpvrager = member.member_role === 'hulpvrager';
            return (
              <Card
                key={member.id}
                style={[styles.memberCard, isHulpvrager && styles.hulpvragerCard]}
              >
                <View style={styles.memberRow}>
                  <ProfileAvatar
                    name={member.profile?.name ?? '?'}
                    avatarPath={member.profile?.avatar_path}
                    backgroundColor={isHulpvrager ? colors.primaryDark : undefined}
                  />
                  <View style={styles.memberInfo}>
                    <TvzText preset="cardTitle">{member.profile?.name ?? ''}</TvzText>
                    <TvzText preset="secondary">{roleLabel}</TvzText>
                  </View>
                  <StatusPill label={t(status.key)} kind={status.kind} />
                </View>
              </Card>
            );
          })}

          {isBeheerder && workload.length > 0 ? (
            <Card style={styles.workloadCard}>
              <TvzText preset="cardTitle">{t('kring.wieDoetWat')}</TvzText>
              <View style={styles.workloadRows}>
                {workload.map((row) => (
                  <View key={row.profileId} style={styles.workloadRow}>
                    <TvzText preset="secondary" style={styles.workloadName}>
                      {row.name}
                    </TvzText>
                    <View style={styles.workloadTrack}>
                      <View
                        style={[
                          styles.workloadBar,
                          {
                            width: `${Math.max(8, (row.count / Math.max(maxCount, 1)) * 100)}%`,
                            backgroundColor:
                              row.count === maxCount ? colors.primary : colors.accent,
                          },
                        ]}
                      />
                    </View>
                    <TvzText preset="meta" style={styles.workloadCount}>
                      {row.count === 1 ? t('kring.taak1') : t('kring.taken', { aantal: row.count })}
                    </TvzText>
                  </View>
                ))}
              </View>
              {workload.length > 1 ? (
                <TvzText preset="secondary" style={styles.advies}>
                  {t('kring.spreidAdvies', { naam: workload[0]!.name })}
                </TvzText>
              ) : null}
            </Card>
          ) : null}

          {isBeheerder ? (
            <>
              <Button
                label={t('kring.uitnodigen')}
                variant="outline"
                size="lg"
                onPress={() => router.push('/uitnodigen')}
              />
              {activeVolunteers >= 2 ? (
                <TvzText preset="secondary" style={styles.limiet}>
                  {t('kring.gratisLimiet')}
                </TvzText>
              ) : null}
              <Card dashed style={styles.codeCardSmall}>
                <TvzText preset="meta" style={styles.codeLabel}>
                  {t('kring.koppelTitel')}
                </TvzText>
                <TvzText preset="cardTitle" style={styles.code}>
                  {linkCode}
                </TvzText>
              </Card>
            </>
          ) : null}
        </ScrollView>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  safeBg: {
    flex: 1,
    backgroundColor: colors.bg,
  },
  leegWrap: {
    flex: 1,
    padding: spacing.screen,
    justifyContent: 'center',
  },
  maakUitleg: {
    marginTop: spacing.xs,
    marginBottom: spacing.xl,
  },
  maakLijst: {
    padding: spacing.screen,
    paddingBottom: 120,
  },
  motief: {
    marginTop: spacing.lg,
    marginBottom: spacing.xl,
  },
  maakBlok: {
    gap: spacing.cardGap,
  },
  maakKaart: {
    paddingVertical: spacing.lg,
  },
  gemaaktNaam: {
    textAlign: 'center',
    marginBottom: spacing.md,
  },
  stapKaart: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: spacing.md,
    paddingVertical: spacing.md,
  },
  stapNr: {
    width: 26,
    height: 26,
    borderRadius: 13,
    backgroundColor: colors.tintBlue,
    alignItems: 'center',
    justifyContent: 'center',
  },
  stapNrTekst: {
    color: colors.primary,
  },
  stapTekst: {
    flex: 1,
  },
  stapTitel: {
    fontSize: 15.5,
    marginBottom: 2,
  },
  codeCard: {
    alignItems: 'center',
    paddingVertical: spacing.xxl,
    marginVertical: spacing.xl,
  },
  codeCardSmall: {
    alignItems: 'center',
    paddingVertical: spacing.lg,
    marginTop: spacing.md,
  },
  codeLabel: {
    color: colors.primaryMid,
  },
  code: {
    letterSpacing: 2,
    marginTop: 4,
  },
  codeUitleg: {
    textAlign: 'center',
    marginTop: spacing.sm,
  },
  header: {
    paddingHorizontal: spacing.screen,
    paddingBottom: spacing.lg,
  },
  headerTitle: {
    color: colors.white,
    fontSize: 24,
    marginTop: spacing.sm,
  },
  headerSub: {
    color: 'rgba(255,255,255,0.8)',
    marginBottom: spacing.md,
  },
  subnav: {
    flexDirection: 'row',
    gap: spacing.sm,
  },
  subnavPill: {
    borderRadius: radius.pill,
    paddingHorizontal: 16,
    paddingVertical: 7,
    backgroundColor: 'rgba(255,255,255,0.18)',
  },
  subnavActive: {
    backgroundColor: colors.white,
  },
  subnavText: {
    color: colors.white,
  },
  subnavTextActive: {
    color: colors.primary,
  },
  ledenList: {
    padding: spacing.screen,
    paddingBottom: 110,
    gap: spacing.cardGap,
  },
  memberCard: {
    paddingVertical: spacing.md,
  },
  hulpvragerCard: {
    borderWidth: 1.5,
    borderColor: colors.primaryMid,
    backgroundColor: colors.tintBlue,
  },
  memberRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
  },
  memberInfo: { flex: 1 },
  workloadCard: {
    marginTop: spacing.sm,
  },
  workloadRows: {
    marginTop: spacing.md,
    gap: spacing.sm,
  },
  workloadRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
  },
  workloadName: {
    width: 56,
  },
  workloadTrack: {
    flex: 1,
    height: 8,
    borderRadius: radius.pill,
    backgroundColor: colors.surfaceAlt,
    overflow: 'hidden',
  },
  workloadBar: {
    height: 8,
    borderRadius: radius.pill,
  },
  workloadCount: {
    width: 64,
    textAlign: 'right',
  },
  advies: {
    marginTop: spacing.md,
    fontStyle: 'italic',
  },
  limiet: {
    textAlign: 'center',
    marginTop: spacing.sm,
    color: colors.inkFaint,
  },
});

import { LinearGradient } from 'expo-linear-gradient';
import { router } from 'expo-router';
import { useState } from 'react';
import { Pressable, ScrollView, StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import {
  useCircleMembers,
  useMyCircle,
  type Member,
} from '@/features/circles/api';
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
  RolChip,
  StatusPill,
  TvzText,
} from '@/ui';
import { ChatView } from '@/features/circles/ChatView';
import { useKringConcept } from '@/features/circles/kringopbouw';
import { KringMotief } from '@/features/circles/KringMotief';
import { haptics } from '@/lib/haptics';
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
    return isBeheerder ? <KringStart /> : <KringLeeg />;
  }
  return (
    <KringDetail
      circleId={circle.data.id}
      name={circle.data.name}
      linkCode={circle.data.link_code}
    />
  );
}

/**
 * Nog geen kring: de beheerder gaat de zes stappen met Bo in (handoff §3e),
 * in plaats van het oude scherm waar je alleen een naam invulde.
 */
function KringStart() {
  const concept = useKringConcept();
  const bezig = !!concept.data && concept.data.stap > 1;

  return (
    <View style={styles.leegWrap}>
      <Card>
        <EmptyState title={t('kring.startTitel')} body={t('kring.startTekst')} bo />
        <Button
          label={t(bezig ? 'kring.startVerder' : 'kring.startKnop')}
          variant="cta"
          size="lg"
          onPress={() => router.push('/regelen/kring-opbouwen')}
        />
      </Card>
    </View>
  );
}

function KringLeeg() {
  return (
    <SafeAreaView style={styles.safeBg} edges={['top']}>
      <View style={styles.leegWrap}>
        <Card>
          <EmptyState title={t('kring.legeStaatTitel')} body={t('kring.legeStaatTekst')} bo />
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

  const roleSuffix = (senderId: string) => {
    const lid = (members.data ?? []).find((item) => item.profile_id === senderId);
    return lid?.member_role === 'beheerder' ? ` (${t('kring.rolBeheerder')})` : '';
  };

  const now = new Date();
  const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
  const monthEnd = new Date(now.getFullYear(), now.getMonth() + 1, 0);
  const monthTasks = useTasks(circleId, monthStart, monthEnd);
  const workload = computeWorkload(monthTasks.data ?? [], now);
  const maxCount = workload[0]?.count ?? 0;

  return (
    <View style={styles.safeBg}>
      {/* Kringkop (handoff, scherm 07): het blauwe blok met de kringnaam en
          twee tabjes. Berichten is geen eigen schuifje meer, maar zit hier. */}
      <LinearGradient {...gradient} style={styles.header}>
        <View style={styles.headerTekst}>
          <TvzText preset="screenTitle" style={styles.headerTitle}>
            {name}
          </TvzText>
          <TvzText preset="secondary" style={styles.headerSub}>
            {isBeheerder
              ? t('kring.subtitel', { aantal: (members.data ?? []).length })
              : t('kring.subtitelLid', { aantal: (members.data ?? []).length })}
          </TvzText>
        </View>
        <View style={styles.tabjes}>
          {(['leden', 'berichten'] as const).map((tabje) => (
            <Pressable
              key={tabje}
              accessibilityRole="tab"
              accessibilityState={{ selected: tab === tabje }}
              onPress={() => {
                if (tab === tabje) return;
                void haptics.selectie();
                setTab(tabje);
              }}
              style={[styles.tabje, tab === tabje && styles.tabjeActief]}
            >
              <TvzText
                preset="meta"
                style={tab === tabje ? styles.tabjeTekstActief : styles.tabjeTekst}
              >
                {t(tabje === 'leden' ? 'kring.tabLeden' : 'kring.tabBerichten')}
              </TvzText>
            </Pressable>
          ))}
        </View>
      </LinearGradient>

      {tab === 'berichten' ? (
        <ChatView circleId={circleId} roleSuffix={roleSuffix} />
      ) : (
        <ScrollView contentContainerStyle={styles.ledenList}>
          <View style={styles.motiefKlein}>
            <KringMotief />
          </View>
          {(members.data ?? []).map((member) => {
            const status = STATUS_MAP[member.status];
            const isHulpvrager = member.member_role === 'hulpvrager';
            const rol =
              member.member_role === 'hulpvrager'
                ? 'hulpvrager'
                : member.member_role === 'beheerder'
                  ? 'beheerder'
                  : 'vrijwilliger';
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
                    <TvzText preset="secondary" style={styles.rolUitleg}>
                      {t(`kring.rolUitleg${rol.charAt(0).toUpperCase()}${rol.slice(1)}`)}
                    </TvzText>
                  </View>
                  <View style={styles.memberRechts}>
                    <RolChip rol={rol} />
                    <StatusPill label={t(status.key)} kind={status.kind} />
                  </View>
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
              {/* Het kleine knopje naar de kaart: sinds de herstructurering is
                  dit de enige plek waar de volledige buurtkaart nog vandaan
                  komt voor een beheerder (handoff §3b). */}
              <Button
                label={t('kring.boZoektBuddy')}
                variant="outline"
                onPress={() => router.push('/buurt')}
              />
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
    paddingTop: spacing.lg,
    paddingBottom: spacing.lg,
  },
  headerTitle: {
    color: colors.white,
    fontSize: 22,
  },
  headerSub: {
    color: 'rgba(255,255,255,0.8)',
  },
  tabjes: {
    flexDirection: 'row',
    gap: spacing.chipGap,
    marginTop: spacing.md,
  },
  tabje: {
    borderRadius: radius.pill,
    paddingHorizontal: 18,
    minHeight: 34,
    justifyContent: 'center',
    backgroundColor: 'rgba(255,255,255,0.18)',
  },
  tabjeActief: {
    backgroundColor: colors.white,
  },
  tabjeTekst: {
    color: colors.white,
  },
  tabjeTekstActief: {
    color: colors.primary,
  },
  headerTekst: {
    flex: 1,
  },
  motiefKlein: {
    marginBottom: spacing.sm,
  },
  memberRechts: {
    alignItems: 'flex-end',
    gap: 6,
  },
  rolUitleg: {
    marginTop: 2,
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
});

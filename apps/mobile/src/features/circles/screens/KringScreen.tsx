import { useQueryClient } from '@tanstack/react-query';
import { router, useLocalSearchParams } from 'expo-router';
import { useEffect, useState } from 'react';
import { Pressable, ScrollView, StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Search, UserPlus } from 'lucide-react-native';

import {
  markCircleChatRead,
  useCircleMembers,
  useMyCircle,
  type Member,
} from '@/features/circles/api';
import { ProfileAvatar } from '@/features/avatars/ProfileAvatar';
import { useTasks } from '@/features/tasks/api';
import { computeWorkload } from '@/features/tasks/logic';
import { useProfile } from '@/features/onboarding/useAuth';
import { t } from '@/i18n';
import { colors, radius, spacing } from '@/theme';
import {
  Button,
  Card,
  EmptyState,
  RolChip,
  StatusPill,
  TextField,
  TvzText,
} from '@/ui';
import { ChatView } from '@/features/circles/ChatView';
import {
  koppelFoutTekst,
  useKoppelNaaste,
  useKringConcept,
} from '@/features/circles/kringopbouw';
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

/**
 * De naaste koppelen met zijn eigen code (feedback Jelle 11-08). Zolang er
 * nog geen hulpvrager in de kring zit, staat dit blok op de kringpagina, want
 * zonder die persoon mist de kring haar middelpunt.
 */
function KoppelNaasteKaart({ circleId }: { circleId: string }) {
  const koppel = useKoppelNaaste();
  const [code, setCode] = useState('');
  const [fout, setFout] = useState<string | null>(null);

  return (
    <Card style={styles.koppelKaart}>
      <TvzText preset="cardTitle">{t('mijnCode.koppelKort')}</TvzText>
      <TvzText preset="secondary">{t('mijnCode.koppelUitleg')}</TvzText>
      <TextField
        label={t('mijnCode.koppelLabel')}
        value={code}
        onChangeText={(waarde) => {
          setFout(null);
          setCode(waarde.toUpperCase());
        }}
        placeholder="TVZ-XXXX"
        autoCapitalize="characters"
        autoCorrect={false}
      />
      {fout ? (
        <TvzText preset="secondary" style={styles.koppelFout}>
          {t(fout)}
        </TvzText>
      ) : null}
      <Button
        label={t('mijnCode.koppelKnop')}
        variant="cta"
        disabled={koppel.isPending || code.trim().length < 6}
        onPress={() => {
          void haptics.stevig();
          koppel.mutate(
            { circleId, code },
            {
              onSuccess: () => setCode(''),
              onError: (error) => setFout(koppelFoutTekst(error)),
            },
          );
        }}
      />
    </Card>
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

function KringDetail({ circleId, name }: { circleId: string; name: string }) {
  const profile = useProfile();
  const members = useCircleMembers(circleId);
  const isBeheerder = profile.data?.role === 'beheerder';
  // Kom je van de berichtenknop, dan sta je meteen op Berichten.
  const { tab: startTab } = useLocalSearchParams<{ tab?: string }>();
  const queryClient = useQueryClient();
  const [tab, setTab] = useState<'leden' | 'berichten'>(
    startTab === 'berichten' ? 'berichten' : 'leden',
  );

  // Bij het verlaten van de Berichten-tab is alles gelezen; de badge
  // verdwijnt dan. Stond eerst op de losse kringchat-pagina.
  useEffect(() => {
    if (tab !== 'berichten') return;
    return () => {
      markCircleChatRead(circleId).then(() =>
        queryClient.invalidateQueries({ queryKey: ['messages-unread', circleId] }),
      );
    };
  }, [tab, circleId, queryClient]);

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
      {/* Kringkop: lichte kop met de kringnaam en een vierkante schuif.
          De tweede gekleurde balk is eruit; de padheader is al gekleurd
          (feedback Jelle 11-08). */}
      <View style={styles.kringKop}>
        <TvzText preset="screenTitle" style={styles.headerTitle}>
          {name}
        </TvzText>
        <TvzText preset="secondary">
          {isBeheerder
            ? t('kring.subtitel', { aantal: (members.data ?? []).length })
            : t('kring.subtitelLid', { aantal: (members.data ?? []).length })}
        </TvzText>
        <View style={styles.schuif}>
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
              style={[styles.schuifVak, tab === tabje && styles.schuifVakActief]}
            >
              <TvzText
                preset="meta"
                style={tab === tabje ? styles.schuifTekstActief : styles.schuifTekst}
              >
                {t(tabje === 'leden' ? 'kring.tabLeden' : 'kring.tabBerichten')}
              </TvzText>
            </Pressable>
          ))}
        </View>
      </View>

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
              {/* Twee gelijkwaardige vierkante knoppen (wens Jelle 11-08):
                  iemand die je al kent uitnodigen, of Bo laten kijken wie er
                  in de buurt is. Allebei gaan ze over buddy's, dus heten ze
                  ook allebei zo. */}
              <View style={styles.knoppenRij}>
                <Pressable
                  accessibilityRole="button"
                  accessibilityLabel={t('kring.uitnodigen')}
                  onPress={() => {
                    void haptics.tik();
                    router.push('/uitnodigen');
                  }}
                  style={styles.vierkanteKnop}
                >
                  <View style={styles.knopIcoon}>
                    <UserPlus color={colors.primary} size={22} strokeWidth={2.2} />
                  </View>
                  <TvzText preset="cardTitle" style={styles.knopTekst}>
                    {t('kring.uitnodigen')}
                  </TvzText>
                </Pressable>

                <Pressable
                  accessibilityRole="button"
                  accessibilityLabel={t('kring.boZoektBuddy')}
                  onPress={() => {
                    void haptics.tik();
                    router.push('/regelen/buddy-zoeken');
                  }}
                  style={styles.vierkanteKnop}
                >
                  <View style={styles.knopIcoon}>
                    <Search color={colors.primary} size={22} strokeWidth={2.2} />
                  </View>
                  <TvzText preset="cardTitle" style={styles.knopTekst}>
                    {t('kring.boZoektBuddy')}
                  </TvzText>
                </Pressable>
              </View>
              {/* De hulpvrager koppel je met zíjn code, niet met die van de
                  kring (feedback Jelle 11-08). Staat hij er al in, dan is dit
                  blok klaar en verdwijnt het. */}
              {members.data && !members.data.some((lid) => lid.member_role === 'hulpvrager') ? (
                <KoppelNaasteKaart circleId={circleId} />
              ) : null}
            </>
          ) : null}
        </ScrollView>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  koppelKaart: {
    gap: spacing.md,
  },
  koppelFout: {
    color: colors.error,
  },
  knoppenRij: {
    flexDirection: 'row',
    gap: spacing.cardGap,
  },
  vierkanteKnop: {
    flex: 1,
    aspectRatio: 1.25,
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing.sm,
    padding: spacing.md,
    backgroundColor: colors.white,
    borderRadius: radius.card,
    borderWidth: 1.5,
    borderColor: colors.line,
  },
  knopIcoon: {
    width: 44,
    height: 44,
    borderRadius: radius.tile,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.tintBlue,
  },
  knopTekst: {
    textAlign: 'center',
  },
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
  kringKop: {
    paddingHorizontal: spacing.screen,
    paddingTop: spacing.lg,
    paddingBottom: spacing.sm,
    gap: 2,
  },
  headerTitle: {
    fontSize: 22,
  },
  schuif: {
    flexDirection: 'row',
    gap: 3,
    marginTop: spacing.md,
    padding: 3,
    borderRadius: radius.card,
    backgroundColor: colors.surfaceAlt,
  },
  schuifVak: {
    flex: 1,
    minHeight: 38,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: radius.row,
  },
  schuifVakActief: {
    backgroundColor: colors.white,
  },
  schuifTekst: {
    color: colors.inkSoft,
  },
  schuifTekstActief: {
    color: colors.primary,
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

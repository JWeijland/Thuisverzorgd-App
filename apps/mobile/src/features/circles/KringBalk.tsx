import { router } from 'expo-router';
import { useState } from 'react';
import { Pressable, ScrollView, StyleSheet, View } from 'react-native';
import { Users } from 'lucide-react-native';

import { ProfileAvatar } from '@/features/avatars/ProfileAvatar';
import { useCircleMembers, type Member } from '@/features/circles/api';
import { t } from '@/i18n';
import { colors, radius, spacing } from '@/theme';
import { BottomSheet, Button, Card, StatusPill, TvzText } from '@/ui';

const STATUS_MAP: Record<Member['status'], { key: string; kind: 'success' | 'warn' | 'info' }> = {
  actief: { key: 'kring.statusActief', kind: 'success' },
  uitgenodigd: { key: 'kring.statusUitgenodigd', kind: 'warn' },
  id_check: { key: 'kring.statusIdCheck', kind: 'warn' },
  kijkt_mee: { key: 'kring.statusKijktMee', kind: 'info' },
};

type Props = {
  circleId: string;
  name: string;
  /** Op donkere achtergrond (in de gradient-header) of op de lichte pagina. */
  onDark?: boolean;
  /** Beheerder: uitnodigen en de koppelcode staan mee in de ledenlijst. */
  isBeheerder?: boolean;
  linkCode?: string;
};

/**
 * Kringbalk in de kop van de planning-tab: foto van de kring, kringnaam en het
 * aantal leden. Tikken opent de ledenlijst. (Feedback 30-07: de vrijwilliger
 * heeft geen aparte kring-tab meer.)
 */
export function KringBalk({
  circleId,
  name,
  onDark = false,
  isBeheerder = false,
  linkCode,
}: Props) {
  const members = useCircleMembers(circleId);
  const [open, setOpen] = useState(false);

  const list = members.data ?? [];
  const actieveVrijwilligers = list.filter(
    (member) => member.member_role === 'vrijwilliger' && member.status === 'actief',
  ).length;
  // De foto van de hulpvrager staat voorop: dat is het gezicht van de kring.
  const hulpvrager = list.find((member) => member.member_role === 'hulpvrager');
  const gezicht = hulpvrager ?? list.find((member) => member.member_role === 'beheerder');

  return (
    <>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel={t('kring.bekijkLeden')}
        onPress={() => setOpen(true)}
        style={[styles.balk, onDark ? styles.balkDark : styles.balkLight]}
      >
        {gezicht?.profile ? (
          <ProfileAvatar
            name={gezicht.profile.name}
            avatarPath={gezicht.profile.avatar_path}
            size={38}
          />
        ) : (
          <View style={styles.iconAvatar}>
            <Users color={colors.white} size={19} strokeWidth={2.2} />
          </View>
        )}
        <View style={styles.balkText}>
          <TvzText
            preset="cardTitle"
            numberOfLines={1}
            style={onDark ? styles.textDark : undefined}
          >
            {name}
          </TvzText>
          <TvzText preset="meta" style={onDark ? styles.subDark : styles.subLight}>
            {list.length === 1
              ? t('kring.lid1Bekijk')
              : t('kring.ledenBekijk', { aantal: list.length })}
          </TvzText>
        </View>
        <TvzText preset="cardTitle" style={onDark ? styles.subDark : styles.subLight}>
          ›
        </TvzText>
      </Pressable>

      <BottomSheet visible={open} onClose={() => setOpen(false)} title={name}>
        <ScrollView style={styles.sheetScroll}>
          {list.map((member) => {
            const status = STATUS_MAP[member.status];
            const roleLabel =
              member.member_role === 'hulpvrager'
                ? t('kring.rolHulpvrager')
                : member.member_role === 'beheerder'
                  ? t('kring.rolBeheerder')
                  : t('kring.rolVrijwilliger');
            return (
              <View key={member.id} style={styles.ledenRij}>
                <ProfileAvatar
                  name={member.profile?.name ?? '?'}
                  avatarPath={member.profile?.avatar_path}
                  backgroundColor={
                    member.member_role === 'hulpvrager' ? colors.primaryDark : undefined
                  }
                />
                <View style={styles.balkText}>
                  <TvzText preset="cardTitle">{member.profile?.name ?? ''}</TvzText>
                  <TvzText preset="secondary">{roleLabel}</TvzText>
                </View>
                <StatusPill label={t(status.key)} kind={status.kind} />
              </View>
            );
          })}

          {isBeheerder ? (
            <View style={styles.beheer}>
              <Button
                label={t('kring.uitnodigen')}
                variant="outline"
                size="lg"
                onPress={() => {
                  setOpen(false);
                  router.push('/uitnodigen');
                }}
              />
              {actieveVrijwilligers >= 2 ? (
                <TvzText preset="secondary" style={styles.limiet}>
                  {t('kring.gratisLimiet')}
                </TvzText>
              ) : null}
              {linkCode ? (
                <Card dashed style={styles.codeKaart}>
                  <TvzText preset="meta" style={styles.codeLabel}>
                    {t('kring.koppelTitel')}
                  </TvzText>
                  <TvzText preset="cardTitle" style={styles.code}>
                    {linkCode}
                  </TvzText>
                </Card>
              ) : null}
            </View>
          ) : null}
        </ScrollView>
      </BottomSheet>
    </>
  );
}

const styles = StyleSheet.create({
  balk: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
    borderRadius: radius.card,
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.sm,
    minHeight: 56,
  },
  balkDark: {
    backgroundColor: 'rgba(255,255,255,0.14)',
  },
  balkLight: {
    backgroundColor: colors.white,
  },
  iconAvatar: {
    width: 38,
    height: 38,
    borderRadius: 19,
    backgroundColor: colors.primaryMid,
    alignItems: 'center',
    justifyContent: 'center',
  },
  balkText: { flex: 1 },
  textDark: {
    color: colors.white,
  },
  subDark: {
    color: 'rgba(255,255,255,0.75)',
  },
  subLight: {
    color: colors.inkSoft,
  },
  sheetScroll: {
    maxHeight: 420,
  },
  ledenRij: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
    paddingVertical: spacing.md,
    borderBottomWidth: 1,
    borderBottomColor: colors.line,
    minHeight: 60,
  },
  beheer: {
    marginTop: spacing.lg,
  },
  limiet: {
    textAlign: 'center',
    marginTop: spacing.sm,
    color: colors.inkFaint,
  },
  codeKaart: {
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
});

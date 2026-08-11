import { router } from 'expo-router';
import { Pressable, ScrollView, StyleSheet, View } from 'react-native';
import { ChevronRight, Settings } from 'lucide-react-native';

import { ProfileAvatar } from '@/features/avatars/ProfileAvatar';
import { useCircleMembers, useMyCircle } from '@/features/circles/api';
import { KringMotief } from '@/features/circles/KringMotief';
import { MijnCode } from '@/features/circles/MijnCode';
import { useProfile } from '@/features/onboarding/useAuth';
import { t } from '@/i18n';
import { colors, radius, spacing } from '@/theme';
import { Card, EmptyState, RolChip, TvzText } from '@/ui';
import { PaginaKop } from '@/ui/PaginaKop';

/**
 * Mijn kring (hulpvrager, ontwerp 4.0): het scherm dat de rollen uitlegt.
 * Wie regelt, wie komt langs, wie denkt mee, met de vaste rolkleuren.
 * Hier staan ook de instellingen, want deze rol heeft geen profieltab.
 */
export function MijnKring() {
  const profile = useProfile();
  const circle = useMyCircle();
  const members = useCircleMembers(circle.data?.id);

  const lijst = members.data ?? [];
  const beheerder = lijst.find((lid) => lid.member_role === 'beheerder');
  const buddys = lijst.filter((lid) => lid.member_role === 'vrijwilliger');

  return (
    <View style={styles.safe}>
      {/* De gekleurde kop is nu de PadHeader van het hulp-pad. */}
      <PaginaKop titel={t('mijnKring.titel')} sub={t('mijnKring.uitleg')} />
      <ScrollView contentContainerStyle={styles.lijst}>
        {!circle.isLoading && !circle.data ? (
          // Nog geen kring: dan is het enige wat deze rol hoeft te doen zijn
          // code doorgeven aan degene die de hulp regelt (feedback 11-08).
          <>
            <Card>
              <EmptyState title={t('mijnCode.nodigTitel')} body={t('mijnCode.nodigTekst')} bo />
            </Card>
            <MijnCode />
          </>
        ) : (
          <>
            <View style={styles.motief}>
              <KringMotief />
            </View>

            {beheerder?.profile ? (
              <Card style={styles.kaart}>
                <View style={styles.kop}>
                  <ProfileAvatar
                    name={beheerder.profile.name}
                    avatarPath={beheerder.profile.avatar_path}
                    size={52}
                  />
                  <View style={styles.kopTekst}>
                    <TvzText preset="cardTitle" style={styles.naam}>
                      {beheerder.profile.name.split(' ')[0]}
                    </TvzText>
                    <RolChip rol="beheerder" />
                  </View>
                </View>
                <TvzText preset="body" style={styles.tekst}>
                  {t('mijnKring.beheerderTekst', {
                    naam: beheerder.profile.name.split(' ')[0]!,
                  })}
                </TvzText>
              </Card>
            ) : null}

            {buddys.length > 0 ? (
              <Card style={styles.kaart}>
                <View style={styles.kop}>
                  <View style={styles.avatars}>
                    {buddys.slice(0, 3).map((lid, index) => (
                      <View key={lid.id} style={index > 0 ? styles.avatarOverlap : undefined}>
                        <ProfileAvatar
                          name={lid.profile?.name ?? '?'}
                          avatarPath={lid.profile?.avatar_path}
                          size={52}
                        />
                      </View>
                    ))}
                  </View>
                  <View style={styles.kopTekst}>
                    <TvzText preset="cardTitle" style={styles.naam}>
                      {buddys.map((lid) => lid.profile?.name?.split(' ')[0]).join(' en ')}
                    </TvzText>
                    <RolChip rol="vrijwilliger" meervoud={buddys.length > 1} />
                  </View>
                </View>
                <TvzText preset="body" style={styles.tekst}>
                  {t('mijnKring.buddyTekst')}
                </TvzText>
              </Card>
            ) : null}

            <Card style={styles.kaart}>
              <View style={styles.kop}>
                <View style={styles.kopTekst}>
                  <TvzText preset="cardTitle" style={styles.naam}>
                    {t('mijnKring.makelaarTitel')}
                  </TvzText>
                  <RolChip rol="makelaar" />
                </View>
              </View>
              <TvzText preset="body" style={styles.tekst}>
                {t('mijnKring.makelaarTekst')}
              </TvzText>
            </Card>
          </>
        )}

        <Pressable accessibilityRole="button" onPress={() => router.push('/profiel')}>
          <Card style={styles.instellingen}>
            <View style={styles.instellingenIcoon}>
              <Settings color={colors.primary} size={22} strokeWidth={2.2} />
            </View>
            <View style={styles.kopTekst}>
              <TvzText preset="cardTitle">{t('mijnKring.instellingen')}</TvzText>
              <TvzText preset="secondary">
                {t('mijnKring.instellingenSub', {
                  naam: profile.data?.name.split(' ')[0] ?? '',
                })}
              </TvzText>
            </View>
            <ChevronRight color={colors.inkFaint} size={20} strokeWidth={2.2} />
          </Card>
        </Pressable>

        <TvzText preset="secondary" style={styles.slotzin}>
          {t('mijnKring.slotzin')}
        </TvzText>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: colors.bg,
  },
  lijst: {
    padding: spacing.screen,
    paddingBottom: 110,
    gap: spacing.md,
  },
  motief: {
    marginBottom: spacing.xs,
  },
  kaart: {
    paddingVertical: spacing.xl,
  },
  kop: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
  },
  kopTekst: {
    flex: 1,
    gap: 4,
  },
  naam: {
    fontSize: 19,
  },
  avatars: {
    flexDirection: 'row',
  },
  avatarOverlap: {
    marginLeft: -14,
  },
  tekst: {
    marginTop: spacing.md,
    fontSize: 17,
  },
  instellingen: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
    paddingVertical: spacing.lg,
  },
  instellingenIcoon: {
    width: 44,
    height: 44,
    borderRadius: radius.tile,
    backgroundColor: colors.tintBlue,
    alignItems: 'center',
    justifyContent: 'center',
  },
  slotzin: {
    textAlign: 'center',
    marginTop: spacing.xs,
    fontSize: 15.5,
  },
});

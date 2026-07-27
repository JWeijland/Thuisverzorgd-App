import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { router, useLocalSearchParams } from 'expo-router';
import { Pressable, ScrollView, StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { useSession } from '@/features/onboarding/useAuth';
import { t } from '@/i18n';
import { supabase } from '@/lib/supabase';
import { colors, radius, spacing } from '@/theme';
import { Avatar, Button, Card, Pill, TvzText } from '@/ui';

type InvitationDetail = {
  id: string;
  circle_id: string;
  kind: 'uitnodiging' | 'aanvraag';
  status: string;
  message: string | null;
  video_done: boolean;
  kring_naam: string;
  owner_id: string;
  profile_id: string | null;
  voornaam: string | null;
  city: string | null;
  helped_count: number | null;
  id_verified: boolean | null;
  waardering: number | null;
  kringen: number | null;
};

/**
 * Aanvraag beoordelen (screen 16): profiel van de vrijwilliger + voorstelbericht.
 * "Toelaten tot de kring" verschijnt pas ná de videokennismaking; afwijzen kan altijd.
 * (De echte videocall via Daily.co volgt; zie docs/PLAN.md · Open punten.)
 */
export default function AanvraagScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const { session } = useSession();
  const queryClient = useQueryClient();

  const invitation = useQuery({
    queryKey: ['invitation', id],
    enabled: !!id,
    queryFn: async (): Promise<InvitationDetail | null> => {
      const { data, error } = await supabase
        .from('v_invitation_detail')
        .select('*')
        .eq('id', id!)
        .maybeSingle();
      if (error) throw error;
      return data as InvitationDetail | null;
    },
  });

  const respond = useMutation({
    mutationFn: async (accept: boolean) => {
      const { error } = await supabase.rpc('respond_invitation', {
        p_invitation: id!,
        p_accept: accept,
      });
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['invitation', id] });
      queryClient.invalidateQueries({ queryKey: ['circle-members'] });
      router.back();
    },
  });

  const markVideo = useMutation({
    mutationFn: async () => {
      const { error } = await supabase.rpc('mark_invitation_video_done', { p_invitation: id! });
      if (error) throw error;
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['invitation', id] }),
  });

  const item = invitation.data;
  const isOwner = item?.owner_id === session?.user.id;
  const isInvitee = item?.profile_id === session?.user.id;
  const open = item?.status === 'open';
  const limietError = respond.error?.message.includes('gratis_limiet');

  return (
    <SafeAreaView style={styles.safe}>
      <ScrollView contentContainerStyle={styles.container}>
        <Pressable accessibilityRole="button" onPress={() => router.back()} style={styles.back}>
          <TvzText preset="cardTitle">←</TvzText>
        </Pressable>
        <TvzText preset="screenTitle" style={styles.title}>
          {item?.kind === 'uitnodiging'
            ? t('aanvraag.titelUitnodiging')
            : t('aanvraag.titelAanvraag')}
        </TvzText>

        {item ? (
          <>
            <Card style={styles.profileCard}>
              <View style={styles.profileRow}>
                <Avatar name={item.voornaam ?? '?'} size={48} />
                <View style={styles.profileInfo}>
                  <TvzText preset="cardTitle">
                    {item.voornaam ?? t('aanvraag.onbekendeVrijwilliger')}
                  </TvzText>
                  <TvzText preset="secondary">
                    {t('aanvraag.onbekendeVrijwilliger')}
                    {item.city ? ` · ${item.city}` : ''}
                  </TvzText>
                </View>
              </View>
              {(item.kringen ?? 0) > 0 ? (
                <Pill
                  label={t('aanvraag.helptIn', { aantal: item.kringen ?? 0 })}
                  style={styles.pill}
                />
              ) : null}
              <View style={styles.ratingRow}>
                {item.waardering ? (
                  <View style={styles.dots}>
                    {[1, 2, 3, 4, 5].map((step) => (
                      <View
                        key={step}
                        style={[
                          styles.ratingDot,
                          {
                            backgroundColor:
                              step <= Math.round(item.waardering ?? 0)
                                ? colors.accent
                                : colors.line,
                          },
                        ]}
                      />
                    ))}
                  </View>
                ) : null}
                <TvzText preset="secondary">
                  {item.waardering ? `${item.waardering}`.replace('.', ',') + ' · ' : ''}
                  {t('aanvraag.metaTaken', {
                    taken: item.helped_count ?? 0,
                    kringen: item.kringen ?? 0,
                  })}
                </TvzText>
              </View>
            </Card>

            {item.message ? (
              <View style={styles.messageCard}>
                <TvzText preset="body" style={styles.message}>
                  “{item.message}”
                </TvzText>
                <TvzText preset="secondary" style={styles.messageMeta}>
                  {item.kind === 'uitnodiging'
                    ? t('aanvraag.uitnodigingVoor', { kring: item.kring_naam })
                    : t('aanvraag.voorstelVan', { naam: item.voornaam ?? '' })}
                </TvzText>
              </View>
            ) : null}

            {!open ? (
              <TvzText preset="secondary" style={styles.done}>
                {t('aanvraag.afgehandeld')}
              </TvzText>
            ) : isOwner && item.kind === 'aanvraag' ? (
              <>
                <Button
                  label={item.video_done ? t('aanvraag.videoGedaan') : t('aanvraag.startVideo')}
                  variant="primary"
                  size="lg"
                  disabled={item.video_done}
                  onPress={() => markVideo.mutate()}
                />
                <TvzText preset="secondary" style={styles.videoNote}>
                  {item.video_done ? t('aanvraag.videoNodig') : t('aanvraag.videoBinnenkort')}
                </TvzText>
                {item.video_done ? (
                  <Button
                    label={t('aanvraag.toelaten')}
                    variant="cta"
                    size="lg"
                    disabled={respond.isPending}
                    onPress={() => respond.mutate(true)}
                    style={styles.action}
                  />
                ) : null}
                {limietError ? (
                  <TvzText preset="secondary" style={styles.limiet}>
                    {t('aanvraag.limiet')}
                  </TvzText>
                ) : null}
                <Button
                  label={t('aanvraag.afwijzen')}
                  variant="outline"
                  disabled={respond.isPending}
                  onPress={() => respond.mutate(false)}
                  style={styles.action}
                />
              </>
            ) : isInvitee && item.kind === 'uitnodiging' ? (
              <>
                <Button
                  label={t('aanvraag.accepteren')}
                  variant="cta"
                  size="lg"
                  disabled={respond.isPending}
                  onPress={() => respond.mutate(true)}
                />
                {limietError ? (
                  <TvzText preset="secondary" style={styles.limiet}>
                    {t('aanvraag.limiet')}
                  </TvzText>
                ) : null}
                <Button
                  label={t('aanvraag.afwijzen')}
                  variant="outline"
                  disabled={respond.isPending}
                  onPress={() => respond.mutate(false)}
                  style={styles.action}
                />
              </>
            ) : null}
          </>
        ) : null}
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: colors.bg,
  },
  container: {
    padding: spacing.screen,
    paddingBottom: 60,
  },
  back: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: colors.surfaceAlt,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing.lg,
  },
  title: {
    marginBottom: spacing.lg,
  },
  profileCard: {
    marginBottom: spacing.cardGap,
  },
  profileRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
  },
  profileInfo: { flex: 1 },
  pill: {
    marginTop: spacing.md,
  },
  ratingRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    marginTop: spacing.md,
    borderTopWidth: 1,
    borderTopColor: colors.line,
    paddingTop: spacing.md,
  },
  dots: {
    flexDirection: 'row',
    gap: 3,
  },
  ratingDot: {
    width: 10,
    height: 10,
    borderRadius: 5,
  },
  messageCard: {
    backgroundColor: colors.surfaceAlt,
    borderRadius: radius.card,
    padding: spacing.lg,
    marginBottom: spacing.xl,
  },
  message: {
    fontStyle: 'italic',
  },
  messageMeta: {
    marginTop: spacing.xs,
    fontSize: 12.5,
  },
  videoNote: {
    textAlign: 'center',
    marginTop: spacing.sm,
    marginBottom: spacing.xs,
    fontSize: 12.5,
    color: colors.inkFaint,
  },
  action: {
    marginTop: spacing.sm,
  },
  limiet: {
    textAlign: 'center',
    marginTop: spacing.sm,
    color: colors.warnText,
  },
  done: {
    textAlign: 'center',
    color: colors.inkFaint,
    marginTop: spacing.md,
  },
});

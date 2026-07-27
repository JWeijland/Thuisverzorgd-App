import { router } from 'expo-router';
import { useState } from 'react';
import { Pressable, ScrollView, StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { NotificationSettings } from '@/features/notifications/NotificationSettings';
import { removePushToken } from '@/features/notifications/push';
import { useProfile } from '@/features/onboarding/useAuth';
import { useSubscription, useUpdateProfile } from '@/features/subscription/api';
import { t } from '@/i18n';
import { supabase } from '@/lib/supabase';
import { WEEKDAY_SHORT } from '@/lib/dates';
import { colors, gradient, radius, spacing, useTextScale } from '@/theme';
import { LinearGradient } from 'expo-linear-gradient';
import { Avatar, BottomSheet, Button, Card, Chip, Pill, Toggle, TvzText } from '@/ui';

const ROLE_LABELS: Record<string, string> = {
  beheerder: 'Beheerder van de kring',
  vrijwilliger: 'Buddy',
  hulpvrager: 'Hulpvrager',
  admin: 'Admin',
  makelaar: 'Hulpmakelaar',
};

const DAY_CODES = ['ma', 'di', 'wo', 'do', 'vr', 'za', 'zo'];

/** Profiel (screens 17/23): rolspecifieke secties + instellingenlijst. */
export default function ProfielScreen() {
  const profile = useProfile();
  const subscription = useSubscription();
  const update = useUpdateProfile();
  const { largeText, setLargeText } = useTextScale();
  const p = profile.data;
  const isVolunteer = p?.role === 'vrijwilliger';
  const isBeheerder = p?.role === 'beheerder';
  const subscribed =
    subscription.data?.status === 'proef' || subscription.data?.status === 'actief';

  const [deleteOpen, setDeleteOpen] = useState(false);
  const [deleteError, setDeleteError] = useState(false);
  const availability = (p as unknown as { availability?: string[] })?.availability ?? [];
  const vacation = p?.vacation_mode ?? false;
  const calendarSync = (p as unknown as { calendar_sync?: boolean })?.calendar_sync ?? false;

  function toggleDay(day: string) {
    const next = availability.includes(day)
      ? availability.filter((code) => code !== day)
      : [...availability, day];
    update.mutate({ availability: next });
  }

  return (
    <SafeAreaView style={styles.safe} edges={['top']}>
      <ScrollView contentContainerStyle={styles.container}>
        <View style={styles.header}>
          <Avatar name={p?.name ?? '?'} size={72} />
          <TvzText preset="screenTitle" style={styles.name}>
            {p?.name ?? ''}
          </TvzText>
          {p?.role ? <Pill label={ROLE_LABELS[p.role] ?? p.role} /> : null}
        </View>

        {isBeheerder ? (
          <Card style={styles.card}>
            <View style={styles.row}>
              <View style={styles.rowText}>
                <TvzText preset="cardTitle">{t('profiel.abonnement')}</TvzText>
                <TvzText preset="secondary">
                  {subscription.data?.status === 'proef'
                    ? t('profiel.proef')
                    : subscribed
                      ? t('profiel.actief')
                      : t('profiel.gratis')}
                </TvzText>
              </View>
              <Button
                label={subscribed ? t('profiel.beheren') : t('profiel.upgraden')}
                variant="outline"
                style={styles.smallButton}
                onPress={() => router.push('/abonnement')}
              />
            </View>
          </Card>
        ) : null}

        {isVolunteer ? (
          <>
            <LinearGradient {...gradient} style={styles.poolCard}>
              <View style={styles.row}>
                <TvzText preset="cardTitle" style={styles.poolTitle}>
                  {t('profiel.poolTitel')}
                </TvzText>
                <Toggle
                  value={p?.pool_opt_in ?? false}
                  onValueChange={(value) => update.mutate({ pool_opt_in: value })}
                  accessibilityLabel={t('profiel.poolTitel')}
                />
              </View>
              <TvzText preset="secondary" style={styles.poolText}>
                {t('profiel.poolUitleg')}
              </TvzText>
            </LinearGradient>

            <Card style={styles.card}>
              <TvzText preset="cardTitle">{t('profiel.beschikbaarheid')}</TvzText>
              <TvzText preset="secondary">{t('profiel.beschikbaarheidUitleg')}</TvzText>
              <View style={styles.days}>
                {DAY_CODES.map((day, i) => (
                  <Chip
                    key={day}
                    label={WEEKDAY_SHORT[i]!}
                    selected={availability.includes(day)}
                    onPress={() => toggleDay(day)}
                  />
                ))}
              </View>
              <View style={[styles.row, styles.rowBorder]}>
                <View style={styles.rowText}>
                  <TvzText preset="cardTitle">{t('profiel.afwezig')}</TvzText>
                  <TvzText preset="secondary">{t('profiel.afwezigUitleg')}</TvzText>
                </View>
                <Toggle
                  value={vacation}
                  onValueChange={(value) => update.mutate({ vacation_mode: value })}
                  accessibilityLabel={t('profiel.afwezig')}
                />
              </View>
              {vacation ? (
                <View style={styles.vacationNote}>
                  <TvzText preset="secondary" style={styles.vacationText}>
                    {t('profiel.afwezigUitleg')}
                  </TvzText>
                </View>
              ) : null}
            </Card>
          </>
        ) : null}

        <Card style={styles.card}>
          <View style={styles.row}>
            <View style={styles.rowText}>
              <TvzText preset="cardTitle">{t('profiel.groteLetters')}</TvzText>
              <TvzText preset="secondary">{t('profiel.groteLettersUitleg')}</TvzText>
            </View>
            <Toggle
              value={largeText}
              onValueChange={setLargeText}
              accessibilityLabel={t('profiel.groteLetters')}
            />
          </View>
          <View style={[styles.row, styles.rowBorder]}>
            <View style={styles.rowText}>
              <TvzText preset="cardTitle">{t('profiel.agenda')}</TvzText>
              <TvzText preset="secondary">{t('profiel.agendaUitleg')}</TvzText>
            </View>
            <Toggle
              value={calendarSync}
              onValueChange={(value) => update.mutate({ calendar_sync: value })}
              accessibilityLabel={t('profiel.agenda')}
            />
          </View>
          <View style={[styles.row, styles.rowBorder]}>
            <TvzText preset="cardTitle">{t('profiel.tvzId')}</TvzText>
            <TvzText preset="secondary">{p?.tvz_id ?? ''}</TvzText>
          </View>
        </Card>

        <NotificationSettings />

        <Button
          label={t('profiel.uitloggen')}
          variant="danger"
          style={styles.logout}
          onPress={async () => {
            await removePushToken();
            supabase.auth.signOut();
          }}
        />
        <Pressable
          accessibilityRole="button"
          onPress={() => setDeleteOpen(true)}
          hitSlop={8}
          style={styles.deleteLink}
        >
          <TvzText preset="secondary" style={styles.deleteText}>
            {t('account.verwijderen')}
          </TvzText>
        </Pressable>
      </ScrollView>

      <BottomSheet
        visible={deleteOpen}
        onClose={() => setDeleteOpen(false)}
        title={t('account.verwijderen')}
      >
        <TvzText preset="secondary">{t('account.verwijderenUitleg')}</TvzText>
        {deleteError ? (
          <TvzText preset="secondary" style={styles.deleteText}>
            {t('account.verwijderenMislukt')}
          </TvzText>
        ) : null}
        <Button
          label={t('account.verwijderenBevestig')}
          variant="danger"
          size="lg"
          style={styles.logout}
          onPress={async () => {
            setDeleteError(false);
            const { error } = await supabase.functions.invoke('delete-account');
            if (error) {
              setDeleteError(true);
              return;
            }
            await removePushToken();
            supabase.auth.signOut();
          }}
        />
        <Button
          label={t('abonnement.later')}
          variant="outline"
          style={styles.logout}
          onPress={() => setDeleteOpen(false)}
        />
      </BottomSheet>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1 },
  container: {
    padding: spacing.screen,
    paddingBottom: 110,
  },
  header: {
    alignItems: 'center',
    gap: spacing.sm,
    marginBottom: spacing.xl,
  },
  name: {
    fontSize: 22,
  },
  card: {
    marginBottom: spacing.md,
  },
  poolCard: {
    borderRadius: radius.card,
    padding: spacing.cardPadding,
    marginBottom: spacing.md,
  },
  poolTitle: {
    color: colors.white,
    flex: 1,
  },
  poolText: {
    color: 'rgba(255,255,255,0.85)',
    marginTop: spacing.sm,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: spacing.xs,
  },
  rowBorder: {
    borderTopWidth: 1,
    borderTopColor: colors.line,
    marginTop: spacing.md,
    paddingTop: spacing.md,
  },
  rowText: {
    flex: 1,
    paddingRight: spacing.md,
  },
  smallButton: {
    minHeight: 38,
    paddingVertical: 6,
    paddingHorizontal: 16,
  },
  days: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing.chipGap,
    marginTop: spacing.md,
  },
  vacationNote: {
    backgroundColor: colors.warnBg,
    borderRadius: radius.row,
    padding: spacing.md,
    marginTop: spacing.md,
  },
  vacationText: {
    color: colors.warnText,
  },
  logout: {
    marginTop: spacing.sm,
  },
  deleteLink: {
    alignSelf: 'center',
    marginTop: spacing.lg,
  },
  deleteText: {
    color: colors.error,
    textAlign: 'center',
  },
});

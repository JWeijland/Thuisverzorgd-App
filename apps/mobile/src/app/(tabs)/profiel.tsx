import { useQueryClient } from '@tanstack/react-query';
import { decode } from 'base64-arraybuffer';
import * as ImagePicker from 'expo-image-picker';
import { router } from 'expo-router';
import { useState } from 'react';
import { Pressable, ScrollView, StyleSheet, View } from 'react-native';
import { Camera, Images } from 'lucide-react-native';

import { ProfileAvatar } from '@/features/avatars/ProfileAvatar';
import { NotificationSettings } from '@/features/notifications/NotificationSettings';
import { removePushToken } from '@/features/notifications/push';
import { useProfile } from '@/features/onboarding/useAuth';
import { useSubscription, useUpdateProfile } from '@/features/subscription/api';
import { t } from '@/i18n';
import { supabase } from '@/lib/supabase';
import { WEEKDAY_SHORT, isoWeekKey, isoWeekNumber } from '@/lib/dates';
import { colors, gradient, radius, spacing, useTextScale } from '@/theme';
import { LinearGradient } from 'expo-linear-gradient';
import {
  BottomSheet,
  Button,
  Card,
  Chip,
  GradientHeader,
  Pill,
  TextField,
  Toggle,
  TvzText,
} from '@/ui';

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

  const queryClient = useQueryClient();
  const [deleteOpen, setDeleteOpen] = useState(false);
  const [deleteError, setDeleteError] = useState(false);
  const [photoOpen, setPhotoOpen] = useState(false);
  const [photoBusy, setPhotoBusy] = useState(false);
  const [photoError, setPhotoError] = useState(false);
  const [roleOpen, setRoleOpen] = useState(false);
  const [roleBusy, setRoleBusy] = useState(false);
  const [roleError, setRoleError] = useState(false);
  const [passOpen, setPassOpen] = useState(false);
  const [passNew, setPassNew] = useState('');
  const [passRepeat, setPassRepeat] = useState('');
  const [passBusy, setPassBusy] = useState(false);
  const [passFeedback, setPassFeedback] = useState<'gelukt' | 'mislukt' | null>(null);
  const [passError, setPassError] = useState<string | undefined>();

  async function savePassword() {
    if (passBusy) return;
    if (passNew.length < 8) {
      setPassError(t('profiel.wachtwoordTeKort'));
      return;
    }
    if (passNew !== passRepeat) {
      setPassError(t('profiel.wachtwoordOngelijk'));
      return;
    }
    setPassError(undefined);
    setPassBusy(true);
    const { error } = await supabase.auth.updateUser({ password: passNew });
    setPassBusy(false);
    if (error) {
      setPassFeedback('mislukt');
      return;
    }
    setPassNew('');
    setPassRepeat('');
    setPassFeedback('gelukt');
  }
  const canChangeRole =
    p?.role === 'beheerder' || p?.role === 'vrijwilliger' || p?.role === 'hulpvrager';

  async function switchRole(role: 'beheerder' | 'vrijwilliger' | 'hulpvrager') {
    if (roleBusy) return;
    if (role === p?.role) {
      setRoleOpen(false);
      return;
    }
    setRoleBusy(true);
    setRoleError(false);
    const { error } = await supabase.rpc('change_role', { p_role: role });
    setRoleBusy(false);
    if (error) {
      setRoleError(true);
      return;
    }
    await queryClient.invalidateQueries();
    setRoleOpen(false);
    router.replace('/');
  }
  const availability = (p as unknown as { availability?: string[] })?.availability ?? [];
  const availabilityWeeks = p?.availability_weeks ?? {};
  const vacation = p?.vacation_mode ?? false;
  const calendarSync = (p as unknown as { calendar_sync?: boolean })?.calendar_sync ?? false;

  // Beschikbaarheid is per week in te stellen voor de komende vier weken;
  // zonder eigen invulling geldt het vaste weekpatroon (standaard: alle dagen).
  const [weekOffset, setWeekOffset] = useState(0);
  const weekDates = [0, 1, 2, 3].map((offset) => {
    const d = new Date();
    d.setDate(d.getDate() + offset * 7);
    return d;
  });
  const weekKey = isoWeekKey(weekDates[weekOffset]!);
  const weekDays = availabilityWeeks[weekKey] ?? availability;

  function toggleDay(day: string) {
    const next = weekDays.includes(day)
      ? weekDays.filter((code) => code !== day)
      : [...weekDays, day];
    update.mutate({ availability_weeks: { ...availabilityWeeks, [weekKey]: next } });
  }

  const PHOTO_OPTIONS = {
    mediaTypes: 'images' as const,
    quality: 0.6,
    base64: true,
    allowsEditing: true,
    aspect: [1, 1] as [number, number],
  };

  async function savePhoto(result: ImagePicker.ImagePickerResult) {
    const asset = !result.canceled ? result.assets[0] : undefined;
    if (!asset?.base64 || !p) {
      setPhotoOpen(false);
      return;
    }
    setPhotoBusy(true);
    setPhotoError(false);
    try {
      const path = `${p.id}/avatar.jpg`;
      const { error: uploadError } = await supabase.storage
        .from('avatars')
        .upload(path, decode(asset.base64), { contentType: 'image/jpeg', upsert: true });
      if (uploadError) throw uploadError;
      const { error: updateError } = await supabase
        .from('profiles')
        .update({ avatar_path: path })
        .eq('id', p.id);
      if (updateError) throw updateError;
      await queryClient.invalidateQueries({ queryKey: ['avatar-url'] });
      await queryClient.invalidateQueries({ queryKey: ['profile'] });
      setPhotoOpen(false);
    } catch {
      setPhotoError(true);
    } finally {
      setPhotoBusy(false);
    }
  }

  async function photoFromCamera() {
    const permission = await ImagePicker.requestCameraPermissionsAsync();
    if (!permission.granted) return;
    savePhoto(await ImagePicker.launchCameraAsync(PHOTO_OPTIONS));
  }

  async function photoFromLibrary() {
    savePhoto(await ImagePicker.launchImageLibraryAsync(PHOTO_OPTIONS));
  }

  return (
    <View style={styles.safe}>
      <GradientHeader title={t('profiel.titel')} subtitle={t('profiel.subtitel')} />
      <ScrollView contentContainerStyle={styles.container}>
        <View style={styles.header}>
          <Pressable
            accessibilityRole="button"
            accessibilityLabel={t('profiel.fotoWijzigen')}
            onPress={() => setPhotoOpen(true)}
            style={styles.avatarWrap}
          >
            <ProfileAvatar name={p?.name ?? '?'} avatarPath={p?.avatar_path} size={72} />
            <View style={styles.avatarBadge}>
              <Camera color={colors.white} size={13} strokeWidth={2.2} />
            </View>
          </Pressable>
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
              <View style={styles.poolRij}>
                <View style={styles.rowText}>
                  <TvzText preset="cardTitle" style={styles.poolTitle}>
                    {t('profiel.spontaanTitel')}
                  </TvzText>
                  <TvzText preset="secondary" style={styles.poolText}>
                    {t('profiel.spontaanUitleg')}
                  </TvzText>
                </View>
                <Toggle
                  value={p?.spontaneous_available ?? true}
                  onValueChange={(value) => update.mutate({ spontaneous_available: value })}
                  accessibilityLabel={t('profiel.spontaanTitel')}
                />
              </View>
            </LinearGradient>

            <Card style={styles.card}>
              <TvzText preset="cardTitle">{t('profiel.beschikbaarheid')}</TvzText>
              <TvzText preset="secondary">{t('profiel.beschikbaarheidUitleg')}</TvzText>
              <View style={styles.days}>
                {weekDates.map((date, offset) => (
                  <Chip
                    key={offset}
                    label={
                      offset === 0
                        ? t('profiel.dezeWeek', { week: isoWeekNumber(date) })
                        : t('profiel.weekLabel', { week: isoWeekNumber(date) })
                    }
                    selected={weekOffset === offset}
                    onPress={() => setWeekOffset(offset)}
                  />
                ))}
              </View>
              <View style={styles.days}>
                {DAY_CODES.map((day, i) => (
                  <Chip
                    key={day}
                    label={WEEKDAY_SHORT[i]!}
                    selected={weekDays.includes(day)}
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
          <View style={[styles.row, styles.rowBorder]}>
            <View style={styles.rowText}>
              <TvzText preset="cardTitle">{t('profiel.wachtwoordTitel')}</TvzText>
              <TvzText preset="secondary">{t('profiel.wachtwoordUitleg')}</TvzText>
            </View>
            <Button
              label={t('profiel.wachtwoordKnop')}
              variant="outline"
              style={styles.smallButton}
              onPress={() => {
                setPassFeedback(null);
                setPassError(undefined);
                setPassOpen(true);
              }}
            />
          </View>
          {canChangeRole ? (
            <View style={[styles.row, styles.rowBorder]}>
              <View style={styles.rowText}>
                <TvzText preset="cardTitle">{t('profiel.rolTitel')}</TvzText>
                <TvzText preset="secondary">{p?.role ? (ROLE_LABELS[p.role] ?? '') : ''}</TvzText>
              </View>
              <Button
                label={t('profiel.rolWijzigen')}
                variant="outline"
                style={styles.smallButton}
                onPress={() => setRoleOpen(true)}
              />
            </View>
          ) : null}
        </Card>

        {p?.platform_admin || p?.role === 'admin' ? (
          <Card style={styles.card}>
            <View style={styles.row}>
              <View style={styles.rowText}>
                <TvzText preset="cardTitle">{t('profiel.adminTitel')}</TvzText>
                <TvzText preset="secondary">{t('profiel.adminUitleg')}</TvzText>
              </View>
              <Button
                label={t('profiel.adminOpenen')}
                variant="outline"
                style={styles.smallButton}
                onPress={() => router.push('/admin')}
              />
            </View>
          </Card>
        ) : null}

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
        visible={passOpen}
        onClose={() => setPassOpen(false)}
        title={t('profiel.wachtwoordSheetTitel')}
      >
        {passFeedback === 'gelukt' ? (
          <>
            <TvzText preset="secondary" style={styles.passGelukt}>
              {t('profiel.wachtwoordGelukt')}
            </TvzText>
            <Button
              label={t('algemeen.sluiten')}
              variant="outline"
              style={styles.logout}
              onPress={() => setPassOpen(false)}
            />
          </>
        ) : (
          <>
            <TvzText preset="secondary" style={styles.passUitleg}>
              {t('profiel.wachtwoordSheetUitleg')}
            </TvzText>
            <TextField
              label={t('profiel.wachtwoordNieuw')}
              placeholder="••••••••"
              value={passNew}
              onChangeText={setPassNew}
              secureTextEntry
              autoCapitalize="none"
              autoComplete="new-password"
            />
            <TextField
              label={t('profiel.wachtwoordHerhaal')}
              placeholder="••••••••"
              value={passRepeat}
              onChangeText={setPassRepeat}
              secureTextEntry
              autoCapitalize="none"
              autoComplete="new-password"
              error={passError}
            />
            {passFeedback === 'mislukt' ? (
              <TvzText preset="secondary" style={styles.deleteText}>
                {t('profiel.wachtwoordMislukt')}
              </TvzText>
            ) : null}
            <Button
              label={passBusy ? t('algemeen.laden') : t('profiel.wachtwoordOpslaan')}
              variant="primary"
              size="lg"
              disabled={passBusy}
              onPress={savePassword}
            />
          </>
        )}
      </BottomSheet>

      <BottomSheet
        visible={roleOpen}
        onClose={() => setRoleOpen(false)}
        title={t('profiel.rolSheetTitel')}
      >
        <TvzText preset="secondary" style={styles.rolUitleg}>
          {t('profiel.rolSheetUitleg')}
        </TvzText>
        {(
          [
            ['beheerder', 'rolkeuze.beheerderTitel', 'rolkeuze.beheerderUitleg'],
            ['vrijwilliger', 'rolkeuze.vrijwilligerTitel', 'rolkeuze.vrijwilligerUitleg'],
            ['hulpvrager', 'profiel.rolHulpvragerTitel', 'profiel.rolHulpvragerUitleg'],
          ] as const
        ).map(([role, titelKey, uitlegKey]) => (
          <Pressable
            key={role}
            accessibilityRole="button"
            accessibilityState={{ selected: p?.role === role }}
            disabled={roleBusy}
            onPress={() => switchRole(role)}
            style={[styles.rolOptie, p?.role === role && styles.rolOptieActief]}
          >
            <View style={styles.rowText}>
              <TvzText preset="cardTitle">{t(titelKey)}</TvzText>
              <TvzText preset="secondary">{t(uitlegKey)}</TvzText>
            </View>
            {p?.role === role ? (
              <TvzText preset="cardTitle" style={styles.rolVink}>
                ✓
              </TvzText>
            ) : null}
          </Pressable>
        ))}
        {roleBusy ? <TvzText preset="secondary">{t('algemeen.laden')}</TvzText> : null}
        {roleError ? (
          <TvzText preset="secondary" style={styles.deleteText}>
            {t('profiel.rolFout')}
          </TvzText>
        ) : null}
      </BottomSheet>

      <BottomSheet
        visible={photoOpen}
        onClose={() => setPhotoOpen(false)}
        title={t('profiel.fotoWijzigen')}
      >
        {photoBusy ? (
          <TvzText preset="secondary">{t('algemeen.laden')}</TvzText>
        ) : (
          <>
            <Pressable accessibilityRole="button" onPress={photoFromCamera} style={styles.photoRow}>
              <Camera color={colors.primary} size={22} strokeWidth={2.2} />
              <TvzText preset="cardTitle" style={styles.photoLabel}>
                {t('idFoto.maakFoto')}
              </TvzText>
            </Pressable>
            <Pressable
              accessibilityRole="button"
              onPress={photoFromLibrary}
              style={styles.photoRow}
            >
              <Images color={colors.primary} size={22} strokeWidth={2.2} />
              <TvzText preset="cardTitle" style={styles.photoLabel}>
                {t('idFoto.uitBibliotheek')}
              </TvzText>
            </Pressable>
            {photoError ? (
              <TvzText preset="secondary" style={styles.deleteText}>
                {t('idFoto.uploadMislukt')}
              </TvzText>
            ) : null}
          </>
        )}
      </BottomSheet>

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
    </View>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: colors.bg },
  container: {
    padding: spacing.screen,
    paddingBottom: 110,
  },
  header: {
    alignItems: 'center',
    gap: spacing.sm,
    marginBottom: spacing.xl,
  },
  avatarWrap: {
    position: 'relative',
  },
  avatarBadge: {
    position: 'absolute',
    right: -2,
    bottom: -2,
    width: 26,
    height: 26,
    borderRadius: 13,
    backgroundColor: colors.primary,
    borderWidth: 2,
    borderColor: colors.white,
    alignItems: 'center',
    justifyContent: 'center',
  },
  photoRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
    paddingVertical: spacing.lg,
    borderBottomWidth: 1,
    borderBottomColor: colors.line,
    minHeight: 56,
  },
  photoLabel: {
    fontSize: 16,
  },
  rolUitleg: {
    marginBottom: spacing.md,
  },
  rolOptie: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
    borderWidth: 1.5,
    borderColor: colors.line,
    borderRadius: radius.card,
    padding: spacing.lg,
    marginBottom: spacing.sm,
  },
  rolOptieActief: {
    borderColor: colors.primaryMid,
    backgroundColor: colors.tintBlue,
  },
  rolVink: {
    color: colors.primaryMid,
  },
  passUitleg: {
    marginBottom: spacing.md,
  },
  passGelukt: {
    color: colors.successText,
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
  poolRij: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: spacing.md,
    paddingTop: spacing.md,
    borderTopWidth: 1,
    borderTopColor: 'rgba(255,255,255,0.25)',
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

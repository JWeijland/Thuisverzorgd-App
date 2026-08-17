import { useQueryClient } from '@tanstack/react-query';
import { decode } from 'base64-arraybuffer';
import * as ImagePicker from 'expo-image-picker';
import { router } from 'expo-router';
import { useState } from 'react';
import { Keyboard, Pressable, ScrollView, StyleSheet, View } from 'react-native';
import { Camera, Check, Images } from 'lucide-react-native';

import { ProfileAvatar } from '@/features/avatars/ProfileAvatar';
import { NotificationSettings } from '@/features/notifications/NotificationSettings';
import { useProfile } from '@/features/onboarding/useAuth';
import { logUit } from '@/features/onboarding/uitloggen';
import { STRAAL_OPTIES, dichtstbijzijndeStraal, straalLabel } from '@/features/onboarding/straal';
import { KeuzeRij } from '@/ui/KeuzeRij';
import { useUpdateProfile } from '@/features/profile/api';
import { t } from '@/i18n';
import { supabase } from '@/lib/supabase';
import { WEEKDAY_SHORT, isoWeekKey, isoWeekNumber } from '@/lib/dates';
import { colors, radius, spacing, useTextScale } from '@/theme';
import {
  BottomSheet,
  Button,
  Card,
  GradientHeader,
  TextField,
  Toggle,
  TvzText,
} from '@/ui';

const ROLE_LABELS: Record<string, string> = {
  beheerder: 'Beheerder van de kring',
  vrijwilliger: 'Buddy',
  hulpvrager: 'Hulpvrager',
  aanbieder: 'Aanbieder',
  admin: 'Admin',
  makelaar: 'Hulpmakelaar',
};

const DAY_CODES = ['ma', 'di', 'wo', 'do', 'vr', 'za', 'zo'];

/** Profiel (screens 17/23): rolspecifieke secties + instellingenlijst. */
export default function ProfielScreen() {
  const profile = useProfile();
  const update = useUpdateProfile();
  const { largeText, setLargeText } = useTextScale();
  const p = profile.data;
  const isVolunteer = p?.role === 'vrijwilliger';

  const queryClient = useQueryClient();
  const [deleteOpen, setDeleteOpen] = useState(false);
  const [deleteError, setDeleteError] = useState(false);
  const [photoOpen, setPhotoOpen] = useState(false);
  // null = nog niet zelf getypt; dan geldt wat er op het profiel staat.
  const [eigenBio, setEigenBio] = useState<string | null>(null);
  const [bioBewaard, setBioBewaard] = useState(false);
  const bio = eigenBio ?? p?.bio ?? '';
  const setBio = setEigenBio;
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
  const [mailOpen, setMailOpen] = useState(false);
  const [mailNieuw, setMailNieuw] = useState('');
  const [mailBusy, setMailBusy] = useState(false);
  const [mailFeedback, setMailFeedback] = useState<'gelukt' | 'mislukt' | null>(null);
  const [mailError, setMailError] = useState<string | undefined>();

  /** E-mailadres toevoegen aan een gebruikersnaam-account (voor herstel). */
  async function saveMail() {
    if (mailBusy) return;
    const adres = mailNieuw.trim().toLowerCase();
    if (!/^\S+@\S+\.\S+$/.test(adres)) {
      setMailError(t('account.emailOngeldig'));
      return;
    }
    setMailError(undefined);
    setMailBusy(true);
    const { error } = await supabase.auth.updateUser({ email: adres });
    if (error) {
      setMailBusy(false);
      setMailFeedback('mislukt');
      return;
    }
    // Ook in het profiel zetten: daar leest de app het adres (en uitnodigingen
    // op e-mail zoeken erop).
    if (p) {
      await supabase.from('profiles').update({ email: adres }).eq('id', p.id);
      await queryClient.invalidateQueries({ queryKey: ['profile'] });
    }
    setMailBusy(false);
    setMailNieuw('');
    setMailFeedback('gelukt');
  }

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
    // Toetsenbord weg, anders staat de bevestiging erachter.
    Keyboard.dismiss();
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
      <GradientHeader title={t('profiel.titel')} subtitle={t('profiel.subtitel')} wobbel terug />
      <ScrollView contentContainerStyle={styles.container}>
        {/* Foto links, naam en rol ernaast als gewone tekst. De pil om de rol
            is weg; de instellingen staan er rustig onder in plaats van in een
            groot gekleurd blok (feedback Jelle 11-08). */}
        <View style={styles.header}>
          <Pressable
            accessibilityRole="button"
            accessibilityLabel={t('profiel.fotoWijzigen')}
            onPress={() => setPhotoOpen(true)}
            style={styles.avatarWrap}
          >
            <ProfileAvatar name={p?.name ?? '?'} avatarPath={p?.avatar_path} size={68} />
            <View style={styles.avatarBadge}>
              <Camera color={colors.white} size={13} strokeWidth={2.2} />
            </View>
          </Pressable>
          <View style={styles.headerTekst}>
            <TvzText preset="screenTitle" style={styles.name} numberOfLines={1}>
              {p?.name ?? ''}
            </TvzText>
            {p?.role ? (
              <TvzText preset="secondary">{ROLE_LABELS[p.role] ?? p.role}</TvzText>
            ) : null}
          </View>
        </View>

        {isVolunteer ? (
          <>
            <Card style={styles.card}>
              <View style={styles.row}>
                <View style={styles.rowText}>
                  <TvzText preset="cardTitle">{t('profiel.poolTitel')}</TvzText>
                  <TvzText preset="secondary">{t('profiel.poolUitleg')}</TvzText>
                </View>
                <Toggle
                  value={p?.pool_opt_in ?? false}
                  onValueChange={(value) => update.mutate({ pool_opt_in: value })}
                  accessibilityLabel={t('profiel.poolTitel')}
                />
              </View>

              <View style={[styles.row, styles.rowBorder]}>
                <View style={styles.rowText}>
                  <TvzText preset="cardTitle">{t('profiel.spontaanTitel')}</TvzText>
                  <TvzText preset="secondary">{t('profiel.spontaanUitleg')}</TvzText>
                </View>
                <Toggle
                  value={p?.spontaneous_available ?? true}
                  onValueChange={(value) => update.mutate({ spontaneous_available: value })}
                  accessibilityLabel={t('profiel.spontaanTitel')}
                />
              </View>

              {/* De afstand bepaalt welke hulpvragen en kringen je ziet, en
                  voor welke kringen jij als buddy in beeld komt. */}
              <View style={[styles.straalBlok, styles.rowBorder]}>
                <TvzText preset="cardTitle">{t('profiel.straalTitel')}</TvzText>
                <TvzText preset="secondary">{t('profiel.straalUitleg')}</TvzText>
                <ScrollView
                  horizontal
                  showsHorizontalScrollIndicator={false}
                  contentContainerStyle={styles.straalRij}
                >
                  <KeuzeRij
                    opties={STRAAL_OPTIES.map((meters) => ({
                      waarde: String(meters),
                      label: straalLabel(meters),
                    }))}
                    gekozen={String(dichtstbijzijndeStraal(p?.help_radius_m))}
                    onKies={(waarde) => update.mutate({ help_radius_m: Number(waarde) })}
                  />
                </ScrollView>
              </View>
            </Card>

            {/* Je eigen woorden staan op je buddykaartje: een beheerder leest
                dit voordat hij je bij iemand thuis uitnodigt (wens Jelle
                11-08). */}
            <Card style={styles.card}>
              <TvzText preset="cardTitle">{t('profiel.bioTitel')}</TvzText>
              <TvzText preset="secondary">{t('profiel.bioUitleg')}</TvzText>
              <TextField
                label={t('profiel.bioTitel')}
                placeholder={t('profiel.bioPlaceholder')}
                value={bio}
                onChangeText={(tekst) => {
                  setBioBewaard(false);
                  setBio(tekst);
                }}
                multiline
              />
              <Button
                label={bioBewaard ? t('profiel.bioBewaard') : t('profiel.bioBewaren')}
                variant={bioBewaard ? 'outline' : 'cta'}
                disabled={bioBewaard || update.isPending || bio.trim() === (p?.bio ?? '')}
                onPress={() => {
                  update.mutate(
                    { bio: bio.trim() || null },
                    { onSuccess: () => setBioBewaard(true) },
                  );
                }}
                style={styles.bioKnop}
              />
            </Card>

            <Card style={styles.card}>
              <TvzText preset="cardTitle">{t('profiel.beschikbaarheid')}</TvzText>
              <TvzText preset="secondary">{t('profiel.beschikbaarheidUitleg')}</TvzText>
              <View style={styles.weken}>
                <KeuzeRij
                  opties={weekDates.map((date, offset) => ({
                    waarde: String(offset),
                    label:
                      offset === 0
                        ? t('profiel.dezeWeek', { week: isoWeekNumber(date) })
                        : t('profiel.weekLabel', { week: isoWeekNumber(date) }),
                  }))}
                  gekozen={String(weekOffset)}
                  onKies={(waarde) => setWeekOffset(Number(waarde))}
                />
              </View>
              {/* Dagen als vierkante vakjes, zoals de dagbalk bij inplannen. */}
              <View style={styles.dagBalk}>
                {DAY_CODES.map((day, i) => {
                  const aan = weekDays.includes(day);
                  return (
                    <Pressable
                      key={day}
                      accessibilityRole="checkbox"
                      accessibilityState={{ checked: aan }}
                      accessibilityLabel={WEEKDAY_SHORT[i]!}
                      onPress={() => toggleDay(day)}
                      style={[styles.dag, aan && styles.dagAan]}
                    >
                      <TvzText preset="meta" style={aan ? styles.dagTekstAan : undefined}>
                        {WEEKDAY_SHORT[i]}
                      </TvzText>
                    </Pressable>
                  );
                })}
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
          {p?.username ? (
            <View style={[styles.row, styles.rowBorder]}>
              <TvzText preset="cardTitle">{t('profiel.gebruikersnaam')}</TvzText>
              <TvzText preset="secondary">{p.username}</TvzText>
            </View>
          ) : null}
          <View style={[styles.row, styles.rowBorder]}>
            <TvzText preset="cardTitle">{t('profiel.tvzId')}</TvzText>
            <TvzText preset="secondary">{p?.tvz_id ?? ''}</TvzText>
          </View>
          {!p?.email ? (
            <View style={[styles.row, styles.rowBorder]}>
              <View style={styles.rowText}>
                <TvzText preset="cardTitle">{t('profiel.mailTitel')}</TvzText>
                <TvzText preset="secondary">{t('profiel.mailUitleg')}</TvzText>
              </View>
              <Button
                label={t('profiel.mailKnop')}
                variant="outline"
                style={styles.smallButton}
                onPress={() => {
                  setMailFeedback(null);
                  setMailError(undefined);
                  setMailOpen(true);
                }}
              />
            </View>
          ) : null}
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
          onPress={logUit}
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
        visible={mailOpen}
        onClose={() => setMailOpen(false)}
        title={t('profiel.mailSheetTitel')}
      >
        {mailFeedback === 'gelukt' ? (
          <>
            <View style={styles.geluktBlok}>
              <View style={styles.geluktRing}>
                <Check color={colors.white} size={30} strokeWidth={3} />
              </View>
              <TvzText preset="cardTitle" style={styles.geluktTitel}>
                {t('profiel.mailGeluktTitel')}
              </TvzText>
              <TvzText preset="secondary" style={styles.geluktTekst}>
                {t('profiel.mailGelukt')}
              </TvzText>
            </View>
            <Button
              label={t('algemeen.klaar')}
              variant="cta"
              size="lg"
              onPress={() => setMailOpen(false)}
            />
          </>
        ) : (
          <>
            <TvzText preset="secondary" style={styles.passUitleg}>
              {t('profiel.mailSheetUitleg')}
            </TvzText>
            <TextField
              label={t('account.emailLabel')}
              placeholder={t('account.emailPlaceholder')}
              value={mailNieuw}
              onChangeText={setMailNieuw}
              autoCapitalize="none"
              autoComplete="email"
              keyboardType="email-address"
              error={mailError}
            />
            {mailFeedback === 'mislukt' ? (
              <TvzText preset="secondary" style={styles.deleteText}>
                {t('profiel.mailMislukt')}
              </TvzText>
            ) : null}
            <Button
              label={mailBusy ? t('algemeen.laden') : t('profiel.mailOpslaan')}
              variant="primary"
              size="lg"
              disabled={mailBusy}
              onPress={saveMail}
            />
          </>
        )}
      </BottomSheet>

      <BottomSheet
        visible={passOpen}
        onClose={() => setPassOpen(false)}
        title={t('profiel.wachtwoordSheetTitel')}
      >
        {passFeedback === 'gelukt' ? (
          <>
            <View style={styles.geluktBlok}>
              <View style={styles.geluktRing}>
                <Check color={colors.white} size={30} strokeWidth={3} />
              </View>
              <TvzText preset="cardTitle" style={styles.geluktTitel}>
                {t('profiel.wachtwoordGeluktTitel')}
              </TvzText>
              <TvzText preset="secondary" style={styles.geluktTekst}>
                {t('profiel.wachtwoordGelukt')}
              </TvzText>
            </View>
            <Button
              label={t('algemeen.klaar')}
              variant="cta"
              size="lg"
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
            await logUit();
          }}
        />
        <Button
          label={t('algemeen.sluiten')}
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
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.lg,
    marginBottom: spacing.xl,
  },
  headerTekst: {
    flex: 1,
  },
  straalRij: {
    paddingRight: spacing.screen,
  },
  weken: {
    marginTop: spacing.sm,
  },
  dagBalk: {
    flexDirection: 'row',
    gap: 6,
    marginTop: spacing.md,
  },
  dag: {
    flex: 1,
    minHeight: 44,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: radius.row,
    backgroundColor: colors.white,
    borderWidth: 1.5,
    borderColor: colors.line,
  },
  dagAan: {
    backgroundColor: colors.primary,
    borderColor: colors.primary,
  },
  dagTekstAan: {
    color: colors.white,
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
  // Onmiskenbare bevestiging: groene cirkel met vinkje.
  geluktBlok: {
    alignItems: 'center',
    paddingVertical: spacing.lg,
    gap: spacing.sm,
  },
  geluktRing: {
    width: 64,
    height: 64,
    borderRadius: 32,
    backgroundColor: colors.accentDark,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing.sm,
  },
  geluktTitel: {
    color: colors.successText,
  },
  geluktTekst: {
    textAlign: 'center',
  },
  name: {
    fontSize: 22,
  },
  bioKnop: {
    marginTop: spacing.sm,
    alignSelf: 'flex-start',
    paddingHorizontal: 22,
  },
  card: {
    marginBottom: spacing.md,
  },
  straalBlok: {
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

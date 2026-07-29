import { useQueryClient } from '@tanstack/react-query';
import { decode } from 'base64-arraybuffer';
import { Image } from 'expo-image';
import * as ImagePicker from 'expo-image-picker';
import { router } from 'expo-router';
import { useState } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Camera, CreditCard, Images, User } from 'lucide-react-native';

import { useSession } from '@/features/onboarding/useAuth';
import { t } from '@/i18n';
import { supabase } from '@/lib/supabase';
import { colors, dashedBorder, radius, spacing } from '@/theme';
import { BottomSheet, Button, TvzText } from '@/ui';

type Slot = 'id' | 'foto';
type Picked = { uri: string; base64: string };

const PICKER_OPTIONS = {
  mediaTypes: 'images' as const,
  quality: 0.6,
  base64: true,
};

/**
 * ID + profielfoto (screen 18): alleen voor vrijwilligers, één keer bij registratie.
 * Foto's via camera óf bibliotheek; upload als base64 (betrouwbaar in productie).
 * Alleen de bevestiging wordt bewaard; het ID-document is kortlopend (ADR-0005).
 */
export default function IdEnFotoScreen() {
  const { session } = useSession();
  const queryClient = useQueryClient();
  const [picked, setPicked] = useState<{ id?: Picked; foto?: Picked }>({});
  const [choosing, setChoosing] = useState<Slot | null>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | undefined>();

  function handleResult(slot: Slot, result: ImagePicker.ImagePickerResult) {
    const asset = !result.canceled ? result.assets[0] : undefined;
    if (asset?.base64) {
      setPicked((prev) => ({ ...prev, [slot]: { uri: asset.uri, base64: asset.base64! } }));
    }
    setChoosing(null);
  }

  async function pickFromCamera(slot: Slot) {
    const permission = await ImagePicker.requestCameraPermissionsAsync();
    if (!permission.granted) {
      setChoosing(null);
      return;
    }
    const result = await ImagePicker.launchCameraAsync({
      ...PICKER_OPTIONS,
      allowsEditing: slot === 'foto',
      aspect: slot === 'foto' ? [1, 1] : undefined,
    });
    handleResult(slot, result);
  }

  async function pickFromLibrary(slot: Slot) {
    const result = await ImagePicker.launchImageLibraryAsync({
      ...PICKER_OPTIONS,
      allowsEditing: slot === 'foto',
      aspect: slot === 'foto' ? [1, 1] : undefined,
    });
    handleResult(slot, result);
  }

  async function upload(bucket: string, path: string, item: Picked) {
    const { error: uploadError } = await supabase.storage
      .from(bucket)
      .upload(path, decode(item.base64), { contentType: 'image/jpeg', upsert: true });
    if (uploadError) throw uploadError;
  }

  async function submit() {
    if (!session || !picked.id || !picked.foto || busy) return;
    setBusy(true);
    setError(undefined);
    try {
      const uid = session.user.id;
      await upload('id-documents', `${uid}/id.jpg`, picked.id);
      await upload('avatars', `${uid}/avatar.jpg`, picked.foto);
      const { error: updateError } = await supabase
        .from('profiles')
        .update({
          id_verified: true,
          id_verified_at: new Date().toISOString(),
          avatar_path: `${uid}/avatar.jpg`,
        })
        .eq('id', uid);
      if (updateError) throw updateError;
      await queryClient.invalidateQueries({ queryKey: ['profile'] });
      router.replace('/rooster');
    } catch (err) {
      const detail = err instanceof Error ? ` (${err.message})` : '';
      setError(`${t('idFoto.uploadMislukt')}${detail}`);
      setBusy(false);
    }
  }

  const ready = !!picked.id && !!picked.foto;

  return (
    <SafeAreaView style={styles.safe}>
      <View style={styles.container}>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={t('algemeen.terug')}
          onPress={() => router.replace('/rolkeuze')}
          style={styles.back}
        >
          <TvzText preset="cardTitle">←</TvzText>
        </Pressable>
        <TvzText preset="screenTitle">{t('idFoto.titel')}</TvzText>
        <TvzText preset="secondary" style={styles.uitleg}>
          {t('idFoto.uitleg')}
        </TvzText>

        <View style={styles.tiles}>
          <Pressable
            accessibilityRole="button"
            onPress={() => setChoosing('id')}
            style={styles.tile}
          >
            {picked.id ? (
              <Image source={{ uri: picked.id.uri }} style={styles.preview} />
            ) : (
              <CreditCard color={colors.primaryMid} size={26} strokeWidth={2.2} />
            )}
            <TvzText preset="cardTitle" style={styles.tileTitle}>
              {t('idFoto.idTitel')}
            </TvzText>
            <TvzText preset="secondary" style={styles.tileText}>
              {t('idFoto.idUitleg')}
            </TvzText>
          </Pressable>
          <Pressable
            accessibilityRole="button"
            onPress={() => setChoosing('foto')}
            style={styles.tile}
          >
            {picked.foto ? (
              <Image
                source={{ uri: picked.foto.uri }}
                style={[styles.preview, styles.previewRound]}
              />
            ) : (
              <User color={colors.primaryMid} size={26} strokeWidth={2.2} />
            )}
            <TvzText preset="cardTitle" style={styles.tileTitle}>
              {t('idFoto.fotoTitel')}
            </TvzText>
            <TvzText preset="secondary" style={styles.tileText}>
              {t('idFoto.fotoUitleg')}
            </TvzText>
          </Pressable>
        </View>

        <View style={styles.privacy}>
          <View style={styles.privacyDash} />
          <TvzText preset="secondary" style={styles.privacyText}>
            {t('idFoto.privacy')}
          </TvzText>
        </View>
        {error ? (
          <TvzText preset="secondary" style={styles.error}>
            {error}
          </TvzText>
        ) : null}

        <View style={styles.footer}>
          <Button
            label={busy ? t('algemeen.laden') : t('idFoto.deAppIn')}
            variant="cta"
            size="lg"
            disabled={!ready || busy}
            onPress={submit}
          />
        </View>
      </View>

      <BottomSheet
        visible={!!choosing}
        onClose={() => setChoosing(null)}
        title={choosing === 'id' ? t('idFoto.idTitel') : t('idFoto.fotoTitel')}
      >
        <Pressable
          accessibilityRole="button"
          onPress={() => choosing && pickFromCamera(choosing)}
          style={styles.sourceRow}
        >
          <Camera color={colors.primary} size={22} strokeWidth={2.2} />
          <TvzText preset="cardTitle" style={styles.sourceLabel}>
            {t('idFoto.maakFoto')}
          </TvzText>
        </Pressable>
        <Pressable
          accessibilityRole="button"
          onPress={() => choosing && pickFromLibrary(choosing)}
          style={styles.sourceRow}
        >
          <Images color={colors.primary} size={22} strokeWidth={2.2} />
          <TvzText preset="cardTitle" style={styles.sourceLabel}>
            {t('idFoto.uitBibliotheek')}
          </TvzText>
        </Pressable>
      </BottomSheet>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: colors.bg,
  },
  container: {
    flex: 1,
    padding: spacing.screen,
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
  uitleg: {
    marginTop: spacing.xs,
    marginBottom: spacing.xl,
  },
  tiles: {
    flexDirection: 'row',
    gap: spacing.cardGap,
  },
  tile: {
    flex: 1,
    ...dashedBorder,
    borderRadius: radius.card,
    padding: spacing.lg,
    minHeight: 120,
    backgroundColor: colors.white,
  },
  preview: {
    width: 44,
    height: 32,
    borderRadius: 6,
  },
  previewRound: {
    width: 40,
    height: 40,
    borderRadius: 20,
  },
  tileTitle: {
    fontSize: 15,
    marginTop: spacing.sm,
  },
  tileText: {
    fontSize: 12.5,
    marginTop: 2,
  },
  privacy: {
    flexDirection: 'row',
    gap: spacing.sm,
    backgroundColor: colors.surfaceAlt,
    borderRadius: radius.row,
    padding: spacing.md,
    marginTop: spacing.md,
  },
  privacyDash: {
    width: 16,
    height: 5,
    borderRadius: radius.pill,
    backgroundColor: colors.accent,
    marginTop: 6,
  },
  privacyText: {
    flex: 1,
  },
  error: {
    color: colors.error,
    marginTop: spacing.md,
  },
  footer: {
    marginTop: 'auto',
  },
  sourceRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
    paddingVertical: spacing.lg,
    borderBottomWidth: 1,
    borderBottomColor: colors.line,
    minHeight: 56,
  },
  sourceLabel: {
    fontSize: 16,
  },
});

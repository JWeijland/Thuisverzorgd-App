import { useQueryClient } from '@tanstack/react-query';
import { Image } from 'expo-image';
import * as ImagePicker from 'expo-image-picker';
import { router } from 'expo-router';
import { useState } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { CreditCard, User } from 'lucide-react-native';

import { useSession } from '@/features/onboarding/useAuth';
import { t } from '@/i18n';
import { supabase } from '@/lib/supabase';
import { colors, dashedBorder, radius, spacing } from '@/theme';
import { Button, TvzText } from '@/ui';

type Slot = 'id' | 'foto';

/**
 * ID + profielfoto (screen 18): alleen voor vrijwilligers, één keer bij registratie.
 * Beide verplicht voordat "De app in →" actief wordt. Alleen de bevestiging wordt
 * bewaard; het ID-document gaat naar een privé bucket met korte bewaartermijn (ADR-0005).
 */
export default function IdEnFotoScreen() {
  const { session } = useSession();
  const queryClient = useQueryClient();
  const [uris, setUris] = useState<{ id?: string; foto?: string }>({});
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | undefined>();

  async function pick(slot: Slot) {
    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: 'images',
      quality: 0.8,
      allowsEditing: slot === 'foto',
      aspect: slot === 'foto' ? [1, 1] : undefined,
    });
    if (!result.canceled && result.assets[0]) {
      setUris((prev) => ({ ...prev, [slot]: result.assets[0]!.uri }));
    }
  }

  async function upload(bucket: string, path: string, uri: string) {
    const response = await fetch(uri);
    const body = await response.arrayBuffer();
    const { error: uploadError } = await supabase.storage
      .from(bucket)
      .upload(path, body, { contentType: 'image/jpeg', upsert: true });
    if (uploadError) throw uploadError;
  }

  async function submit() {
    if (!session || !uris.id || !uris.foto || busy) return;
    setBusy(true);
    setError(undefined);
    try {
      const uid = session.user.id;
      await upload('id-documents', `${uid}/id.jpg`, uris.id);
      await upload('avatars', `${uid}/avatar.jpg`, uris.foto);
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
      router.replace('/');
    } catch {
      setError(t('idFoto.uploadMislukt'));
    } finally {
      setBusy(false);
    }
  }

  const ready = !!uris.id && !!uris.foto;

  return (
    <SafeAreaView style={styles.safe}>
      <View style={styles.container}>
        <TvzText preset="screenTitle">{t('idFoto.titel')}</TvzText>
        <TvzText preset="secondary" style={styles.uitleg}>
          {t('idFoto.uitleg')}
        </TvzText>

        <View style={styles.tiles}>
          <Pressable accessibilityRole="button" onPress={() => pick('id')} style={styles.tile}>
            {uris.id ? (
              <Image source={{ uri: uris.id }} style={styles.preview} />
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
          <Pressable accessibilityRole="button" onPress={() => pick('foto')} style={styles.tile}>
            {uris.foto ? (
              <Image source={{ uri: uris.foto }} style={[styles.preview, styles.previewRound]} />
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
});

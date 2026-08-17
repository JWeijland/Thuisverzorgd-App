import { useQuery, useQueryClient } from '@tanstack/react-query';
import { useState } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';

import { t } from '@/i18n';
import { haptics } from '@/lib/haptics';
import { supabase } from '@/lib/supabase';
import { colors, radius, spacing } from '@/theme';
import { BottomSheet, Button, Card, TextField, TvzText } from '@/ui';

type AdminProvider = {
  id: string;
  name: string;
  business: string;
  profile_id: string | null;
};

/**
 * Aanbieders-accounts (alleen admin). Aanbieders kunnen zich niet zelf
 * aanmelden: hier maakt Thuisverzorgd een account met gebruikersnaam +
 * wachtwoord aan (edge function `aanbieder-account`) en geeft die gegevens
 * aan de aanbieder. Bestaat het account al, dan wordt alleen het wachtwoord
 * opnieuw gezet.
 */
export function AdminAanbieders() {
  const queryClient = useQueryClient();
  const aanbieders = useQuery({
    queryKey: ['admin-aanbieders'],
    queryFn: async (): Promise<AdminProvider[]> => {
      const { data, error } = await supabase
        .from('providers')
        .select('id, name, business, profile_id')
        .order('business');
      if (error) throw error;
      return (data ?? []) as AdminProvider[];
    },
  });

  const [gekozen, setGekozen] = useState<AdminProvider | null>(null);
  const [username, setUsername] = useState('');
  const [wachtwoord, setWachtwoord] = useState('');
  const [bezig, setBezig] = useState(false);
  const [melding, setMelding] = useState<{ tekst: string; fout: boolean } | null>(null);

  function open(aanbieder: AdminProvider) {
    setUsername('');
    setWachtwoord('');
    setMelding(null);
    setGekozen(aanbieder);
  }

  async function versturen() {
    if (!gekozen || bezig) return;
    setBezig(true);
    setMelding(null);
    const { data, error } = await supabase.functions.invoke('aanbieder-account', {
      body: {
        provider_id: gekozen.id,
        username: username.trim(),
        password: wachtwoord,
      },
    });
    if (error) {
      // De edge function stuurt een foutcode in de body mee.
      let code = 'fout';
      const context = (error as { context?: Response }).context;
      if (context && typeof context.json === 'function') {
        const body = (await context.json().catch(() => null)) as { error?: string } | null;
        code = body?.error ?? 'fout';
      }
      const teksten: Record<string, string> = {
        gebruikersnaam_bezet: t('admin.aanbiederNaamBezet'),
        gebruikersnaam_ongeldig: t('admin.aanbiederNaamOngeldig'),
        wachtwoord_kort: t('admin.aanbiederWachtwoordKort'),
      };
      setMelding({ tekst: teksten[code] ?? t('algemeen.foutTitel'), fout: true });
      void haptics.fout();
    } else {
      const resultaat = data as { status: string; username: string };
      setMelding({
        tekst:
          resultaat.status === 'wachtwoord_gereset'
            ? t('admin.aanbiederGereset', { naam: resultaat.username })
            : t('admin.aanbiederAangemaakt', { naam: resultaat.username }),
        fout: false,
      });
      void haptics.voltooid();
      queryClient.invalidateQueries({ queryKey: ['admin-aanbieders'] });
    }
    setBezig(false);
  }

  const heeftAccount = !!gekozen?.profile_id;
  const klaar = heeftAccount
    ? wachtwoord.length >= 8
    : username.trim().length >= 3 && wachtwoord.length >= 8;

  return (
    <Card style={styles.kaart}>
      <TvzText preset="cardTitle">{t('admin.aanbiedersTitel')}</TvzText>
      <TvzText preset="secondary">{t('admin.aanbiedersUitleg')}</TvzText>
      <View style={styles.lijst}>
        {(aanbieders.data ?? []).map((aanbieder, index) => (
          <Pressable
            key={aanbieder.id}
            accessibilityRole="button"
            accessibilityLabel={aanbieder.business}
            onPress={() => open(aanbieder)}
            style={[styles.rij, index > 0 && styles.rijLijn]}
          >
            <View style={styles.rijTekst}>
              <TvzText preset="body">{aanbieder.business}</TvzText>
              <TvzText preset="meta" style={styles.rijNaam}>
                {aanbieder.name}
              </TvzText>
            </View>
            <View
              style={[
                styles.statusPill,
                { backgroundColor: aanbieder.profile_id ? colors.successBg : colors.warnBg },
              ]}
            >
              <TvzText
                preset="meta"
                style={{ color: aanbieder.profile_id ? colors.successText : colors.warnText }}
              >
                {aanbieder.profile_id ? t('admin.aanbiederActief') : t('admin.aanbiederGeen')}
              </TvzText>
            </View>
          </Pressable>
        ))}
      </View>

      <BottomSheet
        visible={!!gekozen}
        onClose={() => setGekozen(null)}
        title={gekozen?.business}
      >
        <TvzText preset="secondary" style={styles.sheetUitleg}>
          {heeftAccount ? t('admin.aanbiederResetUitleg') : t('admin.aanbiederNieuwUitleg')}
        </TvzText>
        {!heeftAccount ? (
          <TextField
            label={t('admin.aanbiederGebruikersnaam')}
            value={username}
            onChangeText={setUsername}
            autoCapitalize="none"
            autoCorrect={false}
            placeholder="bijv. samira"
          />
        ) : null}
        <TextField
          label={t('admin.aanbiederWachtwoord')}
          value={wachtwoord}
          onChangeText={setWachtwoord}
          autoCapitalize="none"
          autoCorrect={false}
          secureTextEntry
          placeholder="minimaal 8 tekens"
        />
        {melding ? (
          <TvzText
            preset="secondary"
            style={[styles.melding, { color: melding.fout ? colors.error : colors.successText }]}
          >
            {melding.tekst}
          </TvzText>
        ) : null}
        <Button
          label={
            bezig
              ? t('algemeen.laden')
              : heeftAccount
                ? t('admin.aanbiederResetKnop')
                : t('admin.aanbiederMaakKnop')
          }
          variant="cta"
          size="lg"
          disabled={!klaar || bezig}
          style={styles.sheetKnop}
          onPress={() => void versturen()}
        />
      </BottomSheet>
    </Card>
  );
}

const styles = StyleSheet.create({
  kaart: {
    marginTop: spacing.cardGap,
  },
  lijst: {
    marginTop: spacing.sm,
  },
  rij: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
    minHeight: 54,
  },
  rijLijn: {
    borderTopWidth: 1,
    borderTopColor: colors.line,
  },
  rijTekst: {
    flex: 1,
  },
  rijNaam: {
    color: colors.inkSoft,
  },
  statusPill: {
    borderRadius: radius.pill,
    paddingHorizontal: 10,
    paddingVertical: 3,
  },
  sheetUitleg: {
    marginBottom: spacing.md,
  },
  melding: {
    marginTop: spacing.sm,
  },
  sheetKnop: {
    marginTop: spacing.md,
  },
});

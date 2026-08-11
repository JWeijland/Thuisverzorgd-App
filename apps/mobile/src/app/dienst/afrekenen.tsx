import { router, useLocalSearchParams } from 'expo-router';
import { useState } from 'react';
import { Pressable, ScrollView, StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { ChevronLeft, CreditCard, Smartphone } from 'lucide-react-native';

import { useCreateBoeking, useDiensten } from '@/features/voorzieningen/api';
import { euro, slotLabel } from '@/features/voorzieningen/slots';
import { t } from '@/i18n';
import { useStatusBalk } from '@/lib/statusbalk';
import { colors, radius, spacing } from '@/theme';
import { Button, Card, TvzText } from '@/ui';

type Betaalwijze = 'apple_pay' | 'ideal';

/**
 * Afrekenen (handoff voorzieningen): overzicht + betaalwijze. Het bedrag wordt
 * pas ná het bezoek afgeschreven; tijdens de pilot schrijft de app niets af.
 * Bewust géén Bo op dit scherm (regel uit de handoff).
 */
export default function AfrekenenScreen() {
  const { slug, slot } = useLocalSearchParams<{ slug: string; slot: string }>();
  const diensten = useDiensten();
  const dienst = (diensten.data ?? []).find((item) => item.slug === slug);
  const [methode, setMethode] = useState<Betaalwijze>('apple_pay');
  const boek = useCreateBoeking();
  const [fout, setFout] = useState(false);
  useStatusBalk('donker');

  if (!dienst || !slot) {
    return <View style={styles.safe} />;
  }

  const moment = slotLabel(new Date(slot));

  function bevestig() {
    if (boek.isPending || !dienst || !slot) return;
    setFout(false);
    boek.mutate(
      { serviceId: dienst.id, slotIso: slot, method: methode },
      {
        onSuccess: () =>
          router.replace({
            pathname: '/dienst/bevestigd',
            params: { naam: dienst.provider.name, moment },
          }),
        onError: () => setFout(true),
      },
    );
  }

  return (
    <SafeAreaView style={styles.safe} edges={['top', 'bottom']}>
      <View style={styles.kopRij}>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={t('algemeen.terug')}
          onPress={() => router.back()}
          style={styles.terug}
        >
          <ChevronLeft color={colors.primary} size={26} strokeWidth={2.4} />
        </Pressable>
        <TvzText preset="screenTitle" style={styles.titel}>
          {t('voorzien.afrekenenTitel')}
        </TvzText>
      </View>

      <ScrollView contentContainerStyle={styles.inhoud}>
        <Card>
          <OverzichtRij label={t('voorzien.overzichtDienst')} waarde={dienst.name} />
          <OverzichtRij label={t('voorzien.overzichtMoment')} waarde={moment} lijn />
          <OverzichtRij
            label={t('voorzien.overzichtAanbieder')}
            waarde={dienst.provider.business}
            lijn
          />
          <OverzichtRij
            label={t('voorzien.overzichtTotaal')}
            waarde={
              dienst.unit === 'uur'
                ? `${euro(dienst.price_cents)} ${t('voorzien.perUur')}`
                : euro(dienst.price_cents)
            }
            vet
            lijn
          />
        </Card>

        <TvzText preset="sectionTitle" style={styles.betaalTitel}>
          {t('voorzien.betaalwijze')}
        </TvzText>
        <Card>
          {(
            [
              ['apple_pay', t('voorzien.applePay'), Smartphone],
              ['ideal', t('voorzien.ideal'), CreditCard],
            ] as const
          ).map(([key, label, Icon], index) => (
            <Pressable
              key={key}
              accessibilityRole="radio"
              accessibilityState={{ checked: methode === key }}
              accessibilityLabel={label}
              onPress={() => setMethode(key)}
              style={[styles.betaalRij, index > 0 && styles.betaalRijLijn]}
            >
              <Icon color={colors.primary} size={22} strokeWidth={2.2} />
              <TvzText preset="body" style={styles.betaalLabel}>
                {label}
              </TvzText>
              <View style={[styles.radio, methode === key && styles.radioActief]}>
                {methode === key ? <View style={styles.radioStip} /> : null}
              </View>
            </Pressable>
          ))}
        </Card>

        <TvzText preset="secondary" style={styles.uitleg}>
          {t('voorzien.betaalUitleg')}
        </TvzText>
        {fout ? (
          <TvzText preset="secondary" style={styles.fout}>
            {t('voorzien.boekFout')}
          </TvzText>
        ) : null}
      </ScrollView>

      <View style={styles.voet}>
        {/* Even vierkant als de boek-knop op de dienstpagina (wens Jelle
            11-08): dit is het einde van dezelfde handeling. */}
        <Button
          label={boek.isPending ? t('algemeen.laden') : t('voorzien.bevestigBoeking')}
          variant="cta"
          size="lg"
          style={styles.bevestigKnop}
          disabled={boek.isPending}
          onPress={bevestig}
        />
      </View>
    </SafeAreaView>
  );
}

function OverzichtRij({
  label,
  waarde,
  vet,
  lijn,
}: {
  label: string;
  waarde: string;
  vet?: boolean;
  lijn?: boolean;
}) {
  return (
    <View style={[styles.overzichtRij, lijn && styles.overzichtLijn]}>
      <TvzText preset="secondary">{label}</TvzText>
      <TvzText preset={vet ? 'cardTitle' : 'body'} style={styles.overzichtWaarde}>
        {waarde}
      </TvzText>
    </View>
  );
}

const styles = StyleSheet.create({
  bevestigKnop: {
    borderRadius: radius.card,
  },
  safe: {
    flex: 1,
    backgroundColor: colors.bg,
  },
  kopRij: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
    paddingHorizontal: spacing.screen,
    paddingTop: spacing.sm,
  },
  terug: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: colors.white,
    alignItems: 'center',
    justifyContent: 'center',
  },
  titel: {
    fontSize: 24,
  },
  inhoud: {
    padding: spacing.screen,
    gap: spacing.cardGap,
  },
  overzichtRij: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: spacing.md,
    minHeight: 40,
  },
  overzichtLijn: {
    borderTopWidth: 1,
    borderTopColor: colors.line,
  },
  overzichtWaarde: {
    textAlign: 'right',
    flexShrink: 1,
  },
  betaalTitel: {
    marginTop: spacing.md,
  },
  betaalRij: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
    minHeight: 54,
  },
  betaalRijLijn: {
    borderTopWidth: 1,
    borderTopColor: colors.line,
  },
  betaalLabel: {
    flex: 1,
  },
  radio: {
    width: 22,
    height: 22,
    borderRadius: 11,
    borderWidth: 2,
    borderColor: colors.inkFaint,
    alignItems: 'center',
    justifyContent: 'center',
  },
  radioActief: {
    borderColor: colors.primaryMid,
  },
  radioStip: {
    width: 11,
    height: 11,
    borderRadius: 5.5,
    backgroundColor: colors.primaryMid,
  },
  uitleg: {
    textAlign: 'center',
    paddingHorizontal: spacing.md,
  },
  fout: {
    color: colors.error,
    textAlign: 'center',
  },
  voet: {
    padding: spacing.screen,
    paddingTop: spacing.sm,
  },
});

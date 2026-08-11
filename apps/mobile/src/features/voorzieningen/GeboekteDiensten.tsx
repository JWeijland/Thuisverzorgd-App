import { useState } from 'react';
import { StyleSheet, View } from 'react-native';

import { AanbiederAvatar } from '@/features/voorzieningen/AanbiederAvatar';
import { useBoekingen, useCancelBoeking, type Boeking } from '@/features/voorzieningen/api';
import { slotLabel } from '@/features/voorzieningen/slots';
import { t } from '@/i18n';
import { colors, radius, spacing } from '@/theme';
import { BottomSheet, Button, Card, SectionHeader, TvzText } from '@/ui';

/**
 * Geboekte voorzieningen in het rooster, naast de kringtaken (handoff).
 * Alleen komende boekingen; annuleren kan tot 24 uur vooraf (server-side).
 */
export function GeboekteDiensten() {
  const boekingen = useBoekingen();
  const annuleer = useCancelBoeking();
  const [gekozen, setGekozen] = useState<Boeking | null>(null);
  const [teLaat, setTeLaat] = useState(false);

  const lijst = boekingen.data ?? [];
  if (lijst.length === 0) return null;

  function bevestigAnnulering() {
    if (!gekozen || annuleer.isPending) return;
    setTeLaat(false);
    annuleer.mutate(gekozen.id, {
      onSuccess: () => setGekozen(null),
      onError: (err) => {
        if (err instanceof Error && err.message.includes('annuleren_te_laat')) {
          setTeLaat(true);
        } else {
          setGekozen(null);
        }
      },
    });
  }

  return (
    <>
      <SectionHeader title={t('voorzien.roosterTitel')} />
      <View style={styles.lijst}>
        {lijst.map((boeking) => (
          <Card key={boeking.id} style={styles.kaart}>
            <View style={styles.rij}>
              <AanbiederAvatar
                slug={boeking.service?.slug ?? ''}
                naam={boeking.service?.provider?.name ?? ''}
                size={40}
              />
              <View style={styles.tekst}>
                <TvzText preset="cardTitle">{boeking.service?.name ?? ''}</TvzText>
                <TvzText preset="secondary">
                  {t('voorzien.roosterKomt', {
                    naam: boeking.service?.provider?.name ?? '',
                    moment: slotLabel(new Date(boeking.slot_at)),
                  })}
                </TvzText>
              </View>
              {/* Geen prijs meer in de planning: die heb je bij het boeken al
                  gezien en in je rooster gaat het om het moment, niet om het
                  bedrag (feedback Jelle 11-08). */}
              <View style={styles.statusPill}>
                <TvzText preset="meta" style={styles.statusTekst}>
                  {t('voorzien.statusGeboekt')}
                </TvzText>
              </View>
            </View>
            <Button
              label={t('voorzien.annuleren')}
              variant="outline"
              style={styles.annuleerKnop}
              onPress={() => {
                setTeLaat(false);
                setGekozen(boeking);
              }}
            />
          </Card>
        ))}
      </View>

      <BottomSheet
        visible={!!gekozen}
        onClose={() => setGekozen(null)}
        title={t('voorzien.annuleren')}
      >
        <TvzText preset="secondary" style={styles.sheetUitleg}>
          {t('voorzien.annulerenUitleg')}
        </TvzText>
        {teLaat ? (
          <TvzText preset="secondary" style={styles.teLaat}>
            {t('voorzien.annulerenTeLaat')}
          </TvzText>
        ) : null}
        <Button
          label={annuleer.isPending ? t('algemeen.laden') : t('voorzien.annulerenBevestig')}
          variant="danger"
          size="lg"
          disabled={annuleer.isPending || teLaat}
          onPress={bevestigAnnulering}
        />
        <Button
          label={t('algemeen.sluiten')}
          variant="outline"
          style={styles.sluitKnop}
          onPress={() => setGekozen(null)}
        />
      </BottomSheet>
    </>
  );
}

const styles = StyleSheet.create({
  lijst: {
    gap: spacing.cardGap,
  },
  kaart: {
    paddingVertical: spacing.md,
  },
  rij: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
  },
  tekst: {
    flex: 1,
  },
  statusPill: {
    backgroundColor: colors.successBg,
    borderRadius: radius.pill,
    paddingHorizontal: 10,
    paddingVertical: 3,
  },
  statusTekst: {
    color: colors.successText,
  },
  annuleerKnop: {
    marginTop: spacing.md,
    minHeight: 40,
    paddingVertical: 6,
    alignSelf: 'flex-start',
    paddingHorizontal: 16,
  },
  sheetUitleg: {
    marginBottom: spacing.md,
  },
  teLaat: {
    color: colors.warnText,
    marginBottom: spacing.md,
  },
  sluitKnop: {
    marginTop: spacing.sm,
  },
});

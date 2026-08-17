import { RefreshControl, ScrollView, StyleSheet, View } from 'react-native';
import { MapPin } from 'lucide-react-native';

import { afspraakTijden, groepeerPerDag } from '@/features/aanbieder/agenda';
import { useAanbiederAfspraken, useMijnAanbieder } from '@/features/aanbieder/api';
import { t } from '@/i18n';
import { formatHumanDate, parseDateString } from '@/lib/dates';
import { colors, radius, spacing } from '@/theme';
import { Card, EmptyState, SectionHeader, TvzText } from '@/ui';

/**
 * Mijn afspraken: alle komende boekingen bij deze aanbieder, per dag. Nieuwe
 * boekingen en annuleringen komen ook als melding binnen (create_booking en
 * cancel_booking sturen ze); dit scherm is het overzicht.
 */
export function AfsprakenScherm() {
  const aanbieder = useMijnAanbieder();
  const afspraken = useAanbiederAfspraken();

  if (aanbieder.isSuccess && aanbieder.data === null) {
    return (
      <EmptyState
        title={t('aanbieder.geenKoppeling')}
        body={t('aanbieder.geenKoppelingUitleg')}
      />
    );
  }

  const groepen = groepeerPerDag(afspraken.data ?? []);

  return (
    <ScrollView
      contentContainerStyle={styles.scroll}
      refreshControl={
        <RefreshControl
          refreshing={afspraken.isRefetching}
          onRefresh={() => void afspraken.refetch()}
        />
      }
    >
      {groepen.length === 0 && !afspraken.isLoading ? (
        <EmptyState
          bo
          title={t('aanbieder.afsprakenLeeg')}
          body={t('aanbieder.afsprakenLeegUitleg')}
        />
      ) : (
        groepen.map((groep) => (
          <View key={groep.datum} style={styles.groep}>
            <SectionHeader title={formatHumanDate(parseDateString(groep.datum))} />
            <View style={styles.lijst}>
              {groep.items.map((afspraak) => (
                <Card key={afspraak.id} style={styles.kaart}>
                  <View style={styles.kopRij}>
                    <View style={styles.tijdPill}>
                      <TvzText preset="meta" style={styles.tijdTekst}>
                        {afspraakTijden(afspraak.slot_at, afspraak.duration_min)}
                      </TvzText>
                    </View>
                    <TvzText preset="cardTitle" style={styles.dienst}>
                      {afspraak.service_name}
                    </TvzText>
                  </View>
                  <TvzText preset="body" style={styles.klant}>
                    {t('aanbieder.bij', { naam: afspraak.klant_naam })}
                  </TvzText>
                  {afspraak.klant_adres || afspraak.klant_plaats ? (
                    <View style={styles.adresRij}>
                      <MapPin color={colors.inkSoft} size={16} strokeWidth={2.2} />
                      <TvzText preset="secondary" style={styles.adresTekst}>
                        {[afspraak.klant_adres, afspraak.klant_plaats].filter(Boolean).join(', ')}
                      </TvzText>
                    </View>
                  ) : null}
                </Card>
              ))}
            </View>
          </View>
        ))
      )}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  scroll: {
    padding: spacing.screen,
    paddingBottom: spacing.xxl,
  },
  groep: {
    marginBottom: spacing.lg,
  },
  lijst: {
    gap: spacing.cardGap,
    marginTop: spacing.md,
  },
  kaart: {
    paddingVertical: spacing.md,
  },
  kopRij: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
  },
  tijdPill: {
    backgroundColor: colors.warnBg,
    borderRadius: radius.pill,
    paddingHorizontal: 10,
    paddingVertical: 4,
  },
  tijdTekst: {
    color: colors.warnText,
  },
  dienst: {
    flex: 1,
  },
  klant: {
    marginTop: spacing.sm,
  },
  adresRij: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.xs,
    marginTop: spacing.xs,
  },
  adresTekst: {
    flexShrink: 1,
  },
});

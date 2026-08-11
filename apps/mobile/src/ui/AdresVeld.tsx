import { useQuery } from '@tanstack/react-query';
import { MapPin } from 'lucide-react-native';
import { useState } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';

import { useDebounced } from '@/lib/useDebounced';
import { t } from '@/i18n';
import { haptics } from '@/lib/haptics';
import { colors, radius, spacing } from '@/theme';
import { TextField } from '@/ui/TextField';
import { TvzText } from '@/ui/TvzText';

/**
 * Adressuggesties uit de PDOK Locatieserver: de officiële adressen van het
 * Kadaster. Gratis, geen sleutel of account nodig, en alleen Nederlandse
 * adressen, wat hier precies past.
 */
const PDOK = 'https://api.pdok.nl/bzk/locatieserver/search/v3_1/suggest';

/** Vanaf hoeveel tekens het zoeken zin heeft. */
const MINIMUM = 4;

async function haalSuggesties(term: string): Promise<string[]> {
  const url = `${PDOK}?q=${encodeURIComponent(term)}&fq=type:adres&rows=6`;
  const antwoord = await fetch(url);
  if (!antwoord.ok) return [];
  const json = (await antwoord.json()) as {
    response?: { docs?: { weergavenaam?: string }[] };
  };
  return (json.response?.docs ?? [])
    .map((doc) => doc.weergavenaam)
    .filter((naam): naam is string => !!naam);
}

type Props = {
  label: string;
  waarde: string;
  onChange: (adres: string) => void;
  placeholder?: string;
};

/**
 * Adresveld met echte suggesties: je typt de straat, tikt het juiste adres
 * aan en dan staat het volledig ingevuld (wens Jelle 11-08). Zo hoeft niemand
 * postcode en plaats over te typen, en staat de kring op de goede plek.
 */
export function AdresVeld({ label, waarde, onChange, placeholder }: Props) {
  // Gekozen? Dan geen lijst meer tonen tot je weer gaat typen.
  const [gekozen, setGekozen] = useState(waarde.length > 0);
  const term = useDebounced(waarde);
  const zoekt = !gekozen && term.trim().length >= MINIMUM;

  const suggesties = useQuery({
    queryKey: ['adres-suggesties', term],
    enabled: zoekt,
    staleTime: 5 * 60 * 1000,
    queryFn: () => haalSuggesties(term.trim()),
  });

  const lijst = zoekt ? (suggesties.data ?? []) : [];

  return (
    <View>
      <TextField
        label={label}
        value={waarde}
        placeholder={placeholder}
        autoCapitalize="words"
        autoCorrect={false}
        onChangeText={(tekst) => {
          setGekozen(false);
          onChange(tekst);
        }}
      />
      {lijst.length > 0 ? (
        <View style={styles.lijst}>
          {lijst.map((adres) => (
            <Pressable
              key={adres}
              accessibilityRole="button"
              accessibilityLabel={adres}
              onPress={() => {
                void haptics.selectie();
                setGekozen(true);
                onChange(adres);
              }}
              style={styles.rij}
            >
              <MapPin color={colors.primaryMid} size={16} strokeWidth={2.2} />
              <TvzText preset="body" numberOfLines={1} style={styles.tekst}>
                {adres}
              </TvzText>
            </Pressable>
          ))}
        </View>
      ) : null}
      {zoekt && suggesties.isFetching && lijst.length === 0 ? (
        <TvzText preset="meta" style={styles.bezig}>
          {t('kringopbouw.adresZoeken')}
        </TvzText>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  lijst: {
    marginTop: spacing.sm,
    borderRadius: radius.card,
    borderWidth: 1,
    borderColor: colors.line,
    backgroundColor: colors.white,
    overflow: 'hidden',
  },
  rij: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    paddingHorizontal: spacing.md,
    minHeight: 46,
    borderBottomWidth: 1,
    borderBottomColor: colors.line,
  },
  tekst: {
    flex: 1,
  },
  bezig: {
    marginTop: spacing.sm,
    color: colors.inkFaint,
  },
});

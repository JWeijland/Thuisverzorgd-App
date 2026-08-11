import { router } from 'expo-router';
import { useState } from 'react';
import { ScrollView, StyleSheet, TextInput, View } from 'react-native';

import { useMyCircle } from '@/features/circles/api';
import { useVraagBuddy } from '@/features/tasks/api';
import { t } from '@/i18n';
import { useStatusBalk } from '@/lib/statusbalk';
import { colors, radius, spacing } from '@/theme';
import { Bo, Button, Card, Chip, EmptyState, Pill, TvzText } from '@/ui';
import { TerugKop } from '@/ui/TerugKop';

const KEUZES = [
  { type: 'gezelschap', labelKey: 'planner.typeGezelschap' },
  { type: 'wandelen', labelKey: 'planner.typeWandelen' },
  { type: 'boodschappen', labelKey: 'planner.typeBoodschappen' },
  { type: 'anders', labelKey: 'planner.typeAnders' },
] as const;

type Keuze = (typeof KEUZES)[number]['type'];

/**
 * Een buddy vragen (hulpvrager, ontwerp 4.0): één vraag, grote knoppen.
 * De vraag wordt een open taak in de kring; de beheerder en de buddy's
 * zien hem meteen in dezelfde week.
 */
export default function BuddyVragenScreen() {
  useStatusBalk('donker');
  const circle = useMyCircle();
  const vraag = useVraagBuddy(circle.data?.id);
  const [keuze, setKeuze] = useState<Keuze>('gezelschap');
  const [anders, setAnders] = useState('');
  const [klaar, setKlaar] = useState(false);

  function verstuur() {
    if (vraag.isPending) return;
    vraag.mutate(
      { type: keuze, custom_label: keuze === 'anders' ? anders.trim() || null : null },
      { onSuccess: () => setKlaar(true) },
    );
  }

  if (klaar) {
    return (
      <View style={styles.safe}>
        <View style={styles.klaarWrap}>
          <Bo width={140} rol="hulpvrager" />
          <TvzText preset="screenTitle" style={styles.klaarTitel}>
            {t('buddyVragen.klaarTitel')}
          </TvzText>
          <TvzText preset="body" style={styles.klaarTekst}>
            {t('buddyVragen.klaarTekst')}
          </TvzText>
          <Button
            label={t('buddyVragen.klaarKnop')}
            variant="cta"
            size="lg"
            onPress={() => router.navigate('/regelen/planning')}
            style={styles.klaarKnop}
          />
        </View>
      </View>
    );
  }

  return (
    <View style={styles.safe}>
      <TerugKop
        titel={t('buddyVragen.titel')}
        sub={t('buddyVragen.uitleg')}
        right={
          <Pill
            label={t('voorzien.gratisPill')}
            color={colors.successText}
            backgroundColor={colors.successBg}
          />
        }
      />
      <ScrollView contentContainerStyle={styles.lijst} keyboardShouldPersistTaps="handled">
        {!circle.isLoading && !circle.data ? (
          <Card>
            <EmptyState title={t('koppelcode.nodigTitel')} body={t('koppelcode.nodigTekst')} />
          </Card>
        ) : (
          <>
            <Card style={styles.kaart}>
              <TvzText preset="cardTitle" style={styles.vraagTitel}>
                {t('buddyVragen.waarvoor')}
              </TvzText>
              <View style={styles.chips}>
                {KEUZES.map((optie) => (
                  <Chip
                    key={optie.type}
                    label={t(optie.labelKey)}
                    selected={keuze === optie.type}
                    onPress={() => setKeuze(optie.type)}
                  />
                ))}
              </View>
              {keuze === 'anders' ? (
                <TextInput
                  textContentType="none"
                  autoComplete="off"
                  value={anders}
                  onChangeText={setAnders}
                  placeholder={t('planner.andersPlaceholder')}
                  placeholderTextColor={colors.inkFaint}
                  style={styles.andersVeld}
                />
              ) : null}
            </Card>
            <TvzText preset="secondary" style={styles.voetTekst}>
              {t('buddyVragen.voet')}
            </TvzText>
            <Button
              label={vraag.isPending ? t('algemeen.laden') : t('buddyVragen.verstuur')}
              variant="cta"
              size="lg"
              disabled={vraag.isPending || (keuze === 'anders' && anders.trim().length < 3)}
              onPress={verstuur}
            />
          </>
        )}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: colors.bg,
  },
  lijst: {
    padding: spacing.screen,
    paddingTop: spacing.sm,
    paddingBottom: 110,
    gap: spacing.md,
  },
  kaart: {
    paddingVertical: spacing.xl,
  },
  vraagTitel: {
    fontSize: 19,
    marginBottom: spacing.md,
  },
  chips: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing.chipGap,
  },
  andersVeld: {
    marginTop: spacing.md,
    backgroundColor: colors.bg,
    borderWidth: 1.5,
    borderColor: colors.line,
    borderRadius: radius.input,
    padding: spacing.md,
    fontFamily: 'ComicNeue_400Regular',
    fontSize: 17,
    color: colors.ink,
    minHeight: 52,
  },
  voetTekst: {
    textAlign: 'center',
    fontSize: 15.5,
  },
  klaarWrap: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: spacing.screen,
  },
  klaarTitel: {
    marginTop: spacing.lg,
  },
  klaarTekst: {
    textAlign: 'center',
    marginTop: spacing.sm,
    maxWidth: 300,
    fontSize: 17,
  },
  klaarKnop: {
    marginTop: spacing.xl,
    alignSelf: 'stretch',
  },
});

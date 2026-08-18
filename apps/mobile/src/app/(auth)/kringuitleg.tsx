import { router, useLocalSearchParams } from 'expo-router';
import { ScrollView, StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { KringMotief } from '@/features/circles/KringMotief';
import { t } from '@/i18n';
import { useStatusBalk } from '@/lib/statusbalk';
import { colors, radius, rolTints, spacing } from '@/theme';
import { Bo, Button, Card, RolChip, TvzText } from '@/ui';

/** De drie rollen die samen een kring vormen. */
type KringRol = 'beheerder' | 'vrijwilliger' | 'hulpvrager';

const ROLLEN: KringRol[] = ['beheerder', 'vrijwilliger', 'hulpvrager'];

/** Startscherm van elke rol na de rolkeuze. */
const START: Record<KringRol, string> = {
  beheerder: '/pad',
  vrijwilliger: '/vrijwilliger/buurt',
  hulpvrager: '/pad',
};

/**
 * Kringuitleg (ontwerp 4.0): direct na de rolkeuze zie je hoe de drie rollen
 * samenwerken en wat jouw plek is. Dit is het antwoord op "wie doet wat":
 * elke rol leert hier de andere twee kennen, in de vaste rolkleuren.
 */
export default function KringuitlegScreen() {
  useStatusBalk('donker');
  const params = useLocalSearchParams<{ rol?: string }>();
  const rol: KringRol = ROLLEN.includes(params.rol as KringRol) ? (params.rol as KringRol) : 'beheerder';

  return (
    <SafeAreaView style={styles.safe} edges={['top']}>
      <ScrollView contentContainerStyle={styles.container}>
        <View style={styles.kop}>
          <RolChip rol={rol} />
          <TvzText preset="screenTitle" style={styles.titel}>
            {t(`kringuitleg.${rol}Titel`)}
          </TvzText>
        </View>

        <View style={styles.motief}>
          <KringMotief />
        </View>

        <Card style={styles.kaart}>
          {ROLLEN.map((item) => (
            <View key={item} style={styles.rij}>
              <View style={[styles.stip, { backgroundColor: rolTints[item].stip }]} />
              <View style={styles.rijTekst}>
                <TvzText preset="cardTitle" style={styles.rijTitel}>
                  {t(`kringuitleg.rol${item.charAt(0).toUpperCase()}${item.slice(1)}Titel`)}
                  {item === rol ? ` ${t('kringuitleg.ditBenJij')}` : ''}
                </TvzText>
                <TvzText preset="secondary">
                  {t(`kringuitleg.rol${item.charAt(0).toUpperCase()}${item.slice(1)}Tekst`)}
                </TvzText>
              </View>
            </View>
          ))}
        </Card>

        <TvzText preset="secondary" style={styles.rodeDraad}>
          {t('kringuitleg.rodeDraad')}
        </TvzText>

        <View style={styles.voet}>
          <View style={styles.boWrap}>
            <Bo width={104} />
          </View>
          <Button
            label={t('kringuitleg.deAppIn')}
            variant="cta"
            size="lg"
            onPress={() => router.replace(START[rol] as never)}
          />
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: colors.bg,
  },
  container: {
    padding: spacing.screen,
    paddingBottom: spacing.xxl,
    flexGrow: 1,
  },
  kop: {
    marginTop: spacing.md,
    gap: spacing.sm,
  },
  titel: {
    marginTop: 2,
  },
  motief: {
    marginVertical: spacing.lg,
  },
  kaart: {
    gap: spacing.lg,
    paddingVertical: spacing.xl,
  },
  rij: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: spacing.md,
  },
  stip: {
    width: 12,
    height: 12,
    borderRadius: radius.pill,
    marginTop: 6,
  },
  rijTekst: {
    flex: 1,
  },
  rijTitel: {
    marginBottom: 2,
  },
  rodeDraad: {
    textAlign: 'center',
    marginTop: spacing.md,
  },
  voet: {
    marginTop: 'auto',
    paddingTop: spacing.lg,
  },
  boWrap: {
    alignItems: 'center',
    marginBottom: spacing.md,
  },
});

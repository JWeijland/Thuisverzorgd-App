import { router } from 'expo-router';
import { Pressable, ScrollView, StyleSheet, View } from 'react-native';
import { ChevronRight, HeartHandshake, Store } from 'lucide-react-native';

import { t } from '@/i18n';
import { colors, radius, spacing } from '@/theme';
import { Card, GradientHeader, Pill, TvzText } from '@/ui';

/**
 * Hulp-tab van de hulpvrager (ontwerp 4.0): één vraag per scherm, op
 * ouderen-maat. Kies gratis een buddy of betaalde hulp aan huis; de
 * flows zelf zijn eigen pagina's (/buddy-vragen en /regelen/voorzieningen).
 */
export function HulpKeuze() {
  return (
    <View style={styles.safe}>
      <GradientHeader
        title={t('hulpKeuze.titel')}
        subtitle={t('hulpKeuze.uitleg')}
        wobbel
        bo
        boRol="hulpvrager"
      />
      <ScrollView contentContainerStyle={styles.lijst}>
        <Pressable accessibilityRole="button" onPress={() => router.push('/buddy-vragen')}>
          <Card style={[styles.kaart, styles.kaartBuddy]}>
            <View style={styles.kop}>
              <View style={[styles.icoon, styles.icoonBuddy]}>
                <HeartHandshake color={colors.successText} size={26} strokeWidth={2.2} />
              </View>
              <TvzText preset="screenTitle" style={styles.kaartTitel}>
                {t('hulpKeuze.buddyTitel')}
              </TvzText>
              <Pill
                label={t('voorzien.gratisPill')}
                color={colors.successText}
                backgroundColor={colors.successBg}
              />
            </View>
            <TvzText preset="body" style={styles.tekst}>
              {t('hulpKeuze.buddyTekst')}
            </TvzText>
            <View style={styles.verder}>
              <TvzText preset="cardTitle" style={styles.verderBuddy}>
                {t('hulpKeuze.buddyKnop')}
              </TvzText>
              <ChevronRight color={colors.successText} size={20} strokeWidth={2.4} />
            </View>
          </Card>
        </Pressable>

        <Pressable accessibilityRole="button" onPress={() => router.push('/regelen/voorzieningen')}>
          <Card style={[styles.kaart, styles.kaartDienst]}>
            <View style={styles.kop}>
              <View style={[styles.icoon, styles.icoonDienst]}>
                <Store color={colors.primaryMid} size={26} strokeWidth={2.2} />
              </View>
              <TvzText preset="screenTitle" style={styles.kaartTitel}>
                {t('hulpKeuze.dienstTitel')}
              </TvzText>
            </View>
            <TvzText preset="body" style={styles.tekst}>
              {t('hulpKeuze.dienstTekst')}
            </TvzText>
            <View style={styles.verder}>
              <TvzText preset="cardTitle" style={styles.verderDienst}>
                {t('hulpKeuze.dienstKnop')}
              </TvzText>
              <ChevronRight color={colors.primaryMid} size={20} strokeWidth={2.4} />
            </View>
          </Card>
        </Pressable>

        <TvzText preset="secondary" style={styles.slotzin}>
          {t('hulpKeuze.slotzin')}
        </TvzText>
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
    paddingBottom: 110,
    gap: spacing.md,
  },
  kaart: {
    paddingVertical: spacing.xl,
    borderLeftWidth: 5,
  },
  kaartBuddy: {
    borderLeftColor: colors.accentDark,
  },
  kaartDienst: {
    borderLeftColor: colors.primaryMid,
  },
  kop: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
  },
  icoon: {
    width: 52,
    height: 52,
    borderRadius: radius.tile,
    alignItems: 'center',
    justifyContent: 'center',
  },
  icoonBuddy: {
    backgroundColor: colors.successBg,
  },
  icoonDienst: {
    backgroundColor: colors.tintBlue,
  },
  kaartTitel: {
    flex: 1,
    fontSize: 21,
  },
  tekst: {
    marginTop: spacing.md,
    fontSize: 17,
  },
  verder: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    marginTop: spacing.md,
  },
  verderBuddy: {
    color: colors.successText,
  },
  verderDienst: {
    color: colors.primaryMid,
  },
  slotzin: {
    textAlign: 'center',
    marginTop: spacing.sm,
    fontSize: 15.5,
  },
});

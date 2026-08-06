import { router } from 'expo-router';
import { Pressable, StyleSheet, View } from 'react-native';
import { ChevronRight, MessagesSquare } from 'lucide-react-native';

import { OpleidingenLijst } from '@/features/learning/OpleidingenLijst';
import { t } from '@/i18n';
import { colors, radius, spacing } from '@/theme';
import { Card, GradientHeader, TvzText } from '@/ui';

/**
 * Leren: de steun-tab van de buddy (ontwerp 4.0). Korte opleidingen die
 * bezoeken makkelijker maken, plus de weg naar het forum. Geen
 * mantelzorg-wegwijzer: die hoort bij de zorgrollen.
 */
export function LerenScherm() {
  return (
    <View style={styles.safe}>
      <GradientHeader
        title={t('leren.titel')}
        subtitle={t('leren.uitleg')}
        wobbel
        bo
        boRol="vrijwilliger"
      />
      <OpleidingenLijst
        footer={
          <Pressable accessibilityRole="button" onPress={() => router.push('/forum')}>
            <Card style={styles.forumTegel}>
              <View style={styles.forumIcoon}>
                <MessagesSquare color={colors.warnText} size={22} strokeWidth={2.2} />
              </View>
              <View style={styles.forumTekst}>
                <TvzText preset="cardTitle">{t('leren.forumTitel')}</TvzText>
                <TvzText preset="secondary">{t('leren.forumTekst')}</TvzText>
              </View>
              <ChevronRight color={colors.inkFaint} size={20} strokeWidth={2.2} />
            </Card>
          </Pressable>
        }
      />
    </View>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: colors.bg,
  },
  forumTegel: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
    paddingVertical: spacing.lg,
    marginTop: spacing.sm,
  },
  forumIcoon: {
    width: 44,
    height: 44,
    borderRadius: radius.tile,
    backgroundColor: colors.warnBg,
    alignItems: 'center',
    justifyContent: 'center',
  },
  forumTekst: {
    flex: 1,
  },
});

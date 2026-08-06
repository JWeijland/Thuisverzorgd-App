import { router } from 'expo-router';
import type { ReactNode } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { t } from '@/i18n';
import { colors, spacing } from '@/theme';
import { TvzText } from '@/ui/TvzText';

type Props = {
  titel: string;
  sub?: string;
  /** Rechts in de kop, bijv. een statuspil. */
  right?: ReactNode;
};

/**
 * Lichte kop met terugpijl voor losse pagina's (één functie per pagina heeft
 * altijd een weg terug). Zelfde patroon als de kringchat-kop.
 */
export function TerugKop({ titel, sub, right }: Props) {
  return (
    <SafeAreaView edges={['top']} style={styles.safe}>
      <View style={styles.row}>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={t('algemeen.terug')}
          onPress={() => router.back()}
          style={styles.back}
        >
          <TvzText preset="cardTitle">←</TvzText>
        </Pressable>
        <View style={styles.tekst}>
          <TvzText preset="cardTitle" numberOfLines={1}>
            {titel}
          </TvzText>
          {sub ? (
            <TvzText preset="secondary" numberOfLines={1}>
              {sub}
            </TvzText>
          ) : null}
        </View>
        {right}
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: {
    backgroundColor: colors.bg,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
    paddingHorizontal: spacing.screen,
    paddingVertical: spacing.sm,
    minHeight: 56,
  },
  back: {
    width: 44,
    height: 44,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 22,
    backgroundColor: colors.tintBlue,
  },
  tekst: {
    flex: 1,
  },
});

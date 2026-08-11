import { Pressable, StyleSheet, View } from 'react-native';

import { haptics } from '@/lib/haptics';
import { colors, hitTarget, spacing } from '@/theme';
import { TvzText } from '@/ui/TvzText';

export type Keuze<T extends string> = {
  waarde: T;
  label: string;
};

type Props<T extends string> = {
  opties: Keuze<T>[];
  gekozen: T;
  onKies: (waarde: T) => void;
};

/**
 * Een rij keuzes zonder pillen: de gekozen optie krijgt een streep eronder
 * (wens Jelle 11-08). Rustiger dan een rij afgeronde knoppen, en je ziet in
 * één oogopslag wat er aan staat.
 */
export function KeuzeRij<T extends string>({ opties, gekozen, onKies }: Props<T>) {
  return (
    <View style={styles.rij}>
      {opties.map((optie) => {
        const aan = optie.waarde === gekozen;
        return (
          <Pressable
            key={optie.waarde}
            accessibilityRole="radio"
            accessibilityState={{ selected: aan }}
            accessibilityLabel={optie.label}
            onPress={() => {
              if (aan) return;
              void haptics.selectie();
              onKies(optie.waarde);
            }}
            style={styles.optie}
          >
            <TvzText preset={aan ? 'bodyBold' : 'body'} style={aan ? styles.aan : styles.uit}>
              {optie.label}
            </TvzText>
            <View style={[styles.streep, aan && styles.streepAan]} />
          </Pressable>
        );
      })}
    </View>
  );
}

const styles = StyleSheet.create({
  rij: {
    flexDirection: 'row',
    gap: spacing.xl,
  },
  optie: {
    minHeight: hitTarget.min,
    justifyContent: 'center',
    gap: 6,
  },
  aan: {
    color: colors.ink,
  },
  uit: {
    color: colors.inkSoft,
  },
  streep: {
    height: 3,
    borderRadius: 2,
    backgroundColor: 'transparent',
  },
  streepAan: {
    backgroundColor: colors.accent,
  },
});

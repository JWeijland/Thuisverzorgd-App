import { StyleSheet, View, type StyleProp, type ViewProps, type ViewStyle } from 'react-native';

import { colors, dashedBorder, radius, shadows, spacing } from '@/theme';

type Props = ViewProps & {
  /** Gestippelde rand = concept / nog te doen (koppelcode, conceptplanning, upload). */
  dashed?: boolean;
  style?: StyleProp<ViewStyle>;
};

/** Vlakken zijn bijna vierkant: kaart met radius 12, zachte merkschaduw. */
export function Card({ dashed = false, style, children, ...rest }: Props) {
  return (
    <View {...rest} style={[styles.card, dashed ? styles.dashed : shadows.card, style]}>
      {children}
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: colors.white,
    borderRadius: radius.card,
    padding: spacing.cardPadding,
  },
  dashed: {
    ...dashedBorder,
    backgroundColor: 'transparent',
  },
});

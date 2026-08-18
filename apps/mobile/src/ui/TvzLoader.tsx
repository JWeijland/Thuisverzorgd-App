import { StyleSheet, View } from 'react-native';

import { colors, radius } from '@/theme';
import { TvzBounce } from '@/ui/animations';

/**
 * Laad-animatie volgens het brandbook ("bij laden valt het logo uiteen in
 * drie stuiterende stippen: rood, groen, dieprood") — geen systeem-spinner.
 */
export function TvzLoader({ onDark = false }: { onDark?: boolean }) {
  const dotColors = [colors.primaryMid, colors.accent, onDark ? colors.white : colors.primaryDark];
  return (
    <View style={styles.row} accessibilityLabel="Laden">
      {dotColors.map((color, i) => (
        <TvzBounce key={i} delay={i * 160}>
          <View style={[styles.dot, { backgroundColor: color }]} />
        </TvzBounce>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    gap: 8,
    alignItems: 'center',
    justifyContent: 'center',
  },
  dot: {
    width: 12,
    height: 12,
    borderRadius: radius.pill,
  },
});

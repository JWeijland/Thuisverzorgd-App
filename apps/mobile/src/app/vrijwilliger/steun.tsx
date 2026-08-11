import { StyleSheet, View } from 'react-native';

import { PadHeader } from '@/features/navigatie/PadHeader';
import { PadPagina } from '@/features/navigatie/PadPagina';
import { LerenScherm } from '@/features/steun/LerenScherm';
import { colors } from '@/theme';

/**
 * Steun voor de vrijwilliger zelf: opleidingen en het forum. De wegwijzer
 * over zorgen voor een naaste hoort bij het weet-pad en zit hier bewust niet
 * in; de vrijwilliger verleent de hulp, hij regelt hem niet.
 */
export default function VrijwilligerSteun() {
  return (
    <View style={styles.safe}>
      <PadHeader pad="vrijwilliger" />
      <PadPagina>
        <LerenScherm />
      </PadPagina>
    </View>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: colors.bg,
  },
});

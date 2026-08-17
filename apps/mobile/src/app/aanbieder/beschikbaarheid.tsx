import { StyleSheet, View } from 'react-native';

import { BeschikbaarheidScherm } from '@/features/aanbieder/BeschikbaarheidScherm';
import { PadHeader } from '@/features/navigatie/PadHeader';
import { PadPagina } from '@/features/navigatie/PadPagina';
import { colors } from '@/theme';

/** Beschikbaarheid: het werkritme en de afwezigheid van de aanbieder. */
export default function AanbiederBeschikbaarheid() {
  return (
    <View style={styles.safe}>
      <PadHeader pad="aanbieder" />
      <PadPagina>
        <BeschikbaarheidScherm />
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

import { StyleSheet, View } from 'react-native';

import { AfsprakenScherm } from '@/features/aanbieder/AfsprakenScherm';
import { PadHeader } from '@/features/navigatie/PadHeader';
import { PadPagina } from '@/features/navigatie/PadPagina';
import { colors } from '@/theme';

/** Mijn afspraken: de komende boekingen bij deze aanbieder. */
export default function AanbiederAfspraken() {
  return (
    <View style={styles.safe}>
      <PadHeader pad="aanbieder" />
      <PadPagina>
        <AfsprakenScherm />
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

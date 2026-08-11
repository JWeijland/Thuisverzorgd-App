import { StyleSheet, View } from 'react-native';

import { PadHeader } from '@/features/navigatie/PadHeader';
import { PadPagina } from '@/features/navigatie/PadPagina';
import { Marktplaats } from '@/features/voorzieningen/Marktplaats';
import { colors } from '@/theme';

/**
 * Voorzieningen (handoff, scherm 03): het raster met Buddy als uitgelichte
 * tegel en daarnaast de betaalde diensten. Ook de hulpvrager komt hier,
 * want die moet zelf een dienst kunnen boeken.
 */
export default function Voorzieningen() {
  return (
    <View style={styles.safe}>
      <PadHeader pad="regelen" />
      <PadPagina>
        <Marktplaats />
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

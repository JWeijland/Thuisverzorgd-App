import { StyleSheet, View } from 'react-native';

import { PadHeader } from '@/features/navigatie/PadHeader';
import { PadPagina } from '@/features/navigatie/PadPagina';
import { RoosterVrijwilliger } from '@/features/tasks/screens/RoosterVrijwilliger';
import { colors } from '@/theme';

/** Mijn taken: het eigen rooster met geclaimde en openstaande taken. */
export default function VrijwilligerTaken() {
  return (
    <View style={styles.safe}>
      <PadHeader pad="vrijwilliger" />
      <PadPagina>
        <RoosterVrijwilliger />
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

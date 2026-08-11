import { StyleSheet, View } from 'react-native';

import { BuurtScherm } from '@/features/map/BuurtScherm';
import { PadHeader } from '@/features/navigatie/PadHeader';
import { t } from '@/i18n';
import { colors } from '@/theme';

/**
 * De volledige buurtkaart voor beheerder en hulpvrager. Die is niet meer
 * prominent (handoff §3b): je komt hier via de buurt-scan van de buddy-flow
 * of via "Buddy zoeken in de buurt" op de kringpagina.
 *
 * Met een padheader erboven, want zonder kop had dit scherm geen weg terug.
 */
export default function BuurtKaart() {
  return (
    <View style={styles.safe}>
      <PadHeader
        pad="regelen"
        actiefRoute="/regelen/kring"
        kruimels={[t('buurt.kruimel')]}
        verbergSchuifjes
      />
      <BuurtScherm />
    </View>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: colors.bg,
  },
});

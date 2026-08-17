import { useLocalSearchParams } from 'expo-router';
import { StyleSheet, View } from 'react-native';

import { BrokerChat } from '@/features/forum/BrokerChat';
import { PadHeader } from '@/features/navigatie/PadHeader';
import { t } from '@/i18n';
import { colors } from '@/theme';

/**
 * De mantelzorgmakelaar als voorziening in het hulp-pad (wens Jelle 17-08):
 * chatten met meerdere makelaars, met hun profielen en onderwerpen
 * (BrokerChat). Je komt hier via de makelaar-tegel op Voorzieningen of via
 * de verwijzing in de zoek-popup; ?vraag=... komt voorgevuld mee.
 */
export default function RegelenMakelaar() {
  const params = useLocalSearchParams<{ vraag?: string; makelaar?: string }>();
  return (
    <View style={styles.safe}>
      <PadHeader
        pad="regelen"
        actiefRoute="/regelen/voorzieningen"
        kruimels={[t('voorzien.makelaarTegelTitel')]}
      />
      <BrokerChat startVraag={params.vraag} startMakelaar={params.makelaar} />
    </View>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: colors.bg,
  },
});

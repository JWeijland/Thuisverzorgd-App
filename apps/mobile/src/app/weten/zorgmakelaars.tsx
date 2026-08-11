import { useLocalSearchParams } from 'expo-router';
import { StyleSheet, View } from 'react-native';

import { BrokerChat } from '@/features/forum/BrokerChat';
import { colors } from '@/theme';
import { PadHeader } from '@/features/navigatie/PadHeader';

/**
 * Chat met de hulpmakelaar als eigen pagina (laag 1). De route /makelaar
 * blijft de console voor de makelaar-rol zelf; dit is de kant van de vrager.
 * Vanuit de wegwijzer kun je hier binnenkomen met ?vraag=... voorgevuld.
 */
export default function Zorgmakelaars() {
  const params = useLocalSearchParams<{ vraag?: string }>();
  return (
    <View style={styles.safe}>
      <PadHeader pad="weten" />
      <BrokerChat startVraag={params.vraag} />
    </View>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: colors.bg,
  },
});

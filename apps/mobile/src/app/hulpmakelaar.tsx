import { useLocalSearchParams } from 'expo-router';
import { StyleSheet, View } from 'react-native';

import { BrokerChat } from '@/features/forum/BrokerChat';
import { t } from '@/i18n';
import { colors } from '@/theme';
import { TerugKop } from '@/ui/TerugKop';
import { useStatusBalk } from '@/lib/statusbalk';

/**
 * Chat met de hulpmakelaar als eigen pagina (laag 1). De route /makelaar
 * blijft de console voor de makelaar-rol zelf; dit is de kant van de vrager.
 * Vanuit de wegwijzer kun je hier binnenkomen met ?vraag=... voorgevuld.
 */
export default function HulpmakelaarScreen() {
  useStatusBalk('donker');
  const params = useLocalSearchParams<{ vraag?: string }>();
  return (
    <View style={styles.safe}>
      <TerugKop titel={t('steun.tabMakelaar')} sub={t('steun.vertrouwelijk')} />
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

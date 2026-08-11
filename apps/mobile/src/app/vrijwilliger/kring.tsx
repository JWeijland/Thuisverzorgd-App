import { useLocalSearchParams } from 'expo-router';
import { StyleSheet, View } from 'react-native';

import { KringScreen } from '@/features/circles/screens/KringScreen';
import { PadHeader } from '@/features/navigatie/PadHeader';
import { t } from '@/i18n';
import { colors } from '@/theme';

/**
 * De kring waar de buddy in zit, met zijn eigen kop. Dit is geen schuifje:
 * je komt hier via een kringrondje op de kaart of via de berichtenknop. De
 * schuifjes staan daarom uit, en de terugpijl brengt je terug naar waar je
 * vandaan kwam.
 */
export default function VrijwilligerKring() {
  const { tab } = useLocalSearchParams<{ tab?: string }>();
  return (
    <View style={styles.safe}>
      <PadHeader
        pad="vrijwilliger"
        kruimels={[tab === 'berichten' ? t('kring.tabBerichten') : t('kring.titel')]}
        verbergSchuifjes
      />
      <KringScreen />
    </View>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: colors.bg,
  },
});

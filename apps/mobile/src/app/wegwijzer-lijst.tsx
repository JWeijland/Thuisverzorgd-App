import { StyleSheet, View } from 'react-native';

import { WegwijzerLijst } from '@/features/wegwijzer/WegwijzerLijst';
import { t } from '@/i18n';
import { colors } from '@/theme';
import { TerugKop } from '@/ui/TerugKop';
import { useStatusBalk } from '@/lib/statusbalk';

/** Wegwijzer als eigen pagina (laag 1): zoeken en lezen, één functie. */
export default function WegwijzerLijstScreen() {
  useStatusBalk('donker');
  return (
    <View style={styles.safe}>
      <TerugKop titel={t('wegwijzer.titel')} sub={t('wegwijzer.intro')} />
      <WegwijzerLijst />
    </View>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: colors.bg,
  },
});

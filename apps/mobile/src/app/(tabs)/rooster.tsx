import { StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { t } from '@/i18n';
import { spacing } from '@/theme';
import { Card, EmptyState } from '@/ui';

// Placeholder — het echte rooster (weekstrip, taakplanner, taaklijst) komt in Fase 5.
export default function RoosterScreen() {
  return (
    <SafeAreaView style={styles.safe} edges={['top']}>
      <View style={styles.container}>
        <Card>
          <EmptyState title={t('placeholder.titel')} body={t('placeholder.tekst')} />
        </Card>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1 },
  container: { flex: 1, padding: spacing.screen },
});

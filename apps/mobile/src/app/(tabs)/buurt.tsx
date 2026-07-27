import { StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { t } from '@/i18n';
import { spacing } from '@/theme';
import { Card, EmptyState } from '@/ui';

// Placeholder — dit scherm wordt in een latere fase gebouwd (zie docs/PLAN.md).
export default function BuurtScreen() {
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

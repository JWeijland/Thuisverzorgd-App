import { router } from 'expo-router';
import { ScrollView, StyleSheet, View } from 'react-native';

import { useMyCircle } from '@/features/circles/api';
import { useCreateTask } from '@/features/tasks/api';
import { TaskPlanner } from '@/features/tasks/TaskPlanner';
import { t } from '@/i18n';
import { useStatusBalk } from '@/lib/statusbalk';
import { colors, spacing } from '@/theme';
import { Card, EmptyState, TvzText } from '@/ui';
import { TerugKop } from '@/ui/TerugKop';

/** Taak inplannen als eigen pagina (laag 2): één taak, één functie. */
export default function TaakPlannenScreen() {
  useStatusBalk('donker');
  const circle = useMyCircle();
  const createTask = useCreateTask(circle.data?.id);

  return (
    <View style={styles.safe}>
      <TerugKop titel={t('planner.titel')} sub={t('planner.uitleg')} />
      <ScrollView contentContainerStyle={styles.lijst} keyboardShouldPersistTaps="handled">
        {!circle.isLoading && !circle.data ? (
          <Card>
            <EmptyState title={t('rooster.geenKring')} body={t('rooster.geenKringTekst')} />
          </Card>
        ) : (
          <Card>
            <TaskPlanner
              anchor={new Date()}
              submitLabel={t('planner.zetInRooster')}
              busy={createTask.isPending}
              onSubmit={(task) => {
                createTask.mutate(task, { onSuccess: () => router.back() });
              }}
            />
          </Card>
        )}
        <TvzText preset="secondary" style={styles.voet}>
          {t('planner.rodeDraad')}
        </TvzText>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: colors.bg,
  },
  lijst: {
    padding: spacing.screen,
    paddingTop: spacing.sm,
    paddingBottom: 110,
    gap: spacing.cardGap,
  },
  voet: {
    textAlign: 'center',
    marginTop: spacing.sm,
    color: colors.inkFaint,
  },
});

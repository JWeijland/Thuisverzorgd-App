import { Tabs } from 'expo-router';
import { View } from 'react-native';

import { WalkthroughOverlay } from '@/features/onboarding/WalkthroughOverlay';
import { useProfile, useSession } from '@/features/onboarding/useAuth';
import { TaskBanner } from '@/features/tasks/TaskBanner';
import { t } from '@/i18n';
import { TAB_ORDER, TvzTabBar, visibleTabs } from '@/ui/TabBar';

export default function TabsLayout() {
  const { session } = useSession();
  const profile = useProfile();
  const role = profile.data?.role;
  const zichtbaar = visibleTabs(role);
  const verborgen = TAB_ORDER.filter((name) => !zichtbaar.includes(name));

  return (
    <View style={{ flex: 1 }}>
      <Tabs
        tabBar={(props) => <TvzTabBar {...props} hidden={verborgen} />}
        screenOptions={{ headerShown: false, sceneStyle: { backgroundColor: '#F5F8FC' } }}
      >
        <Tabs.Screen name="rooster" options={{ title: t('tabs.rooster') }} />
        <Tabs.Screen name="voorzien" options={{ title: t('tabs.voorzien') }} />
        <Tabs.Screen name="buurt" options={{ title: t('tabs.buurt') }} />
        <Tabs.Screen name="kring" options={{ title: t('tabs.kring') }} />
        <Tabs.Screen name="steun" options={{ title: t('tabs.steun') }} />
        <Tabs.Screen name="profiel" options={{ title: t('tabs.profiel') }} />
      </Tabs>
      <TaskBanner />
      <WalkthroughOverlay
        uid={session?.user.id}
        role={
          role === 'beheerder' || role === 'vrijwilliger' || role === 'hulpvrager' ? role : null
        }
      />
    </View>
  );
}

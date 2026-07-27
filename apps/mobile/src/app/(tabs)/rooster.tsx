import { useProfile } from '@/features/onboarding/useAuth';
import { RoosterBeheerder } from '@/features/tasks/screens/RoosterBeheerder';
import { RoosterHulpvrager } from '@/features/tasks/screens/RoosterHulpvrager';
import { RoosterVrijwilliger } from '@/features/tasks/screens/RoosterVrijwilliger';

export default function RoosterScreen() {
  const profile = useProfile();
  switch (profile.data?.role) {
    case 'vrijwilliger':
      return <RoosterVrijwilliger />;
    case 'hulpvrager':
      return <RoosterHulpvrager />;
    default:
      return <RoosterBeheerder />;
  }
}

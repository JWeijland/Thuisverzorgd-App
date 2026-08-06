import { KringScreen } from '@/features/circles/screens/KringScreen';
import { MijnKring } from '@/features/circles/screens/MijnKring';
import { useProfile } from '@/features/onboarding/useAuth';

/**
 * Kring-route (ontwerp 4.0): voor de hulpvrager is dit de tab "Mijn kring"
 * met de roluitleg; beheerder en buddy komen hier via de kringbalk en zien
 * de ledenpagina.
 */
export default function Kring() {
  const profile = useProfile();
  if (profile.data?.role === 'hulpvrager') return <MijnKring />;
  return <KringScreen />;
}

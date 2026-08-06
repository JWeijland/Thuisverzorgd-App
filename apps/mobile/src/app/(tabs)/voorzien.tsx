import { useProfile } from '@/features/onboarding/useAuth';
import { HulpKeuze } from '@/features/voorzieningen/HulpKeuze';
import { Marktplaats } from '@/features/voorzieningen/Marktplaats';

/**
 * Voorzien-tab (ontwerp 4.0): de beheerder ziet de marktplaats (laag 3);
 * voor de hulpvrager heet deze tab "Hulp" en is het een keuzescherm:
 * gratis een buddy of betaalde hulp aan huis.
 */
export default function VoorzienScreen() {
  const profile = useProfile();
  if (profile.data?.role === 'hulpvrager') return <HulpKeuze />;
  return <Marktplaats />;
}

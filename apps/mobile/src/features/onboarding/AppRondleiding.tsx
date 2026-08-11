import { WalkthroughOverlay } from '@/features/onboarding/WalkthroughOverlay';
import { useProfile, useSession } from '@/features/onboarding/useAuth';

/**
 * Hangt de rondleiding aan de ingelogde gebruiker. Zat vroeger in de
 * tabbalk-layout; die bestaat niet meer, dus dit staat nu in de root-layout
 * en haalt zelf de sessie en de rol op.
 */
export function AppRondleiding() {
  const { session } = useSession();
  const profile = useProfile();
  const role = profile.data?.role;

  return (
    <WalkthroughOverlay
      uid={session?.user.id}
      role={role === 'beheerder' || role === 'vrijwilliger' || role === 'hulpvrager' ? role : null}
    />
  );
}

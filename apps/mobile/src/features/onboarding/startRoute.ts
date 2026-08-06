/**
 * Bepaalt waar de gebruiker landt bij het openen van de app.
 * Pure functie, los van React, zodat hij testbaar is.
 */

export type ProfileGate = {
  role: 'beheerder' | 'vrijwilliger' | 'hulpvrager' | 'admin' | 'makelaar' | null;
  id_verified: boolean;
} | null;

export function getStartRoute(hasSession: boolean, profile: ProfileGate): string {
  if (!hasSession) return '/welkom';
  if (!profile || profile.role === null) return '/rolkeuze';
  if (profile.role === 'vrijwilliger' && !profile.id_verified) return '/id-en-foto';
  // Ontwerp 4.0: de beheerder start op Steun (laag 1, het hart van de app);
  // buddy en hulpvrager starten op hun eigen invulling van de rooster-tab
  // (Taken respectievelijk Vandaag).
  if (profile.role === 'beheerder') return '/steun';
  return '/rooster';
}

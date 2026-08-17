/**
 * Bepaalt waar de gebruiker landt bij het openen van de app.
 * Pure functie, los van React, zodat hij testbaar is.
 */

export type ProfileGate = {
  role: 'beheerder' | 'vrijwilliger' | 'hulpvrager' | 'aanbieder' | 'admin' | 'makelaar' | null;
  id_verified: boolean;
} | null;

export function getStartRoute(hasSession: boolean, profile: ProfileGate): string {
  if (!hasSession) return '/welkom';
  // Nog geen rol: eerst het verhaal van de app (weten, regelen, er is
  // iemand), daarna kiest de gebruiker een rol.
  if (!profile || profile.role === null) return '/verhaal';
  if (profile.role === 'vrijwilliger' && !profile.id_verified) return '/id-en-foto';
  // De tabbalk is weg (handoff-voorzieningen): beheerder en hulpvrager kiezen
  // eerst een pad, de vrijwilliger slaat dat keuzescherm over en landt direct
  // op de kaart met hulpvragen.
  if (profile.role === 'vrijwilliger') return '/vrijwilliger/buurt';
  // De aanbieder (account door Thuisverzorgd aangemaakt) heeft geen
  // keuzescherm: die landt direct in Mijn agenda.
  if (profile.role === 'aanbieder') return '/aanbieder/beschikbaarheid';
  // Sinds 17-08 land je standaard op de hulp-pagina; het info-gedeelte zit
  // achter het vergrootglas (zoek-popup). Het keuzescherm blijft bereikbaar
  // via de Bo-knop.
  if (profile.role === 'beheerder' || profile.role === 'hulpvrager') {
    return '/regelen/voorzieningen';
  }
  return '/pad';
}

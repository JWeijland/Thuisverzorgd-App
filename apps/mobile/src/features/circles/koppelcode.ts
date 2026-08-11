/** Hoeveel tekens de code heeft na het vaste voorvoegsel: TVZ-XXXX. */
const LENGTE = 4;

/**
 * Maakt van wat iemand typt een nette koppelcode. Het voorvoegsel "TVZ-" is
 * bij iedereen hetzelfde, dus dat hoef je niet zelf in te tikken (wens Jelle
 * 11-08): je typt de vier tekens en de app zet de rest ervoor.
 *
 * Plak je de hele code, met of zonder streepje, dan werkt dat ook.
 */
export function netteKoppelcode(invoer: string): string {
  const tekens = invoer
    .toUpperCase()
    // Alleen letters en cijfers overhouden; streepjes en spaties zetten we
    // zelf wel op de goede plek.
    .replace(/[^A-Z0-9]/g, '')
    // Wie "TVZ" mee typt of plakt, krijgt het niet dubbel.
    .replace(/^TVZ/, '')
    .slice(0, LENGTE);

  return tekens.length > 0 ? `TVZ-${tekens}` : '';
}

/** Is dit een volledige code? Pas dan heeft koppelen zin. */
export function isVolledigeKoppelcode(code: string): boolean {
  return /^TVZ-[A-Z0-9]{4}$/.test(code);
}

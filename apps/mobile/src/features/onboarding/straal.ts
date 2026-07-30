/**
 * De hulpstraal: binnen welke afstand wil een vrijwilliger hulp verlenen?
 * Standaard 300 meter, oftewel de eigen straat. Losse helpers, zodat de
 * afronding en de labels op één plek staan en getest kunnen worden.
 */

/** Keuzes in meters; de eerste is de standaard. */
export const STRAAL_OPTIES = [300, 500, 1000, 2000, 5000, 10000, 25000] as const;

export const STRAAL_STANDAARD = 300;

/** "300 m" of "2 km" (en "2,5 km" waar dat nodig is). */
export function straalLabel(meters: number): string {
  if (meters < 1000) return `${meters} m`;
  const km = meters / 1000;
  return `${Number.isInteger(km) ? km : km.toFixed(1).replace('.', ',')} km`;
}

/** Buiten bereik afkappen naar de dichtstbijzijnde geldige keuze. */
export function dichtstbijzijndeStraal(meters: number | null | undefined): number {
  if (meters == null) return STRAAL_STANDAARD;
  return STRAAL_OPTIES.reduce((beste, optie) =>
    Math.abs(optie - meters) < Math.abs(beste - meters) ? optie : beste,
  );
}

/**
 * Valt een afstand binnen de straal? De marge vangt op dat locaties ~1 km
 * vervaagd zijn (privacy-eis): zonder die marge zou je bij 300 meter je
 * buurvrouw kunnen mislopen puur door de afronding. Dezelfde marge staat
 * server-side in `hulpstraal_marge_m()`.
 */
export const VERVAGING_MARGE_M = 1200;

export function binnenStraal(afstandKm: number | null | undefined, straalM: number): boolean {
  if (afstandKm == null) return true;
  return afstandKm * 1000 <= straalM + VERVAGING_MARGE_M;
}

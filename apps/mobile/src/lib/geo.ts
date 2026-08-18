/** Geo-helpers voor de buurtkaart. */

export type LatLng = { lat: number; lon: number };

export type Region = {
  latitude: number;
  longitude: number;
  latitudeDelta: number;
  longitudeDelta: number;
};

/** Afstand in kilometers (haversine). */
export function haversineKm(a: LatLng, b: LatLng): number {
  const R = 6371;
  const dLat = ((b.lat - a.lat) * Math.PI) / 180;
  const dLon = ((b.lon - a.lon) * Math.PI) / 180;
  const s =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((a.lat * Math.PI) / 180) * Math.cos((b.lat * Math.PI) / 180) * Math.sin(dLon / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(s));
}

/** "650 m van jou" / "2,1 km van jou". */
export function formatDistance(km: number): string {
  if (km < 1) return `${Math.round(km * 1000)} m`;
  return `${km.toFixed(1).replace('.', ',')} km`;
}

/** Ligt een punt binnen de zichtbare kaartregio? (voor de live teller) */
export function isInRegion(point: LatLng, region: Region): boolean {
  return (
    Math.abs(point.lat - region.latitude) <= region.latitudeDelta / 2 &&
    Math.abs(point.lon - region.longitude) <= region.longitudeDelta / 2
  );
}

export function countInRegion(points: LatLng[], region: Region): number {
  return points.filter((point) => isInRegion(point, region)).length;
}

/**
 * Coördinaten bij een gekozen adres, via de PDOK Locatieserver (dezelfde
 * bron als de suggesties in AdresVeld; gratis, geen sleutel). Geeft null als
 * er niets gevonden wordt; de kring werkt dan gewoon zonder kaartpositie.
 */
export async function adresNaarCoordinaten(adres: string): Promise<LatLng | null> {
  try {
    const url = `https://api.pdok.nl/bzk/locatieserver/search/v3_1/free?q=${encodeURIComponent(
      adres,
    )}&fq=type:adres&rows=1&fl=centroide_ll`;
    const antwoord = await fetch(url);
    if (!antwoord.ok) return null;
    const json = (await antwoord.json()) as {
      response?: { docs?: { centroide_ll?: string }[] };
    };
    const punt = json.response?.docs?.[0]?.centroide_ll;
    const match = punt?.match(/POINT\(([\d.-]+) ([\d.-]+)\)/);
    if (!match) return null;
    return { lon: Number(match[1]), lat: Number(match[2]) };
  } catch {
    return null;
  }
}

/** Startpositie: Amsterdam-centrum, tot de eigen locatie bekend is. */
export const DEFAULT_REGION: Region = {
  latitude: 52.3676,
  longitude: 4.9041,
  latitudeDelta: 0.09,
  longitudeDelta: 0.06,
};

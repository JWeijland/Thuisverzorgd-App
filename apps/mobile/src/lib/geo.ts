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

/** Startpositie: Amsterdam-centrum, tot de eigen locatie bekend is. */
export const DEFAULT_REGION: Region = {
  latitude: 52.3676,
  longitude: 4.9041,
  latitudeDelta: 0.09,
  longitudeDelta: 0.06,
};

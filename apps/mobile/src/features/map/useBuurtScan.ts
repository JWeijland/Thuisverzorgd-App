import * as Location from 'expo-location';
import { useEffect, useState } from 'react';

import { useMapBuddies, type MapBuddy } from '@/features/map/api';
import { haversineKm, type LatLng } from '@/lib/geo';

/** Binnen hoeveel kilometer telt "in jouw buurt"? */
const BUURT_KM = 5;

/** Hoe lang Bo minimaal aan het kijken is, zodat het geen flits wordt. */
const MINIMALE_SCANTIJD_MS = 2200;

export type BuurtScan = {
  bezig: boolean;
  buddys: number;
  /** De buddy's zelf, zodat de kaart ze kan tekenen. */
  buddyLijst: MapBuddy[];
  /** Waar de kaart naartoe moet kijken; null zolang er geen locatie is. */
  locatie: LatLng | null;
};

/**
 * De buurt-scan uit de buddy-flow (handoff §3b): de app kijkt hoeveel buddy's
 * er in de buurt zijn en laat dat even voelen met een korte laadanimatie. De
 * telling gebeurt op de gegevens die de kaart toch al ophaalt, dus er is geen
 * aparte query nodig; zonder locatie tellen we alles wat we mogen zien.
 *
 * Hulpkringen van anderen tellen we bewust niet mee: die gaan je als beheerder
 * niets aan (feedback Jelle 11-08).
 */
export function useBuurtScan(): BuurtScan {
  const buddys = useMapBuddies(true);
  const [locatie, setLocatie] = useState<LatLng | null>(null);
  const [locatieKlaar, setLocatieKlaar] = useState(false);
  const [tijdOm, setTijdOm] = useState(false);

  useEffect(() => {
    const timer = setTimeout(() => setTijdOm(true), MINIMALE_SCANTIJD_MS);
    return () => clearTimeout(timer);
  }, []);

  useEffect(() => {
    let gestopt = false;
    Location.requestForegroundPermissionsAsync()
      .then(async ({ status }) => {
        if (status !== 'granted' || gestopt) return;
        const positie = await Location.getCurrentPositionAsync({
          accuracy: Location.Accuracy.Balanced,
        });
        if (!gestopt) {
          setLocatie({ lat: positie.coords.latitude, lon: positie.coords.longitude });
        }
      })
      .catch(() => {})
      .finally(() => {
        if (!gestopt) setLocatieKlaar(true);
      });
    return () => {
      gestopt = true;
    };
  }, []);

  const dichtbij = <T extends LatLng>(punt: T) =>
    !locatie || haversineKm(locatie, punt) <= BUURT_KM;

  const buddysDichtbij = (buddys.data ?? []).filter((buddy) =>
    dichtbij({ lat: buddy.lat, lon: buddy.lon }),
  );

  return {
    bezig: !tijdOm || !locatieKlaar || buddys.isLoading,
    buddys: buddysDichtbij.length,
    buddyLijst: buddysDichtbij,
    locatie,
  };
}

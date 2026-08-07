import * as Haptics from 'expo-haptics';
import { Platform } from 'react-native';

/**
 * Eén trilschema voor de hele app, zodat hetzelfde soort moment overal
 * hetzelfde voelt:
 *
 *  - tik        gewone knop of navigatie: kort en licht
 *  - selectie   kiezen/schakelen (chips, toggles, tabs): subtiel klikje
 *  - stevig     belangrijke actie ingezet (groene CTA): duidelijk voelbaar
 *  - succes     iets kleins is gelukt (opgeslagen, verstuurd)
 *  - voltooid   groot moment afgerond (boeking betaald, taak aangenomen,
 *               lid van een kring): lang, oplopend en bevredigend
 *  - waarschuwing / fout   let op, of er ging iets mis
 *
 * Trillen is een extraatje: fouten worden stil ingeslikt en op web/simulator
 * gebeurt er gewoon niets.
 */

const ondersteund = Platform.OS === 'ios' || Platform.OS === 'android';

async function stil(actie: () => Promise<void>) {
  if (!ondersteund) return;
  try {
    await actie();
  } catch {
    // geen haptics-hardware: prima
  }
}

const pauze = (ms: number) => new Promise((r) => setTimeout(r, ms));

export const haptics = {
  tik: () => stil(() => Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light)),
  selectie: () => stil(() => Haptics.selectionAsync()),
  stevig: () => stil(() => Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium)),
  succes: () => stil(() => Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success)),
  waarschuwing: () =>
    stil(() => Haptics.notificationAsync(Haptics.NotificationFeedbackType.Warning)),
  fout: () => stil(() => Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error)),

  /** Lang en bevredigend: drie oplopende tikken en een succes-slot. */
  voltooid: () =>
    stil(async () => {
      await Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
      await pauze(100);
      await Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
      await pauze(100);
      await Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Heavy);
      await pauze(150);
      await Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    }),
};

export type HapticSoort = keyof typeof haptics;

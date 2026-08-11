import { create } from 'zustand';

import type { PadId } from '@/features/navigatie/paden';

export type WalkthroughRole = 'beheerder' | 'vrijwilliger' | 'hulpvrager';

export type WalkthroughStep = {
  titleKey: string;
  textKey: string;
  /** Het pad waar deze stap in speelt; bepaalt de kleur van de header. */
  pad: PadId;
  /** Route van het schuifje waar het wolkje naar wijst. */
  route: string;
};

/**
 * Rondleiding per rol. De tabbalk bestaat niet meer, dus de wolkjes wijzen
 * nu omhoog naar de schuifjes in de header. Beheerder en hulpvrager beginnen
 * bij het weet-pad en eindigen in het regel-pad; de vrijwilliger blijft in
 * zijn eigen drie schuifjes. Overslaan kan altijd (eis handoff).
 */
export const WALKTHROUGH_STEPS: Record<WalkthroughRole, WalkthroughStep[]> = {
  beheerder: [
    {
      titleKey: 'rondleiding.beheerderVoorzienTitel',
      textKey: 'rondleiding.beheerderVoorzienTekst',
      pad: 'regelen',
      route: '/regelen/voorzieningen',
    },
    {
      titleKey: 'rondleiding.beheerder1Titel',
      textKey: 'rondleiding.beheerder1Tekst',
      pad: 'regelen',
      route: '/regelen/planning',
    },
    {
      titleKey: 'rondleiding.beheerder2Titel',
      textKey: 'rondleiding.beheerder2Tekst',
      pad: 'regelen',
      route: '/regelen/kring',
    },
    {
      titleKey: 'rondleiding.beheerder4Titel',
      textKey: 'rondleiding.beheerder4Tekst',
      pad: 'weten',
      route: '/weten/wegwijzer',
    },
  ],
  vrijwilliger: [
    {
      titleKey: 'rondleiding.vrijwilliger2Titel',
      textKey: 'rondleiding.vrijwilliger2Tekst',
      pad: 'vrijwilliger',
      route: '/vrijwilliger/buurt',
    },
    {
      titleKey: 'rondleiding.vrijwilliger1Titel',
      textKey: 'rondleiding.vrijwilliger1Tekst',
      pad: 'vrijwilliger',
      route: '/vrijwilliger/taken',
    },
    {
      titleKey: 'rondleiding.vrijwilliger3Titel',
      textKey: 'rondleiding.vrijwilliger3Tekst',
      pad: 'vrijwilliger',
      route: '/vrijwilliger/steun',
    },
  ],
  // De hulpvrager loopt eerst het hele groene pad af en stapt pas daarna naar
  // het blauwe: zo springt de kleur van de kop niet heen en weer, en volgt de
  // rondleiding de volgorde van de schuifjes (feedback Jelle 11-08).
  hulpvrager: [
    {
      titleKey: 'rondleiding.hulpvragerVoorzienTitel',
      textKey: 'rondleiding.hulpvragerVoorzienTekst',
      pad: 'regelen',
      route: '/regelen/voorzieningen',
    },
    {
      titleKey: 'rondleiding.hulpvrager1Titel',
      textKey: 'rondleiding.hulpvrager1Tekst',
      pad: 'regelen',
      route: '/regelen/planning',
    },
    {
      titleKey: 'rondleiding.hulpvrager2Titel',
      textKey: 'rondleiding.hulpvrager2Tekst',
      pad: 'regelen',
      route: '/regelen/kring',
    },
    {
      titleKey: 'rondleiding.hulpvragerSteunTitel',
      textKey: 'rondleiding.hulpvragerSteunTekst',
      pad: 'weten',
      route: '/weten/wegwijzer',
    },
  ],
};

type WalkthroughState = {
  active: boolean;
  step: number;
  role: WalkthroughRole | null;
  /**
   * Waar staat elk schuifje op het scherm? De header meet dat zelf op, zodat
   * het pijltje van het wolkje echt onder het juiste schuifje uitkomt in
   * plaats van op een geschatte plek.
   */
  schuifjeX: Record<string, number>;
  /** Onderkant van de headerbalk; daar begint het wolkje. */
  headerHoogte: number;
  meetSchuifje: (route: string, midden: number) => void;
  meetHeader: (hoogte: number) => void;
  start: (role: WalkthroughRole) => void;
  next: () => void;
  stop: () => void;
};

export const useWalkthrough = create<WalkthroughState>((set, get) => ({
  active: false,
  step: 0,
  role: null,
  schuifjeX: {},
  headerHoogte: 0,
  meetSchuifje: (route, midden) =>
    set((state) =>
      state.schuifjeX[route] === midden
        ? state
        : { schuifjeX: { ...state.schuifjeX, [route]: midden } },
    ),
  meetHeader: (hoogte) => set((state) => (state.headerHoogte === hoogte ? state : { headerHoogte: hoogte })),
  start: (role) => set({ active: true, step: 0, role }),
  next: () => {
    const { step, role } = get();
    const steps = role ? WALKTHROUGH_STEPS[role] : [];
    if (step + 1 >= steps.length) {
      set({ active: false, step: 0, role: null });
    } else {
      set({ step: step + 1 });
    }
  },
  stop: () => set({ active: false, step: 0, role: null }),
}));

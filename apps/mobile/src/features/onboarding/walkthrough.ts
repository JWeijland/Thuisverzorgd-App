import { create } from 'zustand';

export type WalkthroughRole = 'beheerder' | 'vrijwilliger' | 'hulpvrager';

export type WalkthroughStep = {
  titleKey: string;
  textKey: string;
  /** Tab waar het wolkje naar wijst (0 = Rooster ... 4 = Profiel). */
  tabIndex: number;
  route: string;
};

/**
 * Rondleiding per rol: beheerder 5 stappen, vrijwilliger 4, hulpvrager 3.
 * Elk wolkje legt uit welke knop wat doet. Overslaan kan altijd (eis handoff).
 */
export const WALKTHROUGH_STEPS: Record<WalkthroughRole, WalkthroughStep[]> = {
  beheerder: [
    {
      titleKey: 'rondleiding.beheerder1Titel',
      textKey: 'rondleiding.beheerder1Tekst',
      tabIndex: 0,
      route: '/rooster',
    },
    {
      titleKey: 'rondleiding.beheerder2Titel',
      textKey: 'rondleiding.beheerder2Tekst',
      tabIndex: 1,
      route: '/buurt',
    },
    {
      titleKey: 'rondleiding.beheerder3Titel',
      textKey: 'rondleiding.beheerder3Tekst',
      tabIndex: 2,
      route: '/kring',
    },
    {
      titleKey: 'rondleiding.beheerder4Titel',
      textKey: 'rondleiding.beheerder4Tekst',
      tabIndex: 3,
      route: '/steun',
    },
    {
      titleKey: 'rondleiding.beheerder5Titel',
      textKey: 'rondleiding.beheerder5Tekst',
      tabIndex: 4,
      route: '/profiel',
    },
  ],
  vrijwilliger: [
    {
      titleKey: 'rondleiding.vrijwilliger1Titel',
      textKey: 'rondleiding.vrijwilliger1Tekst',
      tabIndex: 0,
      route: '/rooster',
    },
    {
      titleKey: 'rondleiding.vrijwilliger2Titel',
      textKey: 'rondleiding.vrijwilliger2Tekst',
      tabIndex: 1,
      route: '/buurt',
    },
    {
      titleKey: 'rondleiding.vrijwilliger3Titel',
      textKey: 'rondleiding.vrijwilliger3Tekst',
      tabIndex: 3,
      route: '/steun',
    },
    {
      titleKey: 'rondleiding.vrijwilliger4Titel',
      textKey: 'rondleiding.vrijwilliger4Tekst',
      tabIndex: 4,
      route: '/profiel',
    },
  ],
  hulpvrager: [
    {
      titleKey: 'rondleiding.hulpvrager1Titel',
      textKey: 'rondleiding.hulpvrager1Tekst',
      tabIndex: 0,
      route: '/rooster',
    },
    {
      titleKey: 'rondleiding.hulpvrager2Titel',
      textKey: 'rondleiding.hulpvrager2Tekst',
      tabIndex: 2,
      route: '/kring',
    },
    {
      titleKey: 'rondleiding.hulpvrager3Titel',
      textKey: 'rondleiding.hulpvrager3Tekst',
      tabIndex: 4,
      route: '/profiel',
    },
  ],
};

type WalkthroughState = {
  active: boolean;
  step: number;
  role: WalkthroughRole | null;
  start: (role: WalkthroughRole) => void;
  next: () => void;
  stop: () => void;
};

export const useWalkthrough = create<WalkthroughState>((set, get) => ({
  active: false,
  step: 0,
  role: null,
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

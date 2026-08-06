import { create } from 'zustand';

export type WalkthroughRole = 'beheerder' | 'vrijwilliger' | 'hulpvrager';

export type WalkthroughStep = {
  titleKey: string;
  textKey: string;
  /** Tabnaam waar het wolkje naar wijst; de positie hangt af van de rol. */
  tab: string;
  route: string;
};

/**
 * Rondleiding per rol (ontwerp 4.0): de wolkjes volgen de tabvolgorde van de
 * rol, beginnend op het startscherm. Beheerder 5 stappen, vrijwilliger 4,
 * hulpvrager 4. Elke stap wijst naar een tab die deze rol écht heeft.
 * Overslaan kan altijd (eis handoff).
 */
export const WALKTHROUGH_STEPS: Record<WalkthroughRole, WalkthroughStep[]> = {
  beheerder: [
    {
      titleKey: 'rondleiding.beheerder4Titel',
      textKey: 'rondleiding.beheerder4Tekst',
      tab: 'steun',
      route: '/steun',
    },
    {
      titleKey: 'rondleiding.beheerder1Titel',
      textKey: 'rondleiding.beheerder1Tekst',
      tab: 'rooster',
      route: '/rooster',
    },
    {
      titleKey: 'rondleiding.beheerder2Titel',
      textKey: 'rondleiding.beheerder2Tekst',
      tab: 'buurt',
      route: '/buurt',
    },
    {
      titleKey: 'rondleiding.beheerderVoorzienTitel',
      textKey: 'rondleiding.beheerderVoorzienTekst',
      tab: 'voorzien',
      route: '/voorzien',
    },
    {
      titleKey: 'rondleiding.beheerder5Titel',
      textKey: 'rondleiding.beheerder5Tekst',
      tab: 'profiel',
      route: '/profiel',
    },
  ],
  vrijwilliger: [
    {
      titleKey: 'rondleiding.vrijwilliger1Titel',
      textKey: 'rondleiding.vrijwilliger1Tekst',
      tab: 'rooster',
      route: '/rooster',
    },
    {
      titleKey: 'rondleiding.vrijwilliger2Titel',
      textKey: 'rondleiding.vrijwilliger2Tekst',
      tab: 'buurt',
      route: '/buurt',
    },
    {
      titleKey: 'rondleiding.vrijwilliger3Titel',
      textKey: 'rondleiding.vrijwilliger3Tekst',
      tab: 'steun',
      route: '/steun',
    },
    {
      titleKey: 'rondleiding.vrijwilliger4Titel',
      textKey: 'rondleiding.vrijwilliger4Tekst',
      tab: 'profiel',
      route: '/profiel',
    },
  ],
  hulpvrager: [
    {
      titleKey: 'rondleiding.hulpvrager1Titel',
      textKey: 'rondleiding.hulpvrager1Tekst',
      tab: 'rooster',
      route: '/rooster',
    },
    {
      titleKey: 'rondleiding.hulpvragerVoorzienTitel',
      textKey: 'rondleiding.hulpvragerVoorzienTekst',
      tab: 'voorzien',
      route: '/voorzien',
    },
    {
      titleKey: 'rondleiding.hulpvragerSteunTitel',
      textKey: 'rondleiding.hulpvragerSteunTekst',
      tab: 'steun',
      route: '/steun',
    },
    {
      titleKey: 'rondleiding.hulpvrager2Titel',
      textKey: 'rondleiding.hulpvrager2Tekst',
      tab: 'kring',
      route: '/kring',
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

import AsyncStorage from '@react-native-async-storage/async-storage';
import { router } from 'expo-router';
import { useEffect } from 'react';
import { StyleSheet, View, useWindowDimensions } from 'react-native';

import {
  WALKTHROUGH_STEPS,
  useWalkthrough,
  type WalkthroughRole,
} from '@/features/onboarding/walkthrough';
import { t } from '@/i18n';
import { tabCenterX } from '@/ui/TabBar';
import { Coachmark } from '@/ui';

const seenKey = (uid: string) => `walkthrough-gezien-${uid}`;

type Props = {
  uid: string | undefined;
  role: WalkthroughRole | null | undefined;
};

/**
 * Rondleiding: Caveat-wolkjes met pijltje naar de echte tabknoppen.
 * Start één keer na registratie; overslaan kan altijd.
 */
export function WalkthroughOverlay({ uid, role }: Props) {
  const { active, step, role: activeRole, start, next, stop } = useWalkthrough();
  const { width } = useWindowDimensions();

  useEffect(() => {
    if (!uid || !role) return;
    let cancelled = false;
    AsyncStorage.getItem(seenKey(uid)).then((seen) => {
      if (seen || cancelled) return;
      // Even wachten tot de navigatie volledig staat: direct starten bij de
      // allereerste render crashte productiebuilds.
      setTimeout(() => {
        if (!cancelled) start(role);
      }, 1200);
    });
    return () => {
      cancelled = true;
    };
  }, [uid, role, start]);

  const steps = activeRole ? WALKTHROUGH_STEPS[activeRole] : [];
  const current = active ? steps[step] : undefined;

  useEffect(() => {
    // Stap 0 wijst naar het rooster, waar de gebruiker al staat: niet navigeren.
    if (!current || step === 0) return;
    try {
      router.navigate(current.route as never);
    } catch {
      // navigatie is best effort; het wolkje wijst hoe dan ook naar de juiste tab
    }
  }, [current, step]);

  if (!active || !current || !uid) return null;

  function markSeen() {
    AsyncStorage.setItem(seenKey(uid!), 'ja').catch(() => {});
  }

  const arrowX = tabCenterX(current.tabIndex, width);

  return (
    <View pointerEvents="box-none" style={styles.overlay}>
      <Coachmark
        title={t(current.titleKey)}
        body={t(current.textKey)}
        step={step + 1}
        totalSteps={steps.length}
        arrow="down"
        arrowOffset={arrowX - 20 - 10}
        onNext={() => {
          if (step + 1 >= steps.length) markSeen();
          next();
        }}
        onSkip={() => {
          markSeen();
          stop();
        }}
        style={styles.coachmark}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  overlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    justifyContent: 'flex-end',
  },
  coachmark: {
    marginHorizontal: 20,
    marginBottom: 92,
  },
});

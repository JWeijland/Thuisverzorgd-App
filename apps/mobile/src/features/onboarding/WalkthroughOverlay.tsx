import AsyncStorage from '@react-native-async-storage/async-storage';
import { router } from 'expo-router';
import { useEffect } from 'react';
import { StyleSheet, View } from 'react-native';

import {
  WALKTHROUGH_STEPS,
  useWalkthrough,
  type WalkthroughRole,
} from '@/features/onboarding/walkthrough';
import { t } from '@/i18n';
import { spacing } from '@/theme';
import { Coachmark } from '@/ui';

const seenKey = (uid: string) => `walkthrough-gezien-${uid}`;

type Props = {
  uid: string | undefined;
  role: WalkthroughRole | null | undefined;
};

/**
 * Rondleiding: Caveat-wolkjes met een pijltje omhoog naar het schuifje waar
 * de stap over gaat. De header meet zelf op waar de schuifjes staan, dus het
 * pijltje klopt ook als de labels langer of korter zijn.
 * Start één keer na registratie; overslaan kan altijd.
 */
export function WalkthroughOverlay({ uid, role }: Props) {
  const { active, step, role: activeRole, schuifjeX, headerHoogte, start, next, stop } =
    useWalkthrough();

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
    if (!current) return;
    try {
      router.replace(current.route as never);
    } catch {
      // navigatie is best effort; het wolkje wijst hoe dan ook naar het juiste schuifje
    }
  }, [current]);

  if (!active || !current || !uid) return null;

  function markSeen() {
    AsyncStorage.setItem(seenKey(uid!), 'ja').catch(() => {});
  }

  // Zolang de header nog niet is opgemeten wijst het pijltje naar links,
  // waar het eerste schuifje hoe dan ook staat.
  const midden = schuifjeX[current.route] ?? spacing.screen + 40;

  return (
    <View pointerEvents="box-none" style={[styles.overlay, { paddingTop: headerHoogte + 8 }]}>
      <Coachmark
        title={t(current.titleKey)}
        body={t(current.textKey)}
        step={step + 1}
        totalSteps={steps.length}
        bo
        arrow="up"
        arrowOffset={midden - spacing.screen - 10}
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
    justifyContent: 'flex-start',
  },
  coachmark: {
    marginHorizontal: spacing.screen,
  },
});

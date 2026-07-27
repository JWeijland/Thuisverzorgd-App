import { createContext, useContext, useMemo, useState, type ReactNode } from 'react';

/**
 * Ouderen-modus ("Grotere letters"): schaalt alle tekst 1,3×.
 * Primitives vermenigvuldigen hun fontSize/lineHeight met deze factor.
 */

const LARGE_TEXT_FACTOR = 1.3;

type TextScaleValue = {
  factor: number;
  largeText: boolean;
  setLargeText: (on: boolean) => void;
};

const TextScaleContext = createContext<TextScaleValue>({
  factor: 1,
  largeText: false,
  setLargeText: () => {},
});

export function TextScaleProvider({ children }: { children: ReactNode }) {
  const [largeText, setLargeText] = useState(false);
  const value = useMemo(
    () => ({ factor: largeText ? LARGE_TEXT_FACTOR : 1, largeText, setLargeText }),
    [largeText],
  );
  return <TextScaleContext.Provider value={value}>{children}</TextScaleContext.Provider>;
}

export function useTextScale(): TextScaleValue {
  return useContext(TextScaleContext);
}

/** Schaalt een TextStyle-achtig object mee met de ouderen-modus. */
export function scaleText<T extends { fontSize?: number; lineHeight?: number }>(
  style: T,
  factor: number,
): T {
  if (factor === 1) return style;
  return {
    ...style,
    ...(style.fontSize ? { fontSize: style.fontSize * factor } : null),
    ...(style.lineHeight ? { lineHeight: style.lineHeight * factor } : null),
  };
}

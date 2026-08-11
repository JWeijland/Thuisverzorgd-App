import { useEffect, useState } from 'react';

/**
 * Wacht even met doorgeven tot iemand klaar is met typen. Zo zoeken we niet
 * bij elke toetsaanslag opnieuw.
 */
export function useDebounced(waarde: string, ms = 250): string {
  const [traag, setTraag] = useState(waarde);
  useEffect(() => {
    const timer = setTimeout(() => setTraag(waarde), ms);
    return () => clearTimeout(timer);
  }, [waarde, ms]);
  return traag;
}

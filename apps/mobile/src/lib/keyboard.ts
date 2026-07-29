import { useEffect, useState } from 'react';
import { Keyboard, Platform } from 'react-native';

/**
 * Toetsenbordstatus: open + hoogte. Invoerbalken hangen normaal boven de
 * zwevende tabbalk (extra onderruimte); zodra het toetsenbord opent, valt die
 * ruimte weg zodat de balk strak op het toetsenbord aansluit. Overlays op de
 * kaart gebruiken de hoogte om boven het toetsenbord uit te komen.
 */
export function useKeyboard(): { open: boolean; height: number } {
  const [state, setState] = useState({ open: false, height: 0 });

  useEffect(() => {
    const showEvent = Platform.OS === 'ios' ? 'keyboardWillShow' : 'keyboardDidShow';
    const hideEvent = Platform.OS === 'ios' ? 'keyboardWillHide' : 'keyboardDidHide';
    const show = Keyboard.addListener(showEvent, (event) =>
      setState({ open: true, height: event.endCoordinates?.height ?? 0 }),
    );
    const hide = Keyboard.addListener(hideEvent, () => setState({ open: false, height: 0 }));
    return () => {
      show.remove();
      hide.remove();
    };
  }, []);

  return state;
}

export function useKeyboardOpen(): boolean {
  return useKeyboard().open;
}

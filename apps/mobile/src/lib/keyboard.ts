import { useEffect, useState } from 'react';
import { Keyboard, Platform } from 'react-native';

/**
 * Is het toetsenbord open? Invoerbalken hangen normaal boven de zwevende
 * tabbalk (extra onderruimte); zodra het toetsenbord opent, valt die ruimte
 * weg zodat de balk strak op het toetsenbord aansluit.
 */
export function useKeyboardOpen(): boolean {
  const [open, setOpen] = useState(false);

  useEffect(() => {
    const showEvent = Platform.OS === 'ios' ? 'keyboardWillShow' : 'keyboardDidShow';
    const hideEvent = Platform.OS === 'ios' ? 'keyboardWillHide' : 'keyboardDidHide';
    const show = Keyboard.addListener(showEvent, () => setOpen(true));
    const hide = Keyboard.addListener(hideEvent, () => setOpen(false));
    return () => {
      show.remove();
      hide.remove();
    };
  }, []);

  return open;
}

import { useFocusEffect } from 'expo-router';
import { setStatusBarStyle } from 'expo-status-bar';
import { useCallback } from 'react';

/**
 * De klok, wifi en batterij bovenin het toestel tekent iOS zelf; wij bepalen
 * alleen of dat in wit of in donker gebeurt. Eén vaste keuze voor de hele app
 * werkt niet: op de blauwe koppen moet het wit, op de lichte schermen donker,
 * anders valt het weg in de achtergrond.
 *
 * Daarom zet elk scherm het bij binnenkomst zelf. `GradientHeader` doet dat
 * automatisch voor alle schermen met een blauwe kop, dus in de praktijk hoef
 * je deze hook alleen aan te roepen op schermen zonder zo'n kop.
 *
 * Het gebeurt op focus (niet bij het mounten), zodat het ook klopt als je
 * terugkeert naar een scherm dat al in de stapel stond.
 */
export function useStatusBalk(stijl: 'licht' | 'donker') {
  useFocusEffect(
    useCallback(() => {
      setStatusBarStyle(stijl === 'licht' ? 'light' : 'dark');
    }, [stijl]),
  );
}

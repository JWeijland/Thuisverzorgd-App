import Svg, { Circle, Path } from 'react-native-svg';

import { colors } from '@/theme';

/**
 * Eigen icoonset voor de Wegwijzer, getekend volgens het brandbook (5.3
 * Iconografie): lijndikte 2,2 op een 24-raster, ronde uiteinden en hoeken,
 * navy als basis, en de handtekening van het merk: elk icoon heeft precies
 * één ronde vorm die Hulpgroen vult. Nooit twee groene stippen in één icoon.
 *
 * Ze staan op de themategels in een squircle met de themakleur eronder, zoals
 * het brandbook voorschrijft ("rustend op surfaceMuted").
 */

type Tekening = {
  /** De lijnen van het icoon, in volgorde van tekenen. */
  lijnen: string[];
  /** De ene groene stip: [cx, cy, r]. */
  stip: [number, number, number];
};

const TEKENINGEN: Record<string, Tekening> = {
  // Hoe zit het zorgstelsel in elkaar: een wegwijzerbord met twee borden die
  // elk een andere kant op wijzen. De knop bovenop is de groene stip.
  basis: {
    lijnen: [
      'M12 6.4V21',
      'M8.4 21h7.2',
      'M12 8.2h6.2l2.3 2.2-2.3 2.2H12',
      'M12 14.2H6.2L4 16.4l2.2 2.2H12',
    ],
    stip: [12, 4.3, 1.9],
  },

  // Geld en regelingen: een beurs met een klikslot. Het slot is de stip.
  financien: {
    lijnen: [
      'M4.6 10.6c0-1.5 1-2.3 2.5-2.3h9.8c1.5 0 2.5.8 2.5 2.3v7c0 1.5-1 2.3-2.5 2.3H7.1c-1.5 0-2.5-.8-2.5-2.3z',
      'M7 8.3c.5-2.7 2.6-4.1 5-4.1s4.5 1.4 5 4.1',
    ],
    stip: [16.4, 14.1, 2],
  },

  // Wonen en verbouwen: het hoofdhuis met de mantelzorgwoning ernaast. Het
  // verlichte raampje van dat kleine huis is de stip.
  wonen: {
    lijnen: [
      'M2.8 11.4 8.6 6.2l5.8 5.2',
      'M4.3 10.2v9.4h8.6v-9.4',
      'M15.2 14.6 18.2 12l3 2.6',
      'M16.2 13.8v5.8h4v-5.8',
      'M2.2 19.6h19.6',
    ],
    stip: [18.2, 16.7, 1.5],
  },

  // Werk en verlof: een koffer met een band en een klikslot als stip.
  werk: {
    lijnen: [
      'M3.6 8.9h16.8v9.3c0 1-.7 1.6-1.7 1.6H5.3c-1 0-1.7-.6-1.7-1.6z',
      'M9 8.9V6.9c0-1 .7-1.6 1.7-1.6h2.6c1 0 1.7.6 1.7 1.6v2',
      'M3.6 13.1h16.8',
    ],
    stip: [12, 13.1, 1.9],
  },

  // Dementie: een hoofd met een losse draad erin. De draad loopt niet dood,
  // hij eindigt in de groene stip: er is altijd iemand die hem oppakt.
  dementie: {
    lijnen: [
      'M12 3.6c-3.4 0-6.1 2.7-6.1 6s2.7 6 6.1 6 6.1-2.7 6.1-6-2.7-6-6.1-6z',
      'M10 11.1c-.2-1.6.9-2.7 2-2.5 1.2.2 1.6 1.6.9 2.4-.6.7-1.7.6-1.9 1.5',
      'M5.2 21c.9-2.1 3.6-3.5 6.8-3.5s5.9 1.4 6.8 3.5',
    ],
    stip: [11.9, 13.5, 1.4],
  },

  // Beslissen voor een ander: een papier met een omgevouwen hoek, een
  // handtekeningkrul en een groen zegel.
  regelen: {
    lijnen: [
      'M6.2 3.4h8L18.6 7.8v11.2c0 .9-.7 1.6-1.6 1.6H6.2c-.9 0-1.6-.7-1.6-1.6V5c0-.9.7-1.6 1.6-1.6z',
      'M13.9 3.6v4.3h4.5',
      'M7.4 15.4c1.5-1.7 2.6 1.2 4.1-.3',
    ],
    stip: [14.8, 17.4, 1.8],
  },

  // Zorg thuis regelen: een hart dat gedragen wordt door twee handen. De
  // groene stip in het midden is degene om wie het draait.
  'zorg-thuis': {
    lijnen: [
      'M12 8.4c0-1.5-1.1-2.5-2.3-2.5-1.3 0-2.3 1-2.3 2.3 0 2.3 2.6 3.9 4.6 5.3 2-1.4 4.6-3 4.6-5.3 0-1.3-1-2.3-2.3-2.3-1.2 0-2.3 1-2.3 2.5z',
      'M4.6 15.6c0 3.4 3.2 5.2 7.4 5.2s7.4-1.8 7.4-5.2',
    ],
    stip: [12, 17.6, 1.8],
  },

  // Zorgen voor jezelf: een kop thee die staat te dampen. Het belletje in de
  // damp is de stip: even helemaal niets.
  jezelf: {
    lijnen: [
      'M4.8 10.4h11.4v6.2c0 2.2-1.8 4-4 4H8.8c-2.2 0-4-1.8-4-4z',
      'M16.2 11.9h1.9c1.4 0 2.4 1 2.4 2.4s-1 2.4-2.4 2.4h-1.9',
      'M8.9 7.6c0-1.2 1.2-1.4 1.2-2.6',
      'M13.1 7.6c0-1.2 1.2-1.4 1.2-2.6',
    ],
    stip: [11.9, 3.6, 1.6],
  },
};

/** Terugval als er ooit een thema bijkomt zonder eigen tekening. */
const STANDAARD: Tekening = TEKENINGEN.basis!;

export function ThemaIcoon({
  thema,
  size = 22,
  kleur = colors.primary,
}: {
  /** De slug van het thema, bijv. "wonen". */
  thema: string;
  size?: number;
  kleur?: string;
}) {
  const tekening = TEKENINGEN[thema] ?? STANDAARD;
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      {tekening.lijnen.map((d) => (
        <Path
          key={d}
          d={d}
          stroke={kleur}
          strokeWidth={2.2}
          strokeLinecap="round"
          strokeLinejoin="round"
          fill="none"
        />
      ))}
      <Circle
        cx={tekening.stip[0]}
        cy={tekening.stip[1]}
        r={tekening.stip[2]}
        fill={colors.accent}
      />
    </Svg>
  );
}

/** Voor tests en de dev-galerij: welke thema's hebben een eigen tekening. */
export const THEMA_TEKENINGEN = Object.keys(TEKENINGEN);

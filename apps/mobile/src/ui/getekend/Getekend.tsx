import type { StyleProp, ViewStyle } from 'react-native';
import Svg, { Path } from 'react-native-svg';

import { colors } from '@/theme';
import * as vormen from '@/ui/getekend/paden';
import type { GetekendVorm } from '@/ui/getekend/paden';

/**
 * De getekende laag (huisstijl v4, hoofdstuk "Getekend"): één handgetekende
 * lijn per vlak, in Thuisrood op licht of wit op donker.
 *
 * Regels: één gebaar per scherm, altijd horizontaal, nooit over tekst of
 * knoppen heen, nooit tikbaar, breedte 40–80% van de kop. Op Hulpgroen komt
 * geen kringel (te weinig contrast).
 */

type VormProps = {
  /** Breedte in punten; de hoogte volgt de verhouding van de tekening. */
  width?: number;
  /** Kleur van de streek: Thuisrood op licht (standaard), wit op donker. */
  kleur?: string;
  /** Dekking van het hele gebaar, bijv. 0.5 voor de kringel in de paginabalk. */
  dekking?: number;
  style?: StyleProp<ViewStyle>;
};

function Streek({
  vorm,
  width = 120,
  kleur = colors.primary,
  dekking = 1,
  style,
}: VormProps & { vorm: GetekendVorm }) {
  const [vbBreedte, vbHoogte] = vorm.vb;
  const height = (width / vbBreedte) * vbHoogte;
  return (
    <Svg
      width={width}
      height={height}
      viewBox={`0 0 ${vbBreedte} ${vbHoogte}`}
      fill="none"
      opacity={dekking}
      pointerEvents="none"
      style={style}
    >
      {vorm.paden.map((pad, i) => (
        <Path
          key={i}
          d={pad.d}
          stroke={kleur}
          strokeWidth={pad.dikte}
          strokeLinecap="round"
          strokeLinejoin="round"
          opacity={pad.dekking ?? 1}
          fill="none"
        />
      ))}
    </Svg>
  );
}

export type KringelVariant = 'streep' | 'kort' | 'lang' | 'onder';

const kringels: Record<KringelVariant, GetekendVorm> = {
  streep: vormen.streep,
  kort: vormen.kort,
  lang: vormen.lang,
  onder: vormen.onder,
};

/**
 * De kringelstreep, het hoofdgebaar: onder koppen, op covers, in de
 * paginabalk. `kort` is één lus (onder een enkel woord), `lang` vijf lussen
 * (cover en scheiding), `onder` het platte profiel als onderstreping.
 */
export function Kringel({ variant = 'streep', ...rest }: VormProps & { variant?: KringelVariant }) {
  return <Streek vorm={kringels[variant]} {...rest} />;
}

/** Twee snelle halen onder een cijfer of naam (de trotse cijfers). */
export function Onderstreping(props: VormProps) {
  return <Streek vorm={vormen.onderstreping} {...props} />;
}

/** Omcirkelt een datum, woord of gezicht. */
export function Handcirkel(props: VormProps) {
  return <Streek vorm={vormen.handcirkel} {...props} />;
}

/** Wijst naar de volgende stap; alleen in uitleg en onboarding. */
export function Handpijl(props: VormProps) {
  return <Streek vorm={vormen.handpijl} {...props} />;
}

/** Klein feestje: voltooide taak, nieuw level, bedankje. */
export function Vonkje({ width = 28, ...rest }: VormProps) {
  return <Streek vorm={vormen.vonkje} width={width} {...rest} />;
}

/**
 * De golfrand: de onderrand van de paginabalk, en alleen daar. Gevuld vlak
 * in de kleur van de onderkant van het verloop; rekt mee met de breedte.
 */
export function Golfrand({
  width,
  height,
  kleur,
  style,
}: {
  width: number;
  height: number;
  kleur: string;
  style?: StyleProp<ViewStyle>;
}) {
  const [vbBreedte, vbHoogte] = vormen.golfrand.vb;
  return (
    <Svg
      width={width}
      height={height}
      viewBox={`0 0 ${vbBreedte} ${vbHoogte}`}
      preserveAspectRatio="none"
      pointerEvents="none"
      style={style}
    >
      {vormen.golfrand.paden.map((pad, i) => (
        <Path key={i} d={pad.d} fill={kleur} />
      ))}
    </Svg>
  );
}

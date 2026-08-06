import type { StyleProp, ViewStyle } from 'react-native';
import Svg, {
  Circle,
  Defs,
  Ellipse,
  LinearGradient,
  Path,
  RadialGradient,
  Rect,
  Stop,
} from 'react-native-svg';

/**
 * Mascotte Bo (handoff-voorzieningen): vriendelijk rond wezentje met crème
 * buik, blosjes en een blaadje-spruitje. Bo gebruikt bewust een warmer palet
 * dan de UI-tokens; deze kleuren komen uit de aangeleverde SVG's en horen
 * nergens anders in de app voor te komen.
 *
 * Ontwerp 4.0: Bo kleurt per rol mee met het logo-verhaal (blauw vraagt,
 * groen geeft, navy draagt): buddy = groen (origineel), beheerder = navy,
 * hulpvrager = licht kringblauw. Het spruitje blijft bij alle drie groen,
 * zodat de drie Bo's zichtbaar familie zijn.
 *
 * Regels uit de handoff: max één Bo per scherm, nooit uitrekken en nooit op
 * betaal- of juridische schermen.
 */

export type BoRol = 'beheerder' | 'vrijwilliger' | 'hulpvrager';

type BoProps = {
  /** Breedte in punten; de hoogte volgt de vaste verhouding van de tekening. */
  width?: number;
  /** Rolkleur van het lijfje; zonder rol is Bo groen (de buddy-Bo). */
  rol?: BoRol;
  style?: StyleProp<ViewStyle>;
};

type BoPalet = {
  /** lijf-gradient: glans, midden, schaduwrand */
  body: [string, string, string];
  /** arm-gradient */
  arm: [string, string];
  hand: string;
  feet: string;
};

const PALET: Record<BoRol, BoPalet> = {
  vrijwilliger: {
    body: ['#C8EC90', '#8CC64B', '#619A2E'],
    arm: ['#8FC750', '#6CA636'],
    hand: '#9ACD5E',
    feet: '#578C2C',
  },
  beheerder: {
    body: ['#A9C7E3', '#4179B3', '#173D63'],
    arm: ['#5D8DBE', '#2E5F96'],
    hand: '#6E9CC9',
    feet: '#24507C',
  },
  hulpvrager: {
    body: ['#D2E7F8', '#7FB2DE', '#3D77B5'],
    arm: ['#92BEE6', '#5D93C4'],
    hand: '#A5CBEC',
    feet: '#4A7FB0',
  },
};

/** Het spruitje is bij elke rol hetzelfde groen: zorg die groeit. */
const SPRUIT = { steel: '#4E8E2F', blad1: '#7CC252', blad2: '#5FA53A' } as const;

/** Bo helemaal, zwaaiend (welkom, rolkeuze, bevestiging, lege staten). */
export function Bo({ width = 120, rol = 'vrijwilliger', style }: BoProps) {
  const height = (width / 220) * 244;
  const palet = PALET[rol];
  const bodyId = `boBody-${rol}`;
  const bellyId = `boBelly-${rol}`;
  const armId = `boArm-${rol}`;
  return (
    <Svg width={width} height={height} viewBox="0 0 220 244" fill="none" style={style}>
      <Defs>
        <RadialGradient id={bodyId} cx="36%" cy="28%" r="105%">
          <Stop offset="0" stopColor={palet.body[0]} />
          <Stop offset="0.45" stopColor={palet.body[1]} />
          <Stop offset="1" stopColor={palet.body[2]} />
        </RadialGradient>
        <RadialGradient id={bellyId} cx="42%" cy="32%" r="100%">
          <Stop offset="0" stopColor="#FFF9EC" />
          <Stop offset="1" stopColor="#F1DDBD" />
        </RadialGradient>
        <LinearGradient id={armId} x1="0" y1="0" x2="1" y2="1">
          <Stop offset="0" stopColor={palet.arm[0]} />
          <Stop offset="1" stopColor={palet.arm[1]} />
        </LinearGradient>
      </Defs>
      <Ellipse cx={110} cy={226} rx={60} ry={10} fill="#112F50" opacity={0.1} />
      <Rect
        x={146}
        y={66}
        width={58}
        height={26}
        rx={13}
        fill={`url(#${armId})`}
        rotation={-38}
        origin="175, 79"
      />
      <Circle cx={196} cy={58} r={14} fill={palet.hand} />
      <Rect
        x={18}
        y={126}
        width={52}
        height={25}
        rx={12.5}
        fill={`url(#${armId})`}
        rotation={26}
        origin="44, 138"
      />
      <Ellipse cx={85} cy={220} rx={21} ry={12} fill={palet.feet} />
      <Ellipse cx={136} cy={220} rx={21} ry={12} fill={palet.feet} />
      <Ellipse cx={110} cy={132} rx={78} ry={92} fill={`url(#${bodyId})`} />
      <Ellipse cx={110} cy={162} rx={48} ry={55} fill={`url(#${bellyId})`} />
      <Ellipse
        cx={76}
        cy={70}
        rx={30}
        ry={17}
        fill="#FFFFFF"
        opacity={0.35}
        rotation={-24}
        origin="76, 70"
      />
      <Path d="M112 42 q1 -13 11 -19" stroke={SPRUIT.steel} strokeWidth={5} strokeLinecap="round" />
      <Ellipse cx={131} cy={17} rx={13} ry={7} fill={SPRUIT.blad1} rotation={-18} origin="131, 17" />
      <Ellipse cx={113} cy={12} rx={11} ry={6} fill={SPRUIT.blad2} rotation={22} origin="113, 12" />
      <Ellipse cx={88} cy={112} rx={9} ry={12.5} fill="#223349" />
      <Ellipse cx={132} cy={112} rx={9} ry={12.5} fill="#223349" />
      <Circle cx={85} cy={107} r={3.2} fill="#FFFFFF" />
      <Circle cx={129} cy={107} r={3.2} fill="#FFFFFF" />
      <Ellipse cx={70} cy={134} rx={11} ry={7} fill="#F5A78F" opacity={0.85} />
      <Ellipse cx={150} cy={134} rx={11} ry={7} fill="#F5A78F" opacity={0.85} />
      <Path
        d="M92 140 Q110 156 128 140"
        stroke="#223349"
        strokeWidth={5}
        strokeLinecap="round"
        fill="none"
      />
    </Svg>
  );
}

/** Alleen kop en handjes: Bo piept over een rand (headers van hubs). */
export function BoPeek({ width = 88, rol = 'vrijwilliger', style }: BoProps) {
  const height = (width / 220) * 122;
  const palet = PALET[rol];
  const bodyId = `boPeekBody-${rol}`;
  return (
    <Svg width={width} height={height} viewBox="0 0 220 122" fill="none" style={style}>
      <Defs>
        <RadialGradient id={bodyId} cx="36%" cy="22%" r="105%">
          <Stop offset="0" stopColor={palet.body[0]} />
          <Stop offset="0.45" stopColor={palet.body[1]} />
          <Stop offset="1" stopColor={palet.body[2]} />
        </RadialGradient>
      </Defs>
      <Ellipse cx={110} cy={126} rx={78} ry={88} fill={`url(#${bodyId})`} />
      <Ellipse
        cx={76}
        cy={66}
        rx={28}
        ry={15}
        fill="#FFFFFF"
        opacity={0.35}
        rotation={-24}
        origin="76, 66"
      />
      <Path d="M112 40 q1 -12 10 -18" stroke={SPRUIT.steel} strokeWidth={5} strokeLinecap="round" />
      <Ellipse cx={130} cy={16} rx={12} ry={6.5} fill={SPRUIT.blad1} rotation={-18} origin="130, 16" />
      <Ellipse cx={113} cy={11} rx={10} ry={5.5} fill={SPRUIT.blad2} rotation={22} origin="113, 11" />
      <Ellipse cx={88} cy={86} rx={8.5} ry={12} fill="#223349" />
      <Ellipse cx={132} cy={86} rx={8.5} ry={12} fill="#223349" />
      <Circle cx={85} cy={81} r={3} fill="#FFFFFF" />
      <Circle cx={129} cy={81} r={3} fill="#FFFFFF" />
      <Ellipse cx={70} cy={104} rx={10} ry={6.5} fill="#F5A78F" opacity={0.85} />
      <Ellipse cx={150} cy={104} rx={10} ry={6.5} fill="#F5A78F" opacity={0.85} />
      <Path
        d="M94 106 Q110 119 126 106"
        stroke="#223349"
        strokeWidth={5}
        strokeLinecap="round"
        fill="none"
      />
      <Ellipse cx={44} cy={114} rx={15} ry={9} fill={palet.hand} />
      <Ellipse cx={176} cy={114} rx={15} ry={9} fill={palet.hand} />
    </Svg>
  );
}

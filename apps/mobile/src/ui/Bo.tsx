import type { StyleProp, ViewStyle } from 'react-native';
import Svg, {
  Circle,
  Defs,
  Ellipse,
  G,
  LinearGradient,
  Mask,
  Path,
  RadialGradient,
  Rect,
  Stop,
} from 'react-native-svg';

/**
 * Mascotte Bo (huisstijl v4, hoofdstuk "Bo"): vriendelijk rond wezentje met
 * crème buik, blosjes en een blaadje-spruitje. Bo is en blijft groen, want
 * groen is de kleur van bevestiging: zij verandert nooit van kleur, krijgt
 * nooit een uniform en beslist niet. Haar palet komt uit de aangeleverde
 * SVG's en hoort nergens anders in de app voor te komen.
 *
 * Regels: max één Bo per scherm, nooit uitrekken en nooit op betaal- of
 * juridische schermen. Als watermerk (BoMono) 12% wit op rood, 8% op
 * Nachtbruin, rechts geplaatst en onder en rechts uitgesneden.
 */

type BoProps = {
  /** Breedte in punten; de hoogte volgt de vaste verhouding van de tekening. */
  width?: number;
  style?: StyleProp<ViewStyle>;
};

const PALET = {
  body: ['#C8EC90', '#8CC64B', '#619A2E'],
  arm: ['#8FC750', '#6CA636'],
  hand: '#9ACD5E',
  feet: '#578C2C',
} as const;

/** Het spruitje: zorg die groeit. */
const SPRUIT = { steel: '#4E8E2F', blad1: '#7CC252', blad2: '#5FA53A' } as const;

/** Ogen en mond; de grondschaduw is Nachtbruin, zoals elke schaduw in v4. */
const GEZICHT = '#223349';
const SCHADUW = '#3A1D16';

/** Bo helemaal, zwaaiend (welkom, rolkeuze, bevestiging, lege staten). */
export function Bo({ width = 120, style }: BoProps) {
  const height = (width / 220) * 244;
  return (
    <Svg width={width} height={height} viewBox="0 0 220 244" fill="none" style={style}>
      <Defs>
        <RadialGradient id="boBody" cx="36%" cy="28%" r="105%">
          <Stop offset="0" stopColor={PALET.body[0]} />
          <Stop offset="0.45" stopColor={PALET.body[1]} />
          <Stop offset="1" stopColor={PALET.body[2]} />
        </RadialGradient>
        <RadialGradient id="boBelly" cx="42%" cy="32%" r="100%">
          <Stop offset="0" stopColor="#FFF9EC" />
          <Stop offset="1" stopColor="#F1DDBD" />
        </RadialGradient>
        <LinearGradient id="boArm" x1="0" y1="0" x2="1" y2="1">
          <Stop offset="0" stopColor={PALET.arm[0]} />
          <Stop offset="1" stopColor={PALET.arm[1]} />
        </LinearGradient>
      </Defs>
      <Ellipse cx={110} cy={226} rx={60} ry={10} fill={SCHADUW} opacity={0.1} />
      <Rect
        x={146}
        y={66}
        width={58}
        height={26}
        rx={13}
        fill="url(#boArm)"
        rotation={-38}
        origin="175, 79"
      />
      <Circle cx={196} cy={58} r={14} fill={PALET.hand} />
      <Rect
        x={18}
        y={126}
        width={52}
        height={25}
        rx={12.5}
        fill="url(#boArm)"
        rotation={26}
        origin="44, 138"
      />
      <Ellipse cx={85} cy={220} rx={21} ry={12} fill={PALET.feet} />
      <Ellipse cx={136} cy={220} rx={21} ry={12} fill={PALET.feet} />
      <Ellipse cx={110} cy={132} rx={78} ry={92} fill="url(#boBody)" />
      <Ellipse cx={110} cy={162} rx={48} ry={55} fill="url(#boBelly)" />
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
      <Ellipse cx={88} cy={112} rx={9} ry={12.5} fill={GEZICHT} />
      <Ellipse cx={132} cy={112} rx={9} ry={12.5} fill={GEZICHT} />
      <Circle cx={85} cy={107} r={3.2} fill="#FFFFFF" />
      <Circle cx={129} cy={107} r={3.2} fill="#FFFFFF" />
      <Ellipse cx={70} cy={134} rx={11} ry={7} fill="#F5A78F" opacity={0.85} />
      <Ellipse cx={150} cy={134} rx={11} ry={7} fill="#F5A78F" opacity={0.85} />
      <Path
        d="M92 140 Q110 156 128 140"
        stroke={GEZICHT}
        strokeWidth={5}
        strokeLinecap="round"
        fill="none"
      />
    </Svg>
  );
}

/** Alleen kop en handjes: Bo piept over een rand (tips, toasts, headers). */
export function BoPeek({ width = 88, style }: BoProps) {
  const height = (width / 220) * 122;
  return (
    <Svg width={width} height={height} viewBox="0 0 220 122" fill="none" style={style}>
      <Defs>
        <RadialGradient id="boPeekBody" cx="36%" cy="22%" r="105%">
          <Stop offset="0" stopColor={PALET.body[0]} />
          <Stop offset="0.45" stopColor={PALET.body[1]} />
          <Stop offset="1" stopColor={PALET.body[2]} />
        </RadialGradient>
      </Defs>
      <Ellipse cx={110} cy={126} rx={78} ry={88} fill="url(#boPeekBody)" />
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
      <Ellipse cx={88} cy={86} rx={8.5} ry={12} fill={GEZICHT} />
      <Ellipse cx={132} cy={86} rx={8.5} ry={12} fill={GEZICHT} />
      <Circle cx={85} cy={81} r={3} fill="#FFFFFF" />
      <Circle cx={129} cy={81} r={3} fill="#FFFFFF" />
      <Ellipse cx={70} cy={104} rx={10} ry={6.5} fill="#F5A78F" opacity={0.85} />
      <Ellipse cx={150} cy={104} rx={10} ry={6.5} fill="#F5A78F" opacity={0.85} />
      <Path
        d="M94 106 Q110 119 126 106"
        stroke={GEZICHT}
        strokeWidth={5}
        strokeLinecap="round"
        fill="none"
      />
      <Ellipse cx={44} cy={114} rx={15} ry={9} fill={PALET.hand} />
      <Ellipse cx={176} cy={114} rx={15} ry={9} fill={PALET.hand} />
    </Svg>
  );
}

/**
 * Bo als silhouet in één kleur (bo-mono): het watermerk in de paginabalk en
 * op donkere vlakken (wit), of de stempel op licht (rood). Ogen en mond zijn
 * uitgespaard. De dekking regelt de drager: 12% wit op rood, 8% op Nachtbruin.
 */
export function BoMono({ width = 120, kleur = '#FFFFFF', style }: BoProps & { kleur?: string }) {
  const height = (width / 220) * 244;
  return (
    <Svg width={width} height={height} viewBox="0 0 220 244" fill="none" style={style}>
      <Mask id="boMonoGezicht" maskUnits="userSpaceOnUse" x="0" y="0" width="220" height="244">
        <Rect x="0" y="0" width="220" height="244" fill="white" />
        <Ellipse cx={88} cy={112} rx={9} ry={12.5} fill="black" />
        <Ellipse cx={132} cy={112} rx={9} ry={12.5} fill="black" />
        <Path
          d="M92 140 Q110 156 128 140"
          stroke="black"
          strokeWidth={7}
          strokeLinecap="round"
          fill="none"
        />
      </Mask>
      <G mask="url(#boMonoGezicht)">
        <G fill={kleur}>
          <Rect x={146} y={66} width={58} height={26} rx={13} rotation={-38} origin="175, 79" />
          <Circle cx={196} cy={58} r={14} />
          <Rect x={18} y={126} width={52} height={25} rx={12.5} rotation={26} origin="44, 138" />
          <Ellipse cx={85} cy={220} rx={21} ry={12} />
          <Ellipse cx={136} cy={220} rx={21} ry={12} />
          <Ellipse cx={110} cy={132} rx={78} ry={92} />
          <Ellipse cx={131} cy={17} rx={13} ry={7} rotation={-18} origin="131, 17" />
          <Ellipse cx={113} cy={12} rx={11} ry={6} rotation={22} origin="113, 12" />
        </G>
        <Path d="M112 42 q1 -13 11 -19" stroke={kleur} strokeWidth={5} strokeLinecap="round" />
      </G>
    </Svg>
  );
}

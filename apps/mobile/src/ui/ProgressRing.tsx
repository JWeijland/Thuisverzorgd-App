import { StyleSheet, Text, View } from 'react-native';
import Svg, { Circle } from 'react-native-svg';

import { colors, scaleText, useTextScale } from '@/theme';
import { fonts } from '@/theme/typography';

type Props = {
  /** Aandeel gevuld, 0–1. */
  value: number;
  /** Tekst in het midden (bijv. het aantal). */
  label?: string;
  size?: number;
  thickness?: number;
  /** Op donkere achtergrond: lichte baan, groene voortgang. */
  onDark?: boolean;
};

/** Ronde voortgangsmeter (ontwerp 1a-teller): dunne baan met groene boog. */
export function ProgressRing({ value, label, size = 54, thickness = 7, onDark = false }: Props) {
  const { factor } = useTextScale();
  const radius = (size - thickness) / 2;
  const circumference = 2 * Math.PI * radius;
  const filled = Math.max(0, Math.min(1, value));

  return (
    <View style={{ width: size, height: size }}>
      <Svg width={size} height={size}>
        <Circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          stroke={onDark ? 'rgba(255,255,255,0.22)' : colors.surfaceAlt}
          strokeWidth={thickness}
          fill="none"
        />
        {filled > 0 ? (
          <Circle
            cx={size / 2}
            cy={size / 2}
            r={radius}
            stroke={colors.accent}
            strokeWidth={thickness}
            strokeLinecap="round"
            strokeDasharray={`${circumference * filled} ${circumference}`}
            // Beginnen bovenaan in plaats van rechts.
            transform={`rotate(-90 ${size / 2} ${size / 2})`}
            fill="none"
          />
        ) : null}
      </Svg>
      {label ? (
        <View style={styles.midden} pointerEvents="none">
          <Text
            style={[
              scaleText({ fontFamily: fonts.headingBold, fontSize: size * 0.32 }, factor),
              { color: onDark ? colors.white : colors.ink },
            ]}
          >
            {label}
          </Text>
        </View>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  midden: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    alignItems: 'center',
    justifyContent: 'center',
  },
});

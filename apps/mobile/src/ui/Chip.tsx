import { Pressable, StyleSheet, Text } from 'react-native';

import { haptics } from '@/lib/haptics';
import { colors, hitTarget, radius, scaleText, useTextScale } from '@/theme';
import { fonts } from '@/theme/typography';

type Props = {
  label: string;
  selected?: boolean;
  onPress?: () => void;
};

/** Selecteerbare filter-/keuzechip: gekozen wordt Gloedrood, de rest blijft licht. */
export function Chip({ label, selected = false, onPress }: Props) {
  const { factor } = useTextScale();
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityState={{ selected }}
      onPress={() => {
        void haptics.selectie();
        onPress?.();
      }}
      hitSlop={6}
      style={[styles.chip, selected ? styles.selected : styles.unselected]}
    >
      <Text
        style={[
          scaleText({ fontFamily: fonts.heading, fontSize: 13.5 }, factor),
          { color: selected ? colors.white : colors.ink },
        ]}
      >
        {label}
      </Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  chip: {
    minHeight: Math.max(34, hitTarget.min - 10),
    borderRadius: radius.pill,
    paddingHorizontal: 14,
    paddingVertical: 7,
    alignItems: 'center',
    justifyContent: 'center',
  },
  selected: {
    backgroundColor: colors.primaryMid,
  },
  unselected: {
    backgroundColor: colors.white,
    borderWidth: 1.5,
    borderColor: colors.line,
  },
});

import { StyleSheet, View, type StyleProp, type ViewStyle } from 'react-native';

import { colors, radius, scaleText, useTextScale } from '@/theme';
import { fonts } from '@/theme/typography';
import { Text } from 'react-native';

type Props = {
  label: string;
  color?: string;
  backgroundColor?: string;
  style?: StyleProp<ViewStyle>;
};

/** Kleine informatieve pill (badge), bijv. rolpill of "± 1 uur". */
export function Pill({
  label,
  color = colors.primaryDark,
  backgroundColor = colors.primaryTint,
  style,
}: Props) {
  const { factor } = useTextScale();
  return (
    <View style={[styles.pill, { backgroundColor }, style]}>
      <Text style={[scaleText({ fontFamily: fonts.heading, fontSize: 12.5 }, factor), { color }]}>
        {label}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  pill: {
    alignSelf: 'flex-start',
    borderRadius: radius.pill,
    paddingHorizontal: 12,
    paddingVertical: 4,
  },
});

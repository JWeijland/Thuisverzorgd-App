import { Image } from 'expo-image';
import { StyleSheet, Text, View } from 'react-native';

import { colors, scaleText, useTextScale } from '@/theme';
import { fonts } from '@/theme/typography';

type Props = {
  name: string;
  /** Diameter in punten. */
  size?: number;
  /** Profielfoto-URL; zonder foto een gekleurde cirkel met initiaal. */
  uri?: string;
  backgroundColor?: string;
};

/** Avatar: profielfoto of gekleurde cirkel met initiaal (zoals in het prototype). */
export function Avatar({ name, size = 40, uri, backgroundColor = colors.primaryMid }: Props) {
  const { factor } = useTextScale();
  const initial = name.trim().charAt(0).toUpperCase() || '?';
  const round = { width: size, height: size, borderRadius: size / 2 };

  if (uri) {
    return <Image source={{ uri }} style={round} accessibilityLabel={name} />;
  }
  return (
    <View accessibilityLabel={name} style={[styles.circle, round, { backgroundColor }]}>
      <Text
        style={[
          scaleText({ fontFamily: fonts.headingBold, fontSize: size * 0.42 }, factor),
          styles.initial,
        ]}
      >
        {initial}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  circle: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  initial: {
    color: colors.white,
  },
});

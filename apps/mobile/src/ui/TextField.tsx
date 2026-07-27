import { StyleSheet, TextInput, View, type TextInputProps } from 'react-native';

import { colors, radius, scaleText, spacing, useTextScale } from '@/theme';
import { fonts } from '@/theme/typography';
import { TvzText } from '@/ui/TvzText';

type Props = TextInputProps & {
  label: string;
  error?: string;
};

/** Invoerveld: bijna-vierkant vlak (radius 8), label in Baloo 2. */
export function TextField({ label, error, style, ...rest }: Props) {
  const { factor } = useTextScale();
  return (
    <View style={styles.wrap}>
      <TvzText preset="meta" style={styles.label}>
        {label}
      </TvzText>
      <TextInput
        placeholderTextColor={colors.inkFaint}
        style={[
          styles.input,
          scaleText({ fontFamily: fonts.body, fontSize: 15.5 }, factor),
          error ? styles.inputError : null,
          style,
        ]}
        {...rest}
      />
      {error ? (
        <TvzText preset="secondary" style={styles.error}>
          {error}
        </TvzText>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    marginBottom: spacing.lg,
  },
  label: {
    color: colors.ink,
    marginBottom: 6,
  },
  input: {
    backgroundColor: colors.white,
    borderWidth: 1.5,
    borderColor: colors.line,
    borderRadius: radius.input,
    paddingHorizontal: 14,
    paddingVertical: 12,
    color: colors.ink,
    minHeight: 48,
  },
  inputError: {
    borderColor: colors.error,
  },
  error: {
    color: colors.error,
    marginTop: 4,
  },
});

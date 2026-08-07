import { Pressable, StyleSheet, Text, type StyleProp, type ViewStyle } from 'react-native';

import { haptics, type HapticSoort } from '@/lib/haptics';
import { colors, hitTarget, radius, scaleText, shadows, text, useTextScale } from '@/theme';

type Variant = 'primary' | 'cta' | 'outline' | 'outlineOnDark' | 'danger';

type Props = {
  label: string;
  onPress?: () => void;
  variant?: Variant;
  size?: 'md' | 'lg';
  disabled?: boolean;
  style?: StyleProp<ViewStyle>;
  /** Trilpatroon bij indrukken; standaard passend bij de variant. */
  haptic?: HapticSoort | 'geen';
};

/** Standaard voelt een groene CTA steviger dan een gewone knop. */
const hapticPerVariant: Record<Variant, HapticSoort> = {
  primary: 'tik',
  cta: 'stevig',
  outline: 'tik',
  outlineOnDark: 'tik',
  danger: 'waarschuwing',
};

/**
 * Alles wat een actie is, is een pill (radius 999).
 * `cta` (Hulpgroen) maximaal één per scherm; nooit witte tekst op groen.
 */
export function Button({
  label,
  onPress,
  variant = 'primary',
  size = 'md',
  disabled = false,
  style,
  haptic,
}: Props) {
  const { factor } = useTextScale();
  const v = variants[variant];
  const trilSoort = haptic ?? hapticPerVariant[variant];
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityState={{ disabled }}
      disabled={disabled}
      onPress={() => {
        if (trilSoort !== 'geen') void haptics[trilSoort]();
        onPress?.();
      }}
      style={({ pressed }) => [
        styles.base,
        size === 'lg' && styles.lg,
        v.container,
        variant === 'cta' && !disabled && shadows.cta,
        disabled && styles.disabled,
        pressed && !disabled && { opacity: 0.85 },
        style,
      ]}
    >
      <Text
        style={[
          scaleText({ ...text.button }, factor),
          { color: v.color },
          disabled && styles.disabledText,
        ]}
      >
        {label}
      </Text>
    </Pressable>
  );
}

const variants: Record<Variant, { container: ViewStyle; color: string }> = {
  primary: { container: { backgroundColor: colors.primary }, color: colors.white },
  cta: { container: { backgroundColor: colors.accent }, color: colors.primaryDark },
  outline: {
    container: { backgroundColor: colors.white, borderWidth: 1.5, borderColor: colors.line },
    color: colors.primary,
  },
  outlineOnDark: {
    container: {
      backgroundColor: 'transparent',
      borderWidth: 1.5,
      borderColor: 'rgba(255,255,255,0.65)',
    },
    color: colors.white,
  },
  danger: { container: { backgroundColor: colors.errorBg }, color: colors.error },
};

const styles = StyleSheet.create({
  base: {
    minHeight: hitTarget.min + 4,
    borderRadius: radius.pill,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 24,
    paddingVertical: 10,
  },
  lg: {
    minHeight: hitTarget.cta,
  },
  disabled: {
    backgroundColor: '#C7D2E2',
    borderWidth: 0,
  },
  disabledText: {
    color: colors.white,
  },
});

import { Text, type TextProps } from 'react-native';

import { scaleText, text as presets, useTextScale } from '@/theme';

type Preset = keyof typeof presets;

type Props = TextProps & {
  preset?: Preset;
};

/** Tekst met een typografie-preset uit de handoff; schaalt mee met de ouderen-modus. */
export function TvzText({ preset = 'body', style, ...rest }: Props) {
  const { factor } = useTextScale();
  return <Text {...rest} style={[scaleText({ ...presets[preset] }, factor), style]} />;
}

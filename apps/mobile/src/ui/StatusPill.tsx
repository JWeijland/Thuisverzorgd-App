import { Pill } from '@/ui/Pill';
import { colors } from '@/theme';

export type StatusKind = 'success' | 'warn' | 'error' | 'info';

type Props = {
  label: string;
  kind: StatusKind;
};

/**
 * Statuspil: geslaagd/actief (groen), nog open/uitgenodigd (amber),
 * afgewezen/fout (rood), neutraal-informatief (blauw).
 */
export function StatusPill({ label, kind }: Props) {
  const c = kinds[kind];
  return <Pill label={label} color={c.color} backgroundColor={c.bg} />;
}

const kinds: Record<StatusKind, { bg: string; color: string }> = {
  success: { bg: colors.successBg, color: colors.successText },
  warn: { bg: colors.warnBg, color: colors.warnText },
  error: { bg: colors.errorBg, color: colors.error },
  info: { bg: colors.tintBlue, color: colors.blue },
};

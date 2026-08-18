import { StyleSheet, View } from 'react-native';

import { t } from '@/i18n';
import { radius, rolTints, type RolTint } from '@/theme';
import { TvzText } from '@/ui/TvzText';

type Props = {
  rol: RolTint;
  /** Meervoud, bijv. "buddy's" bij een groepje avatars. */
  meervoud?: boolean;
};

/**
 * Rolchip: klein pilletje met stip en rolnaam in de vaste rolkleur
 * (logo-verhaal v4: rood draagt, groen geeft, blauw vraagt; makelaar paars).
 * Staat overal waar een persoon genoemd wordt, zodat rollen herkenbaar zijn.
 */
export function RolChip({ rol, meervoud = false }: Props) {
  const tint = rolTints[rol];
  const label = t(meervoud ? `rolchip.${rol}Meervoud` : `rolchip.${rol}`);
  return (
    <View style={[styles.chip, { backgroundColor: tint.vlak }]}>
      <View style={[styles.stip, { backgroundColor: tint.stip }]} />
      <TvzText preset="meta" style={[styles.label, { color: tint.tekst }]}>
        {label}
      </TvzText>
    </View>
  );
}

const styles = StyleSheet.create({
  chip: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    borderRadius: radius.pill,
    paddingHorizontal: 10,
    paddingVertical: 3,
    alignSelf: 'flex-start',
  },
  stip: {
    width: 7,
    height: 7,
    borderRadius: 4,
  },
  label: {
    fontSize: 12,
  },
});

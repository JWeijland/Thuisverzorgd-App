import { StyleSheet, View } from 'react-native';

import { OpleidingenLijst } from '@/features/learning/OpleidingenLijst';
import { t } from '@/i18n';
import { colors } from '@/theme';
import { PaginaKop } from '@/ui/PaginaKop';

/**
 * Leren: het derde schuifje van de buddy. Korte opleidingen die bezoeken
 * makkelijker maken. Geen wegwijzer en geen forum: die zijn er voor de
 * mensen die hulp regelen, niet voor de buddy zelf (feedback Jelle 11-08).
 */
export function LerenScherm() {
  return (
    <View style={styles.safe}>
      {/* De gekleurde kop is nu de PadHeader van het vrijwilligerspad; hier
          blijft alleen de lichte paginakop over. */}
      <PaginaKop titel={t('leren.titel')} sub={t('leren.uitleg')} />
      <OpleidingenLijst />
    </View>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: colors.bg,
  },
});

import { useEffect, useRef } from 'react';
import { ScrollView, StyleSheet, View } from 'react-native';

import { colors, radius } from '@/theme';
import { TvzText } from '@/ui/TvzText';

/** Hoogte van één regel in de rol; ook de stap waarop hij vastklikt. */
const REGEL = 44;
/** Aantal regels dat boven en onder de selectieband zichtbaar is. */
const RAND = 1;

const UREN = Array.from({ length: 24 }, (_, i) => String(i).padStart(2, '0'));
const MINUTEN = ['00', '15', '30', '45'];

type Props = {
  /** Tijd als "HH:MM". */
  waarde: string;
  onChange: (tijd: string) => void;
};

/**
 * Rollende tijdpicker (handoff, scherm 06): twee rollen met een selectieband
 * in het midden. Hij scrollt zelf naar de gekozen tijd, zodat de snelkeuzes
 * ("Ochtend 09:00") de rollen meenemen.
 */
export function TijdPicker({ waarde, onChange }: Props) {
  const [uur = '09', minuut = '00'] = waarde.split(':');
  const dichtstbijzijndeMinuut =
    MINUTEN.find((optie) => optie === minuut) ??
    MINUTEN.reduce((beste, optie) =>
      Math.abs(Number(optie) - Number(minuut)) < Math.abs(Number(beste) - Number(minuut))
        ? optie
        : beste,
    );

  return (
    <View style={styles.wrap}>
      <View pointerEvents="none" style={styles.band} />
      <Rol opties={UREN} gekozen={uur} onKies={(nieuw) => onChange(`${nieuw}:${minuut}`)} />
      <Rol
        opties={MINUTEN}
        gekozen={dichtstbijzijndeMinuut}
        onKies={(nieuw) => onChange(`${uur}:${nieuw}`)}
      />
    </View>
  );
}

function Rol({
  opties,
  gekozen,
  onKies,
}: {
  opties: string[];
  gekozen: string;
  onKies: (waarde: string) => void;
}) {
  const scrollRef = useRef<ScrollView>(null);
  const index = Math.max(opties.indexOf(gekozen), 0);

  // Volg de gekozen waarde, ook als die van buiten komt (snelkeuzes).
  useEffect(() => {
    scrollRef.current?.scrollTo({ y: index * REGEL, animated: true });
  }, [index]);

  return (
    <ScrollView
      ref={scrollRef}
      style={styles.rol}
      showsVerticalScrollIndicator={false}
      snapToInterval={REGEL}
      decelerationRate="fast"
      contentContainerStyle={styles.rolInhoud}
      onMomentumScrollEnd={(event) => {
        const nieuweIndex = Math.round(event.nativeEvent.contentOffset.y / REGEL);
        const waarde = opties[Math.min(Math.max(nieuweIndex, 0), opties.length - 1)];
        if (waarde && waarde !== gekozen) onKies(waarde);
      }}
    >
      {opties.map((optie) => (
        <View key={optie} style={styles.regel}>
          <TvzText preset="screenTitle" style={optie === gekozen ? styles.aan : styles.uit}>
            {optie}
          </TvzText>
        </View>
      ))}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  wrap: {
    flexDirection: 'row',
    height: REGEL * (RAND * 2 + 1),
    backgroundColor: colors.white,
    borderRadius: radius.card,
    borderWidth: 1,
    borderColor: colors.line,
    overflow: 'hidden',
  },
  band: {
    position: 'absolute',
    left: 0,
    right: 0,
    top: REGEL * RAND,
    height: REGEL,
    backgroundColor: colors.surfaceAlt,
  },
  rol: {
    flex: 1,
  },
  rolInhoud: {
    paddingVertical: REGEL * RAND,
  },
  regel: {
    height: REGEL,
    alignItems: 'center',
    justifyContent: 'center',
  },
  aan: {
    color: colors.ink,
  },
  uit: {
    color: colors.inkFaint,
    fontSize: 20,
  },
});

import { forwardRef, useState, type ReactNode } from 'react';
import { Image, StyleSheet, View } from 'react-native';
import MapView, { Marker, type Region } from 'react-native-maps';
import Svg, {
  Circle as SvgCircle,
  Defs,
  Ellipse,
  G,
  LinearGradient,
  Path,
  Rect,
  Stop,
  Text as SvgText,
} from 'react-native-svg';

import { colors } from '@/theme';
import { TvzText } from '@/ui';

/**
 * Enige plek die react-native-maps importeert (ADR-0004): een latere overstap
 * naar bijv. Mapbox raakt alleen dit bestand.
 */

type TvzMapProps = {
  initialRegion: Region;
  onRegionChangeComplete?: (region: Region) => void;
  children?: ReactNode;
};

export const TvzMap = forwardRef<MapView, TvzMapProps>(function TvzMap(
  { initialRegion, onRegionChangeComplete, children },
  ref,
) {
  return (
    <MapView
      ref={ref}
      style={StyleSheet.absoluteFill}
      initialRegion={initialRegion}
      onRegionChangeComplete={onRegionChangeComplete}
      showsUserLocation={false}
      showsPointsOfInterests={false}
      toolbarEnabled={false}
    >
      {children}
    </MapView>
  );
});

export type { Region };
export { Marker };

/**
 * Druppelmarkers naar het handoff-ontwerp (docs/design/markers/): viewBox 52x66,
 * punt van de druppel op y≈53. De blur-filters uit de SVG's rendert
 * react-native-svg niet; de grondschaduw is daarom een vlakke ellips.
 */
const PIN_PATH =
  'M26 2.75a20.75 20.75 0 0 1 14.67 35.42L26 52.84 11.33 38.17A20.75 20.75 0 0 1 26 2.75z';
const PIN_W = 44;
const PIN_H = 56;
// De punt van de druppel (y 52.84 van 66) hoort op de coördinaat te staan.
const PIN_ANCHOR_Y = 52.84 / 66;

/** Hulpkring: navy druppel met twee buurtgenoten, optioneel "+N plekken vrij". */
export function KringMarker({
  lat,
  lon,
  plekkenVrij = 0,
  onPress,
}: {
  lat: number;
  lon: number;
  plekkenVrij?: number;
  onPress?: () => void;
}) {
  return (
    <Marker
      coordinate={{ latitude: lat, longitude: lon }}
      onPress={onPress}
      tracksViewChanges={false}
      anchor={{ x: 0.5, y: PIN_ANCHOR_Y }}
      centerOffset={{ x: 0, y: (0.5 - PIN_ANCHOR_Y) * PIN_H }}
    >
      <Svg width={PIN_W} height={PIN_H} viewBox="0 0 52 66">
        <Defs>
          <LinearGradient id="kringPin" x1="0" y1="0" x2="1" y2="1">
            <Stop offset="0" stopColor="#2A6CB0" />
            <Stop offset="1" stopColor="#1A4878" />
          </LinearGradient>
        </Defs>
        <Ellipse cx={26} cy={61} rx={11} ry={3.5} fill="#112F50" opacity={0.15} />
        <Path d={PIN_PATH} fill="url(#kringPin)" stroke={colors.white} strokeWidth={2.5} />
        <SvgCircle cx={26} cy={24} r={13.5} fill={colors.white} />
        <G translate="14 12">
          <SvgCircle cx={8.2} cy={9} r={3.1} fill="#2A6CB0" />
          <SvgCircle cx={15.8} cy={9} r={3.1} fill="#8DC93F" />
          <Path d="M2.6 22c0-3.2 2.5-5.8 5.6-5.8s5.6 2.6 5.6 5.8" fill="#2A6CB0" />
          <Path d="M10.2 22c0-3.2 2.5-5.8 5.6-5.8s5.6 2.6 5.6 5.8" fill="#8DC93F" />
        </G>
        {plekkenVrij > 0 ? (
          <G translate="31 1">
            <Rect
              width={20}
              height={20}
              rx={10}
              fill="#8DC93F"
              stroke={colors.white}
              strokeWidth={2}
            />
            <SvgText
              x={10}
              y={14.2}
              fontSize={11}
              fontWeight="700"
              fill="#112F50"
              textAnchor="middle"
            >
              {`+${plekkenVrij}`}
            </SvgText>
          </G>
        ) : null}
      </Svg>
    </Marker>
  );
}

/** Buddy: cirkel met profielfoto (of initiaal zolang er geen foto is). */
export function BuddyMarker({
  lat,
  lon,
  voornaam,
  uri,
}: {
  lat: number;
  lon: number;
  voornaam: string;
  /** Signed URL van de profielfoto. */
  uri?: string;
}) {
  // De marker moet opnieuw renderen zodra de foto binnen is; daarna weer
  // bevriezen voor de performance.
  const [tracks, setTracks] = useState(true);
  return (
    <Marker coordinate={{ latitude: lat, longitude: lon }} tracksViewChanges={tracks}>
      <View style={styles.buddy}>
        {uri ? (
          <Image source={{ uri }} style={styles.buddyFoto} onLoadEnd={() => setTracks(false)} />
        ) : (
          <TvzText preset="meta" style={styles.buddyInitial}>
            {voornaam.charAt(0).toUpperCase()}
          </TvzText>
        )}
      </View>
    </Marker>
  );
}

/** Directe hulp: groene druppel met hartje en een zachte gloed eromheen. */
export function RequestMarker({
  lat,
  lon,
  onPress,
}: {
  lat: number;
  lon: number;
  onPress?: () => void;
}) {
  return (
    <Marker
      coordinate={{ latitude: lat, longitude: lon }}
      onPress={onPress}
      tracksViewChanges={false}
      anchor={{ x: 0.5, y: PIN_ANCHOR_Y }}
      centerOffset={{ x: 0, y: (0.5 - PIN_ANCHOR_Y) * PIN_H }}
    >
      <Svg width={PIN_W} height={PIN_H} viewBox="0 0 52 66">
        <Defs>
          <LinearGradient id="requestPin" x1="0" y1="0" x2="1" y2="1">
            <Stop offset="0" stopColor="#9AD44E" />
            <Stop offset="1" stopColor="#73B02B" />
          </LinearGradient>
        </Defs>
        <Ellipse cx={26} cy={61} rx={11} ry={3.5} fill="#112F50" opacity={0.15} />
        <SvgCircle cx={26} cy={24} r={21} fill="#8DC93F" opacity={0.18} />
        <Path d={PIN_PATH} fill="url(#requestPin)" stroke={colors.white} strokeWidth={2.5} />
        <SvgCircle cx={26} cy={24} r={13.5} fill={colors.white} />
        <G translate="14.5 12.5">
          <Path
            d="M12 21c-3.6-2.2-7-5-7-8.6A4.4 4.4 0 0 1 12 9.4a4.4 4.4 0 0 1 7 3c0 3.6-3.4 6.4-7 8.6z"
            fill="#73B02B"
          />
          <Path
            d="M8.9 6.6c1.1-1 2.6-1 3.6.1M15.4 6.6c-1.1-1-2.6-1-3.6.1"
            stroke="#73B02B"
            strokeWidth={1.7}
            strokeLinecap="round"
            fill="none"
          />
        </G>
      </Svg>
    </Marker>
  );
}

/** Eigen locatie: groene stip met witte rand. */
export function OwnLocationMarker({ lat, lon }: { lat: number; lon: number }) {
  return (
    <Marker coordinate={{ latitude: lat, longitude: lon }} tracksViewChanges={false}>
      <View style={styles.own} />
    </Marker>
  );
}

const styles = StyleSheet.create({
  buddy: {
    width: 34,
    height: 34,
    borderRadius: 17,
    backgroundColor: colors.primary,
    borderWidth: 2,
    borderColor: colors.white,
    alignItems: 'center',
    justifyContent: 'center',
    overflow: 'hidden',
  },
  buddyFoto: {
    width: 30,
    height: 30,
    borderRadius: 15,
  },
  buddyInitial: {
    color: colors.white,
    fontSize: 12,
  },
  own: {
    width: 16,
    height: 16,
    borderRadius: 8,
    backgroundColor: colors.accent,
    borderWidth: 3,
    borderColor: colors.white,
  },
});

import { forwardRef, useState, type ReactNode } from 'react';
import { Image, StyleSheet, View } from 'react-native';
import MapView, { Marker, type Region } from 'react-native-maps';
import Svg, {
  Circle as SvgCircle,
  Ellipse,
  G,
  Path,
  Rect,
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
 * Druppelmarkers naar het handoff-ontwerp 1d ("druppel met labelpill", zonder
 * de labelpill): kleinere druppels; hulpkring wit met twee stipjes, directe
 * hulp navy met groene bliksem. ViewBox 52x66, punt van de druppel op y≈53.
 * De blur-filters uit de SVG's rendert react-native-svg niet; de grondschaduw
 * is daarom een vlakke ellips.
 */
const PIN_PATH =
  'M26 2.75a20.75 20.75 0 0 1 14.67 35.42L26 52.84 11.33 38.17A20.75 20.75 0 0 1 26 2.75z';
const PIN_W = 34;
const PIN_H = 43;
// De punt van de druppel (y 52.84 van 66) hoort op de coördinaat te staan.
const PIN_ANCHOR_Y = 52.84 / 66;

/** Hulpkring: witte druppel met navy rand en twee stipjes (blauw + groen). */
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
        <Ellipse cx={26} cy={61} rx={10} ry={3.5} fill="#112F50" opacity={0.15} />
        <Path d={PIN_PATH} fill={colors.white} stroke={colors.primary} strokeWidth={4} />
        <Rect x={13} y={20.5} width={11} height={8} rx={4} fill={colors.primaryMid} />
        <Rect x={28} y={20.5} width={11} height={8} rx={4} fill={colors.accent} />
        {plekkenVrij > 0 ? (
          <G translate="30 0">
            <Rect
              width={22}
              height={22}
              rx={11}
              fill="#8DC93F"
              stroke={colors.white}
              strokeWidth={2.5}
            />
            <SvgText
              x={11}
              y={15.7}
              fontSize={12.5}
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

/** Directe hulp: navy druppel met groene bliksem en een zachte gloed eromheen. */
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
        <Ellipse cx={26} cy={61} rx={10} ry={3.5} fill="#112F50" opacity={0.15} />
        <SvgCircle cx={26} cy={24} r={22} fill="#8DC93F" opacity={0.18} />
        <Path d={PIN_PATH} fill="#112F50" stroke={colors.white} strokeWidth={3.5} />
        <Path d="M29.5 10.5 L17.5 27.5 h6.5 L22.5 39 L34.5 22.5 h-6.5 Z" fill={colors.accent} />
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

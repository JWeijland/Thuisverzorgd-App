import {
  Camera,
  Map as MapLibreMap,
  Marker as MapLibreMarker,
  type CameraRef,
} from '@maplibre/maplibre-react-native';
import {
  forwardRef,
  useImperativeHandle,
  useRef,
  useState,
  type ReactNode,
} from 'react';
import { Image, StyleSheet, View } from 'react-native';
import Svg, {
  Circle as SvgCircle,
  Ellipse,
  G,
  Path,
  Rect,
  Text as SvgText,
} from 'react-native-svg';

import tvzStijl from '@/features/map/tvz-stijl.json';
import { colors } from '@/theme';
import { TvzText } from '@/ui';

/**
 * Enige plek die de kaartbibliotheek importeert (ADR-0004). Sinds 08-2026 is
 * dat MapLibre met OpenFreeMap-tegels en een eigen merkstijl (tvz-stijl.json:
 * OpenFreeMap Positron, omgekleurd; gratis, geen account of sleutel nodig).
 * De buitenkant (Region, animateToRegion, Marker met coordinate/anchor) houdt
 * bewust de oude react-native-maps-vorm aan, zodat de schermen niets merken.
 */

export type Region = {
  latitude: number;
  longitude: number;
  latitudeDelta: number;
  longitudeDelta: number;
};

export type TvzMapHandle = {
  animateToRegion: (region: Region, durationMs?: number) => void;
};

/** Webmercator-benadering: hoeveel zoom hoort bij deze uitsnede. */
function zoomVoorDelta(longitudeDelta: number): number {
  return Math.log2(360 / Math.max(longitudeDelta, 0.0005));
}

type TvzMapProps = {
  initialRegion: Region;
  onRegionChangeComplete?: (region: Region) => void;
  children?: ReactNode;
};

export const TvzMap = forwardRef<TvzMapHandle, TvzMapProps>(function TvzMap(
  { initialRegion, onRegionChangeComplete, children },
  ref,
) {
  const cameraRef = useRef<CameraRef>(null);

  useImperativeHandle(ref, () => ({
    animateToRegion: (region, durationMs = 500) => {
      cameraRef.current?.easeTo({
        center: [region.longitude, region.latitude],
        zoom: zoomVoorDelta(region.longitudeDelta),
        duration: durationMs,
      });
    },
  }));

  return (
    <MapLibreMap
      style={StyleSheet.absoluteFill}
      mapStyle={tvzStijl as never}
      onRegionDidChange={(event) => {
        const [west, zuid, oost, noord] = event.nativeEvent.bounds;
        onRegionChangeComplete?.({
          latitude: (zuid + noord) / 2,
          longitude: (west + oost) / 2,
          latitudeDelta: noord - zuid,
          longitudeDelta: oost - west,
        });
      }}
    >
      <Camera
        ref={cameraRef}
        initialViewState={{
          center: [initialRegion.longitude, initialRegion.latitude],
          zoom: zoomVoorDelta(initialRegion.longitudeDelta),
        }}
      />
      {children}
    </MapLibreMap>
  );
});

type MarkerProps = {
  coordinate: { latitude: number; longitude: number };
  /** Welk punt van de view op de coördinaat staat (0..1, zoals react-native-maps). */
  anchor?: { x: number; y: number };
  onPress?: () => void;
  children: ReactNode;
};

/**
 * Marker met de oude buitenkant: MapLibre kent alleen benoemde ankers
 * ("center", "bottom", ...), dus het vrije {x,y}-anker wordt hier vertaald
 * naar "center" plus een pixel-offset op basis van de gemeten viewgrootte.
 */
export function Marker({ coordinate, anchor, onPress, children }: MarkerProps) {
  const [maat, setMaat] = useState<{ w: number; h: number } | null>(null);
  const ax = anchor?.x ?? 0.5;
  const ay = anchor?.y ?? 0.5;
  const offset: [number, number] = maat
    ? [(0.5 - ax) * maat.w, (0.5 - ay) * maat.h]
    : [0, 0];
  return (
    <MapLibreMarker
      lngLat={[coordinate.longitude, coordinate.latitude]}
      anchor="center"
      offset={offset}
      onPress={onPress}
    >
      <View
        onLayout={(event) => {
          const { width, height } = event.nativeEvent.layout;
          if (width && height && (maat?.w !== width || maat?.h !== height)) {
            setMaat({ w: width, h: height });
          }
        }}
      >
        {children}
      </View>
    </MapLibreMarker>
  );
}

/**
 * Druppelmarkers naar het handoff-ontwerp 1d ("druppel met labelpill", zonder
 * de labelpill): kleinere druppels; hulpkring wit met twee stipjes, directe
 * hulp navy met groene bliksem. ViewBox 52x66, punt van de druppel op y≈53.
 * De blur-filters uit de SVG's rendert react-native-svg niet; de grondschaduw
 * is daarom een vlakke ellips.
 */
const PIN_PATH =
  'M26 2.75a20.75 20.75 0 0 1 14.67 35.42L26 52.84 11.33 38.17A20.75 20.75 0 0 1 26 2.75z';
const PIN_W = 40;
const PIN_H = 50;
/** Hoogte van de labelpil onder de druppel (inclusief overlap). */
const LABEL_H = 20;
// De punt van de druppel (y 52.84 van 66) hoort op de coördinaat te staan.
const PIN_ANCHOR_Y = 52.84 / 66;
/**
 * Onzichtbare rand rond elke marker: het tikbare vlak van een custom marker is
 * precies de view zelf, en een druppel van 40pt alleen was te priegelig
 * (feedback 05-08). Zo haalt elke marker ruim de 44pt-tikdoelregel.
 */
const HIT_PAD = 12;

/**
 * Hulpkring: witte druppel met navy rand en twee stipjes (blauw + groen), met
 * de kringnaam als labelpil eronder (ontwerp 1d).
 */
export function KringMarker({
  lat,
  lon,
  naam,
  plekkenVrij = 0,
  onPress,
}: {
  lat: number;
  lon: number;
  naam?: string;
  plekkenVrij?: number;
  onPress?: () => void;
}) {
  // Met label is de marker hoger; de punt van de druppel moet op de coördinaat
  // blijven staan, dus schuift het anker mee omhoog. De onzichtbare tikrand
  // bovenaan telt ook mee.
  const hoogte = HIT_PAD + PIN_H + (naam ? LABEL_H : 0);
  const ankerY = (HIT_PAD + PIN_H * PIN_ANCHOR_Y) / hoogte;

  return (
    <Marker
      coordinate={{ latitude: lat, longitude: lon }}
      onPress={onPress}
      anchor={{ x: 0.5, y: ankerY }}
    >
      <View style={styles.kringWrap}>
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
        {naam ? (
          <View style={styles.label}>
            <TvzText preset="meta" numberOfLines={1} style={styles.labelText}>
              {naam}
            </TvzText>
          </View>
        ) : null}
      </View>
    </Marker>
  );
}

/**
 * Buddy: cirkel met profielfoto (of initiaal zolang er geen foto is), met de
 * voornaam als labelpil eronder zodat je op de kaart ziet wie er woont.
 */
export function BuddyMarker({
  lat,
  lon,
  voornaam,
  uri,
  onPress,
}: {
  lat: number;
  lon: number;
  voornaam: string;
  /** Signed URL van de profielfoto. */
  uri?: string;
  onPress?: () => void;
}) {
  return (
    <Marker
      coordinate={{ latitude: lat, longitude: lon }}
      onPress={onPress}
      anchor={{ x: 0.5, y: 0.5 }}
    >
      <View style={styles.buddyWrap}>
        <View style={styles.buddy}>
          {uri ? (
            <Image source={{ uri }} style={styles.buddyFoto} />
          ) : (
            <TvzText preset="meta" style={styles.buddyInitial}>
              {voornaam.charAt(0).toUpperCase()}
            </TvzText>
          )}
        </View>
        <View style={styles.label}>
          <TvzText preset="meta" numberOfLines={1} style={styles.labelText}>
            {voornaam}
          </TvzText>
        </View>
      </View>
    </Marker>
  );
}

/** Directe hulp: navy druppel met groene bliksem en een zachte gloed eromheen. */
export function RequestMarker({
  lat,
  lon,
  label,
  onPress,
}: {
  lat: number;
  lon: number;
  /** Waar de hulpvraag over gaat, bijv. "Boodschappen". */
  label?: string;
  onPress?: () => void;
}) {
  const hoogte = HIT_PAD + PIN_H + (label ? LABEL_H : 0);
  const ankerY = (HIT_PAD + PIN_H * PIN_ANCHOR_Y) / hoogte;

  return (
    <Marker
      coordinate={{ latitude: lat, longitude: lon }}
      onPress={onPress}
      anchor={{ x: 0.5, y: ankerY }}
    >
      <View style={styles.kringWrap}>
        <Svg width={PIN_W} height={PIN_H} viewBox="0 0 52 66">
          <Ellipse cx={26} cy={61} rx={10} ry={3.5} fill="#112F50" opacity={0.15} />
          <SvgCircle cx={26} cy={24} r={22} fill="#8DC93F" opacity={0.18} />
          <Path d={PIN_PATH} fill="#112F50" stroke={colors.white} strokeWidth={3.5} />
          <Path d="M29.5 10.5 L17.5 27.5 h6.5 L22.5 39 L34.5 22.5 h-6.5 Z" fill={colors.accent} />
        </Svg>
        {label ? (
          <View style={[styles.label, styles.labelHulpvraag]}>
            <TvzText preset="meta" numberOfLines={1} style={styles.labelText}>
              {label}
            </TvzText>
          </View>
        ) : null}
      </View>
    </Marker>
  );
}

/** Eigen locatie: groene stip met witte rand. */
export function OwnLocationMarker({ lat, lon }: { lat: number; lon: number }) {
  return (
    <Marker coordinate={{ latitude: lat, longitude: lon }}>
      <View style={styles.own} />
    </Marker>
  );
}

const styles = StyleSheet.create({
  kringWrap: {
    alignItems: 'center',
    paddingTop: HIT_PAD,
    paddingHorizontal: HIT_PAD,
  },
  label: {
    marginTop: -4,
    maxWidth: 130,
    backgroundColor: colors.white,
    borderRadius: 999,
    paddingHorizontal: 9,
    paddingVertical: 3,
    borderWidth: 1.5,
    borderColor: colors.line,
  },
  labelText: {
    color: colors.primary,
    fontSize: 11,
  },
  buddyWrap: {
    alignItems: 'center',
    padding: HIT_PAD - 4,
  },
  labelHulpvraag: {
    borderColor: colors.primaryDark,
  },
  buddy: {
    width: 42,
    height: 42,
    borderRadius: 21,
    backgroundColor: colors.primary,
    borderWidth: 2.5,
    borderColor: colors.white,
    alignItems: 'center',
    justifyContent: 'center',
    overflow: 'hidden',
  },
  buddyFoto: {
    width: 37,
    height: 37,
    borderRadius: 18.5,
  },
  buddyInitial: {
    color: colors.white,
    fontSize: 14,
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

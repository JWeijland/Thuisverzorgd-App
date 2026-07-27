import { forwardRef, type ReactNode } from 'react';
import { StyleSheet, View } from 'react-native';
import MapView, { Marker, type Region } from 'react-native-maps';
import { Zap } from 'lucide-react-native';

import { colors, radius } from '@/theme';
import { PulseDot, TvzText } from '@/ui';

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

/** Hulpkring: witte cirkel Ø42 met navy rand, het logo-balkjespaar en een pootje. */
export function KringMarker({
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
    >
      <View style={styles.kringWrap}>
        <View style={styles.kring}>
          <View style={styles.kringBars}>
            <View style={[styles.kringBar, { backgroundColor: colors.primaryMid }]} />
            <View style={[styles.kringBar, { backgroundColor: colors.accent }]} />
          </View>
        </View>
        <View style={styles.pootje} />
      </View>
    </Marker>
  );
}

/** Buddy: navy cirkel Ø26 met initiaal. */
export function BuddyMarker({
  lat,
  lon,
  voornaam,
}: {
  lat: number;
  lon: number;
  voornaam: string;
}) {
  return (
    <Marker coordinate={{ latitude: lat, longitude: lon }} tracksViewChanges={false}>
      <View style={styles.buddy}>
        <TvzText preset="meta" style={styles.buddyInitial}>
          {voornaam.charAt(0).toUpperCase()}
        </TvzText>
      </View>
    </Marker>
  );
}

/** Directe hulp: navy cirkel Ø42 met groene bliksem en pulsering. */
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
    <Marker coordinate={{ latitude: lat, longitude: lon }} onPress={onPress}>
      <View style={styles.requestWrap}>
        <View style={styles.requestPulse}>
          <PulseDot size={16} />
        </View>
        <View style={styles.request}>
          <Zap color={colors.accent} size={20} strokeWidth={2.2} fill={colors.accent} />
        </View>
      </View>
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
  kringWrap: {
    alignItems: 'center',
  },
  kring: {
    width: 42,
    height: 42,
    borderRadius: 21,
    backgroundColor: colors.white,
    borderWidth: 2,
    borderColor: colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
  },
  kringBars: {
    flexDirection: 'row',
    gap: 3,
  },
  kringBar: {
    width: 12,
    height: 8,
    borderRadius: radius.pill,
  },
  pootje: {
    width: 0,
    height: 0,
    borderLeftWidth: 6,
    borderRightWidth: 6,
    borderTopWidth: 8,
    borderLeftColor: 'transparent',
    borderRightColor: 'transparent',
    borderTopColor: colors.primary,
    marginTop: -1,
  },
  buddy: {
    width: 26,
    height: 26,
    borderRadius: 13,
    backgroundColor: colors.primary,
    borderWidth: 2,
    borderColor: colors.white,
    alignItems: 'center',
    justifyContent: 'center',
  },
  buddyInitial: {
    color: colors.white,
    fontSize: 11,
  },
  requestWrap: {
    width: 56,
    height: 56,
    alignItems: 'center',
    justifyContent: 'center',
  },
  requestPulse: {
    position: 'absolute',
  },
  request: {
    width: 42,
    height: 42,
    borderRadius: 21,
    backgroundColor: colors.primaryDark,
    borderWidth: 2,
    borderColor: colors.white,
    alignItems: 'center',
    justifyContent: 'center',
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

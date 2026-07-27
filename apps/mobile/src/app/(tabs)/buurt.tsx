import * as Location from 'expo-location';
import { useEffect, useRef, useState } from 'react';
import { Pressable, StyleSheet, TextInput, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Search } from 'lucide-react-native';
import type MapView from 'react-native-maps';

import { useMapBuddies, useMapCircles } from '@/features/map/api';
import {
  BuddyMarker,
  KringMarker,
  OwnLocationMarker,
  RequestMarker,
  TvzMap,
  type Region,
} from '@/features/map/TvzMap';
import { useProfile } from '@/features/onboarding/useAuth';
import { useOpenRequests, type OpenRequest } from '@/features/spontaneous/api';
import { RequesterFlow } from '@/features/spontaneous/RequesterFlow';
import { VolunteerFlow } from '@/features/spontaneous/VolunteerFlow';
import { countInRegion, DEFAULT_REGION, type LatLng } from '@/lib/geo';
import { t } from '@/i18n';
import { colors, radius, shadows, spacing } from '@/theme';
import { Chip, TvzText } from '@/ui';

/** Buurt (screens 08/20/21): kaart met kringen, buddy's en directe hulpvragen. */
export default function BuurtScreen() {
  const profile = useProfile();
  const role = profile.data?.role;
  const isVolunteer = role === 'vrijwilliger';

  const circles = useMapCircles();
  const requests = useOpenRequests();
  const [showBuddies, setShowBuddies] = useState(false);
  const buddies = useMapBuddies(!isVolunteer && showBuddies);

  const mapRef = useRef<MapView>(null);
  const [region, setRegion] = useState<Region>(DEFAULT_REGION);
  const [ownLocation, setOwnLocation] = useState<LatLng | null>(null);
  const [query, setQuery] = useState('');
  const [selectedRequest, setSelectedRequest] = useState<OpenRequest | null>(null);

  useEffect(() => {
    Location.requestForegroundPermissionsAsync().then(async ({ status }) => {
      if (status !== 'granted') return;
      const position = await Location.getCurrentPositionAsync({
        accuracy: Location.Accuracy.Balanced,
      });
      const loc = { lat: position.coords.latitude, lon: position.coords.longitude };
      setOwnLocation(loc);
      mapRef.current?.animateToRegion(
        { latitude: loc.lat, longitude: loc.lon, latitudeDelta: 0.05, longitudeDelta: 0.04 },
        600,
      );
    });
  }, []);

  const circleList = (circles.data ?? []).filter((circle) =>
    query.trim().length === 0 ? true : circle.name.toLowerCase().includes(query.toLowerCase()),
  );
  const suggestions = query.trim().length > 0 ? circleList.slice(0, 4) : [];

  const requestList = (requests.data ?? []).filter(
    (request) => request.lat != null && request.lon != null,
  );

  const circlesInView = countInRegion(
    circleList.map((circle) => ({ lat: circle.lat, lon: circle.lon })),
    region,
  );
  const requestsInView = countInRegion(
    requestList.map((request) => ({ lat: request.lat!, lon: request.lon! })),
    region,
  );
  const tellerText =
    requestsInView === 0
      ? t('buurt.tellerGeen', { kringen: circlesInView })
      : requestsInView === 1
        ? t('buurt.teller1', { kringen: circlesInView, aanvragen: requestsInView })
        : t('buurt.tellerMeer', { kringen: circlesInView, aanvragen: requestsInView });

  return (
    <View style={styles.fill}>
      <TvzMap ref={mapRef} initialRegion={DEFAULT_REGION} onRegionChangeComplete={setRegion}>
        {circleList.map((circle) => (
          <KringMarker
            key={circle.id}
            lat={circle.lat}
            lon={circle.lon}
            onPress={() => {
              mapRef.current?.animateToRegion(
                {
                  latitude: circle.lat,
                  longitude: circle.lon,
                  latitudeDelta: 0.03,
                  longitudeDelta: 0.02,
                },
                400,
              );
            }}
          />
        ))}
        {!isVolunteer && showBuddies
          ? (buddies.data ?? []).map((buddy) => (
              <BuddyMarker
                key={buddy.id}
                lat={buddy.lat}
                lon={buddy.lon}
                voornaam={buddy.voornaam}
              />
            ))
          : null}
        {requestList.map((request) => (
          <RequestMarker
            key={request.id}
            lat={request.lat!}
            lon={request.lon!}
            onPress={() => (isVolunteer ? setSelectedRequest(request) : undefined)}
          />
        ))}
        {ownLocation ? <OwnLocationMarker lat={ownLocation.lat} lon={ownLocation.lon} /> : null}
      </TvzMap>

      <SafeAreaView edges={['top']} pointerEvents="box-none" style={styles.topLayer}>
        <View style={[styles.search, shadows.card]}>
          <Search color={colors.inkFaint} size={18} strokeWidth={2.2} />
          <TextInput
            value={query}
            onChangeText={setQuery}
            placeholder={t('buurt.zoekPlaceholder')}
            placeholderTextColor={colors.inkFaint}
            style={styles.searchInput}
          />
        </View>
        {suggestions.length > 0 ? (
          <View style={[styles.suggestions, shadows.card]}>
            {suggestions.map((circle) => (
              <Pressable
                key={circle.id}
                accessibilityRole="button"
                onPress={() => {
                  setQuery('');
                  mapRef.current?.animateToRegion(
                    {
                      latitude: circle.lat,
                      longitude: circle.lon,
                      latitudeDelta: 0.03,
                      longitudeDelta: 0.02,
                    },
                    500,
                  );
                }}
                style={styles.suggestion}
              >
                <TvzText preset="body">{circle.name}</TvzText>
              </Pressable>
            ))}
          </View>
        ) : null}

        {isVolunteer ? (
          <View style={[styles.teller, shadows.card]}>
            <View style={styles.tellerDot} />
            <TvzText preset="meta" style={styles.tellerText}>
              {tellerText}
            </TvzText>
          </View>
        ) : (
          <View style={styles.filterRow}>
            <Chip
              label={t('buurt.chipKringen')}
              selected={!showBuddies}
              onPress={() => setShowBuddies(false)}
            />
            <Chip
              label={t('buurt.chipBuddys')}
              selected={showBuddies}
              onPress={() => setShowBuddies(true)}
            />
          </View>
        )}
      </SafeAreaView>

      <View pointerEvents="box-none" style={styles.bottomLayer}>
        {isVolunteer ? (
          <VolunteerFlow
            selected={selectedRequest}
            onCloseSelected={() => setSelectedRequest(null)}
            ownLocation={ownLocation}
          />
        ) : role === 'beheerder' || role === 'hulpvrager' ? (
          <RequesterFlow ownLocation={ownLocation} />
        ) : null}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  fill: {
    flex: 1,
    backgroundColor: colors.bg,
  },
  topLayer: {
    paddingHorizontal: spacing.screen,
  },
  search: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    backgroundColor: colors.white,
    borderRadius: radius.pill,
    paddingHorizontal: 16,
    minHeight: 46,
  },
  searchInput: {
    flex: 1,
    fontFamily: 'ComicNeue_400Regular',
    fontSize: 15,
    color: colors.ink,
    paddingVertical: 10,
  },
  suggestions: {
    backgroundColor: colors.white,
    borderRadius: radius.card,
    marginTop: 6,
    overflow: 'hidden',
  },
  suggestion: {
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.md,
    borderBottomWidth: 1,
    borderBottomColor: colors.line,
  },
  filterRow: {
    flexDirection: 'row',
    gap: spacing.chipGap,
    marginTop: spacing.sm,
  },
  teller: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    alignSelf: 'flex-start',
    backgroundColor: colors.primaryDark,
    borderRadius: radius.pill,
    paddingHorizontal: 14,
    paddingVertical: 8,
    marginTop: spacing.sm,
  },
  tellerDot: {
    width: 7,
    height: 7,
    borderRadius: 4,
    backgroundColor: colors.accent,
  },
  tellerText: {
    color: colors.white,
  },
  bottomLayer: {
    position: 'absolute',
    left: 0,
    right: 0,
    bottom: 96,
  },
});

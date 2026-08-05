import * as Location from 'expo-location';
import { useEffect, useRef, useState } from 'react';
import { Pressable, ScrollView, StyleSheet, TextInput, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { MapPin, Search, Zap } from 'lucide-react-native';
import type MapView from 'react-native-maps';

import { useAvatarUrl } from '@/features/avatars/api';
import { ProfileAvatar } from '@/features/avatars/ProfileAvatar';
import {
  useMapBuddies,
  useMapCircles,
  useMyCircleStatus,
  useRequestToJoin,
  type MapBuddy,
  type MapCircle,
} from '@/features/map/api';
import {
  BuddyMarker,
  KringMarker,
  OwnLocationMarker,
  RequestMarker,
  TvzMap,
  type Region,
} from '@/features/map/TvzMap';
import { useInvite, useMyCircle } from '@/features/circles/api';
import { useProfile } from '@/features/onboarding/useAuth';
import { useOpenRequests, type OpenRequest } from '@/features/spontaneous/api';
import { REQUEST_TYPE_LABEL, RequesterFlow } from '@/features/spontaneous/RequesterFlow';
import { VolunteerFlow } from '@/features/spontaneous/VolunteerFlow';
import { countInRegion, DEFAULT_REGION, formatDistance, haversineKm, type LatLng } from '@/lib/geo';
import { useKeyboard } from '@/lib/keyboard';
import { t } from '@/i18n';
import { colors, radius, shadows, spacing } from '@/theme';
import { BottomSheet, Button, Chip, TvzText } from '@/ui';
import { useStatusBalk } from '@/lib/statusbalk';

/** Buurt (screens 08/20/21): kaart met kringen, buddy's en directe hulpvragen. */
export default function BuurtScreen() {
  useStatusBalk('donker');
  const profile = useProfile();
  const role = profile.data?.role;
  const isVolunteer = role === 'vrijwilliger';
  // De hulpvrager krijgt een zo rustig mogelijke kaart: alleen de buddy's uit
  // de buurt (met foto), geen kringen, aanvragen van anderen of zoekbalk
  // (feedback 05-08).
  const isHulpvrager = role === 'hulpvrager';

  const circles = useMapCircles();
  const requests = useOpenRequests();
  // Beheerders en hulpvragers zoeken vooral buddy's: die staan standaard aan.
  const [showBuddies, setShowBuddies] = useState(true);
  const buddies = useMapBuddies(!isVolunteer && (isHulpvrager || showBuddies));
  const eigenKring = useMyCircle();

  const mapRef = useRef<MapView>(null);
  const [region, setRegion] = useState<Region>(DEFAULT_REGION);
  const [ownLocation, setOwnLocation] = useState<LatLng | null>(null);
  const [query, setQuery] = useState('');
  const [selectedRequest, setSelectedRequest] = useState<OpenRequest | null>(null);
  const [selectedCircle, setSelectedCircle] = useState<MapCircle | null>(null);
  const [selectedBuddy, setSelectedBuddy] = useState<MapBuddy | null>(null);
  const [listOpen, setListOpen] = useState(false);
  const keyboard = useKeyboard();

  const available = profile.data?.spontaneous_available ?? true;

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

  const circleList = isHulpvrager
    ? []
    : (circles.data ?? []).filter((circle) =>
        query.trim().length === 0 ? true : circle.name.toLowerCase().includes(query.toLowerCase()),
      );
  const suggestions = query.trim().length > 0 ? circleList.slice(0, 4) : [];

  // Niet beschikbaar? Dan blijven spontane aanvragen voor deze vrijwilliger van
  // de kaart. De hulpvrager ziet aanvragen van anderen nooit.
  const requestList =
    isHulpvrager || (isVolunteer && !available)
      ? []
      : (requests.data ?? []).filter((request) => request.lat != null && request.lon != null);

  const distanceTo = (point: LatLng): number | null =>
    ownLocation ? haversineKm(ownLocation, point) : null;
  const sortedRequests = [...requestList].sort((a, b) => {
    if (!ownLocation) return 0;
    return (
      haversineKm(ownLocation, { lat: a.lat!, lon: a.lon! }) -
      haversineKm(ownLocation, { lat: b.lat!, lon: b.lon! })
    );
  });
  const sortedCircles = [...circleList].sort((a, b) => {
    if (!ownLocation) return 0;
    return (
      haversineKm(ownLocation, { lat: a.lat, lon: a.lon }) -
      haversineKm(ownLocation, { lat: b.lat, lon: b.lon })
    );
  });

  function focusOn(lat: number, lon: number) {
    setListOpen(false);
    mapRef.current?.animateToRegion(
      { latitude: lat, longitude: lon, latitudeDelta: 0.03, longitudeDelta: 0.02 },
      500,
    );
  }

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
            naam={circle.name}
            plekkenVrij={circle.plekken_vrij}
            onPress={() => {
              // Iedereen ziet het kaartje met naam, leden en open taken; alleen
              // de vrijwilliger krijgt er de aanmeldknop bij.
              setSelectedRequest(null);
              setSelectedBuddy(null);
              setSelectedCircle(circle);
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
        {!isVolunteer && (isHulpvrager || showBuddies)
          ? (buddies.data ?? []).map((buddy) => (
              <BuddyMetFoto
                key={buddy.id}
                buddy={buddy}
                onPress={() => {
                  setSelectedCircle(null);
                  setSelectedRequest(null);
                  setSelectedBuddy(buddy);
                }}
              />
            ))
          : null}
        {requestList.map((request) => (
          <RequestMarker
            key={request.id}
            lat={request.lat!}
            lon={request.lon!}
            label={t(REQUEST_TYPE_LABEL[request.type])}
            onPress={() => {
              setSelectedCircle(null);
              setSelectedBuddy(null);
              setSelectedRequest(request);
            }}
          />
        ))}
        {ownLocation ? <OwnLocationMarker lat={ownLocation.lat} lon={ownLocation.lon} /> : null}
      </TvzMap>

      <SafeAreaView edges={['top']} pointerEvents="box-none" style={styles.topLayer}>
        {!isHulpvrager ? (
          <View style={[styles.search, shadows.card]}>
            <Search color={colors.inkFaint} size={18} strokeWidth={2.2} />
            <TextInput
              textContentType="none"
              autoComplete="off"
              value={query}
              onChangeText={setQuery}
              placeholder={t('buurt.zoekPlaceholder')}
              placeholderTextColor={colors.inkFaint}
              style={styles.searchInput}
            />
          </View>
        ) : null}
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
          <Pressable
            accessibilityRole="button"
            accessibilityLabel={tellerText}
            onPress={() => setListOpen(true)}
            style={[styles.teller, shadows.card]}
          >
            <View style={styles.tellerIcon}>
              <MapPin color={colors.accent} size={17} strokeWidth={2.4} />
            </View>
            <View style={styles.tellerTextWrap}>
              <TvzText preset="cardTitle" style={styles.tellerTitel}>
                {circlesInView === 1
                  ? t('buurt.tellerKring1')
                  : t('buurt.tellerKringen', { kringen: circlesInView })}
              </TvzText>
              <TvzText preset="meta" style={styles.tellerSub}>
                {requestsInView === 0
                  ? t('buurt.tellerGeenAanvragen')
                  : requestsInView === 1
                    ? t('buurt.tellerAanvraag1')
                    : t('buurt.tellerAanvragen', { aanvragen: requestsInView })}
              </TvzText>
            </View>
            <TvzText preset="cardTitle" style={styles.tellerChevron}>
              ⌄
            </TvzText>
          </Pressable>
        ) : !isHulpvrager ? (
          <View style={styles.filterRow}>
            <Chip
              label={t('buurt.chipBuddys')}
              selected={showBuddies}
              onPress={() => setShowBuddies(true)}
            />
            <Chip
              label={t('buurt.chipKringen')}
              selected={!showBuddies}
              onPress={() => setShowBuddies(false)}
            />
          </View>
        ) : null}
      </SafeAreaView>

      <BottomSheet
        visible={listOpen}
        onClose={() => setListOpen(false)}
        title={t('buurt.lijstTitel')}
      >
        <ScrollView style={styles.sheetScroll}>
          <TvzText preset="meta" style={styles.sheetKop}>
            {t('buurt.lijstAanvragen')}
          </TvzText>
          {sortedRequests.length === 0 ? (
            <TvzText preset="secondary" style={styles.sheetLeeg}>
              {t('buurt.lijstGeenAanvragen')}
            </TvzText>
          ) : null}
          {sortedRequests.map((request) => {
            const km = distanceTo({ lat: request.lat!, lon: request.lon! });
            return (
              <Pressable
                key={request.id}
                accessibilityRole="button"
                onPress={() => {
                  focusOn(request.lat!, request.lon!);
                  if (isVolunteer) setSelectedRequest(request);
                }}
                style={styles.sheetRow}
              >
                <View style={styles.sheetZap}>
                  <Zap
                    color={colors.primaryDark}
                    size={15}
                    strokeWidth={2.2}
                    fill={colors.accent}
                  />
                </View>
                <View style={styles.sheetRowText}>
                  <TvzText preset="cardTitle" style={styles.sheetRowTitle}>
                    {t(REQUEST_TYPE_LABEL[request.type])} · {request.voornaam}
                  </TvzText>
                  <TvzText preset="secondary" style={styles.sheetRowMeta}>
                    {km != null ? t('buurt.afstandVanJou', { afstand: formatDistance(km) }) : ''}
                  </TvzText>
                </View>
              </Pressable>
            );
          })}

          <TvzText preset="meta" style={[styles.sheetKop, styles.sheetKopKringen]}>
            {t('buurt.lijstKringen')}
          </TvzText>
          {sortedCircles.map((circle) => {
            const km = distanceTo({ lat: circle.lat, lon: circle.lon });
            return (
              <Pressable
                key={circle.id}
                accessibilityRole="button"
                onPress={() => {
                  focusOn(circle.lat, circle.lon);
                  if (isVolunteer) {
                    setSelectedRequest(null);
                    setSelectedCircle(circle);
                  }
                }}
                style={styles.sheetRow}
              >
                <View style={styles.sheetKringDot} />
                <View style={styles.sheetRowText}>
                  <TvzText preset="cardTitle" style={styles.sheetRowTitle}>
                    {circle.name}
                  </TvzText>
                  <TvzText preset="secondary" style={styles.sheetRowMeta}>
                    {[
                      km != null ? t('buurt.afstandVanJou', { afstand: formatDistance(km) }) : null,
                      circle.plekken_vrij > 0
                        ? t('buurt.plekkenVrij', { aantal: circle.plekken_vrij })
                        : null,
                    ]
                      .filter(Boolean)
                      .join(' · ')}
                  </TvzText>
                </View>
              </Pressable>
            );
          })}
        </ScrollView>
      </BottomSheet>

      <View
        pointerEvents="box-none"
        style={[
          styles.bottomLayer,
          // Typebalken in de overlay (directe hulp) boven het toetsenbord houden.
          keyboard.open && { bottom: keyboard.height + spacing.sm },
        ]}
      >
        {selectedBuddy ? (
          <BuddyKaart
            buddy={selectedBuddy}
            afstand={
              ownLocation
                ? formatDistance(
                    haversineKm(ownLocation, { lat: selectedBuddy.lat, lon: selectedBuddy.lon }),
                  )
                : null
            }
            kringId={role === 'beheerder' ? (eigenKring.data?.id ?? null) : null}
            hulpvrager={isHulpvrager}
            onClose={() => setSelectedBuddy(null)}
          />
        ) : null}
        {!isVolunteer && selectedRequest ? (
          <HulpvraagKaart
            request={selectedRequest}
            afstand={
              ownLocation && selectedRequest.lat != null && selectedRequest.lon != null
                ? formatDistance(
                    haversineKm(ownLocation, {
                      lat: selectedRequest.lat,
                      lon: selectedRequest.lon,
                    }),
                  )
                : null
            }
            onClose={() => setSelectedRequest(null)}
          />
        ) : null}
        {selectedCircle && !selectedRequest && !selectedBuddy ? (
          <KringKaart
            circle={selectedCircle}
            afstand={
              ownLocation
                ? formatDistance(
                    haversineKm(ownLocation, { lat: selectedCircle.lat, lon: selectedCircle.lon }),
                  )
                : null
            }
            idVerified={profile.data?.id_verified ?? false}
            magAanmelden={isVolunteer}
            onClose={() => setSelectedCircle(null)}
          />
        ) : null}
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

/**
 * Kaartje bij een aangetikte hulpkring: naam, afstand, open taken en de knop om
 * je als buddy aan te melden. De beheerder van die kring beslist daarna.
 */
function KringKaart({
  circle,
  afstand,
  idVerified,
  magAanmelden,
  onClose,
}: {
  circle: MapCircle;
  afstand: string | null;
  idVerified: boolean;
  /** Alleen een vrijwilliger kan zich bij een kring aanmelden. */
  magAanmelden: boolean;
  onClose: () => void;
}) {
  const status = useMyCircleStatus(circle.id);
  const join = useRequestToJoin();
  const aangevraagd = status.data === 'aangevraagd' || join.isSuccess;
  const lid = status.data === 'lid';

  return (
    <View style={[styles.kringKaart, shadows.card]}>
      <View style={styles.kringKop}>
        <View style={styles.kringIcon}>
          <MapPin color={colors.primary} size={17} strokeWidth={2.4} />
        </View>
        <View style={styles.kringKopText}>
          <TvzText preset="cardTitle">{circle.name}</TvzText>
          <TvzText preset="secondary" style={styles.kringMeta}>
            {[
              afstand ? t('buurt.afstandVanJou', { afstand }) : null,
              circle.leden === 1
                ? t('buurt.lid1')
                : t('buurt.leden', { aantal: circle.leden ?? 0 }),
              circle.plekken_vrij > 0
                ? t('buurt.plekkenVrij', { aantal: circle.plekken_vrij })
                : t('buurt.geenOpenTaken'),
            ]
              .filter(Boolean)
              .join(' · ')}
          </TvzText>
        </View>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={t('algemeen.sluiten')}
          onPress={onClose}
          hitSlop={12}
          style={styles.sluitKnop}
        >
          <TvzText preset="cardTitle" style={styles.sluitKruis}>
            ✕
          </TvzText>
        </Pressable>
      </View>

      {!magAanmelden ? null : lid ? (
        <TvzText preset="secondary" style={styles.kringNote}>
          {t('buurt.alLid')}
        </TvzText>
      ) : aangevraagd ? (
        <View style={styles.kringGoed}>
          <TvzText preset="secondary" style={styles.kringGoedText}>
            {t('buurt.aanmeldingVerstuurd')}
          </TvzText>
        </View>
      ) : idVerified ? (
        <>
          <Button
            label={t('buurt.meldJeAan')}
            variant="cta"
            size="lg"
            disabled={join.isPending}
            style={styles.kringKnop}
            onPress={() => join.mutate({ circleId: circle.id })}
          />
          <TvzText preset="secondary" style={styles.kringNote}>
            {t('buurt.aanmeldUitleg')}
          </TvzText>
        </>
      ) : (
        <TvzText preset="secondary" style={styles.kringNote}>
          {t('directeHulp.idNodig')}
        </TvzText>
      )}
    </View>
  );
}

/**
 * Kaartje bij een aangetikte buddy: wie het is, hoe ver weg, en voor de
 * beheerder de knop om hem uit te nodigen voor de eigen hulpkring. Er staat
 * alleen een voornaam en een vervaagde locatie; de rest komt pas als hij de
 * uitnodiging aanneemt.
 */
function BuddyKaart({
  buddy,
  afstand,
  kringId,
  hulpvrager = false,
  onClose,
}: {
  buddy: MapBuddy;
  afstand: string | null;
  /** De kring waarvoor uitgenodigd mag worden, of null als die er niet is. */
  kringId: string | null;
  /** De hulpvrager nodigt zelf niemand uit; de beheerder regelt dat. */
  hulpvrager?: boolean;
  onClose: () => void;
}) {
  const invite = useInvite(kringId ?? undefined);
  const [fout, setFout] = useState<string | null>(null);

  return (
    <View style={[styles.kringKaart, shadows.card]}>
      <View style={styles.kringKop}>
        <ProfileAvatar name={buddy.voornaam} avatarPath={buddy.avatar_path} size={40} />
        <View style={styles.kringKopText}>
          <TvzText preset="cardTitle">{buddy.voornaam}</TvzText>
          <TvzText preset="secondary" style={styles.kringMeta}>
            {[t('buurt.buddyLabel'), afstand ? t('buurt.afstandVanJou', { afstand }) : null]
              .filter(Boolean)
              .join(' · ')}
          </TvzText>
        </View>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={t('algemeen.sluiten')}
          onPress={onClose}
          hitSlop={12}
          style={styles.sluitKnop}
        >
          <TvzText preset="cardTitle" style={styles.sluitKruis}>
            ✕
          </TvzText>
        </Pressable>
      </View>

      {kringId ? (
        invite.isSuccess ? (
          <View style={styles.kringGoed}>
            <TvzText preset="secondary" style={styles.kringGoedText}>
              {t('buurt.buddyUitgenodigd', { naam: buddy.voornaam })}
            </TvzText>
          </View>
        ) : (
          <>
            <Button
              label={t('buurt.buddyUitnodigen')}
              variant="cta"
              size="lg"
              disabled={invite.isPending}
              style={styles.kringKnop}
              onPress={() => {
                setFout(null);
                invite.mutate(
                  { target: buddy.id },
                  {
                    onError: (error) =>
                      setFout(
                        (error as Error).message.includes('al_lid')
                          ? t('buurt.buddyAlLid')
                          : t('algemeen.foutOpnieuw'),
                      ),
                  },
                );
              }}
            />
            <TvzText preset="secondary" style={fout ? styles.kringFout : styles.kringNote}>
              {fout ?? t('buurt.buddyUitleg')}
            </TvzText>
          </>
        )
      ) : (
        <TvzText preset="secondary" style={styles.kringNote}>
          {t(hulpvrager ? 'buurt.buddyHulpvrager' : 'buurt.buddyGeenKring')}
        </TvzText>
      )}
    </View>
  );
}

/** Kaartje bij een aangetikte hulpvraag, voor wie er zelf niet op kan reageren. */
function HulpvraagKaart({
  request,
  afstand,
  onClose,
}: {
  request: OpenRequest;
  afstand: string | null;
  onClose: () => void;
}) {
  return (
    <View style={[styles.kringKaart, shadows.card]}>
      <View style={styles.kringKop}>
        <View style={styles.sheetZap}>
          <Zap color={colors.primaryDark} size={15} strokeWidth={2.2} fill={colors.accent} />
        </View>
        <View style={styles.kringKopText}>
          <TvzText preset="cardTitle">{t(REQUEST_TYPE_LABEL[request.type])}</TvzText>
          <TvzText preset="secondary" style={styles.kringMeta}>
            {[request.voornaam, afstand ? t('buurt.afstandVanJou', { afstand }) : null]
              .filter(Boolean)
              .join(' · ')}
          </TvzText>
        </View>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={t('algemeen.sluiten')}
          onPress={onClose}
          hitSlop={12}
          style={styles.sluitKnop}
        >
          <TvzText preset="cardTitle" style={styles.sluitKruis}>
            ✕
          </TvzText>
        </Pressable>
      </View>
      {request.note ? (
        <TvzText preset="secondary" style={styles.kringNote}>
          {request.note}
        </TvzText>
      ) : null}
    </View>
  );
}

/** Buddy-marker die zelf de profielfoto uit de privé-bucket ophaalt. */
function BuddyMetFoto({ buddy, onPress }: { buddy: MapBuddy; onPress: () => void }) {
  const url = useAvatarUrl(buddy.avatar_path);
  return (
    <BuddyMarker
      lat={buddy.lat}
      lon={buddy.lon}
      voornaam={buddy.voornaam}
      onPress={onPress}
      uri={url.data ?? undefined}
    />
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
  // Tellerkaart (ontwerp 1a): navy vlak met groene pin, kringen dik, aanvragen eronder.
  teller: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
    alignSelf: 'flex-start',
    maxWidth: '86%',
    backgroundColor: colors.primaryDark,
    borderRadius: radius.tile,
    paddingHorizontal: 14,
    paddingVertical: 10,
    marginTop: spacing.sm,
  },
  tellerIcon: {
    width: 34,
    height: 34,
    borderRadius: 17,
    backgroundColor: 'rgba(255,255,255,0.14)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  tellerTextWrap: {
    flex: 1,
  },
  tellerTitel: {
    color: colors.white,
    fontSize: 16,
  },
  tellerSub: {
    color: 'rgba(255,255,255,0.75)',
  },
  tellerChevron: {
    color: 'rgba(255,255,255,0.7)',
  },
  sheetScroll: {
    maxHeight: 420,
  },
  sheetKop: {
    color: colors.primaryMid,
    marginBottom: spacing.sm,
  },
  sheetKopKringen: {
    marginTop: spacing.lg,
  },
  sheetLeeg: {
    marginBottom: spacing.sm,
  },
  sheetRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
    paddingVertical: spacing.md,
    borderBottomWidth: 1,
    borderBottomColor: colors.line,
    minHeight: 56,
  },
  sheetZap: {
    width: 30,
    height: 30,
    borderRadius: 15,
    backgroundColor: colors.successBg,
    alignItems: 'center',
    justifyContent: 'center',
  },
  sheetKringDot: {
    width: 30,
    height: 30,
    borderRadius: 15,
    backgroundColor: colors.tintBlue,
    borderWidth: 1.5,
    borderColor: colors.primaryMid,
  },
  sheetRowText: {
    flex: 1,
  },
  sheetRowTitle: {
    fontSize: 15.5,
  },
  sheetRowMeta: {
    fontSize: 13,
  },
  kringKaart: {
    backgroundColor: colors.white,
    borderRadius: radius.card,
    padding: spacing.cardPadding,
    marginHorizontal: spacing.screen,
    marginBottom: spacing.cardGap,
  },
  kringKop: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
  },
  kringIcon: {
    width: 34,
    height: 34,
    borderRadius: 17,
    backgroundColor: colors.tintBlue,
    alignItems: 'center',
    justifyContent: 'center',
  },
  kringKopText: { flex: 1 },
  // Tikdoel van minimaal 44pt: het losse kruisje was te klein om te raken.
  sluitKnop: {
    width: 44,
    height: 44,
    alignItems: 'center',
    justifyContent: 'center',
  },
  sluitKruis: {
    color: colors.inkSoft,
  },
  kringMeta: {
    fontSize: 13,
  },
  kringKnop: {
    marginTop: spacing.md,
  },
  kringFout: {
    color: colors.error,
    marginTop: spacing.sm,
    textAlign: 'center',
  },
  kringNote: {
    marginTop: spacing.sm,
    fontSize: 12.5,
    color: colors.inkFaint,
    textAlign: 'center',
  },
  kringGoed: {
    backgroundColor: colors.successBg,
    borderRadius: radius.row,
    padding: spacing.md,
    marginTop: spacing.md,
  },
  kringGoedText: {
    color: colors.successText,
    textAlign: 'center',
  },
  bottomLayer: {
    position: 'absolute',
    left: 0,
    right: 0,
    bottom: 96,
  },
});

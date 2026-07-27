# ADR-0004 — Kaart: react-native-maps (Apple/Google) achter eigen abstractie

**Status:** geaccepteerd (2026-07-27)

**Context:** De buurtkaart is een kernscherm. Opdrachtgever kiest nu Apple Maps (gratis, native) maar wil in de toekomst mogelijk een eigen kaartstijl (à la Mapbox).

**Keuze:** `react-native-maps` (Apple Maps op iOS, Google Maps op Android) met alle custom markers als eigen componenten. Eén eigen `features/map/MapView`-wrapper vormt de enige plek die `react-native-maps` importeert, zodat een latere overstap naar Mapbox alleen die wrapper raakt. PostGIS in Supabase voor "wat is er in beeld"-queries en de ~1 km-vervaging vóór toestemming.

**Alternatieven:** Mapbox (stijlbaar maar betaald en extra native config), Leaflet-webview (matige UX in RN).

**Gevolg:** geen kaartkosten in de pilot; Android heeft een Google Maps API-key nodig bij de Android-release; custom stijl later mogelijk zonder herbouw van schermen.

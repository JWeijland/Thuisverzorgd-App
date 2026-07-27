# ADR-0003 — Video: Daily.co voor de videokennismaking

**Status:** geaccepteerd (2026-07-27)

**Context:** De videokennismaking (beheerder ↔ onbekende vrijwilliger) vereist 1-op-1 video met eigen UI. De legacy-app gebruikte Daily.co al succesvol via een edge function die room + kortlopend token uitgeeft.

**Keuze:** Daily.co met `@daily-co/react-native-daily-js`; room-aanmaak en meeting-tokens via een Supabase Edge Function (API-key blijft server-side), UI volledig zelf conform het ontwerp (screen 22).

**Alternatieven:** LiveKit (goede RN-SDK maar meer zelf hosten/configureren), Twilio Video (wordt uitgefaseerd), WebRTC kaal (te veel werk).

**Gevolg:** gratis tier (~10.000 deelnemersminuten/maand) volstaat voor de pilot; bewezen patroon uit legacy kan worden overgenomen.

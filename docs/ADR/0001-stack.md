# ADR-0001 — Stack: Expo + expo-router + Supabase + TanStack Query/Zustand

**Status:** geaccepteerd (2026-07-27)

**Context:** Productieklare mobiele app voor iOS én Android, door één ontwikkelaar/AI te onderhouden, met realtime features, magic-link auth en strenge privacy-eisen. De superprompt schrijft de stack grotendeels voor.

**Keuze:** Expo SDK (laatste stabiele) met expo-router en TypeScript strict; Supabase (Postgres/Auth/Realtime/Storage/Edge Functions); TanStack Query voor server-state, Zustand voor lokale UI-state; react-hook-form + zod (schema's gedeeld met Edge Functions); eigen `theme.ts` + primitives, geen UI-library; react-native-reanimated; Jest + RNTL, Maestro voor e2e.

**Alternatieven:** kale React Native CLI (meer onderhoud, geen EAS-gemak), Flutter (geen hergebruik van web-kennis, ontwerp is RN-gericht), Firebase (geen relationele RLS, Postgres nodig voor PostGIS en views).

**Gevolg:** één codebase voor iOS/Android/web (makelaar-console en admin als web-routes), file-based routing die 1-op-1 op de schermstructuur past, RLS als centrale beveiligingslaag.

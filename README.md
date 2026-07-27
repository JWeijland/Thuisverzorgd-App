# Thuisverzorgd

Nederlandse app die mantelzorgers ontlast door hulp uit de buurt te organiseren in **hulpkringen**: een klein, vast groepje vrijwilligers rond één hulpvrager. Gebouwd met Expo/React Native + Supabase.

> "Zorg dichtbij, geregeld door de buurt."

## In 15 minuten draaien

**Vereisten:** Node 22+, npm, een iPhone/simulator (of Android), en toegang tot het Supabase-project.

```bash
git clone https://github.com/JWeijland/Thuisverzorgd-App.git
cd Thuisverzorgd-App/apps/mobile
npm install
cp .env.example .env        # vul de twee EXPO_PUBLIC_-waarden in (zie hieronder)
npx expo start              # scan de QR met Expo Go, of druk i voor de iOS-simulator
```

`.env` heeft twee waarden nodig, te vinden in het [Supabase-dashboard](https://supabase.com/dashboard/project/pfvxgzosntzzhydzzkaj/settings/api-keys): de project-URL en de publishable (anon) key.

**Demo-accounts** (na `node scripts/seed-demo.mjs`, wachtwoord `DemoThuisverzorgd1!`):
`demo-beheerder@` · `demo-anna@` · `demo-tim@` · `demo-riet@` · `demo-makelaar@` · `demo-admin@` (allemaal `...thuisverzorgd.dev`). In de app log je normaal in met een magic link; voor demo-accounts kan het ook met wachtwoord via een klein testscript of het dashboard.

**Let op:** pushmeldingen, de magic-link-deeplink (`tvz://`) en de kaart-permissies werken volledig in een **development build** (`npx expo run:ios`) of TestFlight; in Expo Go werkt vrijwel alles behalve remote push.

## Structuur

```
apps/mobile/            de Expo-app
  src/app/              expo-router routes: (auth), (tabs), modals
  src/features/         circles, tasks, spontaneous, forum, notifications, subscription, map, onboarding
  src/theme/            design tokens (kleuren/typografie/radii uit docs/design)
  src/ui/               eigen primitives (Button, Card, Chip, Coachmark, ...)
  src/i18n/nl.json      alle UI-copy
  scripts/              rls-smoke.mjs (RLS-bewijs), seed-demo.mjs (demo-data)
supabase/
  migrations/           volledig schema + RLS + triggers (genummerd)
  functions/            send-push, delete-account, cleanup-id-documents
docs/
  design/               de leidende design-handoff (README + screenshots + brandbook)
  PLAN.md               voortgang per fase · ANALYSE.md · ADR/ · REVIEW-fase-11.md
```

## Commando's

In `apps/mobile/`:

| Commando | Doet |
|---|---|
| `npm run lint` / `typecheck` / `test` | kwaliteitschecks (draaien ook in CI) |
| `node scripts/rls-smoke.mjs` | bewijst de RLS-regels tegen de echte database (23 checks) |
| `node scripts/seed-demo.mjs` | vult demo-data (vereist service-role-key in env) |

Supabase (repo-root): `supabase db push` voor migraties, `npx supabase@latest functions deploy <naam> --use-api` voor edge functions. Nooit handmatig in de dashboard-UI klikken.

## Builds (EAS)

```bash
cd apps/mobile
npx eas-cli login                      # eenmalig
npx eas-cli build --profile development --platform ios    # dev-build op je toestel
npx eas-cli build --profile production --platform ios     # TestFlight
npx eas-cli submit --platform ios
```

EAS-project: `jelleweijlands-team/thuisverzorgd`. Bundle-ID `nl.thuisverzorgd.app`, scheme `tvz://`.

## Belangrijk om te weten

- **`docs/design/README.md` is de leidende specificatie** — bouw pixel-precies, neem waarden letterlijk over.
- Het woord "mantelzorger" komt niet in de UI voor (het heet "beheerder"); geen VOG, geen gamification, geen check-in/out.
- Alle autorisatie zit in de database (RLS + security-definer-RPC's); de client is nooit de plek voor beveiligingslogica.
- Locaties zijn overal op wijkniveau (~1 km) tot er expliciete toestemming is; ID-documenten worden na 30 dagen automatisch verwijderd.
- Openstaande punten en besluiten staan in `docs/PLAN.md`.

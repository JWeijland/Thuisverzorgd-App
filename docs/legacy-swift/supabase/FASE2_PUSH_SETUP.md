# Fase 2 — Pushnotificaties (APNs) aanzetten

De code is klaar (client + Edge Function). Hieronder de stappen die **jij** in
Apple en Supabase moet doen om de pushes echt te laten werken. Volg ze in volgorde.

---

## Stap 1 — APNs Auth Key (.p8) aanmaken

> **Waar:** https://developer.apple.com/account → **Certificates, Identifiers & Profiles** → **Keys**

1. Klik op **＋** (nieuwe key).
2. Geef een naam, bijv. `Thuisverzorgd APNs`.
3. Vink **Apple Push Notifications service (APNs)** aan.
4. Klik **Continue** → **Register**.
5. **Download** het `.p8`-bestand. ⚠️ Dit kan maar **één keer** — bewaar het goed.
6. Noteer:
   - **Key ID** (10 tekens, staat bij de key).
   - **Team ID** (rechtsboven in je account, of onder Membership).

---

## Stap 2 — Push aanzetten op de App ID

> **Waar:** zelfde portal → **Identifiers** → je app `com.JelleWeijland.Buddie-Care`

1. Open de identifier.
2. Vink **Push Notifications** aan (Capabilities).
3. **Save**.

> Bij automatische signing in Xcode wordt dit meestal al geregeld zodra je
> stap 3 doet, maar controleer dat het hier aanstaat.

---

## Stap 3 — Push-capability in Xcode

> **Waar:** Xcode → project **Buddy Care** → target → **Signing & Capabilities**

1. Klik **＋ Capability** → voeg **Push Notifications** toe.
   (De entitlement `aps-environment` staat al in `Buddy Care.entitlements`.)
2. Controleer dat **Automatically manage signing** aanstaat met je team.

---

## Stap 4 — Secrets in Supabase zetten

> **Waar:** terminal in de projectmap (Supabase CLI: `brew install supabase/tap/supabase`),
> of via Dashboard → Edge Functions → Secrets.

Eenmalig inloggen + koppelen:
```bash
supabase login
supabase link --project-ref fgavamsvbtxwmlfkfvgp
```

Secrets zetten (vervang de waarden):
```bash
supabase secrets set APNS_KEY_ID=ABC123DEFG
supabase secrets set APNS_TEAM_ID=5QFB2FHYYQ        # jouw Team ID
supabase secrets set APNS_BUNDLE_ID=com.JelleWeijland.Buddie-Care
supabase secrets set APNS_PRIVATE_KEY="$(cat ~/Downloads/AuthKey_ABC123DEFG.p8)"
```

> De laatste regel leest het hele `.p8`-bestand in. Let op de quotes.

---

## Stap 5 — Edge Function deployen

```bash
supabase functions deploy notify-new-task
```

De functiecode staat in `supabase/functions/notify-new-task/index.ts`.

Test handmatig (optioneel) — zou `{"sent":0,...}` of een aantal moeten geven:
```bash
curl -X POST \
  "https://fgavamsvbtxwmlfkfvgp.supabase.co/functions/v1/notify-new-task" \
  -H "Authorization: Bearer <SUPABASE_ANON_KEY>" \
  -H "Content-Type: application/json" \
  -d '{"record":{"status":"open","elderly_first_name":"Test","category":"companionship"}}'
```

---

## Stap 6 — Database Webhook koppelen aan de functie

> **Waar:** Supabase Dashboard → **Database** → **Webhooks** → **Create a new hook**

1. **Name:** `on-new-task`
2. **Table:** `tasks`
3. **Events:** alleen **Insert**
4. **Type:** **Supabase Edge Functions**
5. **Edge Function:** `notify-new-task`
6. **HTTP Method:** POST (standaard)
7. **Save**.

Hierdoor wordt bij elke nieuwe taak automatisch de functie aangeroepen, die de
push naar alle buddies stuurt.

---

## Stap 7 — Testen op een écht toestel

> Push werkt **niet** in de simulator — gebruik een echte iPhone (of TestFlight).

1. Installeer de app op twee toestellen (of via TestFlight).
2. Log op toestel A in als **buddy** → geef toestemming voor meldingen.
   (Controleer in Supabase → Table Editor → `device_tokens` dat er een rij met
   `role = buddy` is bijgekomen.)
3. Log op toestel B in als **ouder** → maak een hulpvraag aan.
4. Toestel A hoort binnen enkele seconden een pushmelding te krijgen. 🎉

---

## Belangrijk over omgevingen (sandbox vs productie)

- Een build die je **vanuit Xcode** op je iPhone zet, gebruikt de **sandbox**-APNs.
- Een **TestFlight/App Store**-build gebruikt **productie**-APNs.

De Edge Function probeert eerst productie en valt automatisch terug op sandbox
bij `BadDeviceToken`, dus beide werken zonder extra configuratie.

## Foutopsporing

- Logs van de functie: Supabase Dashboard → Edge Functions → `notify-new-task` → Logs.
- Geen push maar wel `sent > 0`? Check meldingsrechten op het toestel.
- `sent: 0`? Dan staat er nog geen buddy-token in `device_tokens` (log eerst in als buddy).

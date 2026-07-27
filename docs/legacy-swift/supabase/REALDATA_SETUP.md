# Echte data in de TestFlight-versie — Supabase-checklist

De app start nu standaard op de **echte login** (e-mail + wachtwoord → Supabase) in
plaats van het mock-rolscherm. Zodra een tester inlogt, draait alles op echte
Supabase-data: profielen, hulpvragen, accepteren door buddy's en pushtokens.

Hieronder staat wat er aan de Supabase-kant moet kloppen. Het meeste is al gedaan
(zie de opmerking in `Services/SupabaseManager.swift`), maar loop het even na op het
**nieuwe** project `fgavamsvbtxwmlfkfvgp`.

---

## 1. Database-schema — al gedraaid? Verifieer

Het schema en de migratie horen al op het nieuwe project te staan. Controleer in
**Supabase → Table Editor** of deze tabellen bestaan:

- `profiles`, `elderly_profiles`, `buddy_profiles`, `family_profiles`
- `tasks`, `reviews`, `device_tokens`, `partner_codes`, `linking_codes`

**Zo niet**, draai eenmalig in **Supabase → SQL Editor → New query → Run**:

1. De inhoud van [`supabase/schema.sql`](schema.sql) (alle tabellen, RLS, triggers).
2. Daarna [`supabase/migrations/fase1_live_and_push.sql`](migrations/fase1_live_and_push.sql)
   (idempotent — meermaals draaien kan geen kwaad).

> Geen extra/nieuwe SQL nodig voor de kern-loop (cliënt plaatst hulpvraag →
> buddy ziet & accepteert). Dat werkt op het bestaande schema.

---

## 2. E-mailbevestiging UIT (belangrijk voor testers)

Standaard eist Supabase dat een nieuw account z'n e-mail bevestigt. Voor een snelle
beta is dat hinderlijk. Zet het uit zodat testers meteen kunnen inloggen na
registreren:

> **Supabase → Authentication → Providers → Email** → **"Confirm email"** UIT zetten.

(Laat je het AAN staan, dan moet elke tester eerst op de bevestigingslink in z'n
mail klikken. Werkt ook, maar trager.)

---

## 3. Een cliënt aanmelden zonder koppelcode

De koppelcode-gate voor cliënten valideert nu nog tegen testdata, niet tegen de
echte `partner_codes`-tabel. Voor de beta is daarom een knop **"Verder zonder
koppelcode"** zichtbaar op het cliënt-scherm — testers komen zo altijd door naar
het echte hulpvraag-scherm.

> **Later (productie):** koppel `AppState.redeem(...)` aan
> `TaskService.validatePartnerCode(...)` en seed echte codes, bijv.:
> ```sql
> INSERT INTO partner_codes (code, partner_name, partner_type, is_active)
> VALUES ('TEST2026', 'Testgemeente', 'gemeente', true);
> ```

---

## 4. Pushnotificaties (optioneel voor de eerste test)

De app slaat pushtokens al op in `device_tokens`. Om écht pushes te versturen bij
een nieuw hulpverzoek moet de Edge Function `notify-new-task` gedeployed zijn en
moeten de APNs-secrets gezet zijn. Zie `supabase/FASE2_PUSH_SETUP.md`. Niet nodig
om de kern-loop te testen — testers zien nieuwe taken sowieso via de 5-seconden poll.

---

## 5. Snel testen (de echte loop)

1. Tester A registreert als **buddy** → doorloopt korte onboarding → opent de kaart.
2. Tester B registreert als **cliënt/oudere** → "Verder zonder koppelcode" →
   maakt een hulpvraag aan.
3. Binnen ~5 sec verschijnt die hulpvraag op de kaart van de buddy → accepteren.

Beide accounts en de hulpvraag staan nu echt in Supabase (Table Editor → `tasks`).

# Intake-wachtrij → pushmelding naar de admin

Wanneer een buddy een intake-videogesprek start, komt er een rij in `intake_calls`
(status `waiting`). De edge function **`notify-intake-call`** stuurt dan een
pushnotificatie naar alle admins ("Intake-gesprek in de wachtrij — neem op").

De functie is al **gedeployed** en haalt de admin-device-tokens op (`device_tokens`
met `role = 'admin'`). Het enige wat nog moet: de **Database Webhook** die de functie
afvuurt bij een nieuwe rij. Dit is exact dezelfde stap als de bestaande `on-new-task`
webhook (zie FASE2_PUSH_SETUP.md), maar dan voor `intake_calls`.

## Webhook aanmaken

> **Waar:** Supabase Dashboard → **Database** → **Webhooks** → **Create a new hook**

1. **Name:** `on-intake-call`
2. **Table:** `intake_calls`
3. **Events:** alleen **Insert**
4. **Type:** **Supabase Edge Functions**
5. **Edge Function:** `notify-intake-call`
6. **HTTP Method:** POST (standaard)
7. **Save**

## Testen (op een écht toestel — push werkt niet in de simulator)

1. Log op toestel A in als **admin** → geef toestemming voor meldingen.
   (Check in Supabase → Table Editor → `device_tokens` dat er een rij met
   `role = admin` staat.)
2. Log op toestel B in als **buddy** (VOG al goedgekeurd) → tik
   **Start intake-videogesprek**.
3. Toestel A (admin) hoort binnen enkele seconden de pushmelding te krijgen. 🎉

## Foutopsporing

- Logs: Supabase Dashboard → Edge Functions → `notify-intake-call` → Logs.
- "geen admin-tokens" in de log → er staat (nog) geen admin met meldingen aan in
  `device_tokens`.

---

# VOG-controle → pushmelding naar de admin

Zodra een buddy een VOG **aanvraagt** (`vog_status = 'aangevraagd'`) of een document
**indient** (`vog_status = 'in_behandeling'`), stuurt de edge function
**`notify-vog-review`** een push naar alle admins ("Nieuwe VOG om te controleren").

De functie is al **gedeployed**. Ze pusht ALLEEN als `vog_status` nét naar een
wachtstand verandert — alle andere updates op `buddy_profiles` (beschikbaarheid,
locatie, bio…) worden genegeerd.

## Webhook aanmaken

> **Waar:** Supabase Dashboard → **Database** → **Webhooks** → **Create a new hook**

1. **Name:** `on-vog-review`
2. **Table:** `buddy_profiles`
3. **Events:** alleen **Update**
4. **Type:** **Supabase Edge Functions**
5. **Edge Function:** `notify-vog-review`
6. **HTTP Method:** POST (standaard)
7. **Save**

> Belangrijk: kies **Update** (niet Insert) — de VOG-status wordt via een UPDATE
> gezet. De functie filtert zelf op een échte statuswijziging, dus de webhook mag
> gerust bij elke update afgaan.

## Testen

1. Admin op toestel A met meldingen aan.
2. Buddy op toestel B → profiel → **Ik heb al een VOG — uploaden** (of in de
   onboarding **VOG aanvragen**).
3. Toestel A krijgt de pushmelding. 🎉

Logs: Edge Functions → `notify-vog-review` → Logs.

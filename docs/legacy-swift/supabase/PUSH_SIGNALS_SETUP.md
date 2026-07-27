# Pushmeldingen — setup (fase22)

Alle code staat klaar. Dit zijn de handmatige Supabase-stappen om de meldingen
live te zetten. APNs-secrets uit `FASE2_PUSH_SETUP.md` moeten al gezet zijn.

## 1. Migratie draaien
Draai `supabase/migrations/fase22_push_signals.sql` (voegt buddy-locatie,
mijlpaal-/competitievlaggen, throttles, ranks en de inbox-kolom toe).

## 2. Edge functions deployen
```
supabase functions deploy notify-new-task
supabase functions deploy notify-team-milestone
supabase functions deploy notify-scheduled
```
(`_shared/apns.ts` wordt automatisch meegenomen.)

## 3. Database-webhooks (Dashboard → Database → Webhooks)
- **tasks · INSERT** → `notify-new-task`  (hulpvraag in je buurt)
- **point_events · INSERT** → `notify-team-milestone`  (team 75% / 100%)

Beide met header `Authorization: Bearer <SERVICE_ROLE_KEY>`.

## 4. Dagelijkse cron (tijdgebonden meldingen)
Zet de extensies aan (Database → Extensions): **pg_cron** en **pg_net**.
Draai daarna onderstaand blok één keer met je eigen waarden ingevuld
(zie ook het comment-sjabloon onderaan `fase22_push_signals.sql`):

```sql
select cron.schedule(
  'notify-scheduled-daily',
  '0 9 * * *',                       -- elke dag 09:00 UTC
  $$
  select net.http_post(
    url     := 'https://<PROJECT-REF>.functions.supabase.co/notify-scheduled',
    headers := jsonb_build_object(
      'Content-Type','application/json',
      'Authorization','Bearer <SERVICE_ROLE_KEY>'
    ),
    body    := '{}'::jsonb
  );
  $$
);
```
Handmatig testen kan met dezelfde `net.http_post`-aanroep, of door de functie-URL
direct te POST'en.

## Welke meldingen
| Trigger | Functie | Melding |
|--------|---------|---------|
| Nieuwe hulpvraag | notify-new-task | Beschikbare buddies binnen `max_distance_km` + 5 km |
| Team 75% / 100% | notify-team-milestone | Teamleden ("prijs innen" bij 100%) |
| Buddy ≥2 dagen inactief + werk in de buurt | notify-scheduled | "Je buurt heeft je nodig" |
| Cliënt ≥3 dagen geen hulpvraag | notify-scheduled | "Kan je wel wat hulp gebruiken?" |
| Familie van stille cliënt | notify-scheduled | Zelfde seintje |
| Competitie bijna af / afgerond (top-3) / ranglijst-wissel | notify-scheduled | Zie functie |

Alles komt ook in de in-app berichten-inbox (tabel `notifications`).

## Throttling / niet-dubbel
- Teams: `milestone_75_notified` / `milestone_100_notified`.
- Competitie: `ending_soon_notified` / `finished_notified` + `competition_participants.last_rank`.
- Buddy: `last_neighborhood_push_at` (max 1×/2 dagen).
- Cliënt/familie: `last_help_reminder_at` / `profiles.last_family_reminder_at` (max 1×/3 dagen).

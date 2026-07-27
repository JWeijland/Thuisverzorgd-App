// ============================================================
// Edge Function: schedule-watchdog (cron, elke minuut — zie fase35_zorgkring.sql)
//
// Bewaakt de zorgkring-afspraken en de fallback op losse buddies:
//
// A. Schemamomenten (care_team_visits, nog niet geclaimd):
//    - nieuw moment           → "claim jouw plekken"-melding aan het team
//    - 48 uur vooraf          → 1e herinnering aan het team
//    - 24 uur vooraf          → 2e herinnering aan het team
//    - 30 minuten vooraf      → urgente broadcast aan beschikbare buddies in
//      de buurt (alleen als de hulpvrager fallback toestaat; anders een
//      melding aan hulpvrager/familie dat het moment onvervuld blijft)
//
// A2. Shift-herinnering (fase36): 2 uur vóór een GECLAIMD moment krijgt de
//     buddy die het heeft opgepakt een pushmelding (claim_reminder_sent).
//
// B. Spontane hulpvragen (tasks):
//    - team-exclusief venster (8 min) verlopen → naar de open pool + broadcast
//      binnen 2,5 km
//    - 10 min later nog open (alleen 'nu'-vragen) → bredere broadcast tot 5 km
//    - 15 min later nog open → excuses aan hulpvrager/familie + advies om een
//      team te bouwen (als die er nog niet is)
//    Altijd binnen de eigen straal (max_distance_km) van elke buddy.
//
// Secrets: APNS_KEY_ID, APNS_TEAM_ID, APNS_BUNDLE_ID, APNS_PRIVATE_KEY.
// ============================================================

import { serviceClient, notifyUsers, haversineKm } from "../_shared/apns.ts";
import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

const POOL_RADIUS_KM = 2.5;   // eerste fallback-ring
const WIDE_RADIUS_KM = 5;     // maximale fallback-ring (antwoord 19)
const SHIFT_REMINDER_HOURS = 2; // shift-herinnering aan de geclaimde buddy
const FRESH_MINUTES = 30;     // verse live-locatie telt zwaarder dan thuisadres
const WIDEN_AFTER_MIN = 10;   // pool → 5 km
const GIVE_UP_AFTER_MIN = 15; // 5 km → excuses

const CATEGORY_LABELS: Record<string, string> = {
  companionship: "gezelschap",
  walk_outdoors: "samen wandelen",
  groceries: "boodschappen",
  activity: "samen iets doen",
  digital_help: "digitale hulp",
  social_support: "een luisterend oor",
  light_cleaning: "hand-en-spandiensten",
  appointment: "begeleiding naar een afspraak",
  other: "hulp",
};

interface BuddyLoc {
  id: string;
  latitude: number | null;
  longitude: number | null;
  current_latitude: number | null;
  current_longitude: number | null;
  location_updated_at: string | null;
  max_distance_km: number | null;
}

/** Beschikbare buddies binnen [minKm, maxKm] van (lat, lon), binnen hun eigen straal. */
async function nearbyAvailable(
  supabase: SupabaseClient,
  lat: number | null,
  lon: number | null,
  minKm: number,
  maxKm: number,
  exclude: Set<string>,
): Promise<string[]> {
  const { data } = await supabase
    .from("buddy_profiles")
    .select("id, latitude, longitude, current_latitude, current_longitude, location_updated_at, max_distance_km")
    .eq("is_available_now", true);
  const freshCutoff = Date.now() - FRESH_MINUTES * 60 * 1000;

  return ((data ?? []) as BuddyLoc[]).filter((b) => {
    if (exclude.has(b.id)) return false;
    if (lat == null || lon == null) return minKm === 0; // geen coördinaat → alleen 1e ring
    const currentFresh = b.current_latitude != null && b.current_longitude != null &&
      b.location_updated_at != null &&
      new Date(b.location_updated_at).getTime() >= freshCutoff;
    let bLat: number | null = null, bLon: number | null = null;
    if (currentFresh) { bLat = b.current_latitude; bLon = b.current_longitude; }
    else if (b.latitude != null && b.longitude != null) { bLat = b.latitude; bLon = b.longitude; }
    if (bLat == null || bLon == null) return minKm === 0; // locatie onbekend → 1e ring
    const d = haversineKm(lat, lon, bLat, bLon);
    // De eigen straal van de buddy blijft altijd leidend.
    return d > minKm && d <= Math.min(maxKm, b.max_distance_km ?? 10);
  }).map((b) => b.id);
}

Deno.serve(async (_req) => {
  try {
    const supabase = serviceClient();
    const now = Date.now();
    const summary: Record<string, number> = {
      newVisit: 0, rem48: 0, rem24: 0, urgent: 0, unfilled: 0,
      shiftReminder: 0, toPool: 0, widened: 0, gaveUp: 0,
    };

    // =====================================================================
    // A. Schemamomenten
    // =====================================================================
    const { data: visits } = await supabase
      .from("care_team_visits")
      .select("id, care_team_id, category, scheduled_at, team_notified, " +
        "reminder_48_sent, reminder_24_sent, urgent_sent, claimed_by")
      .is("claimed_by", null)
      .gte("scheduled_at", new Date(now).toISOString());

    // Teams van deze bezoeken in één keer ophalen.
    const teamIds = [...new Set((visits ?? []).map((v: { care_team_id: string }) => v.care_team_id))];
    const teamById = new Map<string, Record<string, unknown>>();
    if (teamIds.length) {
      const { data: teamRows } = await supabase
        .from("care_teams")
        .select("id, elderly_id, elderly_name, status, fallback_allowed, " +
          "approx_latitude, approx_longitude, care_team_members(buddy_id)")
        .in("id", teamIds);
      for (const t of teamRows ?? []) teamById.set(t.id, t);
    }

    for (const visit of visits ?? []) {
      const team = teamById.get(visit.care_team_id) as {
        id: string; elderly_id: string | null; elderly_name: string | null;
        status: string; fallback_allowed: boolean;
        approx_latitude: number | null; approx_longitude: number | null;
        care_team_members: { buddy_id: string }[];
      } | undefined;
      if (!team || team.status === "paused") continue;

      const memberIds = (team.care_team_members ?? []).map((m) => m.buddy_id);
      const firstName = team.elderly_name || "de hulpvrager";
      const catLabel = CATEGORY_LABELS[visit.category] ?? "hulp";
      const when = new Date(visit.scheduled_at);
      const hoursLeft = (when.getTime() - now) / 3600000;
      const whenText = when.toLocaleString("nl-NL", {
        timeZone: "Europe/Amsterdam", weekday: "long", day: "numeric",
        month: "long", hour: "2-digit", minute: "2-digit",
      });

      if (!visit.team_notified) {
        if (memberIds.length) {
          await notifyUsers(supabase, memberIds, {
            kind: "slot_new",
            title: `Nieuw moment voor ${firstName}`,
            body: `${whenText}: ${catLabel}. Claim jouw plek in het schema.`,
            careTeamId: team.id,
          });
        }
        // Een moment dat al binnen het 48u-/24u-venster wordt aangemaakt slaat
        // die herinneringen over (anders stapelen ze direct op de nieuw-melding);
        // de urgente 30-min-broadcast blijft altijd staan.
        await supabase.from("care_team_visits")
          .update({
            team_notified: true,
            reminder_48_sent: hoursLeft <= 48,
            reminder_24_sent: hoursLeft <= 24,
          }).eq("id", visit.id);
        summary.newVisit++;
        continue;
      }

      if (hoursLeft <= 48 && !visit.reminder_48_sent) {
        if (memberIds.length) {
          await notifyUsers(supabase, memberIds, {
            kind: "slot_reminder_48",
            title: `Nog niemand ingepland voor ${firstName}`,
            body: `${whenText} (${catLabel}) is nog niet geclaimd. Kun jij dit moment oppakken?`,
            careTeamId: team.id,
          });
        }
        await supabase.from("care_team_visits")
          .update({ reminder_48_sent: true }).eq("id", visit.id);
        summary.rem48++;
        continue;
      }

      if (hoursLeft <= 24 && !visit.reminder_24_sent) {
        if (memberIds.length) {
          await notifyUsers(supabase, memberIds, {
            kind: "slot_reminder_24",
            title: `Morgen nog niemand bij ${firstName}`,
            body: `${whenText} (${catLabel}) is nog steeds niet geclaimd. Laatste kans voor het team!`,
            careTeamId: team.id,
          });
        }
        await supabase.from("care_team_visits")
          .update({ reminder_24_sent: true, reminder_48_sent: true }).eq("id", visit.id);
        summary.rem24++;
        continue;
      }

      if (hoursLeft <= 0.5 && !visit.urgent_sent) {
        if (team.fallback_allowed) {
          const exclude = new Set<string>([...memberIds, team.elderly_id ?? ""]);
          const pool = await nearbyAvailable(
            supabase, team.approx_latitude, team.approx_longitude,
            0, WIDE_RADIUS_KM, exclude,
          );
          if (pool.length) {
            await notifyUsers(supabase, pool, {
              kind: "slot_urgent",
              title: `${firstName} heeft zo hulp nodig`,
              body: `Om ${when.toLocaleTimeString("nl-NL", { timeZone: "Europe/Amsterdam", hour: "2-digit", minute: "2-digit" })} staat er ${catLabel} gepland en er is nog niemand. Kun jij nú bijspringen?`,
              careTeamId: team.id,
            });
          }
          summary.urgent++;
        } else {
          // Hulpvrager wil geen willekeurige buddies: alleen haar en familie informeren.
          const { data: fam } = await supabase
            .from("family_elderly_links").select("family_id")
            .eq("elderly_id", team.elderly_id);
          const managers = [team.elderly_id, ...(fam ?? []).map(
            (f: { family_id: string }) => f.family_id,
          )].filter(Boolean) as string[];
          await notifyUsers(supabase, managers, {
            kind: "slot_unfilled",
            title: "Moment nog niet vervuld",
            body: `Voor ${whenText} heeft nog geen teamlid zich aangemeld.`,
            careTeamId: team.id,
          });
          summary.unfilled++;
        }
        await supabase.from("care_team_visits")
          .update({ urgent_sent: true, reminder_24_sent: true, reminder_48_sent: true })
          .eq("id", visit.id);
      }
    }

    // =====================================================================
    // A2. Shift-herinnering (fase36): 2 uur vóór een geclaimd moment een
    //     pushmelding aan de buddy die het heeft opgepakt.
    // =====================================================================
    const reminderWindow = new Date(now + SHIFT_REMINDER_HOURS * 3600000).toISOString();
    const { data: upcomingClaims } = await supabase
      .from("care_team_visits")
      .select("id, care_team_id, category, scheduled_at, claimed_by")
      .not("claimed_by", "is", null)
      .eq("claim_reminder_sent", false)
      .gte("scheduled_at", new Date(now).toISOString())
      .lte("scheduled_at", reminderWindow);

    for (const visit of upcomingClaims ?? []) {
      const { data: team } = await supabase
        .from("care_teams").select("id, elderly_name")
        .eq("id", visit.care_team_id).maybeSingle();
      const firstName = team?.elderly_name || "de hulpvrager";
      const catLabel = CATEGORY_LABELS[visit.category] ?? "hulp";
      const timeText = new Date(visit.scheduled_at).toLocaleTimeString("nl-NL", {
        timeZone: "Europe/Amsterdam", hour: "2-digit", minute: "2-digit",
      });
      await notifyUsers(supabase, [visit.claimed_by], {
        kind: "shift_reminder",
        title: `Zo naar ${firstName}`,
        body: `Om ${timeText} staat jouw moment gepland: ${catLabel} bij ${firstName}. Veel plezier!`,
        careTeamId: visit.care_team_id,
      });
      await supabase.from("care_team_visits")
        .update({ claim_reminder_sent: true }).eq("id", visit.id);
      summary.shiftReminder++;
    }

    // =====================================================================
    // B. Spontane hulpvragen (tasks)
    // =====================================================================

    // B1. Team-exclusief venster verlopen → naar de pool + buurt-broadcast.
    const { data: expired } = await supabase
      .from("tasks")
      .select("id, elderly_id, elderly_first_name, elderly_latitude, elderly_longitude, category")
      .eq("status", "open").eq("visibility", "team")
      .lte("team_exclusive_until", new Date(now).toISOString());

    for (const task of expired ?? []) {
      await supabase.from("tasks")
        .update({
          visibility: "pool", fallback_stage: 2,
          fallback_stage_at: new Date(now).toISOString(),
        })
        .eq("id", task.id).eq("status", "open");

      const firstName = task.elderly_first_name ?? "Iemand in de buurt";
      const catLabel = CATEGORY_LABELS[task.category] ?? "hulp";
      const pool = await nearbyAvailable(
        supabase, task.elderly_latitude, task.elderly_longitude,
        0, POOL_RADIUS_KM, new Set([task.elderly_id ?? ""]),
      );
      if (pool.length) {
        await notifyUsers(supabase, pool, {
          kind: "new_task_nearby",
          title: "Hulpvraag in je buurt",
          body: `${firstName} zoekt ${catLabel}. Kun jij helpen?`,
          taskId: task.id,
        });
      }
      summary.toPool++;
    }

    // B2. Nog open na 10 min in de pool → bredere ring tot 5 km ('nu'-vragen).
    const widenCutoff = new Date(now - WIDEN_AFTER_MIN * 60000).toISOString();
    const { data: widen } = await supabase
      .from("tasks")
      .select("id, elderly_id, elderly_first_name, elderly_latitude, elderly_longitude, category, fallback_stage_at, created_at")
      .eq("status", "open").eq("visibility", "pool")
      .eq("timing_type", "now").lte("fallback_stage", 2);

    for (const task of widen ?? []) {
      const ref = task.fallback_stage_at ?? task.created_at;
      if (!ref || ref > widenCutoff) continue;
      await supabase.from("tasks")
        .update({ fallback_stage: 3, fallback_stage_at: new Date(now).toISOString() })
        .eq("id", task.id).eq("status", "open");

      const firstName = task.elderly_first_name ?? "Iemand in de buurt";
      const catLabel = CATEGORY_LABELS[task.category] ?? "hulp";
      // Alleen de buitenste ring (2,5–5 km): de binnenste is al bereikt.
      const pool = await nearbyAvailable(
        supabase, task.elderly_latitude, task.elderly_longitude,
        POOL_RADIUS_KM, WIDE_RADIUS_KM, new Set([task.elderly_id ?? ""]),
      );
      if (pool.length) {
        await notifyUsers(supabase, pool, {
          kind: "new_task_nearby",
          title: "Hulpvraag iets verderop",
          body: `${firstName} zoekt ${catLabel} en er is nog niemand gevonden. Kun jij helpen?`,
          taskId: task.id,
        });
      }
      summary.widened++;
    }

    // B3. Nog open na de brede ring → excuses + advies om een team te bouwen.
    const giveUpCutoff = new Date(now - GIVE_UP_AFTER_MIN * 60000).toISOString();
    const { data: giveUp } = await supabase
      .from("tasks")
      .select("id, elderly_id, fallback_stage_at")
      .eq("status", "open").eq("visibility", "pool")
      .eq("timing_type", "now").eq("fallback_stage", 3)
      .lte("fallback_stage_at", giveUpCutoff);

    for (const task of giveUp ?? []) {
      await supabase.from("tasks")
        .update({ fallback_stage: 4, fallback_stage_at: new Date(now).toISOString() })
        .eq("id", task.id).eq("status", "open");

      if (!task.elderly_id) continue;
      const { data: team } = await supabase
        .from("care_teams").select("id, status")
        .eq("elderly_id", task.elderly_id).maybeSingle();
      const hasLiveTeam = team?.status === "live";

      const { data: fam } = await supabase
        .from("family_elderly_links").select("family_id")
        .eq("elderly_id", task.elderly_id);
      const managers = [task.elderly_id, ...(fam ?? []).map(
        (f: { family_id: string }) => f.family_id,
      )].filter(Boolean) as string[];

      await notifyUsers(supabase, managers, {
        kind: "no_buddy_found",
        title: "Helaas, nog geen buddy gevonden",
        body: hasLiveTeam
          ? "Het is ons nog niet gelukt een buddy in de buurt te vinden. Onze excuses — de vraag blijft open staan."
          : "Het is ons nog niet gelukt een buddy in de buurt te vinden. Onze excuses. Tip: met een eigen zorgkring staat er altijd een vast team voor je klaar.",
        taskId: task.id,
      });
      summary.gaveUp++;
    }

    return new Response(JSON.stringify({ ok: true, summary }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("schedule-watchdog fout:", e);
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 });
  }
});

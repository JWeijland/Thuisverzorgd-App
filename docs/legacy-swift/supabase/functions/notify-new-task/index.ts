// ============================================================
// Edge Function: notify-new-task
//
// Database Webhook op INSERT in `tasks`. Stuurt "hulpvraag in je buurt" naar
// BESCHIKBARE buddies die binnen 2,5 km van hun HUIDIGE locatie zitten — zo krijgt
// een buddy ook een melding als hij niet thuis is maar wél vlakbij. De huidige
// locatie wordt door de app bijgehouden (fase27). Is die niet vers, dan vallen
// we terug op het thuisadres; alleen buddies zonder énige locatie krijgen 'm
// altijd (anders blijven ze onzichtbaar). Levert push + inbox.
//
// Secrets: APNS_KEY_ID, APNS_TEAM_ID, APNS_BUNDLE_ID, APNS_PRIVATE_KEY.
// ============================================================

import { serviceClient, notifyUsers, haversineKm } from "../_shared/apns.ts";

const RADIUS_KM = 2.5;        // binnen 2,5 km vanaf de huidige locatie
const FRESH_MINUTES = 30;     // huidige locatie ouder dan dit → val terug op thuis

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

Deno.serve(async (req) => {
  try {
    const payload = await req.json();
    const record = payload.record ?? payload.new ?? payload;

    if (!record || record.status !== "open") {
      return new Response(JSON.stringify({ skipped: true }), {
        headers: { "Content-Type": "application/json" },
      });
    }

    const firstName: string = record.elderly_first_name ?? "Iemand in de buurt";
    const categoryLabel: string = CATEGORY_LABELS[record.category] ?? "hulp";
    const title = "Nieuwe hulpvraag in je buurt";
    const body = `${firstName} zoekt ${categoryLabel}. Kun jij helpen?`;

    const taskLat: number | null = record.elderly_latitude ?? null;
    const taskLon: number | null = record.elderly_longitude ?? null;

    // De aanvrager zelf mag NOOIT de "hulpvraag in je buurt"-push krijgen, ook
    // niet als die persoon óók een (beschikbaar) buddy-profiel heeft of op
    // hetzelfde toestel is ingelogd. Anders krijgt de hulpvrager een melding
    // over zijn eigen verzoek.
    const requesterId: string | null = record.elderly_id ?? null;

    const supabase = serviceClient();

    // Zorgkring-pivot (fase35): een team-exclusieve hulpvraag gaat alléén naar
    // de teamleden van de zorgkring. Na het 8-minutenvenster zet de
    // schedule-watchdog 'm op 'pool' en volgt alsnog de buurt-broadcast.
    if (record.visibility === "team" && requesterId) {
      const { data: team } = await supabase
        .from("care_teams")
        .select("id, care_team_members(buddy_id)")
        .eq("elderly_id", requesterId)
        .maybeSingle();
      const memberIds: string[] = (team?.care_team_members ?? [])
        .map((m: { buddy_id: string }) => m.buddy_id)
        .filter((id: string) => id !== requesterId);
      const result = await notifyUsers(supabase, memberIds, {
        kind: "team_task_new",
        title: `${firstName} heeft hulp nodig`,
        body: `${firstName} uit jouw zorgkring zoekt ${categoryLabel}. Kun jij helpen?`,
        careTeamId: team?.id ?? null,
        taskId: record.id ?? null,
      });
      return new Response(JSON.stringify({ team: true, ...result }), {
        headers: { "Content-Type": "application/json" },
      });
    }

    // Beschikbare buddies + hun huidige locatie (fase27) en thuisadres (fallback).
    const { data: buddies, error } = await supabase
      .from("buddy_profiles")
      .select("id, latitude, longitude, current_latitude, current_longitude, location_updated_at, is_available_now")
      .eq("is_available_now", true);

    if (error) {
      console.error("buddy_profiles ophalen mislukt:", error);
      return new Response(JSON.stringify({ error: error.message }), { status: 500 });
    }

    const freshCutoff = Date.now() - FRESH_MINUTES * 60 * 1000;

    // Filter op 2,5 km vanaf de HUIDIGE locatie (vers), anders het thuisadres.
    // Geen taak-coördinaat of helemaal geen buddy-locatie bekend → toch meenemen.
    const eligible = (buddies ?? []).filter((b: {
      id: string;
      latitude: number | null; longitude: number | null;
      current_latitude: number | null; current_longitude: number | null;
      location_updated_at: string | null;
    }) => {
      // Nooit de aanvrager zelf.
      if (requesterId && b.id === requesterId) return false;

      if (taskLat == null || taskLon == null) return true;

      // Verse huidige locatie heeft voorrang; anders val terug op het thuisadres.
      const currentFresh =
        b.current_latitude != null && b.current_longitude != null &&
        b.location_updated_at != null &&
        new Date(b.location_updated_at).getTime() >= freshCutoff;

      let lat: number | null = null;
      let lon: number | null = null;
      if (currentFresh) {
        lat = b.current_latitude; lon = b.current_longitude;
      } else if (b.latitude != null && b.longitude != null) {
        lat = b.latitude; lon = b.longitude;
      }
      if (lat == null || lon == null) return true; // geen énige locatie → niet onzichtbaar maken

      return haversineKm(taskLat, taskLon, lat, lon) <= RADIUS_KM;
    }).map((b: { id: string }) => b.id);

    if (!eligible.length) {
      return new Response(JSON.stringify({ sent: 0, note: "geen buddies in de buurt" }), {
        headers: { "Content-Type": "application/json" },
      });
    }

    const result = await notifyUsers(supabase, eligible, {
      kind: "new_task_nearby",
      title,
      body,
    });

    return new Response(JSON.stringify(result), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("notify-new-task fout:", e);
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 });
  }
});

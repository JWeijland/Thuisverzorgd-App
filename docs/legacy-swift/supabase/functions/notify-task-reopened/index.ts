// ============================================================
// Edge Function: notify-task-reopened
//
// Wordt door de app (buddy) aangeroepen NADAT die een al-aangenomen hulpvraag
// annuleert en de taak is teruggezet op 'open'. Doet twee dingen:
//
//  1. HULPVRAGER: push + inbox-melding dat de buddy moest annuleren en dat we
//     opnieuw aan het zoeken zijn — zodat de oudere niet voor niets wacht.
//  2. BUDDIES:    re-alert beschikbare buddies in de buurt (zoals bij een nieuwe
//     hulpvraag), zodat er snel een nieuwe buddy oppakt. De buddy die net
//     annuleerde wordt overgeslagen.
//
// We lezen de taak server-side terug en versturen alleen als die ook echt weer
// 'open' staat.
//
// Aanroep vanuit de app: supabase.functions.invoke("notify-task-reopened",
//   options: .init(body: { "taskId": "<uuid>", "cancelledBuddyId": "<uuid>" })).
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
    const payload = await req.json().catch(() => ({}));
    const taskId: string | null = payload.taskId ?? payload.task_id ?? null;
    const cancelledBuddyId: string | null =
      payload.cancelledBuddyId ?? payload.cancelled_buddy_id ?? null;
    if (!taskId) {
      return new Response(JSON.stringify({ error: "taskId ontbreekt" }), { status: 400 });
    }

    const supabase = serviceClient();
    const { data: task, error } = await supabase
      .from("tasks")
      .select("id, status, elderly_id, elderly_first_name, category, elderly_latitude, elderly_longitude")
      .eq("id", taskId)
      .maybeSingle();

    if (error) {
      console.error("taak ophalen mislukt:", error);
      return new Response(JSON.stringify({ error: error.message }), { status: 500 });
    }

    // Alleen melden als de taak ook echt weer openstaat.
    if (!task || task.status !== "open" || !task.elderly_id) {
      return new Response(JSON.stringify({ skipped: true }), {
        headers: { "Content-Type": "application/json" },
      });
    }

    const categoryLabel: string = CATEGORY_LABELS[task.category] ?? "hulp";

    // --- 1) De hulpvrager informeren -----------------------------------------
    const elderlyResult = await notifyUsers(supabase, [task.elderly_id], {
      kind: "task_reopened",
      title: "We zoeken een nieuwe buddy",
      body: "Je buddy moest helaas annuleren. We zoeken meteen een nieuwe buddy voor je.",
    });

    // --- 2) Buddies in de buurt opnieuw oproepen -----------------------------
    const taskLat: number | null = task.elderly_latitude ?? null;
    const taskLon: number | null = task.elderly_longitude ?? null;

    const { data: buddies } = await supabase
      .from("buddy_profiles")
      .select("id, latitude, longitude, current_latitude, current_longitude, location_updated_at, is_available_now")
      .eq("is_available_now", true);

    const freshCutoff = Date.now() - FRESH_MINUTES * 60 * 1000;
    const eligible = (buddies ?? []).filter((b: {
      id: string;
      latitude: number | null; longitude: number | null;
      current_latitude: number | null; current_longitude: number | null;
      location_updated_at: string | null;
    }) => {
      // Nooit de aanvrager zelf, en niet de buddy die net annuleerde.
      if (b.id === task.elderly_id) return false;
      if (cancelledBuddyId && b.id === cancelledBuddyId) return false;
      if (taskLat == null || taskLon == null) return true;

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
      if (lat == null || lon == null) return true;
      return haversineKm(taskLat, taskLon, lat, lon) <= RADIUS_KM;
    }).map((b: { id: string }) => b.id);

    let buddyResult = { sent: 0, total: 0 };
    if (eligible.length) {
      const firstName: string = task.elderly_first_name ?? "Iemand in de buurt";
      buddyResult = await notifyUsers(supabase, eligible, {
        kind: "new_task_nearby",
        title: "Hulpvraag weer beschikbaar",
        body: `${firstName} zoekt opnieuw ${categoryLabel}. Kun jij helpen?`,
      });
    }

    return new Response(JSON.stringify({ elderly: elderlyResult, buddies: buddyResult }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("notify-task-reopened fout:", e);
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 });
  }
});

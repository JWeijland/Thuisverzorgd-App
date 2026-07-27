// ============================================================
// Edge Function: notify-team-event
//
// Push + inbox voor gebeurtenissen binnen een zorgkring (fase36):
//   • event "chat"         — nieuw teamchat-bericht ('all' of 'buddies')
//   • event "swap_request" — een buddy zoekt vervanging voor een moment
//   • event "swap_taken"   — een buddy heeft het moment overgenomen
//
// De app roept deze functie aan ná de bijbehorende RPC (send_care_team_message /
// request_visit_swap / take_over_visit). Via de meegestuurde Supabase-JWT
// controleren we dat de beller echt bij het team hoort; de ontvangers worden
// hier server-side bepaald (nooit door de client aangeleverd):
//   • kanaal 'buddies'  → alle teamleden behalve de beller
//   • kanaal 'all'/swap → teamleden + hulpvrager + gekoppelde familie,
//                         behalve de beller
//
// Secrets: APNS_KEY_ID, APNS_TEAM_ID, APNS_BUNDLE_ID, APNS_PRIVATE_KEY.
// ============================================================

import { serviceClient, notifyUsers } from "../_shared/apns.ts";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}

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

function whenText(iso: string): string {
  return new Date(iso).toLocaleString("nl-NL", {
    timeZone: "Europe/Amsterdam", weekday: "long", day: "numeric",
    month: "long", hour: "2-digit", minute: "2-digit",
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  try {
    const authHeader = req.headers.get("Authorization") ?? "";
    const token = authHeader.replace(/^Bearer\s+/i, "");
    if (!token) return json({ error: "Niet ingelogd." }, 401);

    const { teamId, event, channel, text, visitId } = await req.json().catch(() => ({}));
    if (!teamId || !event) return json({ error: "teamId en event zijn verplicht." }, 400);
    if (!["chat", "swap_request", "swap_taken"].includes(event)) {
      return json({ error: "Onbekend event." }, 400);
    }

    const supabase = serviceClient();

    // Beller identificeren uit de JWT.
    const { data: userData, error: userErr } = await supabase.auth.getUser(token);
    const caller = userData?.user;
    if (userErr || !caller) return json({ error: "Ongeldige sessie." }, 401);

    // Team + leden + familie ophalen.
    const { data: team, error: teamErr } = await supabase
      .from("care_teams")
      .select("id, elderly_id, elderly_name, care_team_members(buddy_id)")
      .eq("id", teamId)
      .maybeSingle();
    if (teamErr) return json({ error: teamErr.message }, 500);
    if (!team) return json({ error: "Team niet gevonden." }, 404);

    const memberIds: string[] = (team.care_team_members ?? []).map(
      (m: { buddy_id: string }) => m.buddy_id,
    );
    const { data: fam } = await supabase
      .from("family_elderly_links").select("family_id")
      .eq("elderly_id", team.elderly_id);
    const familyIds: string[] = (fam ?? []).map((f: { family_id: string }) => f.family_id);
    const managerIds = [team.elderly_id, ...familyIds].filter(Boolean) as string[];

    // Autorisatie: de beller moet teamlid of beheerder (hulpvrager/familie) zijn.
    const isMember = memberIds.includes(caller.id);
    const isManager = managerIds.includes(caller.id);
    if (!isMember && !isManager) return json({ error: "Geen toegang tot dit team." }, 403);

    const { data: profile } = await supabase
      .from("profiles").select("first_name").eq("id", caller.id).maybeSingle();
    const senderName: string = profile?.first_name || "Iemand";
    const elderlyName: string = team.elderly_name || "de hulpvrager";

    let recipients: string[] = [];
    let kind = "";
    let title = "";
    let body = "";

    if (event === "chat") {
      const ch = channel === "buddies" ? "buddies" : "all";
      if (ch === "buddies" && !isMember) {
        return json({ error: "Alleen vrijwilligers van dit team." }, 403);
      }
      const message = String(text ?? "").trim().slice(0, 200);
      if (!message) return json({ error: "Leeg bericht." }, 400);
      recipients = ch === "buddies" ? memberIds : [...memberIds, ...managerIds];
      kind = "team_chat";
      title = ch === "buddies"
        ? `${senderName} in de buddy-chat (team ${elderlyName})`
        : `${senderName} in de teamchat van ${elderlyName}`;
      body = message;
    } else {
      // Swap-events: het bijbehorende moment ophalen voor een duidelijke tekst.
      if (!visitId) return json({ error: "visitId is verplicht." }, 400);
      const { data: visit } = await supabase
        .from("care_team_visits")
        .select("id, care_team_id, category, scheduled_at, claimed_by")
        .eq("id", visitId)
        .maybeSingle();
      if (!visit || visit.care_team_id !== team.id) {
        return json({ error: "Moment niet gevonden." }, 404);
      }
      const catLabel = CATEGORY_LABELS[visit.category] ?? "hulp";
      recipients = [...memberIds, ...managerIds];

      if (event === "swap_request") {
        kind = "swap_request";
        title = `${senderName} zoekt vervanging`;
        body = `${whenText(visit.scheduled_at)} (${catLabel}) bij ${elderlyName}. Wie neemt dit moment over?`;
      } else {
        kind = "swap_taken";
        title = "Vervanging geregeld";
        body = `${senderName} neemt ${whenText(visit.scheduled_at)} (${catLabel}) bij ${elderlyName} over. Het rooster klopt weer.`;
      }
    }

    // De beller zelf krijgt geen melding van zijn eigen actie.
    recipients = [...new Set(recipients)].filter((id) => id && id !== caller.id);

    const result = await notifyUsers(supabase, recipients, {
      kind, title, body, careTeamId: team.id,
    });
    return json(result);
  } catch (e) {
    console.error("notify-team-event fout:", e);
    return json({ error: String(e) }, 500);
  }
});

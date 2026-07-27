// ============================================================
// Edge Function: notify-buddy-message
//
// De hulpvrager stuurt zijn/haar toegewezen buddy een persoonlijk bericht.
// Levert het als push + inbox-melding bij de buddy af ("push + inbox").
//
// We controleren via de meegestuurde Supabase-JWT dat de beller ook echt de
// hulpvrager van díe taak is, zodat niemand willekeurig buddies kan bestoken.
//
// Aanroep vanuit de app: supabase.functions.invoke("notify-buddy-message",
//   options: .init(body: { "taskId": "<uuid>", "text": "..." })).
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

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  try {
    const authHeader = req.headers.get("Authorization") ?? "";
    const token = authHeader.replace(/^Bearer\s+/i, "");
    if (!token) return json({ error: "Niet ingelogd." }, 401);

    const { taskId, text } = await req.json().catch(() => ({}));
    if (!taskId || !text || !String(text).trim()) {
      return json({ error: "taskId en tekst zijn verplicht." }, 400);
    }
    const message = String(text).trim().slice(0, 500);

    const supabase = serviceClient();

    // Beller identificeren uit de JWT.
    const { data: userData, error: userErr } = await supabase.auth.getUser(token);
    const caller = userData?.user;
    if (userErr || !caller) return json({ error: "Ongeldige sessie." }, 401);

    // Taak ophalen + autoriseren.
    const { data: task, error: taskErr } = await supabase
      .from("tasks")
      .select("id, elderly_id, assigned_buddy_id, elderly_first_name")
      .eq("id", taskId)
      .maybeSingle();
    if (taskErr) return json({ error: taskErr.message }, 500);
    if (!task) return json({ error: "Hulpvraag niet gevonden." }, 404);
    if (task.elderly_id !== caller.id) return json({ error: "Geen toegang tot deze hulpvraag." }, 403);
    if (!task.assigned_buddy_id) return json({ error: "Er is nog geen buddy gekoppeld." }, 409);

    const name: string = task.elderly_first_name ?? "De hulpvrager";
    const result = await notifyUsers(supabase, [task.assigned_buddy_id], {
      kind: "elderly_message",
      title: `Bericht van ${name}`,
      body: message,
    });

    return json(result);
  } catch (e) {
    console.error("notify-buddy-message fout:", e);
    return json({ error: String(e) }, 500);
  }
});

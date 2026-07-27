// ============================================================
// Edge Function: notify-favorite-buddy
//
// Een hulpvrager heeft een buddy als vaste buddy gekozen. Verrast de buddy
// met een push + inbox-melding ("push + inbox").
//
// We controleren via de meegestuurde Supabase-JWT dat de beller ook echt de
// hulpvrager is die deze buddy als favoriet heeft vastgelegd, zodat niemand
// willekeurig meldingen kan versturen.
//
// Aanroep vanuit de app: supabase.functions.invoke("notify-favorite-buddy",
//   options: .init(body: { "buddyId": "<uuid>" })).
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

    const { buddyId } = await req.json().catch(() => ({}));
    if (!buddyId) return json({ error: "buddyId is verplicht." }, 400);

    const supabase = serviceClient();

    // Beller identificeren uit de JWT.
    const { data: userData, error: userErr } = await supabase.auth.getUser(token);
    const caller = userData?.user;
    if (userErr || !caller) return json({ error: "Ongeldige sessie." }, 401);

    // Autoriseren: de favoriet moet echt door déze hulpvrager zijn vastgelegd.
    const { data: fav, error: favErr } = await supabase
      .from("favorite_buddies")
      .select("elderly_id, buddy_id, elderly_name")
      .eq("elderly_id", caller.id)
      .eq("buddy_id", buddyId)
      .maybeSingle();
    if (favErr) return json({ error: favErr.message }, 500);
    if (!fav) return json({ error: "Deze buddy staat niet in uw vaste buddies." }, 403);

    // Naam van de hulpvrager (gedenormaliseerd of uit het profiel).
    let name: string = fav.elderly_name ?? "";
    if (!name) {
      const { data: profile } = await supabase
        .from("profiles")
        .select("first_name")
        .eq("id", caller.id)
        .maybeSingle();
      name = profile?.first_name ?? "Een hulpvrager";
    }

    const result = await notifyUsers(supabase, [buddyId], {
      kind: "favorite_buddy",
      title: `${name} heeft jou als vaste buddy gekozen`,
      body: `Wat leuk! Je bent nu een vertrouwd gezicht voor ${name}.`,
    });

    return json(result);
  } catch (e) {
    console.error("notify-favorite-buddy fout:", e);
    return json({ error: String(e) }, 500);
  }
});

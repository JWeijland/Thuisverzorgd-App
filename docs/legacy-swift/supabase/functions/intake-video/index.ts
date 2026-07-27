// ============================================================
// Edge Function: intake-video
//
// Geeft de app een Daily room-URL + kort geldig meeting token voor een
// intake-videogesprek. De Daily REST API-key (DAILY_API_KEY) blijft HIER, op de
// server — nooit in de app-binary.
//
// De app roept dit aan met `supabase.functions.invoke("intake-video", { callId })`.
// We controleren via de meegestuurde Supabase-JWT dat de beller óf de buddy van
// dat gesprek is, óf een admin. Daarna maken we (idempotent) een Daily-room voor
// dít gesprek en een meeting token dat ~40 min geldig is.
//
// Secret: DAILY_API_KEY  (zet met: supabase secrets set DAILY_API_KEY=...)
// ============================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const DAILY_API = "https://api.daily.co/v1";
const TOKEN_TTL_SECONDS = 40 * 60;

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
    const dailyKey = Deno.env.get("DAILY_API_KEY");
    if (!dailyKey) return json({ error: "DAILY_API_KEY ontbreekt op de server." }, 500);

    // 1) Beller identificeren uit de Supabase-JWT.
    const authHeader = req.headers.get("Authorization") ?? "";
    const token = authHeader.replace(/^Bearer\s+/i, "");
    if (!token) return json({ error: "Niet ingelogd." }, 401);

    const svc = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );
    const { data: userData, error: userErr } = await svc.auth.getUser(token);
    const caller = userData?.user;
    if (userErr || !caller) return json({ error: "Ongeldige sessie." }, 401);

    // 2) Gesprek opzoeken.
    const { callId } = await req.json().catch(() => ({ callId: null }));
    if (!callId) return json({ error: "callId ontbreekt." }, 400);

    const { data: call, error: callErr } = await svc
      .from("intake_calls")
      .select("id, buddy_id, status")
      .eq("id", callId)
      .single();
    if (callErr || !call) return json({ error: "Gesprek niet gevonden." }, 404);

    // 3) Autoriseren: de buddy zelf óf een admin mag joinen.
    const isBuddy = call.buddy_id === caller.id;
    let isAdmin = false;
    if (!isBuddy) {
      const { data: prof } = await svc
        .from("profiles").select("role").eq("id", caller.id).single();
      isAdmin = prof?.role === "admin";
    }
    if (!isBuddy && !isAdmin) return json({ error: "Geen toegang tot dit gesprek." }, 403);

    // 4) Naam van de display-deelnemer.
    const { data: nameRow } = await svc
      .from("profiles").select("first_name, last_name").eq("id", caller.id).single();
    const userName = [nameRow?.first_name, nameRow?.last_name]
      .filter(Boolean).join(" ") || (isAdmin ? "Medewerker" : "Buddy");

    // 5) Daily-room (idempotent: 1 room per gesprek).
    const roomName = `intake-${String(callId).toLowerCase()}`;
    const roomExp = Math.floor(Date.now() / 1000) + TOKEN_TTL_SECONDS;

    let roomUrl: string | null = null;
    const createRoom = await fetch(`${DAILY_API}/rooms`, {
      method: "POST",
      headers: { Authorization: `Bearer ${dailyKey}`, "Content-Type": "application/json" },
      body: JSON.stringify({
        name: roomName,
        privacy: "private",
        properties: {
          exp: roomExp,
          eject_at_room_exp: true,
          enable_chat: true,
          enable_screenshare: false,
          max_participants: 2,
        },
      }),
    });
    if (createRoom.ok) {
      roomUrl = (await createRoom.json()).url;
    } else if (createRoom.status === 400 || createRoom.status === 409) {
      // Bestaat al → ophalen.
      const existing = await fetch(`${DAILY_API}/rooms/${roomName}`, {
        headers: { Authorization: `Bearer ${dailyKey}` },
      });
      if (existing.ok) roomUrl = (await existing.json()).url;
    }
    if (!roomUrl) {
      const detail = await createRoom.text().catch(() => "");
      return json({ error: "Kon de videoroom niet aanmaken.", detail }, 502);
    }

    // 6) Meeting token (kort geldig; admin = owner).
    const tokenResp = await fetch(`${DAILY_API}/meeting-tokens`, {
      method: "POST",
      headers: { Authorization: `Bearer ${dailyKey}`, "Content-Type": "application/json" },
      body: JSON.stringify({
        properties: {
          room_name: roomName,
          user_name: userName,
          is_owner: isAdmin,
          exp: roomExp,
        },
      }),
    });
    if (!tokenResp.ok) {
      const detail = await tokenResp.text().catch(() => "");
      return json({ error: "Kon geen meeting token maken.", detail }, 502);
    }
    const meetingToken = (await tokenResp.json()).token;

    return json({ roomUrl, token: meetingToken });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});

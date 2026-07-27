// ============================================================
// Edge Function: notify-intake-call
//
// Wordt aangeroepen door een Database Webhook op INSERT in `intake_calls`.
// Stuurt een APNs-pushnotificatie naar alle admins dat er iemand in de
// wachtrij staat voor een intake-videogesprek.
//
// Vereiste secrets (zelfde als notify-new-task):
//   APNS_KEY_ID, APNS_TEAM_ID, APNS_BUNDLE_ID, APNS_PRIVATE_KEY
//   SUPABASE_URL en SUPABASE_SERVICE_ROLE_KEY worden automatisch geïnjecteerd.
//
// Webhook instellen: Supabase → Database → Webhooks → New →
//   table: intake_calls, events: INSERT → HTTP Request naar deze functie.
// ============================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

let cachedJwt: { token: string; createdAt: number } | null = null;

function base64url(input: ArrayBuffer | string): string {
  let bytes: Uint8Array;
  if (typeof input === "string") bytes = new TextEncoder().encode(input);
  else bytes = new Uint8Array(input);
  let binary = "";
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const body = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s+/g, "");
  const binary = atob(body);
  const buf = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) buf[i] = binary.charCodeAt(i);
  return buf.buffer;
}

async function makeApnsJwt(): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedJwt && now - cachedJwt.createdAt < 50 * 60) return cachedJwt.token;

  const keyId = Deno.env.get("APNS_KEY_ID")!;
  const teamId = Deno.env.get("APNS_TEAM_ID")!;
  const privateKeyPem = Deno.env.get("APNS_PRIVATE_KEY")!;

  const header = { alg: "ES256", kid: keyId };
  const payload = { iss: teamId, iat: now };
  const signingInput = `${base64url(JSON.stringify(header))}.${base64url(JSON.stringify(payload))}`;

  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(privateKeyPem),
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" },
    key,
    new TextEncoder().encode(signingInput),
  );
  const jwt = `${signingInput}.${base64url(signature)}`;
  cachedJwt = { token: jwt, createdAt: now };
  return jwt;
}

const APNS_HOSTS = {
  production: "https://api.push.apple.com",
  sandbox: "https://api.sandbox.push.apple.com",
};

async function sendPush(host: string, deviceToken: string, jwt: string, bundleId: string, title: string, body: string): Promise<Response> {
  return await fetch(`${host}/3/device/${deviceToken}`, {
    method: "POST",
    headers: {
      "authorization": `bearer ${jwt}`,
      "apns-topic": bundleId,
      "apns-push-type": "alert",
      "apns-priority": "10",
    },
    body: JSON.stringify({ aps: { alert: { title, body }, sound: "default" } }),
  });
}

async function sendWithFallback(deviceToken: string, jwt: string, bundleId: string, title: string, body: string): Promise<boolean> {
  let res = await sendPush(APNS_HOSTS.production, deviceToken, jwt, bundleId, title, body);
  if (res.status === 200) return true;
  const reason = (await res.text()) || "";
  if (res.status === 400 && reason.includes("BadDeviceToken")) {
    res = await sendPush(APNS_HOSTS.sandbox, deviceToken, jwt, bundleId, title, body);
    if (res.status === 200) return true;
    console.error(`[APNs sandbox] ${res.status}: ${await res.text()}`);
    return false;
  }
  console.error(`[APNs prod] ${res.status}: ${reason}`);
  return false;
}

Deno.serve(async (req) => {
  try {
    const payload = await req.json();
    const record = payload.record ?? payload.new ?? payload;

    // Alleen op een nieuw gesprek dat in de wachtrij komt.
    if (!record || record.status !== "waiting") {
      return new Response(JSON.stringify({ skipped: true }), {
        headers: { "Content-Type": "application/json" },
      });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    // Naam van de buddy ophalen voor een persoonlijke melding.
    let buddyName = "Een buddy";
    if (record.buddy_id) {
      const { data: prof } = await supabase
        .from("profiles")
        .select("first_name,last_name")
        .eq("id", record.buddy_id)
        .single();
      if (prof) buddyName = `${prof.first_name ?? ""} ${prof.last_name ?? ""}`.trim() || buddyName;
    }

    const title = "Intake-gesprek in de wachtrij";
    const body = `${buddyName} wacht op een intake-videogesprek. Neem op in de app.`;

    // Admin-device-tokens ophalen (service role → omzeilt RLS).
    const { data: tokens, error } = await supabase
      .from("device_tokens")
      .select("token")
      .eq("role", "admin");

    if (error) {
      console.error("device_tokens ophalen mislukt:", error);
      return new Response(JSON.stringify({ error: error.message }), { status: 500 });
    }
    if (!tokens || tokens.length === 0) {
      return new Response(JSON.stringify({ sent: 0, note: "geen admin-tokens" }), {
        headers: { "Content-Type": "application/json" },
      });
    }

    const jwt = await makeApnsJwt();
    const bundleId = Deno.env.get("APNS_BUNDLE_ID")!;
    const results = await Promise.all(
      tokens.map((t: { token: string }) => sendWithFallback(t.token, jwt, bundleId, title, body)),
    );
    const sent = results.filter(Boolean).length;

    return new Response(JSON.stringify({ sent, total: tokens.length }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("notify-intake-call fout:", e);
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 });
  }
});

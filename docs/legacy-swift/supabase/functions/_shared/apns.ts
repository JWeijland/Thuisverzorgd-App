// ============================================================
// Gedeelde APNs-helper voor alle edge functions.
//
// - makeApnsJwt(): ES256-JWT voor APNs (1 uur geldig, gecachet).
// - sendToTokens(): stuurt een melding naar een lijst device tokens (prod →
//   sandbox fallback), geeft {sent,total} terug.
// - notifyUsers(): schrijft de melding in de in-app inbox (tabel notifications)
//   ÉN stuurt 'm als push naar de device tokens van die gebruikers ("push + inbox").
// - haversineKm(): afstand tussen twee coördinaten in km.
//
// Vereiste secrets: APNS_KEY_ID, APNS_TEAM_ID, APNS_BUNDLE_ID, APNS_PRIVATE_KEY.
// SUPABASE_URL en SUPABASE_SERVICE_ROLE_KEY worden automatisch geïnjecteerd.
// ============================================================

import { createClient, SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

export function serviceClient(): SupabaseClient {
  return createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
}

// ---- JWT (ES256) ---------------------------------------------------------

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

export async function makeApnsJwt(): Promise<string> {
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

// ---- Push versturen ------------------------------------------------------

const APNS_HOSTS = {
  production: "https://api.push.apple.com",
  sandbox: "https://api.sandbox.push.apple.com",
};

async function sendPush(
  host: string,
  deviceToken: string,
  jwt: string,
  bundleId: string,
  title: string,
  body: string,
  data: Record<string, unknown>,
): Promise<Response> {
  return await fetch(`${host}/3/device/${deviceToken}`, {
    method: "POST",
    headers: {
      "authorization": `bearer ${jwt}`,
      "apns-topic": bundleId,
      "apns-push-type": "alert",
      "apns-priority": "10",
    },
    body: JSON.stringify({
      aps: { alert: { title, body }, sound: "default" },
      ...data, // custom velden (bv. kind) voor tap-routing in de app
    }),
  });
}

async function sendWithFallback(
  deviceToken: string,
  jwt: string,
  bundleId: string,
  title: string,
  body: string,
  data: Record<string, unknown>,
): Promise<boolean> {
  let res = await sendPush(APNS_HOSTS.production, deviceToken, jwt, bundleId, title, body, data);
  if (res.status === 200) return true;
  const reason = (await res.text()) || "";
  if (res.status === 400 && reason.includes("BadDeviceToken")) {
    res = await sendPush(APNS_HOSTS.sandbox, deviceToken, jwt, bundleId, title, body, data);
    if (res.status === 200) return true;
    console.error(`[APNs sandbox] ${res.status}: ${await res.text()}`);
    return false;
  }
  console.error(`[APNs prod] ${res.status}: ${reason}`);
  return false;
}

export async function sendToTokens(
  tokens: string[],
  title: string,
  body: string,
  data: Record<string, unknown> = {},
): Promise<{ sent: number; total: number }> {
  if (!tokens.length) return { sent: 0, total: 0 };
  const jwt = await makeApnsJwt();
  const bundleId = Deno.env.get("APNS_BUNDLE_ID")!;
  const results = await Promise.all(
    tokens.map((t) => sendWithFallback(t, jwt, bundleId, title, body, data)),
  );
  return { sent: results.filter(Boolean).length, total: tokens.length };
}

// ---- Inbox + push samen --------------------------------------------------

export interface InboxMeta {
  kind: string;
  title: string;
  body?: string | null;
  teamId?: string | null;
  competitionId?: string | null;
  requestId?: string | null;
  careTeamId?: string | null;
  taskId?: string | null;
}

async function tokensForUsers(supabase: SupabaseClient, userIds: string[]): Promise<string[]> {
  if (!userIds.length) return [];
  const { data } = await supabase.from("device_tokens").select("token").in("user_id", userIds);
  return (data ?? []).map((r: { token: string }) => r.token);
}

/** Schrijft de melding in de inbox van elke gebruiker én stuurt 'm als push. */
export async function notifyUsers(
  supabase: SupabaseClient,
  userIds: string[],
  meta: InboxMeta,
): Promise<{ sent: number; total: number }> {
  const ids = [...new Set(userIds)].filter(Boolean);
  if (!ids.length) return { sent: 0, total: 0 };

  const rows = ids.map((uid) => ({
    user_id: uid,
    kind: meta.kind,
    title: meta.title,
    body: meta.body ?? null,
    team_id: meta.teamId ?? null,
    competition_id: meta.competitionId ?? null,
    request_id: meta.requestId ?? null,
    care_team_id: meta.careTeamId ?? null,
    task_id: meta.taskId ?? null,
  }));
  const { error } = await supabase.from("notifications").insert(rows);
  if (error) console.error("inbox insert mislukt:", error);

  const tokens = await tokensForUsers(supabase, ids);
  return await sendToTokens(tokens, meta.title, meta.body ?? "", {
    kind: meta.kind,
    care_team_id: meta.careTeamId ?? null,
    task_id: meta.taskId ?? null,
  });
}

// ---- Geo -----------------------------------------------------------------

export function haversineKm(
  lat1: number, lon1: number, lat2: number, lon2: number,
): number {
  const R = 6371;
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a = Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * Math.sin(dLon / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

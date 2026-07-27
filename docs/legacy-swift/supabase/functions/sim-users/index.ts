// ============================================================
// Edge Function: sim-users (TIJDELIJK — testgereedschap)
//
// Simuleert ~20 echte gebruikers (2 hulpvragers, 2 familieleden, 16 buddies)
// die met willekeurig gedrag het zorgkring-domein doorlopen:
// teamvorming (ring-dispatch), accepteren/weigeren, review, rooster claimen,
// vervanging vragen/overnemen, teamchat (beide kanalen), join-verzoeken,
// kaart-druppels (buddy_map_pins) en een reeks privacy/RLS-checks.
//
// Elke gebruiker logt echt in (eigen JWT), zodat RLS en RPC-rechten exact
// zo getest worden als in de app. De sim-gebruikers staan bewust ver weg
// (Lauwersoog) zodat echte gebruikers er niets van merken; ze hebben geen
// device tokens, dus er gaan geen pushmeldingen naar echte telefoons.
// Na afloop wordt alles opgeruimd (tenzij keep: true).
//
// Aanroep:  POST { secret: "...", seed?: 42, keep?: false }
// Antwoord: { ok, fase36Applied, findings: [{step, actor, ok, detail}] }
// ============================================================

import { createClient, SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

const SIM_SECRET = "tvz-sim-2026-fase36";
const SIM_DOMAIN = "sim-thuisverzorgd.example.com";
// Ver weg van echte gebruikers (Lauwersoog e.o.).
const CENTER = { lat: 53.36, lon: 6.22 };

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;

function admin(): SupabaseClient {
  return createClient(SUPABASE_URL, SERVICE_KEY, { auth: { persistSession: false } });
}

// Reproduceerbare "willekeur" (mulberry32) — zelfde seed = zelfde run.
function rng(seed: number) {
  let a = seed >>> 0;
  return () => {
    a |= 0; a = (a + 0x6D2B79F5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

interface Finding { step: string; actor: string; ok: boolean; detail: string }

Deno.serve(async (req) => {
  const body = await req.json().catch(() => ({}));
  if (body.secret !== SIM_SECRET) {
    return new Response(JSON.stringify({ error: "geen toegang" }), { status: 403 });
  }
  const rand = rng(Number(body.seed ?? 42));
  const keep = body.keep === true;
  const svc = admin();
  const findings: Finding[] = [];
  const log = (step: string, actor: string, ok: boolean, detail = "") => {
    findings.push({ step, actor, ok, detail });
  };

  // Elke sim-gebruiker: eigen ingelogde client (echte JWT → echte RLS).
  interface SimUser {
    name: string; role: string; email: string; id: string; client: SupabaseClient;
  }
  const users: SimUser[] = [];
  const password = "Sim!" + Math.floor(rand() * 1e9);

  const cleanupUserIds: string[] = [];
  const cleanupTeamIds: string[] = [];

  try {
    // =====================================================================
    // 0. Vooraf: is fase36 gedraaid?
    // =====================================================================
    let fase36Applied = true;
    {
      const { error } = await svc.from("care_team_messages").select("id").limit(1);
      if (error) {
        fase36Applied = false;
        log("fase36-check", "systeem", false,
          `fase36_teamchat_vervanging.sql lijkt NIET gedraaid: ${error.message}`);
      } else {
        log("fase36-check", "systeem", true, "care_team_messages bestaat");
      }
    }

    // =====================================================================
    // 1. Gebruikers aanmaken (registratie-trigger maakt de profielen)
    // =====================================================================
    const spec: Array<{ name: string; role: string }> = [
      { name: "Simriet", role: "elderly" },   // teamvorming
      { name: "Simhenk", role: "elderly" },   // random_only
      { name: "Simsandra", role: "family" },  // gekoppeld aan Simriet
      { name: "Simpeter", role: "family" },   // gekoppeld aan Simhenk
      ...Array.from({ length: 16 }, (_, i) => ({ name: `Simbuddy${i + 1}`, role: "buddy" })),
    ];

    for (const s of spec) {
      const email = `${s.name.toLowerCase()}@${SIM_DOMAIN}`;
      const { data, error } = await svc.auth.admin.createUser({
        email, password, email_confirm: true,
        user_metadata: { role: s.role, first_name: s.name, last_name: "Sim" },
      });
      if (error || !data.user) {
        log("aanmaken", s.name, false, error?.message ?? "geen user");
        continue;
      }
      cleanupUserIds.push(data.user.id);
      const client = createClient(SUPABASE_URL, ANON_KEY, { auth: { persistSession: false } });
      const { error: loginErr } = await client.auth.signInWithPassword({ email, password });
      if (loginErr) {
        log("inloggen", s.name, false, loginErr.message);
        continue;
      }
      users.push({ name: s.name, role: s.role, email, id: data.user.id, client });
    }
    log("aanmaken+inloggen", "systeem", users.length === spec.length,
      `${users.length}/${spec.length} gebruikers aangemaakt en ingelogd`);

    const byName = (n: string) => users.find((u) => u.name === n)!;
    const buddies = users.filter((u) => u.role === "buddy");
    const riet = byName("Simriet");
    const henk = byName("Simhenk");
    const sandra = byName("Simsandra");

    // =====================================================================
    // 2. Profielen inrichten
    // =====================================================================
    // Buddies: gescreend, beschikbaar, locatie rond het sim-dorp.
    for (const b of buddies) {
      const jitter = () => (rand() - 0.5) * 0.04; // ±~2 km
      const { error } = await svc.from("buddy_profiles").update({
        vog_valid: true, intake_completed: true, is_onboarding_complete: true,
        is_available_now: rand() < 0.8, max_distance_km: 10,
        latitude: CENTER.lat + jitter(), longitude: CENTER.lon + jitter(),
        bio: "Sim-testgebruiker",
      }).eq("id", b.id);
      if (error) log("buddy-profiel", b.name, false, error.message);
    }
    // Hulpvragers: adres/locatie via hun eigen account (RLS-check update).
    for (const e of [riet, henk]) {
      const { error } = await e.client.from("elderly_profiles").update({
        address: "Simstraat 1, Simdorp",
        latitude: CENTER.lat, longitude: CENTER.lon,
      }).eq("id", e.id);
      log("adres instellen", e.name, !error, error?.message ?? "eigen adres gezet (RLS ok)");
    }
    // Familie koppelen (setup, via service role zoals de koppelcode-flow doet).
    for (const [fam, eld] of [["Simsandra", "Simriet"], ["Simpeter", "Simhenk"]] as const) {
      const { error } = await svc.from("family_elderly_links").insert({
        family_id: byName(fam).id, elderly_id: byName(eld).id,
      });
      log("familie koppelen", fam, !error, error?.message ?? `gekoppeld aan ${eld}`);
    }
    // Henk kiest bewust voor losse buddies.
    {
      const { error } = await henk.client.from("elderly_profiles")
        .update({ team_mode: "random_only" }).eq("id", henk.id);
      log("random_only kiezen", "Simhenk", !error, error?.message ?? "team_mode = random_only");
    }

    // =====================================================================
    // 3. Teamvorming: Simriet start, ring-dispatch nodigt buddies uit
    // =====================================================================
    let teamId: string | null = null;
    {
      const { data, error } = await riet.client.rpc("start_team_formation", {
        p_name: "Team Simriet", p_min: 2, p_max: 4,
      });
      teamId = data ?? null;
      if (teamId) cleanupTeamIds.push(teamId);
      log("teamvorming starten", "Simriet", !error && !!teamId, error?.message ?? `team ${teamId}`);
    }

    // Ring 1 versturen door de echte team-formation function aan te roepen.
    const invokeCron = async (fn: string) => {
      const res = await fetch(`${SUPABASE_URL}/functions/v1/${fn}`, {
        method: "POST",
        headers: { Authorization: `Bearer ${SERVICE_KEY}`, "Content-Type": "application/json" },
        body: "{}",
      });
      return { ok: res.ok, text: await res.text() };
    };
    {
      const r = await invokeCron("team-formation");
      log("team-formation ring 1", "cron", r.ok, r.text.slice(0, 300));
    }

    // Welke buddies kregen een uitnodiging? (elk leest z'n eigen invites — RLS)
    const invited: Array<{ buddy: SimUser; inviteId: string }> = [];
    for (const b of buddies) {
      const { data, error } = await b.client.from("care_team_invites")
        .select("id,care_team_id,status,elderly_name");
      if (error) { log("invites lezen", b.name, false, error.message); continue; }
      const forOthers = (data ?? []).filter((i) => i.care_team_id !== teamId);
      if (forOthers.length) {
        log("RLS invites", b.name, false, "ziet uitnodigingen van een ander team!");
      }
      const mine = (data ?? []).find((i) => i.care_team_id === teamId && i.status === "pending");
      if (mine) invited.push({ buddy: b, inviteId: mine.id });
    }
    log("ring 1 uitnodigingen", "systeem", invited.length > 0,
      `${invited.length} buddies uitgenodigd (verwacht 5)`);

    // Willekeurig accepteren (70%) / weigeren (30%).
    let accepted = 0;
    for (const inv of invited) {
      if (rand() < 0.7) {
        const { error } = await inv.buddy.client.rpc("accept_team_invite", { p_invite_id: inv.inviteId });
        if (!error) accepted++;
        else if (error.message.includes("vol")) {
          // Gewenst gedrag: boven het maximum netjes geweigerd.
          log("team vol-guard", inv.buddy.name, true, "netjes geweigerd: " + error.message);
          continue;
        }
        log("uitnodiging accepteren", inv.buddy.name, !error, error?.message ?? "in het team");
      } else {
        const { error } = await inv.buddy.client.rpc("decline_team_invite", { p_invite_id: inv.inviteId });
        log("uitnodiging weigeren", inv.buddy.name, !error, error?.message ?? "geweigerd");
      }
    }

    // Tweede ring nodig? Zet de ring-timer terug en draai de cron nog eens,
    // tot het team vol is of de kandidaten op zijn (max 3 extra rondes).
    for (let round = 2; round <= 4 && accepted < 4; round++) {
      await svc.from("care_teams").update({
        last_ring_at: new Date(Date.now() - 6 * 60000).toISOString(),
      }).eq("id", teamId);
      const r = await invokeCron("team-formation");
      log(`team-formation ring ${round}`, "cron", r.ok, r.text.slice(0, 200));
      for (const b of buddies) {
        const { data } = await b.client.from("care_team_invites")
          .select("id,care_team_id,status")
          .eq("care_team_id", teamId).eq("status", "pending");
        for (const i of data ?? []) {
          if (accepted >= 5) break; // bewust 1 te veel proberen (test 'team vol')
          if (rand() < 0.7) {
            const { error } = await b.client.rpc("accept_team_invite", { p_invite_id: i.id });
            if (!error) accepted++;
            else if (error.message.includes("vol")) {
              log("team vol-guard", b.name, true, "5e acceptatie netjes geweigerd: " + error.message);
              continue;
            }
            log("uitnodiging accepteren", b.name, !error, error?.message ?? "in het team");
          }
        }
      }
    }
    log("teamgrootte", "systeem", accepted >= 2, `${accepted} buddies geaccepteerd (min 2, max 4)`);

    // =====================================================================
    // 4. Review door Simriet: 1 buddy weigeren, dan bevestigen
    // =====================================================================
    let memberIds: string[] = [];
    {
      const { data } = await svc.from("care_team_members")
        .select("buddy_id").eq("care_team_id", teamId);
      memberIds = (data ?? []).map((m: { buddy_id: string }) => m.buddy_id);
    }
    if (memberIds.length > 2) {
      const rejectId = memberIds[Math.floor(rand() * memberIds.length)];
      const rejectName = users.find((u) => u.id === rejectId)?.name ?? rejectId;
      const { error } = await riet.client.rpc("review_team_member", {
        p_team_id: teamId, p_buddy_id: rejectId, p_accept: false,
      });
      log("review: buddy weigeren", "Simriet", !error, error?.message ?? `${rejectName} uit het team`);
      memberIds = memberIds.filter((m) => m !== rejectId);
    }
    {
      const { error } = await riet.client.rpc("finalize_team_review", { p_team_id: teamId });
      log("review afronden (live)", "Simriet", !error, error?.message ?? "team live");
    }
    // Niet-beheerder mag NIET finaliseren/verwijderen (RLS/guard-check).
    {
      const outsider = buddies.find((b) => !memberIds.includes(b.id))!;
      const { error } = await outsider.client.rpc("remove_care_team_member", {
        p_team_id: teamId, p_buddy_id: memberIds[0],
      });
      log("guard: buitenstaander verwijdert lid", outsider.name, !!error,
        error ? "netjes geweigerd: " + error.message : "FOUT: mocht zomaar een lid verwijderen!");
    }

    const members = users.filter((u) => memberIds.includes(u.id));

    // =====================================================================
    // 5. Rooster: familie plant, teamleden claimen (met dubbelclaim-race)
    // =====================================================================
    const dates = [26, 50, 74].map((h) => new Date(Date.now() + h * 3600000).toISOString());
    {
      const { data, error } = await sandra.client.rpc("request_care_visits", {
        p_team_id: teamId, p_category: "companionship", p_note: "Sim-bezoek", p_dates: dates,
      });
      log("rooster vullen", "Simsandra", !error, error?.message ?? `${data} momenten ingepland`);
    }
    let visits: Array<{ id: string }> = [];
    {
      const { data } = await svc.from("care_team_visits")
        .select("id").eq("care_team_id", teamId).order("scheduled_at");
      visits = data ?? [];
    }
    // Alle momenten claimen; op het eerste moment proberen er bewust twee.
    if (visits.length && members.length >= 2) {
      const [m1, m2] = [members[0], members[1]];
      const { error: c1 } = await m1.client.rpc("claim_care_visit", { p_visit_id: visits[0].id });
      log("moment claimen", m1.name, !c1, c1?.message ?? "geclaimd");
      const { error: c2 } = await m2.client.rpc("claim_care_visit", { p_visit_id: visits[0].id });
      log("dubbelclaim-guard", m2.name, !!c2,
        c2 ? "netjes geweigerd: " + c2.message : "FOUT: dubbel claimen lukte!");
      for (const v of visits.slice(1)) {
        const m = members[Math.floor(rand() * members.length)];
        const { error } = await m.client.rpc("claim_care_visit", { p_visit_id: v.id });
        log("moment claimen", m.name, !error, error?.message ?? "geclaimd");
      }
    }
    // Buitenstaander mag een team-moment niet claimen (geen urgent).
    {
      const outsider = buddies.find((b) => !memberIds.includes(b.id))!;
      const { data: free } = await svc.from("care_team_visits")
        .select("id").eq("care_team_id", teamId).is("claimed_by", null).limit(1);
      if (free?.length) {
        const { error } = await outsider.client.rpc("claim_care_visit", { p_visit_id: free[0].id });
        log("guard: buitenstaander claimt", outsider.name, !!error,
          error ? "netjes geweigerd: " + error.message : "FOUT: buitenstaander kon claimen!");
      }
    }

    // =====================================================================
    // 6. Vervanging (fase36): vragen, overnemen, guards
    // =====================================================================
    if (fase36Applied && members.length >= 2) {
      const { data: claimed } = await svc.from("care_team_visits")
        .select("id,claimed_by").eq("care_team_id", teamId).not("claimed_by", "is", null).limit(1);
      if (claimed?.length) {
        const visit = claimed[0];
        const owner = users.find((u) => u.id === visit.claimed_by)!;
        const other = members.find((m) => m.id !== visit.claimed_by)!;

        // Een ander mag niet namens jou vervanging vragen.
        const { error: g1 } = await other.client.rpc("request_visit_swap", {
          p_visit_id: visit.id, p_reason: "hack",
        });
        log("guard: ander vraagt jouw vervanging", other.name, !!g1,
          g1 ? "netjes geweigerd: " + g1.message : "FOUT: ander kon vervanging vragen!");

        // Overnemen vóór er een verzoek is → hoort te falen.
        const { error: g2 } = await other.client.rpc("take_over_visit", { p_visit_id: visit.id });
        log("guard: overnemen zonder verzoek", other.name, !!g2,
          g2 ? "netjes geweigerd: " + g2.message : "FOUT: overnemen zonder verzoek lukte!");

        // Echte flow: eigenaar vraagt vervanging, ander neemt over.
        const { error: s1 } = await owner.client.rpc("request_visit_swap", {
          p_visit_id: visit.id, p_reason: "Ik ben verhinderd",
        });
        log("vervanging vragen", owner.name, !s1, s1?.message ?? "vervanging gevraagd");
        const { error: s2 } = await other.client.rpc("take_over_visit", { p_visit_id: visit.id });
        log("vervanging overnemen", other.name, !s2, s2?.message ?? "moment overgenomen");

        // Push/inbox-fanout via notify-team-event (als de overnemende buddy).
        const session = await other.client.auth.getSession();
        const jwt = session.data.session?.access_token ?? "";
        const res = await fetch(`${SUPABASE_URL}/functions/v1/notify-team-event`, {
          method: "POST",
          headers: { Authorization: `Bearer ${jwt}`, apikey: ANON_KEY, "Content-Type": "application/json" },
          body: JSON.stringify({ teamId, event: "swap_taken", visitId: visit.id }),
        });
        log("notify-team-event swap_taken", other.name, res.ok, (await res.text()).slice(0, 200));

        // Inbox-berichten daadwerkelijk aangemaakt?
        const { data: notes } = await svc.from("notifications")
          .select("user_id,kind").eq("care_team_id", teamId).eq("kind", "swap_taken");
        log("inbox swap_taken", "systeem", (notes?.length ?? 0) > 0,
          `${notes?.length ?? 0} inbox-berichten voor het team`);
      }
    }

    // =====================================================================
    // 7. Teamchat (fase36): beide kanalen + privacy-guards
    // =====================================================================
    if (fase36Applied && members.length >= 2) {
      const zeg = async (u: SimUser, channel: string, text: string) =>
        u.client.rpc("send_care_team_message", { p_team_id: teamId, p_channel: channel, p_body: text });

      const { error: m1 } = await zeg(members[0], "all", "Hoi allemaal, hier de sim!");
      log("chat 'all' (buddy)", members[0].name, !m1, m1?.message ?? "verstuurd");
      const { error: m2 } = await zeg(riet, "all", "Fijn dat jullie er zijn!");
      log("chat 'all' (hulpvrager)", "Simriet", !m2, m2?.message ?? "verstuurd");
      const { error: m3 } = await zeg(sandra, "all", "Groetjes van de familie");
      log("chat 'all' (familie)", "Simsandra", !m3, m3?.message ?? "verstuurd");
      const { error: m4 } = await zeg(members[1], "buddies", "Onderling: wie ruilt er eens?");
      log("chat 'buddies' (buddy)", members[1].name, !m4, m4?.message ?? "verstuurd");

      // Hulpvrager mag NIET in het buddy-kanaal schrijven…
      const { error: g3 } = await zeg(riet, "buddies", "mag ik meedoen?");
      log("guard: hulpvrager in buddy-kanaal", "Simriet", !!g3,
        g3 ? "netjes geweigerd: " + g3.message : "FOUT: hulpvrager kon in buddy-kanaal schrijven!");
      // …en het ook niet LEZEN.
      const { data: leak1 } = await riet.client.from("care_team_messages")
        .select("id").eq("care_team_id", teamId).eq("channel", "buddies");
      log("guard: hulpvrager leest buddy-kanaal", "Simriet", (leak1?.length ?? 0) === 0,
        (leak1?.length ?? 0) === 0 ? "0 berichten zichtbaar (goed)" : `FOUT: ziet ${leak1!.length} berichten!`);
      // Buitenstaander ziet niets van deze teamchat.
      const outsider = buddies.find((b) => !memberIds.includes(b.id))!;
      const { data: leak2 } = await outsider.client.from("care_team_messages")
        .select("id").eq("care_team_id", teamId);
      log("guard: buitenstaander leest teamchat", outsider.name, (leak2?.length ?? 0) === 0,
        (leak2?.length ?? 0) === 0 ? "0 berichten zichtbaar (goed)" : `FOUT: ziet ${leak2!.length} berichten!`);
      // Leden en familie zien het 'all'-kanaal wel.
      const { data: seen } = await sandra.client.from("care_team_messages")
        .select("id,sender_name").eq("care_team_id", teamId).eq("channel", "all");
      log("familie leest 'all'", "Simsandra", (seen?.length ?? 0) >= 3,
        `${seen?.length ?? 0} berichten zichtbaar`);
    }

    // =====================================================================
    // 8. Join-verzoek: buddy wil erbij, familie beslist
    // =====================================================================
    {
      const candidates = buddies.filter((b) => !memberIds.includes(b.id));
      if (candidates.length >= 2) {
        const [wil1, wil2] = candidates;
        const { data: req1, error: e1 } = await wil1.client.rpc("request_join_care_team", {
          p_team_id: teamId, p_source: "search",
        });
        log("join-verzoek sturen", wil1.name, !e1, e1?.message ?? "verzoek gestuurd");
        if (req1) {
          const { error } = await sandra.client.rpc("respond_care_join_request", {
            p_request_id: req1, p_approve: rand() < 0.5,
          });
          log("join-verzoek beslissen", "Simsandra", !error, error?.message ?? "beslist");
        }
        // Guard: een willekeurige buddy mag niet zelf goedkeuren.
        const { data: req2 } = await wil2.client.rpc("request_join_care_team", {
          p_team_id: teamId, p_source: "search",
        });
        if (req2) {
          const { error } = await wil2.client.rpc("respond_care_join_request", {
            p_request_id: req2, p_approve: true,
          });
          log("guard: buddy keurt eigen verzoek goed", wil2.name, !!error,
            error ? "netjes geweigerd: " + error.message : "FOUT: kon zichzelf toelaten!");
        }
      }
    }

    // =====================================================================
    // 9. Kaart-druppels: view buddy_map_pins als hulpvrager
    // =====================================================================
    if (fase36Applied) {
      const { data, error } = await riet.client.from("buddy_map_pins")
        .select("id,first_name,latitude,longitude,is_available_now,has_avatar");
      const simPins = (data ?? []).filter((p) => p.first_name?.startsWith("Simbuddy"));
      log("kaart-druppels lezen", "Simriet", !error && simPins.length > 0,
        error?.message ?? `${data?.length ?? 0} pins totaal, waarvan ${simPins.length} sim-buddies met voornaam`);
      // Privacy: het volledige profiel van een ander blijft onleesbaar.
      const target = buddies[0];
      const { data: prof } = await riet.client.from("profiles")
        .select("id,phone_number").eq("id", target.id);
      log("guard: profiel ander onleesbaar", "Simriet", (prof?.length ?? 0) === 0,
        (prof?.length ?? 0) === 0 ? "0 rijen (goed)" : "FOUT: kan andermans profiel lezen!");
    }

    // =====================================================================
    // 10. Rooster rond? (groene gloed-conditie server-side nagerekend)
    // =====================================================================
    {
      const { data } = await svc.from("care_team_visits")
        .select("claimed_by,swap_requested").eq("care_team_id", teamId)
        .gte("scheduled_at", new Date().toISOString());
      const all = data ?? [];
      const covered = all.filter((v) => v.claimed_by && !v.swap_requested).length;
      log("rooster-status", "systeem", true,
        `${covered}/${all.length} aankomende momenten gedekt` +
        (all.length > 0 && covered === all.length ? " → groene gloed actief" : ""));
    }

    // =====================================================================
    // Opruimen
    // =====================================================================
    if (!keep) {
      for (const t of cleanupTeamIds) {
        await svc.from("notifications").delete().eq("care_team_id", t);
        if (fase36Applied) await svc.from("care_team_messages").delete().eq("care_team_id", t);
        await svc.from("care_team_visits").delete().eq("care_team_id", t);
        await svc.from("care_team_invites").delete().eq("care_team_id", t);
        await svc.from("care_team_join_requests").delete().eq("care_team_id", t);
        await svc.from("care_team_members").delete().eq("care_team_id", t);
        await svc.from("care_teams").delete().eq("id", t);
      }
      for (const id of cleanupUserIds) {
        await svc.from("notifications").delete().eq("user_id", id);
        await svc.from("family_elderly_links").delete().eq("family_id", id);
        await svc.from("family_elderly_links").delete().eq("elderly_id", id);
        const { error } = await svc.auth.admin.deleteUser(id);
        if (error) log("opruimen", id, false, error.message);
      }
      log("opruimen", "systeem", true,
        `${cleanupTeamIds.length} team(s) en ${cleanupUserIds.length} sim-gebruikers verwijderd`);
    } else {
      log("opruimen", "systeem", true, "overgeslagen (keep=true)");
    }

    const failed = findings.filter((f) => !f.ok).length;
    return new Response(JSON.stringify({
      ok: failed === 0, fase36Applied, failed, total: findings.length, findings,
    }, null, 2), { headers: { "Content-Type": "application/json" } });
  } catch (e) {
    // Nood-opruiming zodat er nooit sim-rommel achterblijft.
    try {
      for (const t of cleanupTeamIds) await svc.from("care_teams").delete().eq("id", t);
      for (const id of cleanupUserIds) await svc.auth.admin.deleteUser(id);
    } catch (_) { /* laatste redmiddel */ }
    findings.push({ step: "crash", actor: "systeem", ok: false, detail: String(e) });
    return new Response(JSON.stringify({ ok: false, findings }, null, 2), {
      status: 500, headers: { "Content-Type": "application/json" },
    });
  }
});

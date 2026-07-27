// ============================================================
// Edge Function: team-formation (cron, elke minuut — zie fase35_zorgkring.sql)
//
// Drijft de teamvorming van zorgkringen (status 'forming'):
//   1. Ring-dispatch: elke 5 min een volgende ring van 5 dichtstbijzijnde
//      buddies uitnodigen ("«Naam» zoekt een team aan buddies, doe jij mee?").
//      Vaste buddies van de hulpvrager gaan altijd in ring 1, met eigen tekst.
//      Een buddy wordt alleen uitgenodigd als de afstand binnen zijn/haar
//      eigen ingestelde straal (max_distance_km) valt.
//   2. Minimum bereikt → status 'review' + melding aan hulpvrager en familie.
//   3. Maximum bereikt → openstaande uitnodigingen laten vervallen.
//   4. Na 1 uur zonder vol team → keuzemelding aan hulpvrager/familie
//      (aanvullen met willekeurige buddies of doorgaan met dit team) en een
//      éénmalige herinnering aan buddies die afwezen of niet reageerden.
//
// Secrets: APNS_KEY_ID, APNS_TEAM_ID, APNS_BUNDLE_ID, APNS_PRIVATE_KEY.
// ============================================================

import { serviceClient, notifyUsers, haversineKm } from "../_shared/apns.ts";

const RING_SIZE = 5;              // buddies per ring
const RING_INTERVAL_MIN = 5;      // minuten tussen ringen
const CHOICE_AFTER_MIN = 60;      // na 1 uur: keuzemelding + herinnering

interface BuddyRow {
  id: string;
  latitude: number | null;
  longitude: number | null;
  max_distance_km: number | null;
}

Deno.serve(async (_req) => {
  try {
    const supabase = serviceClient();
    const summary: Record<string, unknown>[] = [];

    const { data: teams, error } = await supabase
      .from("care_teams")
      .select("id, name, elderly_id, elderly_name, status, min_size, max_size, " +
        "formation_started_at, last_ring, last_ring_at, choice_sent, " +
        "invite_reminder_sent, review_notified, approx_latitude, approx_longitude, " +
        "area, help_summary")
      .eq("status", "forming");
    if (error) throw error;

    for (const team of teams ?? []) {
      const teamSummary: Record<string, unknown> = { team: team.id };

      const { data: memberRows } = await supabase
        .from("care_team_members").select("buddy_id")
        .eq("care_team_id", team.id);
      const memberIds = (memberRows ?? []).map((m: { buddy_id: string }) => m.buddy_id);

      const { data: familyRows } = await supabase
        .from("family_elderly_links").select("family_id")
        .eq("elderly_id", team.elderly_id);
      const managerIds = [team.elderly_id, ...(familyRows ?? []).map(
        (f: { family_id: string }) => f.family_id,
      )].filter(Boolean);

      const firstName = team.elderly_name || "Een hulpvrager";

      // --- Maximum bereikt: klaar met werven -------------------------------
      if (memberIds.length >= team.max_size) {
        await supabase.from("care_team_invites")
          .update({ status: "expired", responded_at: new Date().toISOString() })
          .eq("care_team_id", team.id).in("status", ["pending", "reminded"]);
        await supabase.from("care_teams")
          .update({ status: "review", review_notified: true })
          .eq("id", team.id);
        if (!team.review_notified) {
          await notifyUsers(supabase, managerIds, {
            kind: "team_review_ready",
            title: "Je team is compleet!",
            body: `Er staan ${memberIds.length} buddies voor ${firstName} klaar. Bekijk en bevestig het team.`,
            careTeamId: team.id,
          });
        }
        teamSummary.full = true;
        summary.push(teamSummary);
        continue;
      }

      // --- Minimum bereikt: review kan alvast, werving loopt door ----------
      if (memberIds.length >= team.min_size && !team.review_notified) {
        await supabase.from("care_teams")
          .update({ status: "review", review_notified: true })
          .eq("id", team.id);
        await notifyUsers(supabase, managerIds, {
          kind: "team_review_ready",
          title: "Genoeg buddies gevonden!",
          body: `Er staan ${memberIds.length} buddies voor ${firstName} klaar. Bekijk het team en bevestig.`,
          careTeamId: team.id,
        });
        teamSummary.reviewReady = true;
        // status is nu 'review'; ringen stoppen. Accepteert de hulpvrager met
        // minder dan max, dan blijven bestaande invites geldig tot ze reageren.
        summary.push(teamSummary);
        continue;
      }

      // --- 1-uur-flow: keuzemelding + éénmalige herinnering ----------------
      const startedAt = team.formation_started_at
        ? new Date(team.formation_started_at).getTime() : Date.now();
      const ageMin = (Date.now() - startedAt) / 60000;

      if (ageMin >= CHOICE_AFTER_MIN && !team.choice_sent) {
        await notifyUsers(supabase, managerIds, {
          kind: "team_choice_needed",
          title: "Je team is nog niet vol",
          body: `Er ${memberIds.length === 1 ? "staat 1 buddy" : `staan ${memberIds.length} buddies`} klaar voor ${firstName}. Wil je gaten laten opvullen door buddies uit de buurt, of voorlopig alleen met dit team verder?`,
          careTeamId: team.id,
        });
        await supabase.from("care_teams")
          .update({ choice_sent: true }).eq("id", team.id);
        teamSummary.choiceSent = true;
      }

      if (ageMin >= CHOICE_AFTER_MIN && !team.invite_reminder_sent) {
        const { data: openInvites } = await supabase
          .from("care_team_invites").select("id, buddy_id, status")
          .eq("care_team_id", team.id).in("status", ["pending", "declined"]);
        const remindIds = (openInvites ?? []).map((i: { buddy_id: string }) => i.buddy_id);
        if (remindIds.length) {
          await notifyUsers(supabase, remindIds, {
            kind: "team_invite_reminder",
            title: `Het team van ${firstName} is nog niet vol`,
            body: `Wil je toch meedoen? ${firstName} zoekt nog buddies voor haar zorgkring.`,
            careTeamId: team.id,
          });
          await supabase.from("care_team_invites")
            .update({ status: "reminded" })
            .eq("care_team_id", team.id).eq("status", "pending");
        }
        await supabase.from("care_teams")
          .update({ invite_reminder_sent: true }).eq("id", team.id);
        teamSummary.reminded = remindIds.length;
      }

      // Na het uur stoppen we met nieuwe ringen; de keuze ligt bij de hulpvrager.
      if (ageMin >= CHOICE_AFTER_MIN) {
        summary.push(teamSummary);
        continue;
      }

      // --- Ring-dispatch ---------------------------------------------------
      const lastRingAt = team.last_ring_at ? new Date(team.last_ring_at).getTime() : 0;
      const ringDue = !team.last_ring_at ||
        (Date.now() - lastRingAt) / 60000 >= RING_INTERVAL_MIN;
      if (!ringDue) { summary.push(teamSummary); continue; }

      const { data: invitedRows } = await supabase
        .from("care_team_invites").select("buddy_id")
        .eq("care_team_id", team.id);
      const alreadyInvited = new Set(
        (invitedRows ?? []).map((i: { buddy_id: string }) => i.buddy_id),
      );

      const { data: favRows } = await supabase
        .from("favorite_buddies").select("buddy_id")
        .eq("elderly_id", team.elderly_id);
      const favoriteIds = new Set(
        (favRows ?? []).map((f: { buddy_id: string }) => f.buddy_id),
      );

      const { data: buddies } = await supabase
        .from("buddy_profiles")
        .select("id, latitude, longitude, max_distance_km");

      const candidates = ((buddies ?? []) as BuddyRow[])
        .filter((b) =>
          b.id !== team.elderly_id &&
          !alreadyInvited.has(b.id) &&
          !memberIds.includes(b.id))
        .map((b) => {
          let dist = Number.MAX_VALUE;
          if (b.latitude != null && b.longitude != null &&
              team.approx_latitude != null && team.approx_longitude != null) {
            dist = haversineKm(team.approx_latitude, team.approx_longitude,
              b.latitude, b.longitude);
          }
          return { id: b.id, dist, maxKm: b.max_distance_km ?? 10, fav: favoriteIds.has(b.id) };
        })
        // Binnen de eigen straal van de buddy; zonder locatie doet een buddy
        // niet mee aan teamvorming (wel aan gewone buurt-broadcasts).
        .filter((c) => c.dist <= c.maxKm)
        // Vaste buddies van deze hulpvrager altijd vooraan (conversie-flow).
        .sort((a, b2) => (a.fav === b2.fav) ? a.dist - b2.dist : (a.fav ? -1 : 1));

      const ring = candidates.slice(0, RING_SIZE);
      if (ring.length) {
        const ringNo = (team.last_ring ?? 0) + 1;
        const inviteRows = ring.map((c) => ({
          care_team_id: team.id,
          buddy_id: c.id,
          ring: ringNo,
          is_favorite: c.fav,
          elderly_name: firstName,
          area: team.area ?? "",
          help_summary: team.help_summary ?? "",
        }));
        const { error: invErr } = await supabase
          .from("care_team_invites").insert(inviteRows);
        if (invErr) console.error("invites insert mislukt:", invErr);

        const favs = ring.filter((c) => c.fav).map((c) => c.id);
        const rest = ring.filter((c) => !c.fav).map((c) => c.id);
        if (favs.length) {
          await notifyUsers(supabase, favs, {
            kind: "team_invite",
            title: `${firstName} bouwt een team — jij bent al vaste buddy`,
            body: `Je bent al vaste buddy van ${firstName}. Zij bouwt nu een zorgkring — doe jij mee?`,
            careTeamId: team.id,
          });
        }
        if (rest.length) {
          await notifyUsers(supabase, rest, {
            kind: "team_invite",
            title: `${firstName} zoekt een team aan buddies`,
            body: `${firstName}${team.area ? ` uit ${team.area}` : ""} zoekt een vast team van buddies. Doe jij mee?`,
            careTeamId: team.id,
          });
        }
        await supabase.from("care_teams")
          .update({ last_ring: ringNo, last_ring_at: new Date().toISOString() })
          .eq("id", team.id);
        teamSummary.ring = ringNo;
        teamSummary.invited = ring.length;
      } else {
        teamSummary.noCandidates = true;
      }
      summary.push(teamSummary);
    }

    return new Response(JSON.stringify({ ok: true, teams: summary }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("team-formation fout:", e);
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 });
  }
});

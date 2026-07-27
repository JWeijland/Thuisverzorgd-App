// ============================================================
// Edge Function: notify-scheduled  (dagelijkse cron via pg_cron + pg_net)
//
// Tijdgebonden meldingen, in één batch:
//  • Buddy ≥2 dagen niet beschikbaar terwijl er open hulpvragen in de buurt zijn.
//  • Cliënt ≥3 dagen geen hulpvraag → "kan je wel wat hulp gebruiken?".
//  • Familie van zo'n cliënt → zelfde seintje.
//  • Competitie bijna afgelopen / afgerond (top-3 prijs) / ranglijst-wissel (top 3).
// Throttle-velden en vlaggen voorkomen herhaling. Alles als push + inbox.
// ============================================================

import { serviceClient, notifyUsers, haversineKm } from "../_shared/apns.ts";

const MARGIN_KM = 5;
const DAY = 86_400_000;

function daysAgoISO(n: number): string {
  return new Date(Date.now() - n * DAY).toISOString();
}

Deno.serve(async () => {
  const supabase = serviceClient();
  const summary: Record<string, number> = {
    buddyNeighborhood: 0, elderlyReminder: 0, familyReminder: 0,
    competitionEndingSoon: 0, competitionFinished: 0, competitionRankChange: 0,
  };

  try {
    await buddyNeighborhood(supabase, summary);
    await inactivityReminders(supabase, summary);
    await competitions(supabase, summary);
  } catch (e) {
    console.error("notify-scheduled fout:", e);
    return new Response(JSON.stringify({ error: String(e), summary }), { status: 500 });
  }

  return new Response(JSON.stringify({ ok: true, summary }), {
    headers: { "Content-Type": "application/json" },
  });
});

// ---- Buddy: 2 dagen inactief + werk in de buurt ---------------------------

async function buddyNeighborhood(supabase: any, summary: Record<string, number>) {
  const { data: openTasks } = await supabase
    .from("tasks")
    .select("elderly_latitude, elderly_longitude")
    .eq("status", "open");
  if (!openTasks || openTasks.length === 0) return;

  const { data: buddies } = await supabase
    .from("buddy_profiles")
    .select("id, latitude, longitude, max_distance_km, availability_off_since, last_neighborhood_push_at")
    .eq("is_available_now", false)
    .lte("availability_off_since", daysAgoISO(2));

  const throttle = daysAgoISO(2);
  for (const b of buddies ?? []) {
    if (b.last_neighborhood_push_at && b.last_neighborhood_push_at > throttle) continue;

    let nearby = true;
    if (b.latitude != null && b.longitude != null) {
      const radius = (b.max_distance_km ?? 10) + MARGIN_KM;
      nearby = (openTasks as any[]).some((t) =>
        t.elderly_latitude != null && t.elderly_longitude != null &&
        haversineKm(b.latitude, b.longitude, t.elderly_latitude, t.elderly_longitude) <= radius
      );
    }
    if (!nearby) continue;

    await notifyUsers(supabase, [b.id], {
      kind: "neighborhood_needs_you",
      title: "Je buurt heeft je nodig 💙",
      body: "Er zijn hulpvragen bij jou in de buurt. Zet jezelf op beschikbaar om te helpen.",
    });
    await supabase.from("buddy_profiles")
      .update({ last_neighborhood_push_at: new Date().toISOString() })
      .eq("id", b.id);
    summary.buddyNeighborhood++;
  }
}

// ---- Cliënt + familie: 3 dagen geen hulpvraag -----------------------------

async function inactivityReminders(supabase: any, summary: Record<string, number>) {
  // Cliënten die de laatste 3 dagen WEL een taak aanmaakten → niet herinneren.
  const { data: recent } = await supabase
    .from("tasks")
    .select("elderly_id")
    .gte("created_at", daysAgoISO(3));
  const recentSet = new Set((recent ?? []).map((r: { elderly_id: string }) => r.elderly_id));

  const { data: elderly } = await supabase
    .from("elderly_profiles")
    .select("id, last_help_reminder_at, profile:profiles!id(first_name)");

  const throttle = daysAgoISO(3);
  const silentElderly: { id: string; name: string }[] = [];

  for (const e of elderly ?? []) {
    if (recentSet.has(e.id)) continue;
    silentElderly.push({ id: e.id, name: e.profile?.first_name ?? "" });
    if (e.last_help_reminder_at && e.last_help_reminder_at > throttle) continue;
    await notifyUsers(supabase, [e.id], {
      kind: "help_reminder",
      title: "Kan je wel wat hulp gebruiken?",
      body: "Geef het aan — een buddy in de buurt helpt je graag.",
    });
    await supabase.from("elderly_profiles")
      .update({ last_help_reminder_at: new Date().toISOString() })
      .eq("id", e.id);
    summary.elderlyReminder++;
  }

  // Familie van stille cliënten.
  if (!silentElderly.length) return;
  const silentIds = silentElderly.map((e) => e.id);
  const nameById = new Map(silentElderly.map((e) => [e.id, e.name]));

  const { data: links } = await supabase
    .from("family_elderly_links")
    .select("family_id, elderly_id")
    .in("elderly_id", silentIds);

  // Eén melding per familielid (eerste stille cliënt als naam).
  const byFamily = new Map<string, string>();
  for (const l of links ?? []) {
    if (!byFamily.has(l.family_id)) byFamily.set(l.family_id, nameById.get(l.elderly_id) ?? "");
  }
  if (!byFamily.size) return;

  const { data: fams } = await supabase
    .from("profiles")
    .select("id, last_family_reminder_at")
    .in("id", [...byFamily.keys()]);

  for (const f of fams ?? []) {
    if (f.last_family_reminder_at && f.last_family_reminder_at > throttle) continue;
    const naam = byFamily.get(f.id) ?? "";
    await notifyUsers(supabase, [f.id], {
      kind: "help_reminder",
      title: naam ? `Kan ${naam} wel wat hulp gebruiken?` : "Kan je naaste wat hulp gebruiken?",
      body: "Het is even stil. Vraag eventueel hulp aan namens je naaste.",
    });
    await supabase.from("profiles")
      .update({ last_family_reminder_at: new Date().toISOString() })
      .eq("id", f.id);
    summary.familyReminder++;
  }
}

// ---- Competities: bijna af / afgerond / ranglijst-wissel ------------------

async function competitions(supabase: any, summary: Record<string, number>) {
  const nowISO = new Date().toISOString();
  const { data: comps } = await supabase
    .from("competitions")
    .select("id, name, status, ends_at, ending_soon_notified, finished_notified, prize_1_title, prize_2_title, prize_3_title");

  for (const c of comps ?? []) {
    const { data: parts } = await supabase
      .from("competition_participants")
      .select("buddy_id, points, last_rank")
      .eq("competition_id", c.id);
    const ranked = [...(parts ?? [])].sort((a, b) => (b.points ?? 0) - (a.points ?? 0));
    const allIds = ranked.map((p) => p.buddy_id);

    // 1) Afgerond: ends_at voorbij en nog niet afgehandeld.
    if (c.ends_at && c.ends_at < nowISO && !c.finished_notified) {
      const prizes = [c.prize_1_title, c.prize_2_title, c.prize_3_title];
      for (let i = 0; i < ranked.length; i++) {
        const top = i < 3;
        await notifyUsers(supabase, [ranked[i].buddy_id], {
          kind: "competition_result",
          title: top ? `Je eindigde als #${i + 1} in ${c.name}! 🏆` : `${c.name} is afgelopen`,
          body: top
            ? (prizes[i] ? `Je hebt gewonnen: ${prizes[i]}. Je kunt 'm innen!` : "Je staat op het podium — gefeliciteerd!")
            : "Bedankt voor je inzet. Tot de volgende competitie!",
          competitionId: c.id,
        });
      }
      await supabase.from("competitions")
        .update({ status: "afgelopen", finished_notified: true })
        .eq("id", c.id);
      summary.competitionFinished++;
      continue; // afgerond → geen verdere meldingen voor deze competitie
    }

    // 2) Bijna afgelopen (binnen 2 dagen), nog niet gemeld.
    if (c.status === "loopt" && c.ends_at && c.ends_at <= daysAgoISO(-2) && c.ends_at >= nowISO && !c.ending_soon_notified) {
      await notifyUsers(supabase, allIds, {
        kind: "competition_ending_soon",
        title: `${c.name} eindigt bijna!`,
        body: "Maak nog snel wat punten om hoger te eindigen.",
        competitionId: c.id,
      });
      await supabase.from("competitions").update({ ending_soon_notified: true }).eq("id", c.id);
      summary.competitionEndingSoon++;
    }

    // 3) Ranglijst-wissel rond de top 3 (alleen lopende competities).
    if (c.status === "loopt") {
      for (let i = 0; i < ranked.length; i++) {
        const newRank = i + 1;
        const old = ranked[i].last_rank;
        if (old !== newRank) {
          await supabase.from("competition_participants")
            .update({ last_rank: newRank })
            .eq("competition_id", c.id).eq("buddy_id", ranked[i].buddy_id);
        }
        const enteredTop3 = newRank <= 3 && (old == null || old > 3);
        const leftTop3 = newRank > 3 && old != null && old <= 3;
        if (enteredTop3) {
          await notifyUsers(supabase, [ranked[i].buddy_id], {
            kind: "competition_rank_change",
            title: `Je staat nu #${newRank} in ${c.name}! 🔥`,
            body: "Knap werk — houd vol om op het podium te blijven.",
            competitionId: c.id,
          });
          summary.competitionRankChange++;
        } else if (leftTop3) {
          await notifyUsers(supabase, [ranked[i].buddy_id], {
            kind: "competition_rank_change",
            title: `Je bent uit de top 3 gezakt in ${c.name}`,
            body: "Pak een paar hulpvragen op om terug te klimmen.",
            competitionId: c.id,
          });
          summary.competitionRankChange++;
        }
      }
    }
  }
}

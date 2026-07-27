// ============================================================
// Edge Function: notify-team-milestone
//
// Database Webhook op INSERT in `point_events`. Telt de teampunten opnieuw op en
// stuurt een melding bij het bereiken van 75% en 100% van het puntendoel
// (outing_target). Vlaggen op `teams` voorkomen dubbele meldingen.
// Levert push + inbox naar de teamleden.
// ============================================================

import { serviceClient, notifyUsers } from "../_shared/apns.ts";

Deno.serve(async (req) => {
  try {
    const payload = await req.json();
    const record = payload.record ?? payload.new ?? payload;
    const teamId: string | null = record?.team_id ?? null;
    if (!teamId) {
      return new Response(JSON.stringify({ skipped: true, note: "geen team_id" }), {
        headers: { "Content-Type": "application/json" },
      });
    }

    const supabase = serviceClient();

    const { data: team } = await supabase
      .from("teams")
      .select("id, name, outing_target, prize_title, milestone_75_notified, milestone_100_notified")
      .eq("id", teamId)
      .single();
    if (!team) {
      return new Response(JSON.stringify({ skipped: true, note: "team niet gevonden" }), {
        headers: { "Content-Type": "application/json" },
      });
    }

    const { data: members } = await supabase
      .from("team_members")
      .select("buddy_id, points")
      .eq("team_id", teamId);

    const memberIds = (members ?? []).map((m: { buddy_id: string }) => m.buddy_id);
    const total = (members ?? []).reduce((s: number, m: { points: number }) => s + (m.points ?? 0), 0);
    const target = team.outing_target && team.outing_target > 0 ? team.outing_target : 1;
    const pct = total / target;
    const prize = team.prize_title && team.prize_title.length > 0 ? team.prize_title : "jullie teamprijs";

    let action = "none";
    if (pct >= 1 && !team.milestone_100_notified) {
      await notifyUsers(supabase, memberIds, {
        kind: "team_milestone_100",
        title: `${team.name} heeft het doel gehaald! 🎉`,
        body: `Jullie hebben ${prize} verdiend — je kunt 'm innen!`,
        teamId,
      });
      await supabase.from("teams")
        .update({ milestone_100_notified: true, milestone_75_notified: true })
        .eq("id", teamId);
      action = "100";
    } else if (pct >= 0.75 && !team.milestone_75_notified) {
      await notifyUsers(supabase, memberIds, {
        kind: "team_milestone_75",
        title: `${team.name} zit al op 75%!`,
        body: `Nog een laatste zetje voor ${prize}.`,
        teamId,
      });
      await supabase.from("teams").update({ milestone_75_notified: true }).eq("id", teamId);
      action = "75";
    }

    return new Response(JSON.stringify({ ok: true, total, pct, action }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("notify-team-milestone fout:", e);
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 });
  }
});

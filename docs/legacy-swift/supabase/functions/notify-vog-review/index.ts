// ============================================================
// Edge Function: notify-vog-review
//
// Database Webhook op UPDATE in `buddy_profiles`. Eén functie voor alle
// verificatie-meldingen rond de buddy:
//
//  1. ADMINS: zodra een buddy een VOG aanvraagt ('aangevraagd') of een document
//     indient ('in_behandeling') → "er is iets te controleren" (push).
//  2. BUDDY:  zodra de admin de VOG goedkeurt ('geldig') of afwijst ('afgewezen')
//     → melding in de app-inbox + push.
//  3. BUDDY:  zodra de admin de intake goedkeurt (intake_completed false→true)
//     → melding in de app-inbox + push.
//
// buddy_profiles wordt voor van alles geüpdatet (beschikbaarheid, locatie, bio…),
// dus we sturen ALLEEN iets als een van bovenstaande overgangen écht plaatsvindt.
//
// Secrets: APNS_KEY_ID, APNS_TEAM_ID, APNS_BUNDLE_ID, APNS_PRIVATE_KEY.
// ============================================================

import { serviceClient, sendToTokens, notifyUsers } from "../_shared/apns.ts";

const PENDING = ["aangevraagd", "in_behandeling"];

Deno.serve(async (req) => {
  try {
    const payload = await req.json();
    const record = payload.record ?? payload.new ?? payload;
    const oldRecord = payload.old_record ?? payload.old ?? null;

    const newStatus = record?.vog_status;
    const oldStatus = oldRecord?.vog_status;
    const vogChanged = newStatus !== oldStatus;

    // Intake: false → true (alleen de échte overgang naar goedgekeurd).
    const intakeApproved =
      record?.intake_completed === true && oldRecord?.intake_completed !== true;

    const supabase = serviceClient();

    // Naam van de buddy voor een persoonlijke melding (één keer ophalen).
    let buddyName = "Een buddy";
    if (record?.id) {
      const { data: prof } = await supabase
        .from("profiles")
        .select("first_name,last_name")
        .eq("id", record.id)
        .single();
      if (prof) buddyName = `${prof.first_name ?? ""} ${prof.last_name ?? ""}`.trim() || buddyName;
    }

    // --- 1) Admins informeren over een nieuwe/ingediende VOG -------------------
    if (vogChanged && PENDING.includes(newStatus)) {
      const isUpload = newStatus === "in_behandeling";
      const title = "Nieuwe VOG om te controleren";
      const body = isUpload
        ? `${buddyName} heeft een VOG-document ingediend. Bekijk 'm in de app.`
        : `${buddyName} heeft een VOG aangevraagd. Bekijk 'm in de app.`;

      const { data: tokens, error } = await supabase
        .from("device_tokens")
        .select("token")
        .eq("role", "admin");
      if (error) console.error("admin device_tokens ophalen mislukt:", error);

      const result = await sendToTokens(
        (tokens ?? []).map((t: { token: string }) => t.token),
        title,
        body,
        { kind: "vog_review" },
      );
      return json({ target: "admins", ...result });
    }

    // --- 2) Buddy informeren: VOG goedgekeurd of afgewezen --------------------
    if (vogChanged && record?.id && (newStatus === "geldig" || newStatus === "afgewezen")) {
      const approved = newStatus === "geldig";
      const result = await notifyUsers(supabase, [record.id], {
        kind: approved ? "vog_approved" : "vog_rejected",
        title: approved ? "Je VOG is goedgekeurd 🎉" : "Je VOG is afgewezen",
        body: approved
          ? "Je VOG is rond. Nog één stap (de intake) en je kunt hulpvragen aannemen."
          : "Je VOG-aanvraag is afgewezen. Open de app om het opnieuw te proberen.",
      });
      return json({ target: "buddy:vog", ...result });
    }

    // --- 3) Buddy informeren: intake goedgekeurd ------------------------------
    if (intakeApproved && record?.id) {
      const result = await notifyUsers(supabase, [record.id], {
        kind: "intake_approved",
        title: "Je intake is goedgekeurd 🎉",
        body: "Je bent helemaal geverifieerd en kunt nu hulpvragen in de buurt aannemen.",
      });
      return json({ target: "buddy:intake", ...result });
    }

    return json({ skipped: true });
  } catch (e) {
    console.error("notify-vog-review fout:", e);
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 });
  }
});

function json(body: unknown): Response {
  return new Response(JSON.stringify(body), {
    headers: { "Content-Type": "application/json" },
  });
}

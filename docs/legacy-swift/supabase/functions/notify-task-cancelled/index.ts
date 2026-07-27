// ============================================================
// Edge Function: notify-task-cancelled
//
// Wordt door de app (hulpvrager) aangeroepen zodra die een al-aangenomen
// hulpvraag intrekt. Stuurt de toegewezen buddy een push + inbox-melding dat de
// hulpvraag is geannuleerd. We lezen de taak server-side terug en versturen
// alleen als die ook echt 'cancelled' is en er een buddy aan hing — zo kan er
// niemand willekeurig een buddy spammen.
//
// Aanroep vanuit de app: supabase.functions.invoke("notify-task-cancelled",
//   options: .init(body: { "taskId": "<uuid>" })).
//
// Secrets: APNS_KEY_ID, APNS_TEAM_ID, APNS_BUNDLE_ID, APNS_PRIVATE_KEY.
// ============================================================

import { serviceClient, notifyUsers } from "../_shared/apns.ts";

Deno.serve(async (req) => {
  try {
    const payload = await req.json().catch(() => ({}));
    const taskId: string | null = payload.taskId ?? payload.task_id ?? null;
    if (!taskId) {
      return new Response(JSON.stringify({ error: "taskId ontbreekt" }), { status: 400 });
    }

    const supabase = serviceClient();
    const { data: task, error } = await supabase
      .from("tasks")
      .select("id, status, assigned_buddy_id, elderly_first_name")
      .eq("id", taskId)
      .maybeSingle();

    if (error) {
      console.error("taak ophalen mislukt:", error);
      return new Response(JSON.stringify({ error: error.message }), { status: 500 });
    }

    // Alleen melden als de taak echt is ingetrokken en er een buddy aan hing.
    if (!task || task.status !== "cancelled" || !task.assigned_buddy_id) {
      return new Response(JSON.stringify({ skipped: true }), {
        headers: { "Content-Type": "application/json" },
      });
    }

    const firstName: string = task.elderly_first_name ?? "De hulpvrager";
    const result = await notifyUsers(supabase, [task.assigned_buddy_id], {
      kind: "task_cancelled",
      title: "Hulpvraag ingetrokken",
      body: `${firstName} heeft de hulpvraag geannuleerd. Je hoeft niet meer te komen.`,
    });

    return new Response(JSON.stringify(result), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("notify-task-cancelled fout:", e);
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 });
  }
});

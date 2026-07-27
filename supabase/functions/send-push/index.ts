// Stuurt één melding als push via de Expo Push API.
// Aangeroepen door de database-trigger `notifications_push` met { id }.
import { createClient } from 'jsr:@supabase/supabase-js@2';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

Deno.serve(async (request) => {
  try {
    const { id } = await request.json();
    if (!id) return new Response('id ontbreekt', { status: 400 });

    const { data: notification } = await supabase
      .from('notifications')
      .select('id, profile_id, title, body, deeplink, pushed_at')
      .eq('id', id)
      .single();
    if (!notification || notification.pushed_at) {
      return new Response('niets te doen', { status: 200 });
    }

    const { data: tokens } = await supabase
      .from('device_tokens')
      .select('token')
      .eq('profile_id', notification.profile_id);

    if (tokens && tokens.length > 0) {
      const messages = tokens.map((row) => ({
        to: row.token,
        title: notification.title,
        body: notification.body ?? undefined,
        data: { deeplink: notification.deeplink },
        sound: 'default',
      }));
      const response = await fetch('https://exp.host/--/api/v2/push/send', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(messages),
      });
      const result = await response.json();
      // Ongeldige tokens opruimen (DeviceNotRegistered).
      const tickets = Array.isArray(result?.data) ? result.data : [];
      for (let i = 0; i < tickets.length; i++) {
        if (tickets[i]?.details?.error === 'DeviceNotRegistered') {
          await supabase.from('device_tokens').delete().eq('token', tokens[i]!.token);
        }
      }
    }

    await supabase
      .from('notifications')
      .update({ pushed_at: new Date().toISOString() })
      .eq('id', id);

    return new Response('ok', { status: 200 });
  } catch (error) {
    console.error('send-push', error);
    return new Response('fout', { status: 500 });
  }
});

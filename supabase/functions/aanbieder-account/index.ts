// Aanbieder-account aanmaken (17-08). Aanbieders kunnen zich niet zelf
// aanmelden: Thuisverzorgd maakt hier een account met gebruikersnaam +
// wachtwoord en koppelt het aan een providers-rij. Wie met dat account inlogt,
// heeft rol 'aanbieder' en landt automatisch in Mijn agenda.
//
// Alleen een admin (profiel met role 'admin' of platform_admin) mag dit
// aanroepen. Heeft de aanbieder al een account, dan wordt alleen het
// wachtwoord opnieuw gezet.
import { createClient } from 'jsr:@supabase/supabase-js@2';

const admin = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

const GEBRUIKERSNAAM = /^[a-z0-9._-]{3,24}$/;
const MIN_WACHTWOORD = 8;

function antwoord(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

Deno.serve(async (request) => {
  try {
    // 1. Alleen ingelogde admins.
    const token = request.headers.get('Authorization')?.replace('Bearer ', '');
    if (!token) return antwoord(401, { error: 'geen_token' });
    const { data: userData, error: userError } = await admin.auth.getUser(token);
    if (userError || !userData.user) return antwoord(401, { error: 'ongeldig_token' });

    const { data: caller } = await admin
      .from('profiles')
      .select('role, platform_admin')
      .eq('id', userData.user.id)
      .single();
    if (!caller || (caller.role !== 'admin' && caller.platform_admin !== true)) {
      return antwoord(403, { error: 'geen_admin' });
    }

    // 2. Invoer.
    const { provider_id, username, password } = await request.json();
    const naam = String(username ?? '')
      .trim()
      .toLowerCase();
    const wachtwoord = String(password ?? '');
    if (!provider_id) return antwoord(400, { error: 'aanbieder_verplicht' });
    if (wachtwoord.length < MIN_WACHTWOORD) return antwoord(400, { error: 'wachtwoord_kort' });

    const { data: provider } = await admin
      .from('providers')
      .select('id, name, business, profile_id')
      .eq('id', provider_id)
      .single();
    if (!provider) return antwoord(404, { error: 'aanbieder_onbekend' });

    // 3. Al een account? Dan alleen het wachtwoord opnieuw zetten.
    if (provider.profile_id) {
      const { error: resetError } = await admin.auth.admin.updateUserById(provider.profile_id, {
        password: wachtwoord,
      });
      if (resetError) throw resetError;
      const { data: bestaand } = await admin
        .from('profiles')
        .select('username')
        .eq('id', provider.profile_id)
        .single();
      return antwoord(200, { status: 'wachtwoord_gereset', username: bestaand?.username ?? '' });
    }

    // 4. Nieuw account: zelfde constructie als gewone gebruikersnaam-accounts
    // (<naam>@tvz.invalid, zie migratie gebruikersnaam) zodat inloggen met
    // gebruikersnaam + wachtwoord gewoon via het bestaande inlogscherm werkt.
    if (!GEBRUIKERSNAAM.test(naam)) return antwoord(400, { error: 'gebruikersnaam_ongeldig' });
    const { data: created, error: createError } = await admin.auth.admin.createUser({
      email: `${naam}@tvz.invalid`,
      password: wachtwoord,
      email_confirm: true,
      user_metadata: { name: provider.name },
    });
    if (createError) {
      const bezet =
        createError.message?.includes('already') || (createError as { status?: number }).status === 422;
      return antwoord(bezet ? 409 : 500, { error: bezet ? 'gebruikersnaam_bezet' : 'aanmaken_mislukt' });
    }

    // 5. Rol en koppeling; de service-role mag langs prevent_role_change.
    const uid = created.user.id;
    const { error: rolError } = await admin
      .from('profiles')
      .update({ role: 'aanbieder', name: provider.name })
      .eq('id', uid);
    if (rolError) throw rolError;
    const { error: linkError } = await admin
      .from('providers')
      .update({ profile_id: uid })
      .eq('id', provider.id);
    if (linkError) throw linkError;

    return antwoord(200, { status: 'aangemaakt', username: naam });
  } catch (error) {
    console.error('aanbieder-account', error);
    return antwoord(500, { error: 'fout' });
  }
});

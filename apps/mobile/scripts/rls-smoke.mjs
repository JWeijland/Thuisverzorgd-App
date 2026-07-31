/**
 * RLS-smoke-test tegen het gekoppelde Supabase-project.
 * Bewijst de harde eisen uit Fase 3:
 *  1. een niet-lid kan géén kringdata lezen (circles, tasks, messages, drafts, profielen)
 *  2. een lid kan dat wél, en claim_task is race-veilig gedragen
 *  3. de gratis limiet (2 vrijwilligers) wordt server-side afgedwongen
 *  4. adres van directe hulp is pas opvraagbaar na acceptatie
 *
 * Draaien:  node scripts/rls-smoke.mjs
 * Vereist env: SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY
 * (de service-key wordt alleen lokaal gebruikt om testgebruikers aan te maken/op te ruimen)
 */
import { createClient } from '@supabase/supabase-js';

const URL = process.env.SUPABASE_URL;
const ANON = process.env.SUPABASE_ANON_KEY;
const SERVICE = process.env.SUPABASE_SERVICE_ROLE_KEY;
if (!URL || !ANON || !SERVICE) {
  console.error('Zet SUPABASE_URL, SUPABASE_ANON_KEY en SUPABASE_SERVICE_ROLE_KEY.');
  process.exit(2);
}

const admin = createClient(URL, SERVICE, { auth: { persistSession: false } });
const run = Date.now();
let failures = 0;
const createdUsers = [];

function check(name, ok, extra = '') {
  const icon = ok ? '✅' : '❌';
  console.log(`${icon} ${name}${extra ? ` — ${extra}` : ''}`);
  if (!ok) failures += 1;
}

async function makeUser(label, role, opts = {}) {
  const email = `rls-${label}-${run}@example.com`;
  const password = `Testwachtwoord!${run}`;
  const { data, error } = await admin.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
    user_metadata: { name: opts.name ?? label },
  });
  if (error) throw new Error(`createUser ${label}: ${error.message}`);
  createdUsers.push(data.user.id);
  const patch = { role, ...(opts.profile ?? {}) };
  const { error: e2 } = await admin.from('profiles').update(patch).eq('id', data.user.id);
  if (e2) throw new Error(`profiel ${label}: ${e2.message}`);
  const client = createClient(URL, ANON, { auth: { persistSession: false } });
  const { error: e3 } = await client.auth.signInWithPassword({ email, password });
  if (e3) throw new Error(`login ${label}: ${e3.message}`);
  return { id: data.user.id, client };
}

try {
  // Gebruikers: A = beheerder, C/D/E = vrijwilligers (lid), B = vrijwilliger (géén lid)
  const A = await makeUser('beheerder', 'beheerder', { name: 'Jelle Test' });
  const B = await makeUser('buitenstaander', 'vrijwilliger', {
    name: 'Bram Buiten',
    profile: { id_verified: true, id_verified_at: new Date().toISOString() },
  });
  const C = await makeUser('lid', 'vrijwilliger', {
    name: 'Anna Lid',
    profile: { id_verified: true, id_verified_at: new Date().toISOString() },
  });
  const D = await makeUser('lid2', 'vrijwilliger', { name: 'Tim Lid' });
  const E = await makeUser('lid3', 'vrijwilliger', { name: 'Sophie Lid' });

  // A maakt een kring met een taak, bericht en conceptplanning
  const { data: circle, error: ce } = await A.client
    .from('circles')
    .insert({ owner_id: A.id, name: 'Kring van mevrouw Test', address: 'Teststraat 1, Zeist' })
    .select()
    .single();
  if (ce) throw new Error(`kring aanmaken: ${ce.message}`);

  await A.client.from('circle_members').insert({
    circle_id: circle.id,
    profile_id: A.id,
    member_role: 'beheerder',
    status: 'actief',
  });
  const { error: me } = await A.client.from('circle_members').insert({
    circle_id: circle.id,
    profile_id: C.id,
    member_role: 'vrijwilliger',
    status: 'actief',
  });
  check('beheerder voegt vrijwilliger 1 toe', !me, me?.message);

  const { data: task } = await A.client
    .from('tasks')
    .insert({
      circle_id: circle.id,
      type: 'boodschappen',
      date: '2026-07-31',
      time: '14:00',
      created_by: A.id,
    })
    .select()
    .single();
  await A.client.from('messages').insert({
    circle_id: circle.id,
    sender_id: A.id,
    body: 'Zou iemand donderdag kunnen helpen?',
  });
  await A.client.from('task_drafts').insert({
    circle_id: circle.id,
    type: 'wandelen',
    date: '2026-08-03',
    time: '10:30',
    created_by: A.id,
  });

  // 1. NIET-LID (B) mag niets van de kring zien
  const b1 = await B.client.from('circles').select('*');
  check('niet-lid ziet geen kringen', (b1.data ?? []).length === 0);
  const b2 = await B.client.from('tasks').select('*');
  check('niet-lid ziet geen taken', (b2.data ?? []).length === 0);
  const b3 = await B.client.from('messages').select('*');
  check('niet-lid ziet geen kringchat', (b3.data ?? []).length === 0);
  const b4 = await B.client.from('task_drafts').select('*');
  check('niet-lid ziet geen conceptplanning', (b4.data ?? []).length === 0);
  const b5 = await B.client.from('profiles').select('*').eq('id', A.id);
  check('niet-lid ziet profiel beheerder niet', (b5.data ?? []).length === 0);
  const b6 = await B.client.rpc('claim_task', { p_task: task.id });
  check('niet-lid kan taak niet claimen', Boolean(b6.error), b6.error?.message);
  const b7 = await B.client.from('circle_members').select('*');
  check('niet-lid ziet geen ledenlijst', (b7.data ?? []).length === 0);

  // 2. LID (C) ziet de kring en claimt race-veilig
  const c1 = await C.client.from('circles').select('*');
  check('lid ziet de kring', (c1.data ?? []).length === 1);
  const c2 = await C.client.rpc('claim_task', { p_task: task.id });
  check('lid claimt open taak', c2.data === true, c2.error?.message);
  const c3 = await C.client.rpc('claim_task', { p_task: task.id });
  check('tweede claim op dezelfde taak faalt', c3.data === false);
  const c4 = await C.client.rpc('complete_task', { p_task: task.id, p_note: 'Ging gezellig!' });
  check('lid rondt af met logboekje', c4.data === true, c4.error?.message);
  const a1 = await A.client.from('task_logs').select('*').eq('circle_id', circle.id);
  check('beheerder ziet notitie "Uit de kring"', (a1.data ?? []).length === 1);

  // conceptplanning blijft onzichtbaar voor leden tot publicatie
  const c5 = await C.client.from('task_drafts').select('*');
  check('lid ziet conceptplanning niet', (c5.data ?? []).length === 0);

  // 3. Gratis limiet: 2e vrijwilliger mag, 3e niet zonder abonnement
  const d1 = await A.client.from('circle_members').insert({
    circle_id: circle.id,
    profile_id: D.id,
    member_role: 'vrijwilliger',
    status: 'actief',
  });
  check('vrijwilliger 2 mag erbij (gratis)', !d1.error, d1.error?.message);
  const e1 = await A.client.from('circle_members').insert({
    circle_id: circle.id,
    profile_id: E.id,
    member_role: 'vrijwilliger',
    status: 'actief',
  });
  check('vrijwilliger 3 geweigerd zonder abonnement', Boolean(e1.error), e1.error?.message);
  await A.client.rpc('activate_subscription_stub');
  const e2 = await A.client.from('circle_members').insert({
    circle_id: circle.id,
    profile_id: E.id,
    member_role: 'vrijwilliger',
    status: 'actief',
  });
  check('vrijwilliger 3 mag erbij mét abonnement', !e2.error, e2.error?.message);

  // 4. Directe hulp: adres pas na acceptatie
  const { data: req } = await A.client
    .from('spontaneous_requests')
    .insert({
      requester_id: A.id,
      type: 'vervoer',
      address: 'Geheime Straat 12',
      note: 'Vervoer naar de apotheek',
    })
    .select()
    .single();
  const v1 = await B.client.from('v_open_requests').select('*').eq('id', req.id);
  check(
    'vrijwilliger ziet open aanvraag (zonder adres)',
    (v1.data ?? []).length === 1 && !('address' in (v1.data?.[0] ?? {})),
  );
  const g1 = await B.client.rpc('get_request_address', { p_request: req.id });
  check('adres geweigerd vóór acceptatie', Boolean(g1.error));
  const { data: offer, error: oe } = await B.client
    .from('request_offers')
    .insert({ request_id: req.id, volunteer_id: B.id, message: 'Ik kan er over 15 minuten zijn!' })
    .select()
    .single();
  check('vrijwilliger doet aanbod met berichtje', !oe, oe?.message);
  const acc = await A.client.rpc('accept_offer', { p_offer: offer.id });
  check('aanvrager accepteert aanbod', acc.data === true, acc.error?.message);
  const g2 = await B.client.rpc('get_request_address', { p_request: req.id });
  check('adres zichtbaar ná acceptatie', g2.data === 'Geheime Straat 12', g2.error?.message);

  // 5. Rol wijzigen mag niet
  const r1 = await B.client.from('profiles').update({ role: 'admin' }).eq('id', B.id).select();
  check(
    'eigen rol wijzigen geweigerd',
    Boolean(r1.error) || (r1.data ?? []).length === 0,
    r1.error?.message,
  );
} catch (err) {
  console.error('❌ Testrun brak af:', err.message);
  failures += 1;
} finally {
  for (const id of createdUsers) {
    await admin.auth.admin.deleteUser(id).catch(() => {});
  }
  console.log(`\nOpruimen klaar (${createdUsers.length} testgebruikers verwijderd).`);
}

if (failures > 0) {
  console.error(`\n${failures} check(s) gefaald.`);
  process.exit(1);
}
console.log('\nAlle RLS-checks geslaagd.');

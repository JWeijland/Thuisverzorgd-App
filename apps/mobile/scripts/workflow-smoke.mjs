/**
 * Workflow-smoke-test: nepaccounts per rol doorlopen de echte gebruikersflows
 * en we controleren of de rollen correct met elkaar communiceren.
 *
 *  A. kring aanmaken → buddy uitnodigen → melding + push → aannemen (met bericht terug)
 *  B. taken: publiceren, claimen, annuleren, weekreeks
 *  C. kringchat: bericht → melding bij alle leden behalve afzender
 *  D. directe hulp: aanbod met berichtje, accepteren, afwijzen, intrekken
 *  E. forum-antwoord en hulpmakelaar-chat
 *  F. meldingsvoorkeuren en vakantiemodus worden gerespecteerd
 *  G. pushpijplijn: notificatie → edge function → pushed_at + tokenopruiming
 *
 * Draaien:  node scripts/workflow-smoke.mjs
 * Vereist env: SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY
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

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

/** Poll tot fn een truthy waarde geeft (of timeout). */
async function waitFor(fn, timeoutMs = 15000, stepMs = 1000) {
  const start = Date.now();
  for (;;) {
    const value = await fn();
    if (value) return value;
    if (Date.now() - start > timeoutMs) return null;
    await sleep(stepMs);
  }
}

/** Meldingen van een gebruiker ophalen (eigen client, dus onder RLS). */
async function meldingen(user, kind) {
  const { data, error } = await user.client
    .from('notifications')
    .select('*')
    .eq('kind', kind)
    .order('created_at', { ascending: false });
  if (error) throw new Error(`meldingen ${kind}: ${error.message}`);
  return data ?? [];
}

async function makeUser(label, role, opts = {}) {
  const email = `wf-${label}-${run}@example.com`;
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
  return { id: data.user.id, email, client, name: opts.name ?? label };
}

try {
  console.log('— Nepaccounts aanmaken —');
  const ans = await makeUser('ans', 'beheerder', { name: 'Ans Beheerder' });
  const bert = await makeUser('bert', 'vrijwilliger', {
    name: 'Bert Buddy',
    profile: { id_verified: true, id_verified_at: new Date().toISOString() },
  });
  const carla = await makeUser('carla', 'vrijwilliger', {
    name: 'Carla Buddy',
    profile: { id_verified: true, id_verified_at: new Date().toISOString() },
  });
  const dirk = await makeUser('dirk', 'vrijwilliger', {
    name: 'Dirk Buddy',
    profile: { id_verified: true, id_verified_at: new Date().toISOString() },
  });
  const els = await makeUser('els', 'hulpvrager', { name: 'Els Hulpvrager' });
  const mia = await makeUser('mia', 'makelaar', { name: 'Mia Makelaar' });

  // =========================================================================
  console.log('\n— A. Kring aanmaken en buddy uitnodigen —');
  const { data: circle, error: ce } = await ans.client
    .from('circles')
    .insert({ owner_id: ans.id, name: 'Kring van meneer De Vries', address: 'Teststraat 1, Zeist' })
    .select()
    .single();
  if (ce) throw new Error(`kring aanmaken: ${ce.message}`);
  await ans.client.from('circle_members').insert({
    circle_id: circle.id,
    profile_id: ans.id,
    member_role: 'beheerder',
    status: 'actief',
  });

  const inv1 = await ans.client.rpc('create_invitation', {
    p_circle: circle.id,
    p_target: bert.email,
    p_message: 'Help je mee bij meneer De Vries? Vooral boodschappen en gezelschap.',
  });
  check('beheerder nodigt buddy uit met bericht', !inv1.error, inv1.error?.message);

  const bertUitnodiging = await waitFor(async () => (await meldingen(bert, 'uitnodiging'))[0]);
  check('buddy krijgt in-app melding van de uitnodiging', Boolean(bertUitnodiging));
  check(
    'melding noemt de kring en linkt naar het beoordeel-scherm',
    bertUitnodiging?.title?.includes('Kring van meneer De Vries') &&
      bertUitnodiging?.deeplink?.startsWith('tvz://aanvraag/'),
    `title=${bertUitnodiging?.title} deeplink=${bertUitnodiging?.deeplink}`,
  );
  const pushed1 = await waitFor(async () => {
    const { data } = await admin
      .from('notifications')
      .select('pushed_at')
      .eq('id', bertUitnodiging?.id)
      .single();
    return data?.pushed_at;
  });
  check('pushpijplijn draaide voor de uitnodiging (pushed_at gezet)', Boolean(pushed1));

  const acc1 = await bert.client.rpc('respond_invitation', {
    p_invitation: inv1.data,
    p_accept: true,
    p_message: 'Leuk! Ik kom dinsdag graag kennismaken.',
  });
  check('buddy accepteert de uitnodiging', acc1.data === true, acc1.error?.message);
  const bertLid = await ans.client
    .from('circle_members')
    .select('*')
    .eq('circle_id', circle.id)
    .eq('profile_id', bert.id)
    .eq('status', 'actief');
  check('buddy is daarna actief lid', (bertLid.data ?? []).length === 1);
  const ansAntwoord = await waitFor(
    async () => (await meldingen(ans, 'uitnodiging_antwoord'))[0],
    8000,
  );
  check(
    'beheerder krijgt melding dat de buddy heeft aangenomen, met berichtje',
    Boolean(ansAntwoord) && ansAntwoord.body?.includes('dinsdag'),
    ansAntwoord ? ansAntwoord.body : 'GEEN melding: respond_invitation stuurt niets terug naar de beheerder',
  );

  const join1 = await carla.client.rpc('request_to_join_circle', {
    p_circle: circle.id,
    p_message: 'Ik woon om de hoek en help graag met wandelen.',
  });
  check('tweede buddy meldt zich aan met voorstelbericht', !join1.error, join1.error?.message);
  const ansAanvraag = await waitFor(async () =>
    (await meldingen(ans, 'uitnodiging')).find((n) => n.title === 'Aanvraag voor je kring'),
  );
  check('beheerder krijgt melding van de aanvraag', Boolean(ansAanvraag));
  const acc2 = await ans.client.rpc('respond_invitation', {
    p_invitation: join1.data,
    p_accept: true,
    p_message: 'Welkom Carla, fijn dat je meedoet!',
  });
  check('beheerder accepteert de aanvraag', acc2.data === true, acc2.error?.message);
  const carlaAntwoord = await waitFor(
    async () => (await meldingen(carla, 'uitnodiging_antwoord'))[0],
    8000,
  );
  check(
    'buddy krijgt melding dat haar aanvraag is geaccepteerd, met berichtje',
    Boolean(carlaAntwoord) && carlaAntwoord.body?.includes('Welkom Carla'),
    carlaAntwoord ? carlaAntwoord.body : 'GEEN melding: respond_invitation stuurt niets terug naar de aanvrager',
  );

  // =========================================================================
  console.log('\n— B. Taken: publiceren, claimen, annuleren, weekreeks —');
  const { data: task, error: te } = await ans.client
    .from('tasks')
    .insert({
      circle_id: circle.id,
      type: 'boodschappen',
      date: '2026-08-14',
      time: '14:00',
      created_by: ans.id,
    })
    .select()
    .single();
  check('beheerder publiceert taak', !te, te?.message);
  const bertTaak = await waitFor(async () =>
    (await meldingen(bert, 'taak_nieuw')).find((n) => n.body?.includes('14-08')),
  );
  const carlaTaak = await waitFor(async () =>
    (await meldingen(carla, 'taak_nieuw')).find((n) => n.body?.includes('14-08')),
  );
  check('beide buddy’s krijgen "nieuwe taak"-melding', Boolean(bertTaak && carlaTaak));
  const ansTaakEigen = (await meldingen(ans, 'taak_nieuw')).length;
  check('beheerder krijgt zijn eigen taak niet gemeld', ansTaakEigen === 0);

  const claim = await bert.client.rpc('claim_task', { p_task: task.id });
  check('buddy claimt de taak', claim.data === true, claim.error?.message);
  const ansClaim = await waitFor(async () => (await meldingen(ans, 'taak_geclaimd'))[0]);
  check(
    'beheerder ziet wie de taak aanneemt',
    Boolean(ansClaim) && ansClaim.title.startsWith('Bert'),
    ansClaim?.title,
  );

  const cancel = await ans.client.rpc('cancel_task', { p_task: task.id });
  check('beheerder trekt de taak in', cancel.data === true, cancel.error?.message);
  const bertAnnulering = await waitFor(async () => (await meldingen(bert, 'taak_geannuleerd'))[0]);
  check('buddy hoort dat de taak niet doorgaat', Boolean(bertAnnulering));

  const voorBert = (await meldingen(bert, 'taak_nieuw')).length;
  const { error: se } = await ans.client.from('tasks').insert({
    circle_id: circle.id,
    type: 'wandelen',
    date: '2026-08-17',
    time: '10:30',
    recurrence: 'wekelijks',
    created_by: ans.id,
  });
  check('weekreeks aanmaken lukt', !se, se?.message);
  const reeks = await admin
    .from('tasks')
    .select('id')
    .eq('circle_id', circle.id)
    .eq('type', 'wandelen');
  check('reeks plant 8 weken vooruit', (reeks.data ?? []).length === 8);
  await sleep(4000);
  const naBert = (await meldingen(bert, 'taak_nieuw')).length;
  check('reeks meldt maar één keer (niet 8 losse meldingen)', naBert === voorBert + 1, `${naBert - voorBert} meldingen`);

  // =========================================================================
  console.log('\n— C. Kringchat en hulpvrager —');
  const { error: msgErr } = await bert.client.from('messages').insert({
    circle_id: circle.id,
    sender_id: bert.id,
    body: 'Ik doe morgen de boodschappen, iemand nog iets nodig?',
  });
  check('buddy stuurt kringbericht', !msgErr, msgErr?.message);
  const ansChat = await waitFor(async () => (await meldingen(ans, 'kringbericht'))[0]);
  const carlaChat = await waitFor(async () => (await meldingen(carla, 'kringbericht'))[0]);
  check('beheerder en andere buddy krijgen chatmelding', Boolean(ansChat && carlaChat));
  check(
    'chatmelding toont afzender en tekst',
    ansChat?.title?.startsWith('Bert') && ansChat?.body?.includes('boodschappen'),
    ansChat?.title,
  );
  const bertChatEigen = (await meldingen(bert, 'kringbericht')).length;
  check('afzender krijgt zijn eigen bericht niet gemeld', bertChatEigen === 0);

  await admin.from('circle_members').insert({
    circle_id: circle.id,
    profile_id: els.id,
    member_role: 'hulpvrager',
    status: 'actief',
  });
  const vb = await els.client.rpc('vraag_buddy', {
    p_circle: circle.id,
    p_type: 'gezelschap',
    p_date: '2026-08-15',
  });
  check('hulpvrager vraagt zelf een buddy', !vb.error, vb.error?.message);
  const bertVraag = await waitFor(async () =>
    (await meldingen(bert, 'taak_nieuw')).find((n) => n.body?.includes('15-08')),
  );
  check('buddy’s krijgen melding van de buddy-vraag', Boolean(bertVraag));

  // =========================================================================
  console.log('\n— D. Directe hulp: aanbod, accepteren, afwijzen, intrekken —');
  const { data: req, error: re } = await els.client
    .from('spontaneous_requests')
    .insert({
      requester_id: els.id,
      type: 'vervoer',
      address: 'Geheime Straat 12, Zeist',
      note: 'Vervoer naar de fysiotherapeut',
    })
    .select()
    .single();
  check('hulpvrager plaatst directe hulpvraag', !re, re?.message);

  const open1 = await bert.client.from('v_open_requests').select('*').eq('id', req.id);
  check(
    'buddy ziet open aanvraag zonder adres',
    (open1.data ?? []).length === 1 && !('address' in (open1.data?.[0] ?? {})),
  );
  const { data: offerBert } = await bert.client
    .from('request_offers')
    .insert({ request_id: req.id, volunteer_id: bert.id, message: 'Ik kan er om 14:00 zijn met de auto!' })
    .select()
    .single();
  await carla.client
    .from('request_offers')
    .insert({ request_id: req.id, volunteer_id: carla.id, message: 'Ik kan ook, iets later.' });
  const elsAanbod = await waitFor(async () => (await meldingen(els, 'aanbod'))[0]);
  check(
    'hulpvrager krijgt aanbod-melding met naam en berichtje',
    Boolean(elsAanbod) && elsAanbod.body?.length > 0,
    elsAanbod?.title,
  );

  const accOffer = await els.client.rpc('accept_offer', { p_offer: offerBert.id });
  check('hulpvrager accepteert het aanbod', accOffer.data === true, accOffer.error?.message);
  const bertJa = await waitFor(async () =>
    (await meldingen(bert, 'aanbod_antwoord')).find((n) => n.title === 'Je kunt helpen!'),
  );
  const carlaNee = await waitFor(async () =>
    (await meldingen(carla, 'aanbod_antwoord')).find((n) => n.title === 'Dit keer niet'),
  );
  check('gekozen buddy krijgt ja-melding', Boolean(bertJa));
  check('andere buddy krijgt nette afwijzing', Boolean(carlaNee));
  const adres = await bert.client.rpc('get_request_address', { p_request: req.id });
  check('adres pas zichtbaar na acceptatie', adres.data === 'Geheime Straat 12, Zeist', adres.error?.message);

  const { data: req2 } = await els.client
    .from('spontaneous_requests')
    .insert({ requester_id: els.id, type: 'boodschappen', address: 'Teststraat 2', note: 'Klein boodschappenlijstje' })
    .select()
    .single();
  const { data: offer2 } = await carla.client
    .from('request_offers')
    .insert({ request_id: req2.id, volunteer_id: carla.id, message: 'Doe ik!' })
    .select()
    .single();
  await els.client.rpc('accept_offer', { p_offer: offer2.id });
  const cancelReq = await els.client
    .from('spontaneous_requests')
    .update({ status: 'geannuleerd', cancelled_message: 'Mijn dochter komt toch langs, sorry!' })
    .eq('id', req2.id);
  check('hulpvrager trekt aanvraag in', !cancelReq.error, cancelReq.error?.message);
  const carlaIngetrokken = await waitFor(async () => (await meldingen(carla, 'aanvraag_ingetrokken'))[0]);
  check(
    'helper hoort de intrekking met persoonlijk bericht',
    Boolean(carlaIngetrokken) && carlaIngetrokken.body?.includes('dochter'),
    carlaIngetrokken?.body,
  );

  // =========================================================================
  console.log('\n— E. Forum en hulpmakelaar —');
  const { data: post, error: pe } = await ans.client
    .from('forum_posts')
    .insert({ author_id: ans.id, title: 'Hoe combineren jullie werk en zorg?', body: 'Ik loop vast met mijn rooster.' })
    .select()
    .single();
  check('beheerder plaatst forumvraag', !pe, pe?.message);
  await bert.client
    .from('forum_replies')
    .insert({ post_id: post.id, author_id: bert.id, body: 'Bij ons hielp een vaste weekplanning enorm.' });
  const ansForum = await waitFor(async () => (await meldingen(ans, 'forum_antwoord'))[0]);
  check('vraagsteller krijgt melding van het antwoord', Boolean(ansForum));

  const { data: chat, error: bce } = await els.client
    .from('broker_chats')
    .insert({ profile_id: els.id })
    .select()
    .single();
  check('hulpvrager start makelaar-chat', !bce, bce?.message);
  await els.client
    .from('broker_messages')
    .insert({ chat_id: chat.id, sender_id: els.id, body: 'Ik zoek hulp bij het aanvragen van een indicatie.' });
  const miaZietChat = await mia.client.from('broker_chats').select('*').eq('id', chat.id);
  check('makelaar ziet de chat', (miaZietChat.data ?? []).length === 1);
  const { error: bme } = await mia.client
    .from('broker_messages')
    .insert({ chat_id: chat.id, sender_id: mia.id, body: 'Dat kan via het CIZ, ik stuur u de stappen.' });
  check('makelaar antwoordt in de chat', !bme, bme?.message);
  const elsMakelaar = await waitFor(async () => (await meldingen(els, 'makelaar'))[0]);
  check('hulpvrager krijgt melding van het antwoord', Boolean(elsMakelaar));

  // =========================================================================
  console.log('\n— F. Meldingsvoorkeuren en vakantiemodus —');
  await admin.from('circle_members').insert({
    circle_id: circle.id,
    profile_id: dirk.id,
    member_role: 'vrijwilliger',
    status: 'actief',
  });
  await admin
    .from('profiles')
    .update({ notification_prefs: { kringbericht: false } })
    .eq('id', dirk.id);
  await ans.client.from('messages').insert({
    circle_id: circle.id,
    sender_id: ans.id,
    body: 'Welkom Dirk in de kring!',
  });
  await sleep(4000);
  const dirkChat = (await meldingen(dirk, 'kringbericht')).length;
  check('uitgezette categorie geeft geen melding', dirkChat === 0);

  await admin.from('profiles').update({ vacation_mode: true }).eq('id', dirk.id);
  const voorVak = (await meldingen(dirk, 'taak_nieuw')).length;
  await ans.client.from('tasks').insert({
    circle_id: circle.id,
    type: 'vervoer',
    date: '2026-08-20',
    time: '09:00',
    created_by: ans.id,
  });
  await sleep(4000);
  const naVak = (await meldingen(dirk, 'taak_nieuw')).length;
  check('vakantiemodus onderdrukt taaksuggesties', naVak === voorVak);

  // =========================================================================
  console.log('\n— G. Pushpijplijn en tokenopruiming —');
  const fakeToken = `ExponentPushToken[wf-test-${run}]`;
  const { error: dte } = await bert.client
    .from('device_tokens')
    .insert({ token: fakeToken, profile_id: bert.id, platform: 'ios' });
  check('buddy registreert pushtoken', !dte, dte?.message);
  await ans.client.from('messages').insert({
    circle_id: circle.id,
    sender_id: ans.id,
    body: 'Nog een berichtje voor de pushtest.',
  });
  const bertPush = await waitFor(async () => {
    const rows = await meldingen(bert, 'kringbericht');
    return rows.find((n) => n.body?.includes('pushtest') && n.pushed_at);
  });
  check('melding is via de pushpijplijn verwerkt', Boolean(bertPush));
  const tokenWeg = await waitFor(async () => {
    const { data } = await admin.from('device_tokens').select('token').eq('token', fakeToken);
    return (data ?? []).length === 0;
  }, 10000);
  check('ongeldig token wordt opgeruimd (DeviceNotRegistered)', Boolean(tokenWeg));
} catch (err) {
  console.error('❌ Testrun brak af:', err.message);
  failures += 1;
} finally {
  console.log('\n— Opruimen —');
  for (const id of createdUsers) {
    await admin.auth.admin.deleteUser(id).catch(() => {});
  }
  console.log(`Opruimen klaar (${createdUsers.length} nepaccounts verwijderd).`);
}

if (failures > 0) {
  console.error(`\n${failures} check(s) gefaald.`);
  process.exit(1);
}
console.log('\nAlle workflow-checks geslaagd.');

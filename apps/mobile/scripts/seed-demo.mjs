/**
 * Seed-script: vult het gekoppelde Supabase-project met fictieve demo-data
 * (namen uit het prototype: Anna de Wit, Tim Bakker, Sophie van Dijk, mevrouw Jansen).
 *
 * Draaien:  node scripts/seed-demo.mjs
 * Vereist env: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
 * Alle accounts loggen in met wachtwoord "DemoThuisverzorgd1!".
 */
import { createClient } from '@supabase/supabase-js';

const URL = process.env.SUPABASE_URL;
const SERVICE = process.env.SUPABASE_SERVICE_ROLE_KEY;
if (!URL || !SERVICE) {
  console.error('Zet SUPABASE_URL en SUPABASE_SERVICE_ROLE_KEY.');
  process.exit(2);
}
const admin = createClient(URL, SERVICE, { auth: { persistSession: false } });
const PASSWORD = 'DemoThuisverzorgd1!';

async function upsertUser(email, name, role, extra = {}) {
  const { data: existing } = await admin
    .from('profiles')
    .select('id')
    .eq('email', email)
    .maybeSingle();
  let id = existing?.id;
  if (!id) {
    const { data, error } = await admin.auth.admin.createUser({
      email,
      password: PASSWORD,
      email_confirm: true,
      user_metadata: { name },
    });
    if (error) throw new Error(`${email}: ${error.message}`);
    id = data.user.id;
  }
  await admin
    .from('profiles')
    .update({ role, name, ...extra })
    .eq('id', id);
  console.log(`✓ ${name} (${role})`);
  return id;
}

function nextDate(dayOffset) {
  const d = new Date();
  d.setDate(d.getDate() + dayOffset);
  return d.toISOString().slice(0, 10);
}

const jelle = await upsertUser('demo-beheerder@thuisverzorgd.dev', 'Jelle de Boer', 'beheerder', {
  city: 'Amsterdam',
  phone: '0612345678',
});
const anna = await upsertUser('demo-anna@thuisverzorgd.dev', 'Anna de Wit', 'vrijwilliger', {
  city: 'Amsterdam',
  phone: '0612345678',
  id_verified: true,
  id_verified_at: new Date().toISOString(),
  pool_opt_in: true,
  availability: ['ma', 'wo', 'do', 'za'],
  helped_count: 12,
});
const tim = await upsertUser('demo-tim@thuisverzorgd.dev', 'Tim Bakker', 'vrijwilliger', {
  city: 'Amsterdam',
  phone: '0687654321',
  id_verified: true,
  id_verified_at: new Date().toISOString(),
  pool_opt_in: true,
  helped_count: 8,
});
const riet = await upsertUser('demo-riet@thuisverzorgd.dev', 'Riet Jansen', 'hulpvrager', {
  city: 'Amsterdam',
});
const sanne = await upsertUser('demo-makelaar@thuisverzorgd.dev', 'Sanne Vermeer', 'makelaar', {});
await upsertUser('demo-admin@thuisverzorgd.dev', 'Admin Thuisverzorgd', 'admin', {});

// Kring + leden
let { data: circle } = await admin
  .from('circles')
  .select('id')
  .eq('name', 'Kring van mevrouw Jansen')
  .maybeSingle();
if (!circle) {
  const { data, error } = await admin
    .from('circles')
    .insert({
      owner_id: jelle,
      name: 'Kring van mevrouw Jansen',
      address: 'Keizersgracht 100, Amsterdam',
    })
    .select('id')
    .single();
  if (error) throw error;
  circle = data;
}
const members = [
  [jelle, 'beheerder', 'actief'],
  [anna, 'vrijwilliger', 'actief'],
  [tim, 'vrijwilliger', 'actief'],
  [riet, 'hulpvrager', 'kijkt_mee'],
];
// abonnement zodat de 2e+ vrijwilliger past
await admin
  .from('subscriptions')
  .update({ status: 'proef', started_at: new Date().toISOString() })
  .eq('profile_id', jelle);
for (const [profileId, role, status] of members) {
  await admin
    .from('circle_members')
    .upsert(
      { circle_id: circle.id, profile_id: profileId, member_role: role, status },
      { onConflict: 'circle_id,profile_id' },
    );
}
console.log('✓ Kring van mevrouw Jansen + 4 leden');

// Taken deze week
const { count } = await admin
  .from('tasks')
  .select('*', { count: 'exact', head: true })
  .eq('circle_id', circle.id);
if ((count ?? 0) === 0) {
  await admin.from('tasks').insert([
    {
      circle_id: circle.id,
      created_by: jelle,
      type: 'boodschappen',
      date: nextDate(0),
      time: '14:00',
      status: 'ingepland',
      claimed_by: anna,
    },
    {
      circle_id: circle.id,
      created_by: jelle,
      type: 'wandelen',
      date: nextDate(1),
      time: '10:30',
      status: 'ingepland',
      claimed_by: tim,
    },
    {
      circle_id: circle.id,
      created_by: jelle,
      type: 'vervoer',
      custom_label: null,
      date: nextDate(2),
      time: '09:15',
      status: 'open',
    },
    {
      circle_id: circle.id,
      created_by: jelle,
      type: 'gezelschap',
      date: nextDate(3),
      time: '15:00',
      status: 'open',
    },
  ]);
  console.log('✓ 4 taken in het rooster');
}

// Kringchat + forum
await admin.from('messages').insert({
  circle_id: circle.id,
  sender_id: jelle,
  body: 'Zou iemand donderdag de boodschappen kunnen doen?',
});
await admin.from('messages').insert({
  circle_id: circle.id,
  sender_id: anna,
  body: 'Ik kom eraan! 😊',
});

const { count: postCount } = await admin
  .from('forum_posts')
  .select('*', { count: 'exact', head: true });
if ((postCount ?? 0) === 0) {
  const { data: post } = await admin
    .from('forum_posts')
    .insert({
      author_id: jelle,
      tag: 'wonen',
      city: 'Amsterdam',
      title: 'Kan ik mijn moeder zomaar bij ons in huis nemen?',
      body: 'Ze woont nu nog zelfstandig maar het gaat steeds moeilijker. Waar moet ik aan denken?',
    })
    .select('id')
    .single();
  await admin.from('forum_replies').insert({
    post_id: post.id,
    author_id: sanne,
    body: 'Goede vraag! Denk aan de kostendelersnorm en een eventuele mantelzorgwoning. Bel gerust even met de chat, dan lopen we jouw situatie samen door.',
  });
  console.log('✓ Forumvraag + makelaar-antwoord');
}

console.log(`\nKlaar! Inloggen kan met wachtwoord: ${PASSWORD}`);
console.log('(magic link werkt uiteraard ook — dit zijn @thuisverzorgd.dev demo-adressen)');

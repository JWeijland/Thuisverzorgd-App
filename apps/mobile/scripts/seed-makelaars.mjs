/**
 * Seed: drie hulpmakelaars met een eigen profiel (bio + onderwerpen), zodat
 * het kaartendeck en de profielweergave in de app iets laten zien.
 *
 * Draaien:  node scripts/seed-makelaars.mjs
 * Vereist env: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
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

async function upsertMakelaar(email, name, profielvelden) {
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
  const { error } = await admin
    .from('profiles')
    .update({ role: 'makelaar', name, ...profielvelden })
    .eq('id', id);
  if (error) throw new Error(`${email}: ${error.message}`);
  console.log(`✓ ${name} (makelaar)`);
  return id;
}

await upsertMakelaar('demo-makelaar@thuisverzorgd.dev', 'Sanne Vermeer', {
  city: 'Amsterdam',
  broker_bio:
    'Al twaalf jaar wegwijzer in zorg en regelingen. Ik luister eerst, denk daarna met je mee en verwijs je door naar de juiste persoon of instantie. Geen vraag is te klein.',
  broker_topics: ['Regelingen en vergoedingen', 'Overbelasting', 'Respijtzorg'],
});

await upsertMakelaar('demo-makelaar2@thuisverzorgd.dev', 'Mark de Vries', {
  city: 'Haarlem',
  broker_bio:
    'Voormalig wijkverpleegkundige. Ik ken de weg bij gemeenten en zorgkantoren en help je met aanvragen, indicaties en alles rond wonen met zorg.',
  broker_topics: ['Wonen en zorg', 'Indicaties en Wmo', 'Thuiszorg regelen'],
});

await upsertMakelaar('demo-makelaar3@thuisverzorgd.dev', 'Fatima el Amrani', {
  city: 'Amsterdam',
  broker_bio:
    'Gespecialiseerd in dementie en alles wat daarbij komt kijken voor de omgeving. Samen kijken we wat er in jouw situatie kan, stap voor stap.',
  broker_topics: ['Dementie', 'Dagbesteding', 'Casemanagement'],
});

console.log('\nKlaar! Drie makelaars met profiel staan in de database.');

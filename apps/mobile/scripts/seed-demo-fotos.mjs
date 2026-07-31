/**
 * Seed: profielfoto's voor de demo-accounts.
 *
 * Zonder foto tonen de kaart, het forum en de chats alleen een letter in een
 * cirkel. Dat maakt de app kil, terwijl het brandbook juist zegt: "gezichten,
 * geen nummers". Dit script zet bij elk demo-account een portret.
 *
 * De foto's komen van Pexels en vallen onder de Pexels-licentie: gratis te
 * gebruiken, ook commercieel, zonder naamsvermelding. Ze staan hier alleen als
 * demomateriaal. Voor echte gebruikers geldt de regel uit het brandbook: eigen
 * foto's, met toestemming.
 *
 * Er wordt per account ingelogd met het demowachtwoord en daarna geüpload naar
 * de eigen map in de avatars-bucket, precies zoals de app het zelf doet. Er is
 * dus geen service-key voor nodig.
 *
 * Draaien vanuit apps/mobile:  node scripts/seed-demo-fotos.mjs
 * Vereist env: EXPO_PUBLIC_SUPABASE_URL en EXPO_PUBLIC_SUPABASE_ANON_KEY (.env)
 */
import { createClient } from '@supabase/supabase-js';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const env = Object.fromEntries(
  fs
    .readFileSync(new URL('../.env', import.meta.url), 'utf8')
    .split('\n')
    .filter((regel) => regel.includes('='))
    .map((regel) => {
      const i = regel.indexOf('=');
      return [regel.slice(0, i).trim(), regel.slice(i + 1).trim()];
    }),
);

const URL_SUPABASE = env.EXPO_PUBLIC_SUPABASE_URL;
const ANON = env.EXPO_PUBLIC_SUPABASE_ANON_KEY;
const WACHTWOORD = 'DemoThuisverzorgd1!';
// fileURLToPath, want het pad bevat spaties (Buddy Care)
const MAP = path.join(path.dirname(fileURLToPath(import.meta.url)), 'demo-fotos');

/** Welk portret hoort bij welk demo-account. */
const TOEWIJZING = [
  { email: 'demo-sophie@thuisverzorgd.dev', bestand: '30004322.jpg' },
  { email: 'demo-mark@thuisverzorgd.dev', bestand: '30450838.jpg' },
  { email: 'demo-fatima@thuisverzorgd.dev', bestand: '10347162.jpg' },
  { email: 'demo-riet@thuisverzorgd.dev', bestand: '12644996.jpg' },
  { email: 'demo-willem@thuisverzorgd.dev', bestand: '8450208.jpg' },
  { email: 'demo-karin@thuisverzorgd.dev', bestand: '20404749.jpg' },
  { email: 'demo-henk@thuisverzorgd.dev', bestand: '2421934.jpg' },
  { email: 'demo-thomas@thuisverzorgd.dev', bestand: '15946547.jpg' },
];

let gelukt = 0;
let mislukt = 0;

for (const { email, bestand } of TOEWIJZING) {
  const client = createClient(URL_SUPABASE, ANON, { auth: { persistSession: false } });
  const { data: sessie, error: loginFout } = await client.auth.signInWithPassword({
    email,
    password: WACHTWOORD,
  });
  if (loginFout || !sessie.user) {
    console.log(`- ${email}: inloggen lukt niet (${loginFout?.message ?? 'geen sessie'})`);
    mislukt += 1;
    continue;
  }

  const pad = `${sessie.user.id}/avatar.jpg`;
  const bytes = fs.readFileSync(path.join(MAP, bestand));
  const { error: uploadFout } = await client.storage
    .from('avatars')
    .upload(pad, bytes, { contentType: 'image/jpeg', upsert: true });
  if (uploadFout) {
    console.log(`- ${email}: uploaden lukt niet (${uploadFout.message})`);
    mislukt += 1;
    continue;
  }

  const { error: updateFout } = await client
    .from('profiles')
    .update({ avatar_path: pad })
    .eq('id', sessie.user.id);
  if (updateFout) {
    console.log(`- ${email}: profiel bijwerken lukt niet (${updateFout.message})`);
    mislukt += 1;
    continue;
  }

  console.log(`+ ${email} -> ${bestand}`);
  gelukt += 1;
  await client.auth.signOut();
}

console.log(`\nKlaar: ${gelukt} foto's geplaatst, ${mislukt} niet.`);

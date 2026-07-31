/**
 * Seed-script "demo vol": bouwt voort op seed-demo.mjs en vult de app rijk
 * voor een live demo: weekrooster met historie, logboekjes, kringchat, forum,
 * buurtvragen met kaartlocaties, reviews, meldingen en een open aanvraag.
 *
 * Draaien:  node scripts/seed-demo-vol.mjs
 * Vereist env: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
 * Let op: zet vooraf de push-trigger uit (notifications_push), anders krijgt
 * elk geregistreerd toestel tientallen echte pushberichten.
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

const dag = (offset, uur = 12, min = 0) => {
  const d = new Date();
  d.setDate(d.getDate() + offset);
  d.setHours(uur, min, 0, 0);
  return d;
};
const datum = (offset) => dag(offset).toISOString().slice(0, 10);
const uurGeleden = (h) => new Date(Date.now() - h * 3600_000).toISOString();

async function idVan(email) {
  const { data, error } = await admin.from('profiles').select('id').eq('email', email).single();
  if (error) throw new Error(`${email}: ${error.message}`);
  return data.id;
}

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
  const { error: upErr } = await admin
    .from('profiles')
    .update({ role, name, ...extra })
    .eq('id', id);
  if (upErr) throw new Error(`profiel ${email}: ${upErr.message}`);
  console.log(`✓ ${name} (${role})`);
  return id;
}

function moet(label) {
  return ({ error }) => {
    if (error) throw new Error(`${label}: ${error.message}`);
  };
}

// ---------------------------------------------------------------------------
// Bestaande accounts ophalen + verrijken
// ---------------------------------------------------------------------------
const jelle = await idVan('demo-beheerder@thuisverzorgd.dev');
const anna = await idVan('demo-anna@thuisverzorgd.dev');
const tim = await idVan('demo-tim@thuisverzorgd.dev');
const riet = await idVan('demo-riet@thuisverzorgd.dev');
const sanne = await idVan('demo-makelaar@thuisverzorgd.dev');
const jelleEcht = await idVan('j.p.weijland@gmail.com');

await admin
  .from('profiles')
  .update({
    city: 'Amsterdam',
    location: 'POINT(4.8896 52.3740)',
    availability: ['ma', 'di', 'do'],
  })
  .eq('id', jelle)
  .then(moet('jelle'));
await admin
  .from('profiles')
  .update({
    location: 'POINT(4.8721 52.3667)',
    availability: ['ma', 'wo', 'do', 'za'],
    helped_count: 14,
  })
  .eq('id', anna)
  .then(moet('anna'));
await admin
  .from('profiles')
  .update({
    location: 'POINT(4.9041 52.3676)',
    availability: ['di', 'do', 'zo'],
    helped_count: 9,
  })
  .eq('id', tim)
  .then(moet('tim'));
await admin
  .from('profiles')
  .update({
    location: 'POINT(4.8952 52.3702)',
  })
  .eq('id', riet)
  .then(moet('riet'));
await admin
  .from('profiles')
  .update({
    city: 'Amsterdam',
    location: 'POINT(4.8837 52.3628)',
  })
  .eq('id', jelleEcht)
  .then(moet('jelle echt'));

// Nieuwe figuranten
const sophie = await upsertUser(
  'demo-sophie@thuisverzorgd.dev',
  'Sophie van Dijk',
  'vrijwilliger',
  {
    city: 'Amsterdam',
    phone: '0623456789',
    id_verified: true,
    id_verified_at: uurGeleden(24 * 20),
    pool_opt_in: true,
    availability: ['wo', 'vr', 'za'],
    helped_count: 21,
    location: 'POINT(4.8786 52.3599)',
  },
);
const mark = await upsertUser('demo-mark@thuisverzorgd.dev', 'Mark Visser', 'vrijwilliger', {
  city: 'Amsterdam',
  phone: '0634567890',
  id_verified: true,
  id_verified_at: uurGeleden(24 * 3),
  pool_opt_in: true,
  availability: ['ma', 'za', 'zo'],
  helped_count: 3,
  location: 'POINT(4.9138 52.3609)',
});
const fatima = await upsertUser(
  'demo-fatima@thuisverzorgd.dev',
  'Fatima el Amrani',
  'vrijwilliger',
  {
    city: 'Amsterdam',
    phone: '0645678901',
    id_verified: true,
    id_verified_at: uurGeleden(24 * 45),
    pool_opt_in: true,
    availability: ['di', 'wo', 'vr'],
    helped_count: 17,
    location: 'POINT(4.8659 52.3731)',
  },
);
const karin = await upsertUser('demo-karin@thuisverzorgd.dev', 'Karin Smit', 'beheerder', {
  city: 'Haarlem',
  location: 'POINT(4.6462 52.3874)',
});
const henk = await upsertUser('demo-henk@thuisverzorgd.dev', 'Henk de Groot', 'beheerder', {
  city: 'Amstelveen',
  location: 'POINT(4.8639 52.3114)',
});
const willem = await upsertUser('demo-willem@thuisverzorgd.dev', 'Willem de Vries', 'hulpvrager', {
  city: 'Amsterdam',
  location: 'POINT(4.8992 52.3781)',
});

// Abonnement beheerder actief (demo toont premium)
await admin
  .from('subscriptions')
  .update({
    status: 'actief',
    started_at: uurGeleden(24 * 30),
    expires_at: dag(335).toISOString(),
  })
  .eq('profile_id', jelle)
  .then(moet('abonnement'));

// ---------------------------------------------------------------------------
// Kring: Sophie en het echte account van Jelle erbij
// ---------------------------------------------------------------------------
const { data: circle } = await admin
  .from('circles')
  .select('id')
  .eq('name', 'Kring van mevrouw Jansen')
  .single();
await admin.from('circles').update({ location: 'POINT(4.8896 52.3740)' }).eq('id', circle.id);

for (const [profileId, role, status] of [
  [sophie, 'vrijwilliger', 'actief'],
  [jelleEcht, 'vrijwilliger', 'actief'],
]) {
  await admin
    .from('circle_members')
    .upsert(
      { circle_id: circle.id, profile_id: profileId, member_role: role, status },
      { onConflict: 'circle_id,profile_id' },
    )
    .then(moet('lid'));
}
console.log('✓ Sophie + Jelle (echt account) in de kring');

// Open aanvraag van Mark, videokennismaking al gedaan → "Toelaten tot de kring"
const { count: aanvraagCount } = await admin
  .from('invitations')
  .select('*', { count: 'exact', head: true })
  .eq('circle_id', circle.id)
  .eq('profile_id', mark);
if ((aanvraagCount ?? 0) === 0) {
  await admin
    .from('invitations')
    .insert({
      circle_id: circle.id,
      kind: 'aanvraag',
      profile_id: mark,
      invited_by: mark,
      status: 'open',
      video_done: true,
      created_at: uurGeleden(26),
      message:
        'Hallo! Ik woon om de hoek bij de Westerkerk en help al in een andere kring. Ik loop graag een rondje of doe een boodschap.',
    })
    .then(moet('aanvraag'));
  console.log('✓ Open aanvraag van Mark (video gedaan)');
}

// ---------------------------------------------------------------------------
// Rooster: afgeronde taken met logboekjes + gevulde week vooruit
// ---------------------------------------------------------------------------
const { count: taakCount } = await admin
  .from('tasks')
  .select('*', { count: 'exact', head: true })
  .eq('circle_id', circle.id)
  .eq('status', 'gedaan');
if ((taakCount ?? 0) === 0) {
  const gedaan = [
    {
      type: 'boodschappen',
      d: -13,
      t: '14:00',
      wie: anna,
      log: 'Alles gehaald bij de Albert Heijn. Mevrouw Jansen wilde graag extra roomboter voor de appeltaart.',
    },
    {
      type: 'wandelen',
      d: -12,
      t: '10:30',
      wie: tim,
      log: 'Rondje Westerpark gelopen, het ging vandaag heel goed. Bankje bij de vijver blijft favoriet.',
    },
    {
      type: 'vervoer',
      d: -10,
      t: '09:15',
      wie: sophie,
      log: 'Naar de fysio geweest en weer veilig thuis. Volgende afspraak staat over twee weken.',
    },
    {
      type: 'gezelschap',
      d: -8,
      t: '15:00',
      wie: anna,
      log: "Samen gerummikupt en foto's van vroeger bekeken. Ze vertelde prachtig over de bakkerij.",
    },
    {
      type: 'boodschappen',
      d: -6,
      t: '14:00',
      wie: anna,
      log: 'Boodschappen gedaan, de koelkast ligt weer vol. Ze was in een goede bui vandaag.',
    },
    {
      type: 'wandelen',
      d: -5,
      t: '10:30',
      wie: sophie,
      log: 'Korte wandeling, het waaide flink. Binnen nog een kop thee gedronken.',
    },
    {
      type: 'anders',
      label: 'Plantjes water geven',
      d: -3,
      t: '11:00',
      wie: tim,
      log: 'Alle planten gehad, de orchidee staat weer in de knop.',
    },
    { type: 'gezelschap', d: -1, t: '15:00', wie: sophie, log: null },
  ];
  for (const t of gedaan) {
    const { data: taak, error } = await admin
      .from('tasks')
      .insert({
        circle_id: circle.id,
        created_by: jelle,
        type: t.type,
        custom_label: t.label ?? null,
        date: datum(t.d),
        time: t.t,
        status: 'gedaan',
        claimed_by: t.wie,
        created_at: dag(t.d - 3).toISOString(),
      })
      .select('id')
      .single();
    if (error) throw new Error(`taak: ${error.message}`);
    if (t.log) {
      await admin
        .from('task_logs')
        .insert({
          task_id: taak.id,
          circle_id: circle.id,
          author_id: t.wie,
          note: t.log,
          created_at: dag(t.d, 17).toISOString(),
        })
        .then(moet('logboek'));
    }
  }
  console.log('✓ 8 afgeronde taken + logboekjes');
}

// Komende week aanvullen (naast de 4 bestaande): ingepland + open + weekreeks
const { count: weekCount } = await admin
  .from('tasks')
  .select('*', { count: 'exact', head: true })
  .eq('circle_id', circle.id)
  .eq('recurrence', 'wekelijks');
if ((weekCount ?? 0) === 0) {
  const serie = crypto.randomUUID();
  await admin
    .from('tasks')
    .insert([
      {
        circle_id: circle.id,
        created_by: jelle,
        type: 'gezelschap',
        custom_label: null,
        date: datum(4),
        time: '15:00',
        recurrence: 'eenmalig',
        series_id: null,
        status: 'ingepland',
        claimed_by: sophie,
      },
      {
        circle_id: circle.id,
        created_by: jelle,
        type: 'anders',
        custom_label: 'Kapper',
        date: datum(5),
        time: '11:30',
        recurrence: 'eenmalig',
        series_id: null,
        status: 'open',
        claimed_by: null,
      },
      {
        circle_id: circle.id,
        created_by: jelle,
        type: 'boodschappen',
        custom_label: null,
        date: datum(7),
        time: '14:00',
        recurrence: 'wekelijks',
        series_id: serie,
        status: 'ingepland',
        claimed_by: anna,
      },
      {
        circle_id: circle.id,
        created_by: jelle,
        type: 'boodschappen',
        custom_label: null,
        date: datum(14),
        time: '14:00',
        recurrence: 'wekelijks',
        series_id: serie,
        status: 'open',
        claimed_by: null,
      },
      {
        circle_id: circle.id,
        created_by: jelle,
        type: 'wandelen',
        custom_label: null,
        date: datum(6),
        time: '10:30',
        recurrence: 'eenmalig',
        series_id: null,
        status: 'ingepland',
        claimed_by: tim,
      },
      {
        circle_id: circle.id,
        created_by: jelle,
        type: 'vervoer',
        custom_label: null,
        date: datum(9),
        time: '08:45',
        recurrence: 'eenmalig',
        series_id: null,
        status: 'open',
        claimed_by: null,
      },
    ])
    .then(moet('week vooruit'));
  console.log('✓ Komende week gevuld (ingepland, open en weekreeks)');
}

// ---------------------------------------------------------------------------
// Kringchat: gespreksgeschiedenis van de afgelopen dagen
// ---------------------------------------------------------------------------
const { count: chatCount } = await admin
  .from('messages')
  .select('*', { count: 'exact', head: true })
  .eq('circle_id', circle.id);
if ((chatCount ?? 0) <= 2) {
  const chat = [
    [
      jelle,
      70,
      'Goedemorgen allemaal! Mevrouw Jansen heeft donderdag om 9:15 een afspraak in het OLVG. Wie zou haar kunnen brengen?',
    ],
    [tim, 69, 'Ik kan die ochtend! Zet hem maar op mijn naam.'],
    [jelle, 68, 'Top Tim, dank je wel!'],
    [
      anna,
      52,
      'Boodschappen zijn gedaan, de koelkast ligt weer vol. Ze was in een goede bui vandaag 😊',
    ],
    [
      sophie,
      49,
      'Wat leuk! Zaterdag ga ik weer met haar naar de markt, ze verheugt zich er al op.',
    ],
    [jelle, 47, 'Mooi om te lezen allemaal, jullie zijn kanjers.'],
    [tim, 26, 'Kleine update: de rollator piepte een beetje, ik heb de wieltjes even gesmeerd.'],
    [anna, 25, 'Held! 💪'],
    [
      sophie,
      20,
      'Denken jullie aan haar verjaardag volgende maand? Misschien iets leuks organiseren met de kring?',
    ],
    [jelle, 19, 'Goed idee Sophie, daar komen we in de chat op terug.'],
  ];
  for (const [wie, urenTerug, body] of chat) {
    await admin
      .from('messages')
      .insert({
        circle_id: circle.id,
        sender_id: wie,
        body,
        created_at: uurGeleden(urenTerug),
      })
      .then(moet('chat'));
  }
  console.log('✓ Kringchat gevuld');
}

// ---------------------------------------------------------------------------
// Reviews op de vrijwilligers (zichtbaar op buddy-kaartjes)
// ---------------------------------------------------------------------------
const reviews = [
  [jelle, anna, 5, 'Anna is er altijd, weer of geen weer. Mevrouw Jansen bloeit op als zij komt.'],
  [jelle, tim, 4, 'Betrouwbaar en handig, regelt ook kleine klusjes in huis.'],
  [jelle, sophie, 5, 'Sophie denkt overal aan en neemt alle tijd. Een topper.'],
  [riet, anna, 5, "Zo'n lief mens. Ik kijk elke week uit naar haar bezoekjes."],
];
for (const [reviewer, volunteer, score, note] of reviews) {
  await admin
    .from('reviews')
    .upsert(
      { circle_id: circle.id, reviewer_id: reviewer, volunteer_id: volunteer, score, note },
      { onConflict: 'circle_id,reviewer_id,volunteer_id' },
    )
    .then(moet('review'));
}
console.log('✓ Reviews gezet');

// ---------------------------------------------------------------------------
// Buurtvragen (kaart) + aanbod
// ---------------------------------------------------------------------------
const { count: reqCount } = await admin
  .from('spontaneous_requests')
  .select('*', { count: 'exact', head: true });
if ((reqCount ?? 0) === 0) {
  // Afgerond vorige week (historie voor Riet en Anna)
  await admin
    .from('spontaneous_requests')
    .insert({
      requester_id: riet,
      circle_id: circle.id,
      type: 'medicijnen',
      status: 'afgerond',
      note: 'Zou iemand mijn medicijnen bij apotheek De Jordaan kunnen ophalen?',
      address: 'Keizersgracht 100, Amsterdam',
      location: 'POINT(4.8952 52.3702)',
      helper_id: anna,
      created_at: uurGeleden(24 * 6),
    })
    .then(moet('afgeronde vraag'));

  // Open vraag van Riet met een aanbod van Tim
  const { data: vraag, error: vErr } = await admin
    .from('spontaneous_requests')
    .insert({
      requester_id: riet,
      circle_id: circle.id,
      type: 'boodschappen',
      status: 'aanbod',
      note: 'Mijn dochter is dit weekend weg. Wie kan zaterdag een boodschapje voor mij doen?',
      address: 'Keizersgracht 100, Amsterdam',
      location: 'POINT(4.8952 52.3702)',
      created_at: uurGeleden(5),
    })
    .select('id')
    .single();
  if (vErr) throw new Error(`open vraag: ${vErr.message}`);
  await admin
    .from('request_offers')
    .insert({
      request_id: vraag.id,
      volunteer_id: tim,
      status: 'aangeboden',
      message: 'Ik ga zaterdagochtend toch naar de markt, ik neem het graag mee!',
      created_at: uurGeleden(3),
    })
    .then(moet('aanbod'));

  // Open vraag van Willem (verse melding op de kaart)
  await admin
    .from('spontaneous_requests')
    .insert({
      requester_id: willem,
      type: 'gezelschap',
      status: 'open',
      note: 'Ik zit veel alleen sinds mijn vrouw is overleden. Een kop koffie en een praatje zou fijn zijn.',
      address: 'Haarlemmerdijk 45, Amsterdam',
      location: 'POINT(4.8992 52.3781)',
      created_at: uurGeleden(2),
    })
    .then(moet('vraag willem'));
  console.log('✓ Buurtvragen op de kaart (open, aanbod en afgerond)');
}

// ---------------------------------------------------------------------------
// Forum: vragen met antwoorden, ook van de hulpmakelaar
// ---------------------------------------------------------------------------
await admin.from('forum_replies').update({ is_broker: true }).eq('author_id', sanne);
const { count: forumCount } = await admin
  .from('forum_posts')
  .select('*', { count: 'exact', head: true });
if ((forumCount ?? 0) <= 1) {
  const posts = [
    {
      author: karin,
      tag: 'financien',
      city: 'Haarlem',
      uren: 96,
      title: 'Wie heeft ervaring met het aanvragen van een pgb?',
      body: 'Voor mijn vader wil ik een persoonsgebonden budget aanvragen, maar ik zie door de bomen het bos niet meer. Waar begin ik?',
      replies: [
        [
          henk,
          false,
          92,
          'Wij hebben dit vorig jaar gedaan. Begin bij het zorgkantoor van je regio en vraag meteen het gratis gesprek met een onafhankelijk clientondersteuner aan, dat scheelt enorm.',
        ],
        [
          sanne,
          true,
          90,
          'Goede tip van Henk! Let er ook op of de zorg onder de Wmo, de Zvw of de Wlz valt, want daar zit het grootste verschil in de aanvraag. In de chat loop ik het graag stap voor stap met je door.',
        ],
      ],
    },
    {
      author: henk,
      tag: 'dementie',
      city: 'Amstelveen',
      uren: 72,
      title: 'Mijn vader vergeet steeds vaker welke dag het is',
      body: 'Het begint met kleine dingen, maar ik merk dat het vaker gebeurt. Hoe gaan jullie hiermee om zonder hem het gevoel te geven dat we hem controleren?',
      replies: [
        [
          anna,
          false,
          70,
          'Bij ons hielp een grote dagkalender op tafel enorm. En vaste rituelen op vaste dagen, dat geeft houvast zonder dat je er iets van hoeft te zeggen.',
        ],
        [
          sanne,
          true,
          65,
          'Herkenbaar en heel normaal dat u hiermee zit. Een geheugenpoli-verwijzing via de huisarts geeft duidelijkheid, en dagstructuur zoals Anna beschrijft helpt echt. Denk ook aan de casemanager dementie, die is er ook voor u.',
        ],
      ],
    },
    {
      author: karin,
      tag: 'werk',
      city: 'Haarlem',
      uren: 48,
      title: 'Zorgverlof bespreken met je werkgever, hoe pakken jullie dat aan?',
      body: 'Ik zorg naast mijn baan voor mijn moeder en het wordt me soms te veel. Ik durf het gesprek op werk niet goed aan te gaan.',
      replies: [
        [
          sanne,
          true,
          40,
          'Wat goed dat u dit bespreekbaar wilt maken. U heeft wettelijk recht op kortdurend zorgverlof, vaak tegen 70 procent van het loon. Neem de folder van rijksoverheid.nl mee naar het gesprek, dat maakt het concreet.',
        ],
      ],
    },
    {
      author: sophie,
      tag: 'overig',
      city: 'Amsterdam',
      uren: 30,
      title: 'Tips voor een rolstoelvriendelijk uitje in Amsterdam?',
      body: 'Ik wil binnenkort een middagje weg met de mevrouw voor wie ik zorg. Wie kent leuke plekken die goed toegankelijk zijn?',
      replies: [
        [
          tim,
          false,
          28,
          'De Hortus is prachtig en bijna overal goed begaanbaar. En bij het Rijksmuseum kun je gratis een rolstoel lenen als je even belt.',
        ],
        [
          karin,
          false,
          24,
          'Rondvaart met de salonboot! Sommige rederijen hebben een lift aan boord, even vooraf bellen.',
        ],
      ],
    },
    {
      author: willem,
      tag: 'wonen',
      city: 'Amsterdam',
      uren: 12,
      title: 'Traplift of toch verhuizen?',
      body: 'De trap wordt te zwaar voor mij. Mijn kinderen zeggen verhuizen, maar ik woon hier al veertig jaar. Wat zijn de mogelijkheden?',
      replies: [
        [
          sanne,
          true,
          8,
          'Een herkenbaar dilemma. Via de Wmo kan de gemeente meebetalen aan een traplift, en een ergotherapeut kan gratis meekijken wat er in uw huis mogelijk is. Blijven wonen kan vaker dan mensen denken.',
        ],
      ],
    },
  ];
  for (const p of posts) {
    const { data: post, error } = await admin
      .from('forum_posts')
      .insert({
        author_id: p.author,
        tag: p.tag,
        city: p.city,
        title: p.title,
        body: p.body,
        created_at: uurGeleden(p.uren),
      })
      .select('id')
      .single();
    if (error) throw new Error(`forum: ${error.message}`);
    for (const [wie, isBroker, uren, body] of p.replies) {
      await admin
        .from('forum_replies')
        .insert({
          post_id: post.id,
          author_id: wie,
          is_broker: isBroker,
          body,
          created_at: uurGeleden(uren),
        })
        .then(moet('forumantwoord'));
    }
  }
  console.log('✓ Forum gevuld (5 nieuwe vragen + antwoorden)');
}

// ---------------------------------------------------------------------------
// Chat met de hulpmakelaar
// ---------------------------------------------------------------------------
const { count: brokerCount } = await admin
  .from('broker_chats')
  .select('*', { count: 'exact', head: true })
  .eq('profile_id', jelle);
if ((brokerCount ?? 0) === 0) {
  const { data: chat, error } = await admin
    .from('broker_chats')
    .insert({
      profile_id: jelle,
      status: 'open',
      created_at: uurGeleden(22),
    })
    .select('id')
    .single();
  if (error) throw new Error(`makelaarchat: ${error.message}`);
  const gesprek = [
    [
      jelle,
      22,
      'Hoi Sanne, mijn moeder krijgt volgende maand een indicatiegesprek voor de Wlz. Waar moet ik op letten?',
    ],
    [
      sanne,
      21,
      'Goedemorgen Jelle! Fijn dat u het op tijd oppakt. Belangrijkste tip: beschrijf een slechte dag, niet een goede. Het CIZ kijkt naar wat structureel nodig is.',
    ],
    [
      sanne,
      21,
      'Zal ik u de checklist sturen die wij hiervoor gebruiken? Dan kunt u die samen met uw moeder rustig doorlopen.',
    ],
    [jelle, 20, 'Dat zou heel fijn zijn, dank je wel!'],
    [
      sanne,
      18,
      'Staat in uw mail. Als het gesprek is geweest hoor ik graag hoe het ging, dan kijken we samen naar de volgende stap.',
    ],
  ];
  for (const [wie, uren, body] of gesprek) {
    await admin
      .from('broker_messages')
      .insert({
        chat_id: chat.id,
        sender_id: wie,
        body,
        created_at: uurGeleden(uren),
      })
      .then(moet('makelaarbericht'));
  }
  console.log('✓ Gesprek met de hulpmakelaar');
}

// ---------------------------------------------------------------------------
// Meldingen: alles wat de triggers net genereerden op gelezen zetten,
// daarna een handjevol verse ongelezen meldingen voor de demo.
// ---------------------------------------------------------------------------
await admin.from('notifications').update({ read: true }).eq('read', false);
for (const wie of [jelle, jelleEcht]) {
  const { count } = await admin
    .from('notifications')
    .select('*', { count: 'exact', head: true })
    .eq('profile_id', wie)
    .eq('read', false);
  if ((count ?? 0) > 0) continue;
  await admin
    .from('notifications')
    .insert([
      {
        profile_id: wie,
        kind: 'uitnodiging',
        title: 'Aanvraag voor je kring',
        read: false,
        body: 'Mark wil zich aansluiten en stuurde een voorstelbericht mee.',
        deeplink: 'tvz://inbox',
        created_at: uurGeleden(26),
      },
      {
        profile_id: wie,
        kind: 'makelaar',
        title: 'De hulpmakelaar heeft geantwoord',
        read: false,
        body: 'Staat in uw mail. Als het gesprek is geweest hoor ik graag hoe het ging.',
        deeplink: 'tvz://steun',
        created_at: uurGeleden(18),
      },
      {
        profile_id: wie,
        kind: 'taak_geclaimd',
        title: 'Anna neemt een taak aan',
        read: false,
        body: `Boodschappen · ${datum(7).slice(8, 10)}-${datum(7).slice(5, 7)} om 14:00`,
        deeplink: 'tvz://rooster',
        created_at: uurGeleden(2),
      },
      {
        profile_id: wie,
        kind: 'kringbericht',
        title: 'Anna in de kringchat',
        read: false,
        body: 'Ik kom eraan! 😊',
        deeplink: 'tvz://kring',
        created_at: uurGeleden(1),
      },
    ])
    .then(moet('meldingen'));
}
console.log('✓ Meldingen: historie gelezen, 4 verse ongelezen per beheerderaccount');

console.log(`\nKlaar! De app staat vol. Demo-accounts loggen in met: ${PASSWORD}`);

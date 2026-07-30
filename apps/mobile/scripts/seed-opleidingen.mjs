/**
 * Seed: drie korte cursussen (tekst + video + toets) en een paar klassikale
 * groepen, zodat de opleidingen-tab meteen inhoud heeft.
 *
 * Draaien:  node scripts/seed-opleidingen.mjs
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

const COURSES = [
  {
    slug: 'tillen-en-bewegen',
    title: 'Veilig tillen en bewegen',
    subtitle: 'Help zonder je eigen rug te belasten',
    description:
      'Iemand helpen bij opstaan, draaien in bed of instappen in de auto: met de juiste techniek is het veel lichter, voor jullie beiden. In een kwartier weet je de basis.',
    topic: 'Praktische hulp',
    duur_minuten: 15,
    sortering: 1,
    modules: [
      {
        title: 'Waarom techniek belangrijker is dan kracht',
        body: 'Rugklachten zijn de meestgehoorde klacht van mensen die voor iemand zorgen. Bijna altijd komt dat niet door te zwaar werk, maar door een verkeerde houding: gebogen rug, gedraaide romp, te ver van de ander af.\n\nDrie basisregels:\n\n1. Sta dicht bij de ander. Hoe verder je reikt, hoe zwaarder het voelt.\n2. Buig door je knieën, houd je rug recht.\n3. Draai nooit je romp terwijl je gewicht draagt. Verzet je voeten.\n\nEn de belangrijkste: laat de ander zelf doen wat die zelf kan. Jij begeleidt de beweging, je tilt niet.',
        video_url: 'https://www.youtube.com/watch?v=Y2ANEXGRDDU',
        video_label: 'Video: de juiste tilhouding (3 min)',
      },
      {
        title: 'Opstaan uit een stoel',
        body: 'Vraag de ander eerst naar voren te schuiven op de zitting en de voeten plat op de grond te zetten, iets naar achteren onder de knieën.\n\nGa naast de ander staan, niet ervoor: zo blokkeer je de beweging niet. Laat de ander voorover komen ("neus boven de knieën") en op jouw teken opstaan. Jij geeft steun bij de rug of de arm, je trekt niet aan de handen.\n\nGaat het moeizaam? Verhoog de zitting of gebruik een stoel met armleuningen. Dat scheelt meer dan welke tiltechniek ook.',
      },
      {
        title: 'Wanneer je hulp of hulpmiddelen inschakelt',
        body: 'Til nooit alleen iemand die is gevallen. Blijf bij de ander, maak het comfortabel en bel hulp. Bij twijfel over letsel: 112.\n\nVoor terugkerende situaties bestaan eenvoudige hulpmiddelen: een glijzeil, een draaischijf, een bedverhoger of een sta-op-stoel. Veel gemeenten vergoeden die via de Wmo, en de wijkverpleging kan het aanvragen.\n\nMerk je dat je zelf klachten krijgt? Meld het bij de beheerder van de kring. Een taak anders verdelen is beter dan uitvallen.',
      },
    ],
    questions: [
      {
        question: 'Wat is de belangrijkste reden dat mensen rugklachten krijgen bij het helpen?',
        options: [
          'Ze zijn niet sterk genoeg',
          'Een verkeerde houding, zoals een gebogen of gedraaide rug',
          'Ze helpen te vaak',
        ],
        correct_index: 1,
        uitleg: 'Techniek en houding bepalen de belasting, niet je spierkracht.',
      },
      {
        question: 'Iemand moet opstaan uit een stoel. Waar ga je staan?',
        options: ['Recht voor de ander', 'Naast de ander', 'Achter de stoel'],
        correct_index: 1,
        uitleg: 'Naast de ander blokkeer je de voorwaartse beweging niet.',
      },
      {
        question: 'Iemand is gevallen en ligt op de grond. Wat doe je?',
        options: [
          'Zelf overeind helpen, snel is het minst pijnlijk',
          'Bij de ander blijven en hulp bellen',
          'Wachten tot de ander zelf opstaat',
        ],
        correct_index: 1,
        uitleg: 'Alleen tillen na een val is risicovol voor jullie beiden.',
      },
      {
        question: 'Wat doe je als je zelf klachten krijgt van het helpen?',
        options: [
          'Doorgaan, het hoort erbij',
          'Melden bij de beheerder zodat taken anders verdeeld worden',
          'Stoppen zonder iets te zeggen',
        ],
        correct_index: 1,
        uitleg: 'De kring kan taken herverdelen. Uitvallen helpt niemand.',
      },
    ],
  },
  {
    slug: 'dementie-begrijpen',
    title: 'Dementie begrijpen',
    subtitle: 'Contact houden als het geheugen hapert',
    description:
      'Waarom iemand met dementie doet wat die doet, en hoe je reageert zonder ruzie of verdriet. Met voorbeelden uit het dagelijks leven.',
    topic: 'Dementie',
    duur_minuten: 20,
    sortering: 2,
    modules: [
      {
        title: 'Wat er in het brein gebeurt',
        body: 'Dementie is geen vergeetachtigheid maar hersenschade. Het kortetermijngeheugen verdwijnt vaak het eerst, terwijl gevoelens en oude herinneringen lang blijven.\n\nDaarom werkt corrigeren zelden. Als iemand zegt "ik ga naar mijn moeder", is dat voor die persoon op dat moment waar. "Je moeder is al twintig jaar dood" levert alleen schrik en verdriet op, en het wordt toch weer vergeten.\n\nWat wél blijft hangen: het gevoel dat het gesprek achterliet.',
        video_url: 'https://www.youtube.com/watch?v=Eq_Er-tqPsA',
        video_label: 'Video: wat dementie doet met het brein (4 min)',
      },
      {
        title: 'Meebewegen in plaats van corrigeren',
        body: 'Reageer op het gevoel, niet op de feiten. "Je mist je moeder, hè? Vertel eens over haar." Zo neem je de onrust weg zonder te liegen over de situatie van vandaag.\n\nPraktische hulp bij een gesprek:\n\n• Eén vraag per keer, korte zinnen.\n• Geef tijd. Stiltes zijn goed.\n• Noem namen in plaats van "hij" of "zij".\n• Sluit aan bij wat je ziet: pak een fotoboek, zet muziek van vroeger op.\n\nVoelt de ander zich betrapt of nagekeken, dan volgt bijna altijd verzet. Vraag om hulp ("wil jij de aardappels doen?") in plaats van hulp aan te bieden.',
      },
      {
        title: 'Onrust, boosheid en zwerven',
        body: 'Moeilijk gedrag is bijna altijd een signaal: pijn, honger, te veel prikkels, te weinig te doen, of niet weten waar je bent. Zoek eerst de oorzaak.\n\nBij onrust helpt vaste regelmaat: dezelfde tijden, dezelfde gezichten, een rustige omgeving zonder televisie op de achtergrond.\n\nBlijf zelf rustig en zacht in je stem, ook als je iets voor de vijfde keer vertelt. Loopt het uit de hand, ga dan even weg als dat veilig kan en kom een paar minuten later opnieuw binnen: vaak is de bui dan over.\n\nGaat iemand zwerven of de deur uit? Praat het in de kring door en overleg met de casemanager dementie. Die is er ook voor jou.',
      },
    ],
    questions: [
      {
        question: 'Iemand wil naar haar moeder, die al lang is overleden. Wat zeg je?',
        options: [
          '"Je moeder is overleden, weet je dat niet meer?"',
          '"Je mist haar, hè? Vertel eens over haar."',
          '"Daar gaan we morgen naartoe."',
        ],
        correct_index: 1,
        uitleg: 'Reageer op het gevoel. Corrigeren geeft schrik, liegen geeft later teleurstelling.',
      },
      {
        question: 'Wat blijft bij iemand met dementie het langst bewaard?',
        options: [
          'Het gevoel dat een gesprek achterlaat',
          'Wat er vijf minuten eerder is gezegd',
          'Afspraken in de agenda',
        ],
        correct_index: 0,
        uitleg: 'Gevoelens en oude herinneringen blijven veel langer dan recente feiten.',
      },
      {
        question: 'Wat is meestal de beste eerste stap bij plotselinge onrust?',
        options: [
          'Streng grenzen stellen',
          'Zoeken naar de oorzaak, zoals pijn, honger of te veel prikkels',
          'De televisie aanzetten voor afleiding',
        ],
        correct_index: 1,
        uitleg: 'Moeilijk gedrag is een signaal; de oorzaak wegnemen werkt het beste.',
      },
      {
        question: 'Hoe stel je het beste een vraag aan iemand met dementie?',
        options: [
          'Meerdere keuzes in één zin, dan kan die kiezen',
          'Eén korte vraag, met tijd om te antwoorden',
          'Zo snel mogelijk, voordat de aandacht weg is',
        ],
        correct_index: 1,
        uitleg: 'Eén vraag per keer, korte zinnen en ruimte voor stiltes.',
      },
    ],
  },
  {
    slug: 'grenzen-en-volhouden',
    title: 'Grenzen stellen en volhouden',
    subtitle: 'Zorgen voor iemand zonder jezelf te verliezen',
    description:
      'Hoe je merkt dat je over je grens gaat, hoe je hulp vraagt zonder schuldgevoel, en welke regelingen er zijn om het vol te houden.',
    topic: 'Overbelasting',
    duur_minuten: 15,
    sortering: 3,
    modules: [
      {
        title: 'De signalen van overbelasting',
        body: 'Overbelasting komt zelden plotseling. Het kruipt: slecht slapen, kort aangebrand zijn, geen zin meer in dingen die je leuk vond, vaker ziek, het gevoel dat je nooit klaar bent.\n\nEen simpele check: kun je een middag weg zonder je zorgen te maken? Weet iemand anders wat er moet gebeuren als jij een week wegvalt? Is er nog iets in je week dat alleen voor jou is?\n\nDrie keer nee betekent niet dat je het slecht doet. Het betekent dat de last te veel op één paar schouders ligt.',
        video_url: 'https://www.youtube.com/watch?v=lYlrrPFcqxA',
        video_label: 'Video: herken overbelasting op tijd (3 min)',
      },
      {
        title: 'Hulp vragen die mensen ook kunnen geven',
        body: 'Op "laat maar weten of ik iets kan doen" komt bijna nooit iets. Op een concrete vraag wel: "kun jij donderdag om 16 uur boodschappen doen?"\n\nMaak daarom een lijstje met losse, afgebakende taken en verdeel die. Precies daarvoor is de hulpkring in deze app: je zet taken in het rooster en buddy\'s nemen ze aan. Je hoeft dus niet elke keer opnieuw te vragen.\n\nZeg ook wat je níet meer doet. Grenzen die je niet uitspreekt, bestaan voor anderen niet.',
      },
      {
        title: 'Regelingen die lucht geven',
        body: 'Er is meer mogelijk dan de meeste mensen weten:\n\n• Respijtzorg: iemand neemt de zorg tijdelijk over, van een dagje tot een week.\n• Dagbesteding: vaste dagen buitenshuis voor je naaste, rust voor jou.\n• Huishoudelijke hulp en hulpmiddelen via de Wmo van je gemeente.\n• Wijkverpleging voor persoonlijke zorg, via de zorgverzekering.\n• Mantelzorgwaardering: een jaarlijkse vergoeding van veel gemeenten.\n\nWeet je niet waar te beginnen? Stel je vraag aan een hulpmakelaar in deze app. Die kent de regelingen en verwijst je door naar de juiste persoon of instantie.',
      },
    ],
    questions: [
      {
        question: 'Wat is een duidelijk signaal van overbelasting?',
        options: [
          'Je slaapt slecht en bent korter aangebrand dan normaal',
          'Je hebt een drukke week gehad',
          'Je naaste heeft veel zorg nodig',
        ],
        correct_index: 0,
        uitleg: 'Slecht slapen, prikkelbaarheid en geen plezier meer zijn klassieke signalen.',
      },
      {
        question: 'Welke vraag levert het meeste hulp op?',
        options: [
          '"Laat maar weten of ik iets kan doen"',
          '"Kun jij donderdag om 16 uur boodschappen doen?"',
          '"Het lukt me even niet allemaal"',
        ],
        correct_index: 1,
        uitleg: 'Concrete, afgebakende vragen worden veel vaker opgepakt.',
      },
      {
        question: 'Wat is respijtzorg?',
        options: [
          'Een vergoeding voor mantelzorgers',
          'Iemand die de zorg tijdelijk overneemt zodat jij vrij bent',
          'Hulp bij het huishouden',
        ],
        correct_index: 1,
        uitleg: 'Respijtzorg neemt de zorg tijdelijk over, van een dag tot een week.',
      },
      {
        question: 'Bij wie kun je in deze app terecht met vragen over regelingen?',
        options: ['De hulpmakelaar', 'De beheerder van de kring', 'De andere buddy\'s'],
        correct_index: 0,
        uitleg: 'Hulpmakelaars kennen de regelingen en verwijzen je door.',
      },
    ],
  },
];

function overDagen(dagen, uur) {
  const d = new Date();
  d.setDate(d.getDate() + dagen);
  d.setHours(uur, 0, 0, 0);
  return d.toISOString();
}

const { data: makelaar } = await admin
  .from('profiles')
  .select('id')
  .eq('email', 'demo-makelaar@thuisverzorgd.dev')
  .maybeSingle();

for (const course of COURSES) {
  const { modules, questions, ...velden } = course;
  const { data: saved, error } = await admin
    .from('courses')
    .upsert(velden, { onConflict: 'slug' })
    .select('id')
    .single();
  if (error) throw new Error(`${course.slug}: ${error.message}`);

  // Onderdelen en vragen opnieuw zetten (idempotent bij herhaald seeden).
  await admin.from('course_modules').delete().eq('course_id', saved.id);
  await admin.from('course_questions').delete().eq('course_id', saved.id);

  const { error: mErr } = await admin.from('course_modules').insert(
    modules.map((m, i) => ({
      course_id: saved.id,
      sortering: i + 1,
      title: m.title,
      body: m.body,
      video_url: m.video_url ?? null,
      video_label: m.video_label ?? null,
    })),
  );
  if (mErr) throw new Error(`${course.slug} modules: ${mErr.message}`);

  const { error: qErr } = await admin.from('course_questions').insert(
    questions.map((q, i) => ({
      course_id: saved.id,
      sortering: i + 1,
      question: q.question,
      options: q.options,
      correct_index: q.correct_index,
      uitleg: q.uitleg ?? null,
    })),
  );
  if (qErr) throw new Error(`${course.slug} vragen: ${qErr.message}`);

  console.log(`✓ ${course.title} (${modules.length} onderdelen, ${questions.length} vragen)`);
}

// Klassikale groepen: een professional geeft les op een locatie in de buurt.
const { data: alleCursussen } = await admin.from('courses').select('id, slug');
const idVan = (slug) => alleCursussen.find((c) => c.slug === slug)?.id;

const GROEPEN = [
  {
    course_id: idVan('tillen-en-bewegen'),
    titel: 'Tilcursus met een fysiotherapeut',
    begeleider: 'Ellen Bakker, fysiotherapeut',
    locatie: 'Buurthuis De Pijp',
    adres: 'Tweede van der Helststraat 66, Amsterdam',
    city: 'Amsterdam',
    start_op: overDagen(6, 19),
    duur_minuten: 120,
    plekken: 12,
  },
  {
    course_id: idVan('dementie-begrijpen'),
    titel: 'Avond over dementie in het dagelijks leven',
    begeleider: 'Fatima el Amrani, casemanager dementie',
    locatie: 'Wijkcentrum Oost',
    adres: 'Wijttenbachstraat 36, Amsterdam',
    city: 'Amsterdam',
    start_op: overDagen(11, 19),
    duur_minuten: 90,
    plekken: 16,
  },
  {
    course_id: idVan('grenzen-en-volhouden'),
    titel: 'Groepsgesprek: hoe houd je het vol?',
    begeleider: 'Sanne Vermeer, hulpmakelaar',
    locatie: 'Bibliotheek Haarlem Centrum',
    adres: 'Gasthuisstraat 32, Haarlem',
    city: 'Haarlem',
    start_op: overDagen(17, 14),
    duur_minuten: 90,
    plekken: 10,
  },
];

for (const groep of GROEPEN) {
  if (!groep.course_id) continue;
  const { data: bestaat } = await admin
    .from('course_groups')
    .select('id')
    .eq('titel', groep.titel)
    .maybeSingle();
  if (bestaat) {
    await admin
      .from('course_groups')
      .update({ ...groep, created_by: makelaar?.id ?? null })
      .eq('id', bestaat.id);
  } else {
    const { error } = await admin
      .from('course_groups')
      .insert({ ...groep, created_by: makelaar?.id ?? null });
    if (error) throw new Error(`${groep.titel}: ${error.message}`);
  }
  console.log(`✓ groep: ${groep.titel}`);
}

console.log('\nKlaar! Opleidingen staan in de database.');

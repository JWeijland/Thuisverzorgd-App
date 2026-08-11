// De wegwijzer beantwoordt een getypte vraag met AI, maar uitsluitend op onze
// eigen kennisbank (feedback Jelle 11-08: het oude, extractieve antwoord was
// niet accuraat). De opzet is bewust streng:
//
//   1. `wegwijzer_context` haalt de stukken tekst op die over de vraag gaan.
//   2. Claude krijgt alleen díe stukken en mag er niets buiten gebruiken.
//   3. Het antwoord komt terug met de nummers van de bronnen die het gebruikt,
//      zodat de app onder elk antwoord kan tonen waar het vandaan komt.
//
// Weet de kennisbank het niet, dan zegt het model dat eerlijk en verwijst de
// app naar een hulpmakelaar. Liever geen antwoord dan een verzonnen antwoord:
// het gaat hier over regelingen waar mensen beslissingen op baseren.
import Anthropic from 'npm:@anthropic-ai/sdk@0.116.0';
import { createClient } from 'jsr:@supabase/supabase-js@2';

/**
 * Claude Opus 5. Bewust het beste model: dit zijn vragen over WMO, geld en
 * zorg, waar een net-niet-antwoord schadelijk is. Kosten per vraag blijven
 * klein omdat we alleen de gevonden stukken meesturen (zie CONTEXT_LIMIET).
 */
const MODEL = 'claude-opus-5';

/** Hoeveel stukken kennisbank er hoogstens mee gaan als context. */
const CONTEXT_LIMIET = 8;

const anthropic = new Anthropic({ apiKey: Deno.env.get('ANTHROPIC_API_KEY')! });

const SYSTEEM = `Je beantwoordt vragen in de app Thuisverzorgd, voor mensen die
voor een naaste zorgen of zelf hulp krijgen. Vaak zijn ze moe, ongerust of niet
thuis in de regels.

Je krijgt genummerde fragmenten uit onze eigen kennisbank. Dat is je enige bron.

Regels:
- Gebruik uitsluitend wat er in de fragmenten staat. Verzin niets, ook geen
  bedragen, termijnen, wetsartikelen of instanties.
- Staat het antwoord er niet in, zet dan gevonden op false en leg in één zin
  uit wat je wel weet en wat niet.
- Schrijf in gewone taal, in het Nederlands, en spreek de lezer aan met je.
  Geen jargon zonder uitleg. Hooguit een paar zinnen.
- Noem bij bronnen de nummers van de fragmenten die je echt hebt gebruikt.
- Gebruik geen gedachtestreepjes (—) in je antwoord.
- Geef geen medisch, juridisch of financieel advies dat verder gaat dan wat er
  in de fragmenten staat. Bij twijfel verwijs je naar een hulpmakelaar.`;

/** Het model levert het antwoord in dit vaste formaat aan. */
const ANTWOORD_SCHEMA = {
  type: 'object',
  properties: {
    gevonden: {
      type: 'boolean',
      description: 'Staat het antwoord echt in de meegegeven fragmenten?',
    },
    antwoord: {
      type: 'string',
      description: 'Het antwoord in gewone taal, hooguit een paar zinnen.',
    },
    bronnen: {
      type: 'array',
      description: 'Nummers van de fragmenten waarop dit antwoord berust.',
      items: { type: 'integer' },
    },
  },
  required: ['gevonden', 'antwoord', 'bronnen'],
  additionalProperties: false,
} as const;

type Fragment = {
  module_id: string;
  module_slug: string;
  module_titel: string;
  sectie_titel: string;
  body: string;
  wetten: string[];
};

Deno.serve(async (request) => {
  if (request.method !== 'POST') {
    return json({ fout: 'methode' }, 405);
  }

  // De vraag hoort bij een ingelogde gebruiker: we lezen de kennisbank onder
  // zijn eigen token, zodat RLS gewoon blijft gelden.
  const authorization = request.headers.get('Authorization');
  if (!authorization) {
    return json({ fout: 'niet ingelogd' }, 401);
  }

  let vraag = '';
  try {
    const body = await request.json();
    vraag = typeof body?.vraag === 'string' ? body.vraag.trim() : '';
  } catch {
    return json({ fout: 'ongeldige aanvraag' }, 400);
  }
  if (vraag.length < 8 || vraag.length > 500) {
    return json({ fout: 'vraag te kort of te lang' }, 400);
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    { global: { headers: { Authorization: authorization } } },
  );

  const { data, error } = await supabase.rpc('wegwijzer_context', {
    p_vraag: vraag,
    p_limiet: CONTEXT_LIMIET,
  });
  if (error) {
    console.error('wegwijzer-ai: context ophalen mislukt', error);
    return json({ fout: 'kennisbank niet bereikbaar' }, 502);
  }

  const fragmenten = (data ?? []) as Fragment[];
  if (fragmenten.length === 0) {
    // Niets gevonden: dan hoeven we het model niet eens te vragen.
    return json({ gevonden: false, antwoord: null, bronnen: [] });
  }

  const context = fragmenten
    .map((fragment, i) => {
      const wetten = fragment.wetten?.length ? `\nWettelijke basis: ${fragment.wetten.join('; ')}` : '';
      return `[${i + 1}] ${fragment.module_titel} — ${fragment.sectie_titel}\n${fragment.body}${wetten}`;
    })
    .join('\n\n');

  try {
    const response = await anthropic.messages.create({
      model: MODEL,
      max_tokens: 4000,
      system: SYSTEEM,
      // Lage effort: dit is samenvatten uit gegeven tekst, geen puzzel. Dat
      // scheelt wachttijd en kosten zonder dat het antwoord slechter wordt.
      output_config: {
        effort: 'low',
        format: { type: 'json_schema', schema: ANTWOORD_SCHEMA },
      },
      messages: [
        {
          role: 'user',
          content: `Fragmenten uit de kennisbank:\n\n${context}\n\nDe vraag: ${vraag}`,
        },
      ],
    });

    if (response.stop_reason === 'refusal') {
      console.warn('wegwijzer-ai: geweigerd', response.stop_details);
      return json({ gevonden: false, antwoord: null, bronnen: [] });
    }

    const tekst = response.content.find((blok) => blok.type === 'text');
    if (!tekst || tekst.type !== 'text') {
      return json({ gevonden: false, antwoord: null, bronnen: [] });
    }

    const uitkomst = JSON.parse(tekst.text) as {
      gevonden: boolean;
      antwoord: string;
      bronnen: number[];
    };

    // De nummers terugvertalen naar echte modules, zodat de app er naartoe
    // kan linken. Onbekende nummers gooien we weg.
    const bronnen = (uitkomst.bronnen ?? [])
      .map((nummer) => fragmenten[nummer - 1])
      .filter((fragment): fragment is Fragment => !!fragment)
      .map((fragment) => ({
        module_id: fragment.module_id,
        slug: fragment.module_slug,
        titel: fragment.module_titel,
      }))
      // Twee fragmenten uit dezelfde module worden één bron.
      .filter(
        (bron, i, alle) => alle.findIndex((ander) => ander.module_id === bron.module_id) === i,
      );

    return json({
      gevonden: uitkomst.gevonden && bronnen.length > 0,
      antwoord: uitkomst.gevonden ? uitkomst.antwoord : null,
      bronnen,
    });
  } catch (fout) {
    console.error('wegwijzer-ai: model niet bereikbaar', fout);
    return json({ fout: 'antwoord niet gelukt' }, 502);
  }
});

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json' },
  });
}

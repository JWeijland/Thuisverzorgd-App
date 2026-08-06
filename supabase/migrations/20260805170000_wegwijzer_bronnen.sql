-- Wegwijzer: correcties uit de factcheck van augustus 2026, en veel meer
-- bronnen ("verder lezen") per onderwerp. Elke URL in dit bestand is op
-- 5/6 augustus 2026 gecontroleerd en gaf een geldige pagina terug.
--
-- Correcties:
--  * De Alzheimer Telefoon heet inmiddels DementieLijn (0800-5088) en is
--    bereikbaar van 9.00 tot 21.00 uur, niet dag en nacht.
--  * Het bedrag "1.434 euro per kwartaal" bij de dubbele kinderbijslag staat
--    niet (meer) op svb.nl; we verwijzen nu naar de actuele SVB-pagina.
--  * rechtspraak.nl, svb.nl en rijksoverheid.nl hebben hun URL-structuur
--    omgegooid; vier links gaven een 404 en zijn vervangen.
--
-- De seed-hulpfuncties zijn na de eerste vulling opgeruimd; hier maken we ze
-- opnieuw aan. De migratie met nieuwe onderwerpen (hierna) ruimt ze weer op.

create or replace function public.wegwijzer_seed_module(
  p_thema text, p_slug text, p_titel text, p_samenvatting text,
  p_kern text[], p_wetten text[], p_zoektermen text[],
  p_leestijd integer, p_sortering integer, p_populair boolean default false
)
returns void
language sql as $$
  insert into public.guide_modules (
    theme_id, slug, titel, samenvatting, kern, wetten, zoektermen,
    leestijd_minuten, sortering, populair
  )
  select t.id, p_slug, p_titel, p_samenvatting, p_kern, p_wetten, p_zoektermen,
         p_leestijd, p_sortering, p_populair
  from public.guide_themes t
  where t.slug = p_thema
  on conflict (slug) do update set
    theme_id = excluded.theme_id,
    titel = excluded.titel,
    samenvatting = excluded.samenvatting,
    kern = excluded.kern,
    wetten = excluded.wetten,
    zoektermen = excluded.zoektermen,
    leestijd_minuten = excluded.leestijd_minuten,
    sortering = excluded.sortering,
    populair = excluded.populair,
    bijgewerkt_op = current_date;
$$;

create or replace function public.wegwijzer_seed_sectie(
  p_module text, p_sortering integer, p_soort text, p_titel text, p_body text
)
returns void
language sql as $$
  insert into public.guide_sections (module_id, sortering, soort, titel, body)
  select m.id, p_sortering, p_soort, p_titel, p_body
  from public.guide_modules m
  where m.slug = p_module
  on conflict (module_id, sortering) do update set
    soort = excluded.soort,
    titel = excluded.titel,
    body = excluded.body;
$$;

create or replace function public.wegwijzer_seed_link(
  p_module text, p_sortering integer, p_titel text, p_url text
)
returns void
language sql as $$
  insert into public.guide_links (module_id, sortering, titel, url)
  select m.id, p_sortering, p_titel, p_url
  from public.guide_modules m
  where m.slug = p_module
  on conflict (module_id, sortering) do update set
    titel = excluded.titel,
    url = excluded.url;
$$;

-- ---------------------------------------------------------------------------
-- Correcties
-- ---------------------------------------------------------------------------

-- DementieLijn in plaats van Alzheimer Telefoon, met de juiste tijden.
select public.wegwijzer_seed_link('dementie-herkennen', 2,
  'DementieLijn: 0800-5088, elke dag van 9.00 tot 21.00 uur',
  'https://www.alzheimer-nederland.nl/over-ons/wat-doen-wij/hulp-en-advies/dementielijn');

select public.wegwijzer_seed_module(
  'jezelf', 'steunpunt-en-lotgenoten', 'Steunpunt mantelzorg en lotgenotencontact',
  'In vrijwel elke gemeente zit een steunpunt met gratis ondersteuning, cursussen en een luisterend oor. Daarnaast helpt contact met mensen die precies weten hoe het is.',
  array[
    'Het steunpunt is gratis en je hebt er geen indicatie voor nodig.',
    'Ze regelen praktische zaken: vrijwilligers, cursussen, een pas met kortingen.',
    'Alzheimer Cafés en lotgenotengroepen zijn vrij toegankelijk, ook zonder aanmelding.',
    'De Mantelzorglijn en de DementieLijn zijn er als je gewoon even wilt praten.'
  ],
  array['Wmo 2015, artikel 2.1.2 lid 4'],
  array['steunpunt mantelzorg', 'lotgenoten', 'alzheimer cafe', 'praten', 'mantelzorglijn', 'dementielijn', 'cursus', 'vrijwilliger', 'contact', 'hulp in de buurt'],
  4, 3, false
);

select public.wegwijzer_seed_sectie('steunpunt-en-lotgenoten', 3, 'stappen', 'Waar je terecht kunt', $t$Steunpunt mantelzorg van je gemeente: gratis ondersteuning en cursussen.
De Mantelzorglijn van MantelzorgNL: voor vragen en een luisterend oor.
De DementieLijn (0800-5088): elke dag bereikbaar van 9.00 tot 21.00 uur, ook voor naasten.
Het Alzheimer Café in je regio: maandelijks, vrij binnenlopen.
In deze app: het forum bij Steun, en een gesprek met een hulpmakelaar.$t$);

-- Dubbele kinderbijslag: het kwartaalbedrag verandert per jaar en staat niet
-- meer zo op svb.nl; verwijs naar de bron in plaats van een los bedrag.
select public.wegwijzer_seed_sectie('dubbele-kinderbijslag', 1, 'uitleg', 'Wanneer je er recht op hebt', $t$Je kind is tussen de 3 en 18 jaar, heeft intensieve zorg nodig en woont minstens vier nachten per week bij jou. Er moet een Wlz-indicatie zijn, of een positief advies van het CIZ.

Woont je kind doordeweeks elders, bijvoorbeeld op een zorginstelling, dan kan het nog steeds, maar moet je aantonen dat je voldoende aan het onderhoud bijdraagt. De SVB hanteert daarvoor een minimumbedrag per kwartaal dat elk jaar opnieuw wordt vastgesteld; het actuele bedrag staat op svb.nl.$t$);

-- Medehuur: de verhuurder hoeft niet te weigeren; ook niets laten horen telt.
select public.wegwijzer_seed_sectie('huurwoning-en-overlijden', 3, 'stappen', 'Regel het nu, niet straks', $t$Vraag samen schriftelijk medehuurderschap aan bij de verhuurder.
Voeg bewijs bij: inschrijving op het adres, gedeelde kosten, duur van de situatie.
Weigert de verhuurder, of laat hij drie maanden niets van zich horen, dan kun je het aan de kantonrechter voorleggen.
Doe dit zolang de huurder nog leeft; achteraf is de bewijslast veel zwaarder.
Twijfel je, vraag gratis advies bij het Juridisch Loket of de Woonbond.$t$);

-- ---------------------------------------------------------------------------
-- Bronnen per onderwerp. Volgorde: eerst de praktische pagina's, dan de
-- wettekst zelf op wetten.overheid.nl als onderbouwing.
-- ---------------------------------------------------------------------------

-- Thema: hoe zit het zorgstelsel in elkaar
select public.wegwijzer_seed_link('wat-is-mantelzorg', 3, 'Rijksoverheid: mantelzorg', 'https://www.rijksoverheid.nl/themas/familie-zorg-en-gezondheid/mantelzorg');
select public.wegwijzer_seed_link('wat-is-mantelzorg', 4, 'Wettekst Wmo 2015 op wetten.overheid.nl', 'https://wetten.overheid.nl/BWBR0035362');

select public.wegwijzer_seed_link('welke-wet', 3, 'Zorginstituut Nederland: wat zit er in het basispakket', 'https://www.zorginstituutnederland.nl');
select public.wegwijzer_seed_link('welke-wet', 4, 'Wettekst Wet langdurige zorg', 'https://wetten.overheid.nl/BWBR0035917');
select public.wegwijzer_seed_link('welke-wet', 5, 'Wettekst Zorgverzekeringswet', 'https://wetten.overheid.nl/BWBR0018450');
select public.wegwijzer_seed_link('welke-wet', 6, 'Wettekst Jeugdwet', 'https://wetten.overheid.nl/BWBR0034925');

select public.wegwijzer_seed_link('hulp-aanvragen-gemeente', 1, 'Rijksoverheid: zorg en ondersteuning thuis', 'https://www.rijksoverheid.nl/themas/familie-zorg-en-gezondheid/zorg-en-ondersteuning-thuis');
select public.wegwijzer_seed_link('hulp-aanvragen-gemeente', 2, 'Regelhulp: ondersteuning en advies voor mantelzorgers', 'https://www.regelhulp.nl/mantelzorgers/ondersteuning-en-advies');
select public.wegwijzer_seed_link('hulp-aanvragen-gemeente', 3, 'Wettekst Wmo 2015 (melding, onderzoek en termijnen)', 'https://wetten.overheid.nl/BWBR0035362');

select public.wegwijzer_seed_link('clientondersteuning', 2, 'MEE: cliëntondersteuning in de buurt', 'https://www.mee.nl');
select public.wegwijzer_seed_link('clientondersteuning', 3, 'Wettekst Wmo 2015, artikel 2.2.4', 'https://wetten.overheid.nl/BWBR0035362');

select public.wegwijzer_seed_link('bezwaar-en-klacht', 2, 'Nationale ombudsman', 'https://www.nationaleombudsman.nl');
select public.wegwijzer_seed_link('bezwaar-en-klacht', 3, 'Wettekst Algemene wet bestuursrecht', 'https://wetten.overheid.nl/BWBR0005537');

-- Thema: geld en regelingen
select public.wegwijzer_seed_link('mantelzorgwaardering', 1, 'MantelzorgNL: waardering en vergoedingen', 'https://www.mantelzorg.nl');
select public.wegwijzer_seed_link('mantelzorgwaardering', 2, 'Wettekst Wmo 2015, artikel 2.1.6', 'https://wetten.overheid.nl/BWBR0035362');
select public.wegwijzer_seed_link('mantelzorgwaardering', 3, 'Rijksoverheid: mantelzorg', 'https://www.rijksoverheid.nl/themas/familie-zorg-en-gezondheid/mantelzorg');

select public.wegwijzer_seed_link('pgb', 1, 'Rijksoverheid: persoonsgebonden budget', 'https://www.rijksoverheid.nl/themas/familie-zorg-en-gezondheid/persoonsgebonden-budget-pgb');
select public.wegwijzer_seed_link('pgb', 4, 'Regelhulp: pgb', 'https://www.regelhulp.nl/onderwerpen/pgb');

select public.wegwijzer_seed_link('eigen-bijdrage', 2, 'Rijksoverheid: de zorgverzekering en het eigen risico', 'https://www.rijksoverheid.nl/themas/familie-zorg-en-gezondheid/zorgverzekering');
select public.wegwijzer_seed_link('eigen-bijdrage', 3, 'Wettekst Wmo 2015, artikel 2.1.4a', 'https://wetten.overheid.nl/BWBR0035362');

select public.wegwijzer_seed_link('zorgkosten-belasting', 3, 'Belastingdienst: het drempelbedrag berekenen (2026)', 'https://www.belastingdienst.nl/wps/wcm/connect/bldcontentnl/belastingdienst/prive/relatie_familie_en_gezondheid/gezondheid/aftrek_zorgkosten/hoe_berekent_u_uw_aftrek/drempelbedrag_berekenen/drempelbedrag-2026');
select public.wegwijzer_seed_link('zorgkosten-belasting', 4, 'Nibud: grip op geld en regelingen', 'https://www.nibud.nl');

select public.wegwijzer_seed_link('uitkering-en-inwonen', 3, 'SVB: AOW en samenwonen', 'https://www.svb.nl/nl/aow');
select public.wegwijzer_seed_link('uitkering-en-inwonen', 4, 'Wettekst Participatiewet', 'https://wetten.overheid.nl/BWBR0015703');

select public.wegwijzer_seed_link('dubbele-kinderbijslag', 1, 'SVB: dubbele kinderbijslag bij intensieve zorg', 'https://www.svb.nl/nl/kinderbijslag/dubbele-kinderbijslag/dubbele-kinderbijslag-thuiswonend-kind-intensieve-zorg');
select public.wegwijzer_seed_link('dubbele-kinderbijslag', 2, 'SVB: extra kinderbijslag bij intensieve zorg', 'https://www.svb.nl/nl/kinderbijslag/dubbele-kinderbijslag/extra-kinderbijslag-bij-intensieve-zorg');
select public.wegwijzer_seed_link('dubbele-kinderbijslag', 3, 'Meerkosten.nl: dubbele kinderbijslag', 'https://meerkosten.nl/inkomensondersteuning/dubbele-kinderbijslag/');
select public.wegwijzer_seed_link('dubbele-kinderbijslag', 4, 'Wettekst Algemene Kinderbijslagwet, artikel 7a', 'https://wetten.overheid.nl/BWBR0002368');

select public.wegwijzer_seed_link('erfenis-en-schenken', 3, 'Wettekst Successiewet 1956', 'https://wetten.overheid.nl/BWBR0002226');

-- Thema: wonen en verbouwen
select public.wegwijzer_seed_link('mantelzorgwoning', 3, 'Wettekst Besluit bouwwerken leefomgeving', 'https://wetten.overheid.nl/BWBR0041297');
select public.wegwijzer_seed_link('mantelzorgwoning', 4, 'Rijksoverheid: mantelzorg', 'https://www.rijksoverheid.nl/themas/familie-zorg-en-gezondheid/mantelzorg');

select public.wegwijzer_seed_link('inwonen-bij-elkaar', 1, 'Belastingdienst: proefberekening toeslagen', 'https://www.belastingdienst.nl/wps/wcm/connect/nl/toeslagen/toeslagen');
select public.wegwijzer_seed_link('inwonen-bij-elkaar', 2, 'SVB: gevolgen van samenwonen voor de AOW', 'https://www.svb.nl/nl/aow');
select public.wegwijzer_seed_link('inwonen-bij-elkaar', 3, 'Rijksoverheid: nieuwe regels bijstand 2026 en 2027', 'https://www.rijksoverheid.nl/themas/belastingen-uitkeringen-en-toeslagen/bijstand/nieuwe-regels-bijstand-2026-en-2027');

select public.wegwijzer_seed_link('woning-aanpassen', 1, 'Regelhulp: wonen met zorg', 'https://www.regelhulp.nl/onderwerpen/wonen');
select public.wegwijzer_seed_link('woning-aanpassen', 2, 'Rijksoverheid: zorg en ondersteuning thuis', 'https://www.rijksoverheid.nl/themas/familie-zorg-en-gezondheid/zorg-en-ondersteuning-thuis');
select public.wegwijzer_seed_link('woning-aanpassen', 3, 'Wettekst Wmo 2015, artikel 2.3.5', 'https://wetten.overheid.nl/BWBR0035362');

select public.wegwijzer_seed_link('verhuizen-en-urgentie', 1, 'Regelhulp: wonen', 'https://www.regelhulp.nl/onderwerpen/wonen');
select public.wegwijzer_seed_link('verhuizen-en-urgentie', 2, 'Woonbond', 'https://www.woonbond.nl');
select public.wegwijzer_seed_link('verhuizen-en-urgentie', 3, 'Wettekst Huisvestingswet 2014', 'https://wetten.overheid.nl/BWBR0035303');

select public.wegwijzer_seed_link('huurwoning-en-overlijden', 2, 'Juridisch Loket: wonen en huren', 'https://www.juridischloket.nl/wonen-en-buren');
select public.wegwijzer_seed_link('huurwoning-en-overlijden', 3, 'Wettekst Burgerlijk Wetboek Boek 7 (artikel 267 en 268)', 'https://wetten.overheid.nl/BWBR0005290');

-- Thema: werk en verlof
select public.wegwijzer_seed_link('zorgverlof-kort', 1, 'Rijksoverheid: zorgverlof', 'https://www.rijksoverheid.nl/themas/familie-zorg-en-gezondheid/zorgverlof');
select public.wegwijzer_seed_link('zorgverlof-kort', 2, 'Wettekst Wet arbeid en zorg', 'https://wetten.overheid.nl/BWBR0013008');
select public.wegwijzer_seed_link('zorgverlof-kort', 3, 'Juridisch Loket', 'https://www.juridischloket.nl');

select public.wegwijzer_seed_link('langdurend-zorgverlof', 1, 'Rijksoverheid: zorgverlof', 'https://www.rijksoverheid.nl/themas/familie-zorg-en-gezondheid/zorgverlof');
select public.wegwijzer_seed_link('langdurend-zorgverlof', 2, 'Wettekst Wet arbeid en zorg, hoofdstuk 5', 'https://wetten.overheid.nl/BWBR0013008');
select public.wegwijzer_seed_link('langdurend-zorgverlof', 3, 'MantelzorgNL: werk en mantelzorg', 'https://www.mantelzorg.nl');

select public.wegwijzer_seed_link('werktijden-aanpassen', 1, 'Wettekst Wet flexibel werken', 'https://wetten.overheid.nl/BWBR0011173');
select public.wegwijzer_seed_link('werktijden-aanpassen', 2, 'Juridisch Loket', 'https://www.juridischloket.nl');
select public.wegwijzer_seed_link('werktijden-aanpassen', 3, 'Rijksoverheid: zorgverlof en werk', 'https://www.rijksoverheid.nl/themas/familie-zorg-en-gezondheid/zorgverlof');

select public.wegwijzer_seed_link('gesprek-met-werkgever', 1, 'MantelzorgNL: werk en mantelzorg combineren', 'https://www.mantelzorg.nl');
select public.wegwijzer_seed_link('gesprek-met-werkgever', 2, 'Rijksoverheid: mantelzorg', 'https://www.rijksoverheid.nl/themas/familie-zorg-en-gezondheid/mantelzorg');

select public.wegwijzer_seed_link('zzp-en-geen-werkgever', 1, 'UWV: regels rond je uitkering', 'https://www.uwv.nl/particulieren');
select public.wegwijzer_seed_link('zzp-en-geen-werkgever', 2, 'KVK: ondernemen en zorg combineren', 'https://www.kvk.nl');
select public.wegwijzer_seed_link('zzp-en-geen-werkgever', 3, 'SVB: betaald worden uit een pgb', 'https://www.svb.nl/nl/pgb');

-- Thema: dementie
select public.wegwijzer_seed_link('dementie-herkennen', 3, 'Thuisarts.nl: dementie', 'https://www.thuisarts.nl/dementie');
select public.wegwijzer_seed_link('dementie-herkennen', 4, 'Dementie.nl: voor mantelzorgers', 'https://dementie.nl');

select public.wegwijzer_seed_link('casemanager-dementie', 2, 'Alzheimer Nederland', 'https://www.alzheimer-nederland.nl');
select public.wegwijzer_seed_link('casemanager-dementie', 3, 'Dementie.nl: hulp regelen', 'https://dementie.nl');

select public.wegwijzer_seed_link('omgaan-met-verandering', 2, 'Dementie.nl: omgaan met veranderend gedrag', 'https://dementie.nl');
select public.wegwijzer_seed_link('omgaan-met-verandering', 3, 'Thuisarts.nl: dementie', 'https://www.thuisarts.nl/dementie');

select public.wegwijzer_seed_link('wet-zorg-en-dwang', 2, 'Wettekst Wet zorg en dwang', 'https://wetten.overheid.nl/BWBR0040632');
select public.wegwijzer_seed_link('wet-zorg-en-dwang', 3, 'Alzheimer Nederland', 'https://www.alzheimer-nederland.nl');

select public.wegwijzer_seed_link('naar-het-verpleeghuis', 3, 'CAK: eigen bijdrage Wlz berekenen', 'https://www.hetcak.nl');
select public.wegwijzer_seed_link('naar-het-verpleeghuis', 4, 'Wettekst Wet langdurige zorg', 'https://wetten.overheid.nl/BWBR0035917');

-- Thema: beslissen voor een ander
select public.wegwijzer_seed_link('wilsbekwaamheid', 1, 'Goedvertegenwoordigd.nl: wie beslist er', 'https://goedvertegenwoordigd.nl');
select public.wegwijzer_seed_link('wilsbekwaamheid', 2, 'Patiëntenfederatie Nederland', 'https://www.patientenfederatie.nl');
select public.wegwijzer_seed_link('wilsbekwaamheid', 3, 'Wettekst Burgerlijk Wetboek Boek 7, artikel 465 (WGBO)', 'https://wetten.overheid.nl/BWBR0005290');

select public.wegwijzer_seed_link('volmacht-en-levenstestament', 2, 'Goedvertegenwoordigd.nl: volmacht en levenstestament', 'https://goedvertegenwoordigd.nl');
select public.wegwijzer_seed_link('volmacht-en-levenstestament', 3, 'Patiëntenfederatie Nederland', 'https://www.patientenfederatie.nl');

select public.wegwijzer_seed_link('mentorschap-bewind-curatele', 1, 'Rechtspraak.nl: bewind aanvragen', 'https://www.rechtspraak.nl/onderwerpen/bewind');
select public.wegwijzer_seed_link('mentorschap-bewind-curatele', 2, 'Rechtspraak.nl: mentorschap aanvragen', 'https://www.rechtspraak.nl/onderwerpen/mentorschap');
select public.wegwijzer_seed_link('mentorschap-bewind-curatele', 3, 'Rechtspraak.nl: curatele aanvragen', 'https://www.rechtspraak.nl/onderwerpen/curatele');
select public.wegwijzer_seed_link('mentorschap-bewind-curatele', 4, 'Goedvertegenwoordigd.nl', 'https://goedvertegenwoordigd.nl');
select public.wegwijzer_seed_link('mentorschap-bewind-curatele', 5, 'Wettekst Burgerlijk Wetboek Boek 1', 'https://wetten.overheid.nl/BWBR0002656');

select public.wegwijzer_seed_link('wilsverklaring-en-behandelverbod', 1, 'Thuisarts.nl: nadenken over het levenseinde', 'https://www.thuisarts.nl/levenseinde');
select public.wegwijzer_seed_link('wilsverklaring-en-behandelverbod', 2, 'Patiëntenfederatie: wilsverklaring en niet-reanimerenpenning', 'https://www.patientenfederatie.nl');
select public.wegwijzer_seed_link('wilsverklaring-en-behandelverbod', 3, 'Wettekst Wet toetsing levensbeëindiging op verzoek', 'https://wetten.overheid.nl/BWBR0012410');

select public.wegwijzer_seed_link('dossier-en-privacy', 1, 'Patiëntenfederatie: rechten rond je dossier', 'https://www.patientenfederatie.nl');
select public.wegwijzer_seed_link('dossier-en-privacy', 2, 'Goedvertegenwoordigd.nl', 'https://goedvertegenwoordigd.nl');
select public.wegwijzer_seed_link('dossier-en-privacy', 3, 'Wettekst WGBO (Burgerlijk Wetboek Boek 7, afdeling 5)', 'https://wetten.overheid.nl/BWBR0005290');

-- Thema: zorg thuis regelen
select public.wegwijzer_seed_link('wijkverpleging', 1, 'Rijksoverheid: zorg en ondersteuning thuis', 'https://www.rijksoverheid.nl/themas/familie-zorg-en-gezondheid/zorg-en-ondersteuning-thuis');
select public.wegwijzer_seed_link('wijkverpleging', 2, 'Zorginstituut Nederland: wijkverpleging in het basispakket', 'https://www.zorginstituutnederland.nl');
select public.wegwijzer_seed_link('wijkverpleging', 3, 'Zorgkaart Nederland: thuiszorgorganisaties vergelijken', 'https://www.zorgkaartnederland.nl');

select public.wegwijzer_seed_link('huishoudelijke-hulp', 1, 'Regelhulp: ondersteuning voor mantelzorgers', 'https://www.regelhulp.nl/mantelzorgers/ondersteuning-en-advies');
select public.wegwijzer_seed_link('huishoudelijke-hulp', 2, 'CAK: eigen bijdrage Wmo', 'https://www.hetcak.nl');
select public.wegwijzer_seed_link('huishoudelijke-hulp', 3, 'Wettekst Wmo 2015', 'https://wetten.overheid.nl/BWBR0035362');

select public.wegwijzer_seed_link('dagbesteding', 1, 'Dementie.nl: dagbesteding', 'https://dementie.nl');
select public.wegwijzer_seed_link('dagbesteding', 2, 'Rijksoverheid: zorg en ondersteuning thuis', 'https://www.rijksoverheid.nl/themas/familie-zorg-en-gezondheid/zorg-en-ondersteuning-thuis');
select public.wegwijzer_seed_link('dagbesteding', 3, 'Zorgkaart Nederland: dagbesteding in de buurt', 'https://www.zorgkaartnederland.nl');

select public.wegwijzer_seed_link('respijtzorg', 3, 'De Zonnebloem: vakanties en dagjes uit met zorg', 'https://www.zonnebloem.nl');
select public.wegwijzer_seed_link('respijtzorg', 4, 'Rijksoverheid: mantelzorg en vervangende zorg', 'https://www.rijksoverheid.nl/themas/familie-zorg-en-gezondheid/mantelzorg');

select public.wegwijzer_seed_link('hulpmiddelen-en-vervoer', 1, 'Regelhulp: hulpmiddelen', 'https://www.regelhulp.nl/onderwerpen/hulpmiddelen');
select public.wegwijzer_seed_link('hulpmiddelen-en-vervoer', 2, 'Valys: vervoer voor langere afstanden', 'https://www.valys.nl');
select public.wegwijzer_seed_link('hulpmiddelen-en-vervoer', 3, 'Zorginstituut Nederland: hulpmiddelen en zittend ziekenvervoer', 'https://www.zorginstituutnederland.nl');

-- Thema: zorgen voor jezelf
select public.wegwijzer_seed_link('overbelasting', 1, 'MantelzorgNL en de Mantelzorglijn', 'https://www.mantelzorg.nl');
select public.wegwijzer_seed_link('overbelasting', 2, 'Thuisarts.nl: klachten en gezond blijven', 'https://www.thuisarts.nl');
select public.wegwijzer_seed_link('overbelasting', 3, 'Regelhulp: ondersteuning voor mantelzorgers', 'https://www.regelhulp.nl/mantelzorgers/ondersteuning-en-advies');

select public.wegwijzer_seed_link('mantelzorgmakelaar', 1, 'BMZM: beroepsvereniging van mantelzorgmakelaars', 'https://www.bmzm.nl');
select public.wegwijzer_seed_link('mantelzorgmakelaar', 2, 'MantelzorgNL: de mantelzorgmakelaar', 'https://www.mantelzorg.nl');

select public.wegwijzer_seed_link('steunpunt-en-lotgenoten', 3, 'DementieLijn: 0800-5088, elke dag van 9.00 tot 21.00 uur', 'https://www.alzheimer-nederland.nl/over-ons/wat-doen-wij/hulp-en-advies/dementielijn');

select public.wegwijzer_seed_link('als-de-zorg-stopt', 1, 'Slachtofferhulp Nederland: steun bij verlies', 'https://www.slachtofferhulp.nl');
select public.wegwijzer_seed_link('als-de-zorg-stopt', 2, 'MantelzorgNL: als de zorg stopt', 'https://www.mantelzorg.nl');
select public.wegwijzer_seed_link('als-de-zorg-stopt', 3, 'Geestelijke verzorging thuis', 'https://geestelijkeverzorging.nl');

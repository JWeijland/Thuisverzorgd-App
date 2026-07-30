-- Wegwijzer, inhoud 4 van 4: zorg thuis regelen en zorgen voor jezelf.
-- Ruimt aan het eind de hulpfuncties op die alleen voor het vullen dienden.
-- Bijgewerkt: juli 2026.

-- ===========================================================================
-- THEMA: zorg thuis regelen
-- ===========================================================================

select public.wegwijzer_seed_module(
  'zorg-thuis', 'wijkverpleging', 'Wijkverpleging aan huis',
  'Verpleging en verzorging thuis: wassen, aankleden, steunkousen, wondzorg, medicijnen. Uit de basisverzekering, zonder eigen risico en zonder verwijzing van de huisarts.',
  array[
    'De wijkverpleegkundige stelt zelf de indicatie; je hebt geen verwijzing nodig.',
    'Het valt onder de basisverzekering en telt niet mee voor het eigen risico.',
    'Je mag zelf een thuiszorgorganisatie kiezen, ook een niet-gecontracteerde.',
    'Ben je het oneens met het aantal uren, vraag dan om een herindicatie op papier.'
  ],
  array['Zorgverzekeringswet, artikel 2.10 Besluit zorgverzekering'],
  array['wijkverpleging', 'thuiszorg', 'verzorging', 'wassen en aankleden', 'steunkousen', 'wondverzorging', 'medicijnen', 'verpleegkundige', 'indicatie thuiszorg'],
  5, 1, false
);

select public.wegwijzer_seed_sectie('wijkverpleging', 1, 'uitleg', 'Wat eronder valt', $t$Wijkverpleging omvat verpleging (wondzorg, injecties, katheters, medicatie) en persoonlijke verzorging (wassen, aankleden, steunkousen, toiletgang, hulp bij eten). Ook advies aan jou hoort erbij, net als het coördineren met de huisarts.

Wat er níét onder valt: het huishouden, gezelschap houden en begeleiding. Dat loopt via de Wmo.$t$);

select public.wegwijzer_seed_sectie('wijkverpleging', 2, 'stappen', 'Zo regel je het', $t$Bel een thuiszorgorganisatie in de buurt, of vraag de huisarts om een naam.
Vraag naar een indicatiegesprek met een wijkverpleegkundige; dat is gratis.
Bereid het gesprek voor: beschrijf een gewone dag en wat er misgaat.
Vertel expliciet wat jij nu opvangt en wat er gebeurt als jij wegvalt.
Je krijgt een zorgplan met het aantal uren en de taken; vraag om een kopie.
Verandert de situatie, vraag dan om een herindicatie; dat kan altijd.$t$);

select public.wegwijzer_seed_sectie('wijkverpleging', 3, 'letop', 'Let op de gecontracteerde zorg', $t$Kies je een aanbieder die geen contract heeft met de zorgverzekeraar, dan krijg je vaak maar een deel vergoed, meestal 70 tot 80 procent. Vraag dit vooraf na, zowel bij de aanbieder als bij de verzekeraar.

Bij een naturapolis is het verschil groot; bij een restitutiepolis meestal niet.$t$);

select public.wegwijzer_seed_sectie('wijkverpleging', 4, 'vraag', 'De thuiszorg komt te weinig, wat kan ik doen', $t$Bespreek eerst met de wijkverpleegkundige wat er niet lukt en vraag om herindicatie. Zet het daarna op de mail.

Verandert er niets, dan kun je klagen bij de organisatie en daarna bij de onafhankelijke klachtenfunctionaris of de geschilleninstantie. Je kunt ook overstappen naar een andere aanbieder; daar heb je geen toestemming voor nodig.$t$);

-- ---------------------------------------------------------------------------

select public.wegwijzer_seed_module(
  'zorg-thuis', 'huishoudelijke-hulp', 'Huishoudelijke hulp via de gemeente',
  'Schoonmaken, wassen, strijken en soms de boodschappen: dat loopt via de Wmo. Er wordt eerst gekeken naar wat huisgenoten en het netwerk zelf kunnen.',
  array[
    'Aanvragen bij de gemeente, met een melding en een keukentafelgesprek.',
    'Je betaalt de eigen bijdrage via het CAK, in 2026 een vast maandbedrag.',
    'De gemeente kijkt eerst naar gebruikelijke hulp door huisgenoten.',
    'Ook hier kun je kiezen voor een pgb in plaats van hulp in natura.'
  ],
  array['Wmo 2015, artikel 2.3.5'],
  array['huishoudelijke hulp', 'schoonmaakhulp', 'poetshulp', 'thuishulp', 'wmo hulp', 'huishouden', 'strijken', 'boodschappen'],
  4, 2, false
);

select public.wegwijzer_seed_sectie('huishoudelijke-hulp', 1, 'uitleg', 'Hoe de gemeente kijkt', $t$De gemeente onderzoekt eerst of het huishouden op een andere manier opgelost kan worden: door een huisgenoot, door het netwerk, met hulpmiddelen of met een algemene voorziening zoals een boodschappendienst of maaltijdservice.

Blijft er een gat over, dan volgt een maatwerkvoorziening: een aantal uren huishoudelijke ondersteuning per week. Steeds vaker wordt niet in uren maar in resultaten geïndiceerd ("een schoon en leefbaar huis").$t$);

select public.wegwijzer_seed_sectie('huishoudelijke-hulp', 2, 'letop', 'Gebruikelijke hulp van huisgenoten', $t$Woont er een gezonde volwassene in huis, dan verwacht de gemeente in principe dat die het huishouden doet. Dat heet gebruikelijke hulp.

Er zijn uitzonderingen: als die huisgenoot zelf overbelast is, fulltime werkt in combinatie met zware zorgtaken, of zelf beperkingen heeft. Onderbouw dat, liefst met een verklaring van de huisarts. Overbelasting is een erkende grond, maar je moet hem wel aandragen.$t$);

select public.wegwijzer_seed_sectie('huishoudelijke-hulp', 3, 'vraag', 'Kan ik zelf iemand kiezen', $t$Ja, met een pgb kun je zelf een schoonmaker of een bekende inhuren, tegen een tarief dat de gemeente vaststelt. Je sluit dan een zorgovereenkomst via de SVB.

In natura kies je uit de aanbieders waarmee de gemeente een contract heeft. Klikt het niet met een medewerker, dan kun je vragen om iemand anders.$t$);

-- ---------------------------------------------------------------------------

select public.wegwijzer_seed_module(
  'zorg-thuis', 'dagbesteding', 'Dagbesteding en ontmoeting',
  'Een of meer dagen per week een zinvolle plek buitenshuis. Voor de ander structuur en contact, voor jou een paar uur adem, elke week opnieuw.',
  array[
    'Dagbesteding loopt via de Wmo, of via de Wlz als er een indicatie is.',
    'Vervoer van en naar de dagbesteding zit er meestal bij.',
    'Er is meer keuze dan je denkt: zorgboerderij, ontmoetingscentrum, dagclub, hobbywerkplaats.',
    'Een gewenningsperiode van enkele weken is normaal; geef het even de tijd.'
  ],
  array['Wmo 2015, artikel 2.3.5', 'Wet langdurige zorg'],
  array['dagbesteding', 'dagopvang', 'zorgboerderij', 'ontmoetingscentrum', 'dagclub', 'activiteiten', 'even weg', 'structuur overdag'],
  4, 3, false
);

select public.wegwijzer_seed_sectie('dagbesteding', 1, 'uitleg', 'Waarom het meer is dan bezigheid', $t$Dagbesteding geeft ritme en contact, en dat vertraagt vaak de achteruitgang. Voor jou is het minstens zo belangrijk: twee dagdelen per week vrij maakt het verschil tussen volhouden en instorten.

Vraag het aan vóórdat het echt nodig is. Wennen gaat makkelijker als iemand er nog zelf iets van kan vinden.$t$);

select public.wegwijzer_seed_sectie('dagbesteding', 2, 'stappen', 'Zo vind je een passende plek', $t$Meld je bij het Wmo-loket, of vraag de casemanager om suggesties.
Vraag welke vormen er in de gemeente zijn; er is vaak meer dan de standaard dagopvang.
Ga eerst samen een keer kijken, zonder verplichting.
Let op de sfeer en de groep: past het bij wie iemand is en was.
Begin met één dagdeel en bouw op.
Regel het vervoer meteen mee; dat zit meestal in de voorziening.$t$);

select public.wegwijzer_seed_sectie('dagbesteding', 3, 'letop', '"Ik ga daar niet heen"', $t$Bijna iedereen zegt dat de eerste keer. Wat helpt: noem het geen dagopvang maar bijvoorbeeld "de club" of "de werkplaats", ga de eerste keren mee, en kies iets dat aansluit bij een oud beroep of een hobby.

Reken op drie tot vijf keer voordat je weet of het wat wordt. Werkt het na een paar weken echt niet, vraag dan om een andere plek in plaats van te stoppen.$t$);

-- ---------------------------------------------------------------------------

select public.wegwijzer_seed_module(
  'zorg-thuis', 'respijtzorg', 'Respijtzorg: de zorg tijdelijk overdragen',
  'Even helemaal vrij zijn van de zorg: een weekend, een week, of elke woensdag. Het kan thuis of buitenshuis, en er zijn vier verschillende geldpotjes voor.',
  array[
    'Respijtzorg kan via de Wmo, de Wlz, de aanvullende zorgverzekering of vrijwilligers.',
    'Vormen: iemand komt thuis, logeeropvang, dagbesteding of een zorghotel.',
    'Vraag het aan vóór je op is; wachttijden zijn er, en op vakantieperiodes is het druk.',
    'Bij de Wmo betaal je de gewone eigen bijdrage, bij vrijwilligersorganisaties vaak niets.'
  ],
  array['Wmo 2015, artikel 2.3.5', 'Wet langdurige zorg, artikel 3.1.1'],
  array['respijtzorg', 'vervangende zorg', 'logeeropvang', 'even vrij', 'vakantie', 'weekend weg', 'zorghotel', 'kortdurend verblijf', 'oppas', 'overnemen zorg'],
  6, 4, true
);

select public.wegwijzer_seed_sectie('respijtzorg', 1, 'uitleg', 'De vormen op een rij', $t$Thuis: een vrijwilliger of beroepskracht komt bij de zorgvrager, van een paar uur per week tot 24 uur per dag gedurende een vakantie.

Buitenshuis: logeeropvang in een zorginstelling, een logeerhuis, een zorgboerderij of een zorghotel, van een weekend tot enkele weken.

Structureel: dagbesteding of nachtopvang, elke week op vaste momenten. Dat is vaak duurzamer dan één keer per jaar een week weg.$t$);

select public.wegwijzer_seed_sectie('respijtzorg', 2, 'uitleg', 'Waar het uit betaald wordt', $t$Via de Wmo: de gemeente kan kortdurend verblijf of vervangende zorg toekennen. Je betaalt dan de gewone eigen bijdrage.

Via de Wlz: heeft de zorgvrager een Wlz-indicatie met zorg thuis, dan kan logeeropvang daaruit betaald worden.

Via de aanvullende zorgverzekering: veel polissen vergoeden een aantal dagen respijtzorg per jaar. Dit staat in de polisvoorwaarden onder mantelzorg of vervangende zorg.

Via vrijwilligersorganisaties: er zijn landelijke organisaties die vrijwilligers thuis laten logeren zodat jij weg kunt, vaak tegen een kleine vergoeding.$t$);

select public.wegwijzer_seed_sectie('respijtzorg', 3, 'stappen', 'Zo regel je het op tijd', $t$Kijk eerst in je aanvullende polis onder "mantelzorg" of "vervangende zorg"; dat is de snelste route.
Meld tegelijk bij de gemeente dat je respijtzorg nodig hebt en vraag om een maatwerkvoorziening.
Vraag de casemanager of wijkverpleegkundige welke logeerplekken er in de regio zijn.
Boek vakantieperiodes maanden vooruit; die zijn het eerst vol.
Bouw het op: eerst een middag, dan een nacht, dan een weekend. Dat maakt het voor iedereen makkelijker.$t$);

select public.wegwijzer_seed_sectie('respijtzorg', 4, 'letop', 'Het schuldgevoel is normaal, en geen reden om het niet te doen', $t$Bijna iedereen stelt respijtzorg uit met het argument dat het "nog wel gaat" of dat de ander het niet fijn vindt. Ondertussen loopt de rek eruit.

Zie het als onderhoud, niet als luxe. De zorg die jij geeft is alleen houdbaar als jij er ook af en toe uit bent.$t$);

select public.wegwijzer_seed_link('respijtzorg', 1, 'Regelhulp: vervangende zorg', 'https://www.regelhulp.nl/mantelzorgers/ondersteuning-en-advies/vervangende-zorg');
select public.wegwijzer_seed_link('respijtzorg', 2, 'MantelzorgNL: respijtzorg vinden', 'https://www.mantelzorg.nl');

-- ---------------------------------------------------------------------------

select public.wegwijzer_seed_module(
  'zorg-thuis', 'hulpmiddelen-en-vervoer', 'Hulpmiddelen, vervoer en alarmering',
  'Rollator, rolstoel, tillift, personenalarmering, regiotaxi en de gehandicaptenparkeerkaart: welk loket hoort bij welk hulpmiddel.',
  array[
    'Kortdurend lenen (tot ongeveer 26 weken) gaat via de zorgverzekering.',
    'Blijvend nodig en gericht op zelfredzaamheid thuis: via de Wmo.',
    'Woont iemand in een instelling met Wlz-zorg, dan levert de instelling de hulpmiddelen.',
    'De gehandicaptenparkeerkaart vraag je aan bij de gemeente, met een medische keuring.'
  ],
  array['Zorgverzekeringswet', 'Wmo 2015, artikel 2.3.5', 'Regeling gehandicaptenparkeerkaart'],
  array['hulpmiddelen', 'rolstoel', 'rollator', 'scootmobiel', 'tillift', 'hoog-laagbed', 'personenalarmering', 'alarmknop', 'regiotaxi', 'valys', 'gehandicaptenparkeerkaart', 'vervoer', 'taxi'],
  6, 5, false
);

select public.wegwijzer_seed_sectie('hulpmiddelen-en-vervoer', 1, 'uitleg', 'Welk loket voor welk hulpmiddel', $t$Kortdurend nodig, bijvoorbeeld na een operatie: leen het bij de thuiszorgwinkel. Dat loopt via de zorgverzekering, meestal tot ongeveer 26 weken en zonder kosten.

Blijvend nodig en bedoeld om thuis zelfredzaam te blijven, zoals een rolstoel, een scootmobiel of een traplift: via de Wmo bij de gemeente.

Medische hulpmiddelen zoals een hoog-laagbed, een tillift of een antidecubitusmatras bij verpleging thuis: vaak via de zorgverzekering, in overleg met de wijkverpleegkundige.

Woont iemand in een Wlz-instelling, dan regelt en betaalt de instelling het.$t$);

select public.wegwijzer_seed_sectie('hulpmiddelen-en-vervoer', 2, 'uitleg', 'Vervoer', $t$Voor korte ritten in de eigen regio, naar de winkel, de familie of de dagbesteding, is er het Wmo-vervoer: regiotaxi of collectief vervoer tegen een laag tarief per rit. Aanvragen bij de gemeente.

Voor langere reizen door het land bestaat Valys, met een persoonlijk kilometerbudget per jaar. Je komt daarvoor in aanmerking met bijvoorbeeld een Wmo-vervoerspas of een gehandicaptenparkeerkaart.

Naar een medische behandeling kan zittend ziekenvervoer vergoed worden vanuit de basisverzekering, maar alleen in specifieke situaties, bijvoorbeeld bij nierdialyse of oncologische behandelingen. Vraag het na bij de verzekeraar; er geldt wel eigen risico.$t$);

select public.wegwijzer_seed_sectie('hulpmiddelen-en-vervoer', 3, 'stappen', 'De gehandicaptenparkeerkaart', $t$Vraag hem aan bij de gemeente waar de zorgvrager woont.
Er volgt vrijwel altijd een medische keuring door een onafhankelijke arts.
Er zijn drie soorten: bestuurder, passagier en instelling. Kies bewust; als jij rijdt, is het de passagierskaart.
De kaart is persoonsgebonden en geldt in heel Europa.
Vraag de gemeente ook naar een eigen parkeerplaats bij de woning; dat is een aparte aanvraag.$t$);

select public.wegwijzer_seed_sectie('hulpmiddelen-en-vervoer', 4, 'uitleg', 'Alarmering en veiligheid thuis', $t$Personenalarmering, een halsknop of polsband waarmee iemand hulp kan roepen, is soms een Wmo-voorziening, soms vergoed uit de aanvullende verzekering, en soms iets wat je zelf betaalt. Vraag het bij beide na.

Denk ook aan praktische dingen die niets kosten: een sleutelkluis bij de voordeur zodat de thuiszorg en de ambulance binnen kunnen, goede verlichting op de route naar het toilet, losse kleedjes weg, en een lijstje met telefoonnummers naast de telefoon.$t$);

-- ===========================================================================
-- THEMA: zorgen voor jezelf
-- ===========================================================================

select public.wegwijzer_seed_module(
  'jezelf', 'overbelasting', 'Overbelasting herkennen, bij jezelf',
  'Je merkt het meestal als laatste. De signalen, de vraag die je jezelf eerlijk moet stellen, en wat je kunt doen voordat het misgaat.',
  array[
    'Slecht slapen, kort lont, alles alleen willen doen en niets meer leuk vinden zijn signalen.',
    'De gemeente moet bij het onderzoek ook naar jouw belasting kijken; zeg het expliciet.',
    'Bespreek het met je huisarts; overbelasting is een gezondheidsprobleem.',
    'Kleine, structurele ontlasting werkt beter dan één keer per jaar een week vrij.'
  ],
  array['Wmo 2015, artikel 2.3.2 lid 4'],
  array['overbelasting', 'overbelast', 'op', 'burn-out', 'moe', 'niet meer volhouden', 'schuldgevoel', 'hulp voor mezelf', 'te zwaar', 'stress'],
  5, 1, true
);

select public.wegwijzer_seed_sectie('overbelasting', 1, 'uitleg', 'De signalen', $t$Slecht slapen of piekeren 's nachts. Een korter lont dan je van jezelf kent. Lichamelijke klachten: hoofdpijn, rugpijn, een steeds terugkerende verkoudheid. Geen zin meer in dingen die je altijd leuk vond. Afspraken met vrienden afzeggen. Het gevoel dat niemand het zo goed kan als jij, en tegelijk dat je het niet meer trekt.

En het meest verraderlijke: het idee dat je geen recht hebt om moe te zijn, omdat de ander het zwaarder heeft.$t$);

select public.wegwijzer_seed_sectie('overbelasting', 2, 'vraag', 'Drie vragen om jezelf eerlijk te stellen', $t$Wanneer had ik voor het laatst een dag waarop ik nergens aan hoefde te denken?

Wie neemt het over als ik morgen twee weken plat lig? Is dat geregeld, of hoop ik dat het niet gebeurt?

Zou ik een vriendin die dit vertelde aanraden om zo door te gaan?

Blijf je bij die laatste vraag hangen, dan is dit het moment om iets te veranderen, niet over drie maanden.$t$);

select public.wegwijzer_seed_sectie('overbelasting', 3, 'stappen', 'Wat je nu kunt doen', $t$Maak een afspraak bij je huisarts en vertel dat je overbelast bent. Vraag naar de praktijkondersteuner.
Meld bij de gemeente dat je als beheerder ondersteuning nodig hebt; dat is een eigen recht, los van de zorgvrager.
Zet één vaste ontlasting in de week vast: dagbesteding, een buddy uit de kring, een vrijwilliger.
Vraag respijtzorg aan, ook als je nu nog denkt dat het niet nodig is.
Verdeel taken in de kring: niet alles hoeft door jou.
Zoek contact met anderen in dezelfde situatie, via het steunpunt of een Alzheimer Café.$t$);

select public.wegwijzer_seed_sectie('overbelasting', 4, 'wet', 'De gemeente moet ook naar jou kijken', $t$In de Wmo staat dat de gemeente bij het onderzoek de behoeften en de mogelijkheden van degene die de zorg geeft moet betrekken. Dat betekent: jouw belasting hoort onderdeel te zijn van het gesprek.

In de praktijk gebeurt dat alleen als je het zelf op tafel legt. Zeg letterlijk: "ik wil dat mijn eigen belasting in het verslag komt", en controleer of het erin staat.$t$);

-- ---------------------------------------------------------------------------

select public.wegwijzer_seed_module(
  'jezelf', 'mantelzorgmakelaar', 'De hulpmakelaar: iemand die het regelwerk overneemt',
  'Een mantelzorgmakelaar neemt de administratie en het uitzoekwerk van je over: aanvragen, bezwaren, verzekeringen en het schakelen tussen instanties. Vaak vergoed uit de aanvullende verzekering.',
  array[
    'Hij regelt, jij zorgt: aanvragen, formulieren, bezwaar, en bellen met instanties.',
    'Veel aanvullende zorgverzekeringen vergoeden een aantal uren per jaar.',
    'Let erop dat hij is aangesloten bij de beroepsvereniging BMZM.',
    'In deze app kun je rechtstreeks een hulpmakelaar aanspreken via Steun.'
  ],
  array['Zorgverzekeringswet, aanvullende verzekering'],
  array['mantelzorgmakelaar', 'hulpmakelaar', 'makelaar', 'regelhulp', 'papierwerk', 'administratie', 'iemand die het regelt', 'vergoeding verzekering', 'bmzm'],
  4, 2, true
);

select public.wegwijzer_seed_sectie('mantelzorgmakelaar', 1, 'uitleg', 'Wat hij voor je doet', $t$Een hulpmakelaar kent de wetten, de loketten en de formulieren. Hij zoekt uit welke regeling past, vraagt hem aan, voert het gesprek met de gemeente, dient bezwaar in, regelt de aanvullende verzekering en zorgt dat instanties met elkaar praten.

Het doel is simpel: jij houdt tijd en energie over voor de zorg zelf, in plaats van voor de bureaucratie eromheen.$t$);

select public.wegwijzer_seed_sectie('mantelzorgmakelaar', 2, 'uitleg', 'Wat het kost', $t$Veel aanvullende zorgverzekeringen vergoeden een aantal uren mantelzorgmakelaar per jaar. Hoeveel uren en welk bedrag verschilt sterk per verzekeraar en per pakket; kijk in je polisvoorwaarden onder "mantelzorg".

Voorwaarde is meestal dat de makelaar is aangesloten bij de beroepsvereniging BMZM. Sommige gemeenten en werkgevers bieden daarnaast zelf uren aan.$t$);

select public.wegwijzer_seed_sectie('mantelzorgmakelaar', 3, 'stappen', 'Zo begin je', $t$Kijk in je aanvullende polis onder "mantelzorg" of "mantelzorgmakelaar" hoeveel uur je hebt.
Vraag ook bij je gemeente en je werkgever of zij uren vergoeden.
In deze app: ga naar Steun en start een gesprek met een hulpmakelaar. Zet je vraag zo concreet mogelijk neer.
Verzamel vooraf de papieren: het besluit, de indicatie, de polis, de brieven.
Spreek af wie wat doet, zodat je niet dubbel werk doet.$t$);

select public.wegwijzer_seed_sectie('mantelzorgmakelaar', 4, 'voorbeeld', 'Waar zo iemand vaak het verschil maakt', $t$Een afgewezen Wmo-aanvraag, waarbij bezwaar binnen zes weken moet en niemand weet hoe.

Een pgb-administratie die vastloopt bij de SVB, waardoor de zorgverlener niet betaald krijgt.

Een situatie waarin drie loketten naar elkaar wijzen: gemeente, zorgkantoor en verzekeraar. Iemand die alle drie kent, doorbreekt dat in één telefoontje.$t$);

-- ---------------------------------------------------------------------------

select public.wegwijzer_seed_module(
  'jezelf', 'steunpunt-en-lotgenoten', 'Steunpunt mantelzorg en lotgenotencontact',
  'In vrijwel elke gemeente zit een steunpunt met gratis ondersteuning, cursussen en een luisterend oor. Daarnaast helpt contact met mensen die precies weten hoe het is.',
  array[
    'Het steunpunt is gratis en je hebt er geen indicatie voor nodig.',
    'Ze regelen praktische zaken: vrijwilligers, cursussen, een pas met kortingen.',
    'Alzheimer Cafés en lotgenotengroepen zijn vrij toegankelijk, ook zonder aanmelding.',
    'De Mantelzorglijn en de Alzheimer Telefoon zijn er als je gewoon even wilt praten.'
  ],
  array['Wmo 2015, artikel 2.1.2 lid 4'],
  array['steunpunt mantelzorg', 'lotgenoten', 'alzheimer cafe', 'praten', 'mantelzorglijn', 'cursus', 'vrijwilliger', 'contact', 'hulp in de buurt'],
  4, 3, false
);

select public.wegwijzer_seed_sectie('steunpunt-en-lotgenoten', 1, 'uitleg', 'Wat een steunpunt doet', $t$Elk steunpunt is anders, maar meestal vind je er: een vast contactpersoon die met je meedenkt, hulp bij formulieren, cursussen (omgaan met dementie, grenzen stellen, tillen), inzet van vrijwilligers die af en toe komen, en informatie over de regelingen van jouw gemeente.

Het is gratis en je hoeft er niets voor aan te vragen. Zoek op "steunpunt mantelzorg" plus de naam van je gemeente, of vraag ernaar bij het Wmo-loket.$t$);

select public.wegwijzer_seed_sectie('steunpunt-en-lotgenoten', 2, 'uitleg', 'Waarom lotgenoten helpen', $t$Bij vrienden en familie moet je uitleggen. Bij mensen in dezelfde situatie niet. Dat scheelt energie, en je hoort praktische dingen die in geen enkele folder staan.

Alzheimer Cafés zijn maandelijkse bijeenkomsten, vrij toegankelijk, met een thema en tijd om te praten. Daarnaast zijn er gespreksgroepen, online communities en, in deze app, het forum waar je je vraag anoniem kunt stellen.$t$);

select public.wegwijzer_seed_sectie('steunpunt-en-lotgenoten', 3, 'stappen', 'Waar je terecht kunt', $t$Steunpunt mantelzorg van je gemeente: gratis ondersteuning en cursussen.
De Mantelzorglijn van MantelzorgNL: voor vragen en een luisterend oor.
De Alzheimer Telefoon: dag en nacht bereikbaar, ook voor naasten.
Het Alzheimer Café in je regio: maandelijks, vrij binnenlopen.
In deze app: het forum bij Steun, en een gesprek met een hulpmakelaar.$t$);

select public.wegwijzer_seed_link('steunpunt-en-lotgenoten', 1, 'MantelzorgNL en de Mantelzorglijn', 'https://www.mantelzorg.nl');
select public.wegwijzer_seed_link('steunpunt-en-lotgenoten', 2, 'Alzheimer Café bij jou in de buurt', 'https://www.alzheimer-nederland.nl/regios');

-- ---------------------------------------------------------------------------

select public.wegwijzer_seed_module(
  'jezelf', 'als-de-zorg-stopt', 'Als de zorg stopt',
  'Bij een verhuizing naar het verpleeghuis of na een overlijden valt er van alles weg, praktisch en persoonlijk. Wat er geregeld moet worden, en wat er met jou gebeurt.',
  array[
    'Zeg lopende zorg, voorzieningen en een pgb tijdig op; anders volgt terugvordering.',
    'Woon je in de huurwoning van de overledene zonder medehuur, dan heb je zes maanden.',
    'De leegte na jaren zorgen is een bekend en normaal verschijnsel.',
    'Steunpunten en rouwbegeleiding zijn er ook voor jou, ook maanden later nog.'
  ],
  array['Burgerlijk Wetboek 7, artikel 268'],
  array['overlijden', 'rouw', 'na het overlijden', 'zorg stopt', 'verpleeghuis opname', 'nabestaanden', 'uitvaart', 'leegte', 'afscheid', 'opzeggen zorg'],
  6, 4, false
);

select public.wegwijzer_seed_sectie('als-de-zorg-stopt', 1, 'stappen', 'Praktisch: wat er opgezegd moet worden', $t$Meld het overlijden of de opname bij de gemeente, het CAK, de zorgverzekeraar en het zorgkantoor.
Zeg de wijkverpleging, huishoudelijke hulp, dagbesteding en het vervoer op.
Loopt er een pgb, meld dat dan direct bij de SVB en het verstrekkende loket; onterecht doorlopende betalingen worden teruggevorderd.
Lever hulpmiddelen in of meld dat ze opgehaald kunnen worden.
Zeg abonnementen, alarmering en maaltijdservice op.
Bij een huurwoning: informeer de verhuurder over de situatie.$t$);

select public.wegwijzer_seed_sectie('als-de-zorg-stopt', 2, 'letop', 'Als je in de woning van de overledene woont', $t$Ben je geen medehuurder, dan mag je de huur nog zes maanden voortzetten. Binnen die periode kun je de rechter vragen om de huur te mogen voortzetten.

Wacht daar niet mee tot de laatste weken. Zie het onderwerp over medehuur voor wat je nodig hebt aan bewijs.$t$);

select public.wegwijzer_seed_sectie('als-de-zorg-stopt', 3, 'uitleg', 'De leegte die erna komt', $t$Jarenlang draaide je dagen om iemand anders. Als dat wegvalt, verdwijnt niet alleen de zorg maar ook de structuur, het doel en vaak een deel van je contacten. Veel mensen zijn verbaasd hoe zwaar dat is, en schamen zich soms voor de opluchting die er óók is.

Beide kloppen. Opluchting is geen verraad, en verdriet gaat niet over in weken. Geef het tijd, en verwacht van jezelf niet dat je meteen weer "de oude" bent.$t$);

select public.wegwijzer_seed_sectie('als-de-zorg-stopt', 4, 'stappen', 'Waar je terecht kunt', $t$Je huisarts: ook maanden later nog, voor een gesprek of een verwijzing.
Het steunpunt mantelzorg: veel steunpunten hebben nazorg voor wie klaar is met zorgen.
Rouwgroepen en lotgenotengroepen, in de buurt of online.
Slachtofferhulp of een geestelijk verzorger, ook zonder geloofsachtergrond.
De kring in deze app: laat mensen weten dat het klaar is; de meesten willen graag nog iets voor jou doen.$t$);

-- ---------------------------------------------------------------------------
-- Hulpfuncties voor het vullen weer opruimen.
-- ---------------------------------------------------------------------------
drop function if exists public.wegwijzer_seed_module(text, text, text, text, text[], text[], text[], integer, integer, boolean);
drop function if exists public.wegwijzer_seed_sectie(text, integer, text, text, text);
drop function if exists public.wegwijzer_seed_link(text, integer, text, text);

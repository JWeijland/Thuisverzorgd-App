-- Wegwijzer: dertien nieuwe onderwerpen, verdeeld over de bestaande thema's.
-- Onderwerpen die mantelzorgers veel zoeken maar die nog ontbraken: palliatieve
-- zorg, ziekenhuisontslag, medicijnen, GGZ, 18 worden, toeslagen, de
-- aanvullende verzekering, minimaregelingen, woonvormen, rijbewijs bij
-- dementie, technologie thuis, financieel misbruik en jonge mantelzorgers.
-- Alle links zijn op 5/6 augustus 2026 gecontroleerd.
-- Ruimt aan het eind de seed-hulpfuncties weer op.

-- ===========================================================================
-- THEMA: hoe zit het zorgstelsel in elkaar
-- ===========================================================================

select public.wegwijzer_seed_module(
  'basis', 'ggz-naasten', 'Zorgen voor iemand met psychische problemen',
  'Ook wie zorgt voor een partner of kind met een psychische aandoening is mantelzorger. Hoe de ggz werkt, wat je bij een crisis doet en welke rechten familie heeft.',
  array[
    'De weg naar de ggz loopt via de huisarts; reken helaas op wachttijden.',
    'Bij een crisis bel je de huisarts of huisartsenpost; bij direct gevaar 112.',
    'Verplichte zorg kan alleen via de rechter of de burgemeester (Wvggz), en familie heeft daarin een stem.',
    'De familievertrouwenspersoon is er gratis voor jou, niet voor de patiënt.'
  ],
  array['Wet verplichte geestelijke gezondheidszorg', 'Zorgverzekeringswet'],
  array['ggz', 'psychisch', 'psychiatrie', 'depressie', 'psychose', 'verward gedrag', 'crisis', 'crisisdienst', 'gedwongen opname', 'wvggz', 'familievertrouwenspersoon', 'naasten ggz'],
  6, 6, false
);

select public.wegwijzer_seed_sectie('ggz-naasten', 1, 'uitleg', 'Hoe de ggz georganiseerd is', $t$Psychische zorg begint bij de huisarts en de praktijkondersteuner ggz. Voor zwaardere zorg verwijst de huisarts naar een psycholoog of een ggz-instelling; dat valt onder de basisverzekering, met eigen risico. Wachttijden zijn vaak lang: vraag om overbrugging bij de praktijkondersteuner en meld je bij meerdere aanbieders tegelijk.

Als naaste sta je er vaak naast: je ziet dat het misgaat, maar de zorg draait om de patiënt. Vraag de behandelaar expliciet om een familiegesprek. Veel instellingen hebben naastenbeleid en een aparte contactpersoon voor familie.$t$);

select public.wegwijzer_seed_sectie('ggz-naasten', 2, 'stappen', 'Wat je doet bij een crisis', $t$Bel overdag de eigen huisarts, 's avonds en in het weekend de huisartsenpost; zij kunnen de crisisdienst inschakelen.
Is er direct gevaar voor de persoon zelf of anderen, bel dan 112.
Blijf zo rustig mogelijk, houd afstand van een discussie en haal prikkels weg.
Noteer na afloop wat er gebeurde; dat helpt bij de beoordeling en een eventuele zorgmachtiging.
Maak je je langer zorgen over iemand die zorg weigert, dan kun je dat melden bij de gemeente; die moet je melding laten onderzoeken.$t$);

select public.wegwijzer_seed_sectie('ggz-naasten', 3, 'wet', 'Verplichte zorg en jouw stem als familie', $t$Sinds 2020 regelt de Wet verplichte geestelijke gezondheidszorg wanneer iemand tegen zijn wil behandeld mag worden. Dat kan alleen via een zorgmachtiging van de rechter, of in acute situaties via een crisismaatregel van de burgemeester. De burgemeester moet de betrokkene zo mogelijk horen, en ook familie kan haar zorgen kenbaar maken.

Voor jou als naaste is er de familievertrouwenspersoon: gratis, onafhankelijk, en er speciaal voor familie en naasten. Die helpt je de weg te vinden, gesprekken voor te bereiden en je verhaal kwijt te kunnen.$t$);

select public.wegwijzer_seed_link('ggz-naasten', 1, 'Familievertrouwenspersonen: gratis steun voor naasten', 'https://www.familievertrouwenspersonen.nl');
select public.wegwijzer_seed_link('ggz-naasten', 2, 'MIND: informatie en lotgenoten', 'https://mindplatform.nl');
select public.wegwijzer_seed_link('ggz-naasten', 3, 'Regelhulp: ondersteuning voor mantelzorgers', 'https://www.regelhulp.nl/mantelzorgers/ondersteuning-en-advies');

-- ---------------------------------------------------------------------------

select public.wegwijzer_seed_module(
  'basis', 'kind-wordt-18', 'Je zorgkind wordt 18',
  'Op de achttiende verjaardag stopt de Jeugdwet en verandert er in één klap veel: zorg, geld en zeggenschap. Wat je vanaf zestien of zeventien alvast regelt.',
  array[
    'De Jeugdwet stopt op de 18e verjaardag; zorg loopt daarna via Wmo, zorgverzekering of Wlz.',
    'Kinderbijslag en dubbele kinderbijslag stoppen; kijk naar Wajong of studietoeslag.',
    'Vanaf 18 beslist je kind juridisch zelf; regel op tijd een volmacht, bewind of mentorschap.',
    'Begin een jaar van tevoren; aanvragen bij UWV en de rechtbank kunnen vóór de verjaardag.'
  ],
  array['Jeugdwet', 'Wet langdurige zorg', 'Participatiewet'],
  array['18 worden', 'achttien', 'jeugdwet stopt', 'volwassen worden', 'wajong', 'studietoeslag', 'zorgkind', 'gehandicapt kind volwassen', 'overgang jeugdzorg'],
  6, 7, false
);

select public.wegwijzer_seed_sectie('kind-wordt-18', 1, 'uitleg', 'Wat er op de verjaardag verandert', $t$De hulp die via de Jeugdwet liep (begeleiding, dagbesteding, logeeropvang) moet opnieuw geregeld worden: bij de gemeente via de Wmo, bij de zorgverzekeraar, of via een Wlz-indicatie als er blijvend intensieve zorg nodig is.

Je kind moet vanaf 18 een eigen zorgverzekering hebben en betaalt premie en eigen risico. En juridisch beslist je kind vanaf dat moment zelf, ook als het dat niet kan overzien. Zonder regeling mag jij formeel niets meer: geen dossier inzien, geen contract tekenen, geen bankzaken doen.$t$);

select public.wegwijzer_seed_sectie('kind-wordt-18', 2, 'stappen', 'De checklist vanaf zestien, zeventien', $t$Bespreek met de gemeente of de huidige hulp na de 18e via de Wmo doorloopt, of vraag bij blijvende zware zorg een Wlz-indicatie aan bij het CIZ.
Kan je kind niet zelf beslissen, vraag dan bewind of mentorschap aan bij de kantonrechter; dat kan vóór de verjaardag, met ingang van de 18e.
Kan je kind duurzaam niet werken, vraag dan Wajong aan bij het UWV; dat kan vanaf 17,5 jaar.
Studeert je kind met een beperking, kijk dan naar de individuele studietoeslag van DUO of de gemeente.
Regel een zorgverzekering, DigiD en een eigen bankrekening.
Zet de veranderingen in geld op een rij: kinderbijslag stopt, toeslagen en eigen bijdragen beginnen.$t$);

select public.wegwijzer_seed_sectie('kind-wordt-18', 3, 'letop', 'Regel de vertegenwoordiging vóór de verjaardag', $t$Dit is de meest gemaakte fout: wachten tot na de 18e. Dan is er ineens niemand die formeel mag beslissen, terwijl de zorg gewoon doorloopt. De aanvraag bij de kantonrechter kan maanden duren.

Kies bewust wat past: mentorschap voor zorgbeslissingen, bewind voor geld, of allebei. Kan je kind zelf goed genoeg overzien wat een volmacht is, dan is dat de lichtste route.$t$);

select public.wegwijzer_seed_link('kind-wordt-18', 1, 'Rechtspraak.nl: bewind aanvragen', 'https://www.rechtspraak.nl/onderwerpen/bewind');
select public.wegwijzer_seed_link('kind-wordt-18', 2, 'UWV: Wajong aanvragen', 'https://www.uwv.nl/particulieren');
select public.wegwijzer_seed_link('kind-wordt-18', 3, 'SVB: wanneer de kinderbijslag stopt', 'https://www.svb.nl/nl/kinderbijslag');
select public.wegwijzer_seed_link('kind-wordt-18', 4, 'Goedvertegenwoordigd.nl', 'https://goedvertegenwoordigd.nl');

-- ===========================================================================
-- THEMA: geld en regelingen
-- ===========================================================================

select public.wegwijzer_seed_module(
  'financien', 'toeslagen', 'Zorgtoeslag, huurtoeslag en de proefberekening',
  'Toeslagen zijn een recht, geen gunst, maar ze luisteren nauw: wie meetelt in je huishouden bepaalt wat je krijgt. Reken elke verandering vooraf door.',
  array[
    'Zorgtoeslag kijkt alleen naar jou en je toeslagpartner; huurtoeslag ook naar medebewoners.',
    'Inwonen, verhuizen of een pgb-inkomen kan je toeslagen veranderen; reken het vooraf door.',
    'Geef wijzigingen meteen door; terugvorderingen zijn het grootste toeslagenleed.',
    'Met de proefberekening van de Belastingdienst zie je binnen vijf minuten waar je staat.'
  ],
  array['Algemene wet inkomensafhankelijke regelingen'],
  array['toeslagen', 'zorgtoeslag', 'huurtoeslag', 'toeslagpartner', 'proefberekening', 'toeslag aanvragen', 'terugbetalen toeslag', 'recht op toeslag'],
  5, 8, false
);

select public.wegwijzer_seed_sectie('toeslagen', 1, 'uitleg', 'Hoe de toeslagen in elkaar zitten', $t$Zorgtoeslag is een bijdrage in de premie van de zorgverzekering en hangt af van het inkomen van jou en je eventuele toeslagpartner. Huurtoeslag hangt daarnaast af van de huurprijs én van het inkomen van iedereen die op het adres woont.

Daarom raakt inwonen om te zorgen vooral de huurtoeslag: een inwonend familielid telt als medebewoner mee, ook zonder dat jullie partners zijn. Voor de zorgtoeslag verandert er alleen iets als je toeslagpartners wordt, bijvoorbeeld door een notarieel samenlevingscontract.$t$);

select public.wegwijzer_seed_sectie('toeslagen', 2, 'stappen', 'Zo houd je het onder controle', $t$Doe de proefberekening op de site van de Belastingdienst vóór elke grote verandering: inwonen, verhuizen, minder werken, een pgb-vergoeding.
Vraag toeslagen aan via Mijn toeslagen; het kan met terugwerkende kracht tot 1 september van het volgende jaar.
Geef elke wijziging in inkomen of huishouden binnen vier weken door.
Zet een deel van een hoge toeslag apart als je inkomen wisselt; dan doet een naheffing geen pijn.
Kom je er niet uit, dan helpen het steunpunt mantelzorg, een toeslagenservicepunt of een hulpmakelaar gratis.$t$);

select public.wegwijzer_seed_sectie('toeslagen', 3, 'letop', 'Vergoedingen uit een pgb tellen mee', $t$Word je betaald uit het pgb van degene voor wie je zorgt, dan is dat inkomen. Het telt mee voor je toeslagen en kan ze verlagen of laten vervallen.

Een onkostenvergoeding of de mantelzorgwaardering van de gemeente telt juist níét mee. Houd het onderscheid scherp, en reken betaalde zorg altijd eerst door voordat je de zorgovereenkomst tekent.$t$);

select public.wegwijzer_seed_link('toeslagen', 1, 'Belastingdienst: toeslagen en proefberekening', 'https://www.belastingdienst.nl/wps/wcm/connect/nl/toeslagen/toeslagen');
select public.wegwijzer_seed_link('toeslagen', 2, 'Nibud: overzicht van regelingen', 'https://www.nibud.nl');

-- ---------------------------------------------------------------------------

select public.wegwijzer_seed_module(
  'financien', 'aanvullende-verzekering', 'De zorgverzekering slim kiezen als je zorgt',
  'De basisverzekering is voor iedereen gelijk, maar aanvullende pakketten verschillen enorm in wat ze voor mantelzorgers vergoeden. Eén avond vergelijken kan honderden euro''s schelen.',
  array[
    'Voor de basisverzekering geldt een acceptatieplicht; overstappen kan altijd, ongeacht gezondheid.',
    'Aanvullende pakketten vergoeden vaak mantelzorgmakelaar, vervangende zorg en cursussen.',
    'Opzeggen kan tot en met 31 december, een nieuwe kiezen tot en met 31 januari.',
    'Vergelijk óók de polis van de zorgvrager; daar zitten de meeste vergoedingen op.'
  ],
  array['Zorgverzekeringswet'],
  array['zorgverzekering', 'aanvullende verzekering', 'overstappen', 'vergoeding mantelzorg', 'polis', 'verzekeraar', 'premie', 'vergoeding respijtzorg'],
  5, 9, false
);

select public.wegwijzer_seed_sectie('aanvullende-verzekering', 1, 'uitleg', 'Waar je op let als mantelzorger', $t$Kijk in de aanvullende voorwaarden onder "mantelzorg" naar drie dingen: vergoeding van een mantelzorgmakelaar (vaak een aantal uren per jaar), vergoeding van vervangende zorg zodat jij weg kunt, en cursussen of ondersteuning voor mantelzorgers.

Let daarnaast op wat de zorgvrager zelf nodig heeft: fysiotherapie, tandarts, hulpmiddelen, personenalarmering, vervoer. De meeste van die vergoedingen zitten op de polis van degene die de zorg krijgt, niet op die van jou.$t$);

select public.wegwijzer_seed_sectie('aanvullende-verzekering', 2, 'stappen', 'Zo stap je over zonder gedoe', $t$Pak in november of december de huidige polis erbij en noteer wat jullie echt gebruikt hebben.
Vergelijk pakketten op de vergoedingen die jullie nodig hebben, niet op de premie alleen.
Zeg de oude verzekering uiterlijk 31 december op; met de overstapservice regelt de nieuwe verzekeraar dat meestal voor je.
Sluit de nieuwe af vóór 1 februari, met terugwerkende kracht tot 1 januari.
Let op: voor de basisverzekering geldt acceptatieplicht, maar een aanvullende verzekering mag een verzekeraar weigeren of met vragen omkleden. Stap dus niet over vóórdat de nieuwe aanvullende verzekering rond is.$t$);

select public.wegwijzer_seed_sectie('aanvullende-verzekering', 3, 'vraag', 'Is een restitutiepolis het waard', $t$Bij een naturapolis krijg je niet-gecontracteerde zorg maar deels vergoed; bij een restitutiepolis (of een polis met vrije zorgkeuze) meer of alles. Dat maakt uit als je een specifieke thuiszorgorganisatie of casemanager wilt die geen contract heeft met de verzekeraar.

Vraag het na vóór je kiest: welke aanbieders in de buurt zijn gecontracteerd, en wat vergoedt de polis als het jouw voorkeursaanbieder niet is.$t$);

select public.wegwijzer_seed_link('aanvullende-verzekering', 1, 'Rijksoverheid: hoe de zorgverzekering werkt', 'https://www.rijksoverheid.nl/themas/familie-zorg-en-gezondheid/zorgverzekering');
select public.wegwijzer_seed_link('aanvullende-verzekering', 2, 'MantelzorgNL: vergoedingen voor mantelzorgers', 'https://www.mantelzorg.nl');
select public.wegwijzer_seed_link('aanvullende-verzekering', 3, 'BMZM: vergoeding van de mantelzorgmakelaar', 'https://www.bmzm.nl');

-- ---------------------------------------------------------------------------

select public.wegwijzer_seed_module(
  'financien', 'bijzondere-bijstand', 'Bijzondere bijstand en minimaregelingen',
  'Voor noodzakelijke kosten die nergens anders vergoed worden, kent elke gemeente bijzondere bijstand en minimaregelingen. Ook met AOW of een bescheiden inkomen kun je er recht op hebben.',
  array[
    'Bijzondere bijstand is voor noodzakelijke, bijzondere kosten die je nergens vergoed krijgt.',
    'Denk aan bewindvoeringskosten, eigen bijdragen, reiskosten naar het ziekenhuis of een wasmachine.',
    'Vraag aan vóórdat je de kosten maakt; achteraf is de kans op afwijzing groot.',
    'Kijk ook naar de collectieve zorgverzekering voor minima en kwijtschelding van gemeentebelastingen.'
  ],
  array['Participatiewet, artikel 35'],
  array['bijzondere bijstand', 'minimaregelingen', 'laag inkomen', 'kwijtschelding', 'collectieve zorgverzekering', 'gemeentebelasting', 'geen geld', 'schulden', 'inkomenstoeslag'],
  5, 10, false
);

select public.wegwijzer_seed_sectie('bijzondere-bijstand', 1, 'uitleg', 'Wat eronder valt', $t$Bijzondere bijstand is maatwerk van de gemeente voor kosten die noodzakelijk zijn, uit bijzondere omstandigheden voortkomen en nergens anders vergoed worden. In de zorgpraktijk gaat het vaak om: de jaarlijkse beloning van een professionele bewindvoerder, eigen bijdragen, reiskosten voor ziekenbezoek, extra waskosten of het vervangen van een kapotte wasmachine of koelkast.

De inkomensgrens verschilt per gemeente; vaak ligt hij rond 110 tot 130 procent van de bijstandsnorm, en met een hoger inkomen kan een deel worden toegekend.$t$);

select public.wegwijzer_seed_sectie('bijzondere-bijstand', 2, 'stappen', 'Zo vraag je het aan', $t$Vraag de bijzondere bijstand aan vóórdat je de kosten maakt, via de site van de gemeente of het Wmo-loket.
Onderbouw waarom de kosten noodzakelijk zijn: een verklaring van arts, bewindvoerder of de indicatie helpt.
Bewaar offertes, bonnen en het besluit.
Vraag in hetzelfde gesprek naar de andere minimaregelingen: de collectieve zorgverzekering, kwijtschelding van gemeentelijke belastingen en waterschapsbelasting, de individuele inkomenstoeslag en een stadspas of participatieregeling.
Afgewezen? Bezwaar maken kan binnen zes weken, en een hulpmakelaar of het steunpunt helpt daar gratis bij.$t$);

select public.wegwijzer_seed_sectie('bijzondere-bijstand', 3, 'letop', 'Schaam je niet, en wacht niet te lang', $t$Veel mensen die er recht op hebben vragen niets aan, uit schaamte of omdat ze de regelingen niet kennen. Zonde: het is er precies voor situaties waarin zorgkosten zich opstapelen.

Loop je vast in schulden, trek dan vroeg aan de bel. Elke gemeente heeft gratis schuldhulpverlening, en hoe eerder je komt, hoe meer er mogelijk is.$t$);

select public.wegwijzer_seed_link('bijzondere-bijstand', 1, 'Rijksoverheid: regels rond de bijstand', 'https://www.rijksoverheid.nl/themas/belastingen-uitkeringen-en-toeslagen/bijstand/nieuwe-regels-bijstand-2026-en-2027');
select public.wegwijzer_seed_link('bijzondere-bijstand', 2, 'Nibud: rondkomen en regelingen', 'https://www.nibud.nl');
select public.wegwijzer_seed_link('bijzondere-bijstand', 3, 'Wettekst Participatiewet, artikel 35', 'https://wetten.overheid.nl/BWBR0015703');

-- ===========================================================================
-- THEMA: wonen en verbouwen
-- ===========================================================================

select public.wegwijzer_seed_module(
  'wonen', 'tussen-thuis-en-verpleeghuis', 'Woonvormen tussen thuis en het verpleeghuis',
  'Tussen zelfstandig thuis en het verpleeghuis zit veel: aanleunwoningen, serviceflats, hofjes en geclusterde woonvormen. Wie vroeg inschrijft, heeft later iets te kiezen.',
  array[
    'Een aanleunwoning of seniorenwoning is een gewone huurwoning: inschrijfduur telt, dus schrijf vroeg in.',
    'Zorg verhuist gewoon mee: wijkverpleging, Wmo-hulp of een Wlz-pakket kan in elke woonvorm.',
    'Geclusterd wonen met een gezamenlijke ruimte scheelt eenzaamheid en maakt zorg makkelijker te organiseren.',
    'Particuliere woonzorg is er ook, maar kent naast de zorg vaak forse woon- en servicekosten.'
  ],
  array['Huisvestingswet 2014', 'Wmo 2015'],
  array['aanleunwoning', 'serviceflat', 'seniorenwoning', 'hofje', 'geclusterd wonen', 'woonzorg', 'verzorgingshuis', 'zelfstandig wonen met zorg', 'knarrenhof', 'woonvormen ouderen'],
  5, 6, false
);

select public.wegwijzer_seed_sectie('tussen-thuis-en-verpleeghuis', 1, 'uitleg', 'De vormen op een rij', $t$Aanleunwoningen en seniorenwoningen zijn zelfstandige woningen dicht bij een zorglocatie, gelijkvloers en met alarmering in de buurt. Serviceflats voegen daar diensten aan toe: een receptie, maaltijden, een klusjesman, tegen servicekosten.

Hofjes en geclusterde woonvormen draaien om nabijheid: eigen voordeuren rond een gezamenlijke tuin of ontmoetingsruimte. En particuliere woonzorghuizen bieden wonen en zorg in één pakket, met een eigen prijs bovenop de vergoede zorg.

Het oude verzorgingshuis bestaat niet meer; wie blijvend 24 uur zorg nodig heeft, komt via een Wlz-indicatie in een verpleeghuis of kiest zorg thuis in een van deze vormen.$t$);

select public.wegwijzer_seed_sectie('tussen-thuis-en-verpleeghuis', 2, 'stappen', 'Zo kom je binnen', $t$Schrijf in bij de woningcorporaties in de regio, ook als verhuizen nog ver weg voelt; inschrijfduur is goud.
Vraag bij de corporatie naar seniorenlabels, aanleunwoningen en voorrang bij zorgbehoefte.
Kijk bij zorgorganisaties in de buurt welke locaties zelfstandige woningen verhuren.
Ga kijken: sfeer, buren en de afstand tot winkels zeggen meer dan een folder.
Check de kosten: kale huur, servicekosten en wat verplicht afgenomen moet worden.
Regel de zorg apart: die loopt gewoon via de wijkverpleging, de Wmo of het zorgkantoor.$t$);

select public.wegwijzer_seed_sectie('tussen-thuis-en-verpleeghuis', 3, 'vraag', 'Is het verstandig om te verhuizen vóór het echt moet', $t$Meestal wel. Wie verhuist terwijl het nog goed gaat, went makkelijker, bouwt een nieuw netwerk op en voorkomt een crisisverhuizing op het slechtste moment. Voor jou scheelt het reistijd en zorgen over trappen, drempels en alleen zijn.

Bespreek het op tijd, en betrek degene om wie het gaat bij elke stap; een woning die "voor de zorg" gekozen is maar niet voelt als thuis, houdt niemand vol.$t$);

select public.wegwijzer_seed_link('tussen-thuis-en-verpleeghuis', 1, 'Regelhulp: wonen met zorg', 'https://www.regelhulp.nl/onderwerpen/wonen');
select public.wegwijzer_seed_link('tussen-thuis-en-verpleeghuis', 2, 'Woonbond', 'https://www.woonbond.nl');
select public.wegwijzer_seed_link('tussen-thuis-en-verpleeghuis', 3, 'Zorgkaart Nederland: woonzorglocaties vergelijken', 'https://www.zorgkaartnederland.nl');

-- ===========================================================================
-- THEMA: dementie
-- ===========================================================================

select public.wegwijzer_seed_module(
  'dementie', 'rijbewijs-en-dementie', 'Rijbewijs en dementie',
  'Na de diagnose dementie mag iemand niet zomaar blijven rijden: het CBR moet opnieuw beoordelen of het nog veilig kan. Hoe die melding werkt en hoe je de auto bespreekbaar maakt.',
  array[
    'Na de diagnose moet een gezondheidsverklaring naar het CBR; het CBR beslist, niet de familie of de arts.',
    'Vaak volgt een rapport van een specialist en soms een rijtest; bij lichte dementie kan rijden tijdelijk nog mogen.',
    'Doorrijden zonder melding kan de verzekering in gevaar brengen bij een ongeluk.',
    'Regel alternatieven vóór het rijbewijs stopt: Wmo-vervoer, Valys en meerijden uit de kring.'
  ],
  array['Reglement rijbewijzen'],
  array['rijbewijs', 'autorijden', 'cbr', 'gezondheidsverklaring', 'rijtest', 'mag hij nog rijden', 'auto weg', 'rijden met dementie', 'keuring rijbewijs'],
  5, 6, false
);

select public.wegwijzer_seed_sectie('rijbewijs-en-dementie', 1, 'stappen', 'Zo werkt de melding bij het CBR', $t$Vul na de diagnose een gezondheidsverklaring in op de site van het CBR (met DigiD) of op papier.
Het CBR vraagt een rapport, meestal van een specialist of een onafhankelijk keurend arts.
Op basis daarvan beslist het CBR: doorrijden, doorrijden met beperkingen of een rijtest.
Bij een rijtest rijdt een deskundige van het CBR mee in de eigen omgeving.
Mag iemand blijven rijden, dan is dat meestal voor beperkte tijd; daarna volgt opnieuw een beoordeling.$t$);

select public.wegwijzer_seed_sectie('rijbewijs-en-dementie', 2, 'letop', 'Waarom niet melden geen optie is', $t$Rijdt iemand door zonder het CBR te informeren, dan rijdt hij formeel met een rijbewijs dat niet meer bij zijn gezondheid past. Bij een ongeluk kan de verzekeraar moeilijk doen over de dekking, en de bestuurder is strafbaar bezig als de rijgeschiktheid ontbreekt.

De huisarts of casemanager kan helpen het gesprek te voeren. Meld het als familie niet stiekem zelf; dat beschadigt het vertrouwen precies op het moment dat je elkaar nodig hebt. Probeer het eerst samen.$t$);

select public.wegwijzer_seed_sectie('rijbewijs-en-dementie', 3, 'uitleg', 'Als rijden niet meer gaat', $t$De auto staat voor vrijheid; het verlies ervan is voor veel mensen groter dan de diagnose zelf. Wat helpt: niet de sleutel afpakken maar alternatieven klaarzetten. De regiotaxi via de Wmo voor korte ritten, Valys voor langere afstanden, een OV-begeleiderskaart, en vaste afspraken met de kring wie wanneer rijdt.

Laat de auto niet stilletjes verdwijnen, maar markeer het moment: de auto verkopen en er samen iets van doen werkt beter dan een lege plek op de oprit.$t$);

select public.wegwijzer_seed_link('rijbewijs-en-dementie', 1, 'CBR: rijden met een aandoening', 'https://www.cbr.nl');
select public.wegwijzer_seed_link('rijbewijs-en-dementie', 2, 'Alzheimer Nederland', 'https://www.alzheimer-nederland.nl');
select public.wegwijzer_seed_link('rijbewijs-en-dementie', 3, 'Valys: vervoer voor langere afstanden', 'https://www.valys.nl');

-- ---------------------------------------------------------------------------

select public.wegwijzer_seed_module(
  'dementie', 'technologie-en-veiligheid', 'Technologie en veiligheid thuis bij dementie',
  'Een gps-horloge, een medicijndispenser of een sensor bij de deur kan thuis wonen langer mogelijk maken. Wat er is, wat het oplost en waar de grens ligt tussen helpen en controleren.',
  array[
    'Gps en dwaaldetectie geven vrijheid terug, maar het blijft volgen: bespreek het en leg de afspraak vast.',
    'Een medicijndispenser met alarm voorkomt vergeten en dubbel innemen.',
    'Kleine dingen eerst: sleutelkluis, automatische verlichting, gasmelder, kleedjes weg.',
    'Wordt technologie ingezet tegen iemands wil, dan gelden de regels van de Wet zorg en dwang.'
  ],
  array['Wet zorg en dwang'],
  array['gps', 'gps horloge', 'dwaaldetectie', 'tracker', 'medicijndispenser', 'sensor', 'personenalarmering', 'domotica', 'sleutelkluis', 'veilig thuis wonen', 'technologie dementie', 'camera thuis'],
  5, 7, false
);

select public.wegwijzer_seed_sectie('technologie-en-veiligheid', 1, 'uitleg', 'Wat er is en wat het oplost', $t$Voor dwalen: een gps-horloge of -zender waarmee je iemand kunt vinden, en sensoren die melden dat de voordeur 's nachts opengaat. Voor medicijnen: een dispenser die op vaste tijden het juiste vakje opent en alarm slaat als er niets uitgenomen wordt. Voor contact: beeldbellen met één knop en een vaste dagstructuur op een dementieklok.

En voor de basisveiligheid: een sleutelkluis zodat thuiszorg en ambulance binnen kunnen, automatische verlichting op de route naar het toilet, een gas- en rookmelder en een fornuisbeveiliging.$t$);

select public.wegwijzer_seed_sectie('technologie-en-veiligheid', 2, 'stappen', 'Zo pak je het aan', $t$Begin bij het probleem, niet bij het apparaat: wat gaat er nu echt mis, en wanneer.
Bespreek het met de persoon zelf zolang dat kan, en met de casemanager of ergotherapeut.
Probeer eerst één ding en kijk twee weken of het werkt; een huis vol piepende apparaten helpt niemand.
Vraag bij de gemeente en de zorgverzekeraar wat vergoed wordt; personenalarmering en soms een dispenser vallen onder een regeling.
Leg bij gps en sensoren vast wie de meldingen krijgt en wat diegene dan doet; techniek zonder opvolging is schijnveiligheid.$t$);

select public.wegwijzer_seed_sectie('technologie-en-veiligheid', 3, 'letop', 'Volgen is ook toezicht', $t$Een gps-tracker of camera zet je niet "gewoon even" in. Het is toezicht op een volwassene, en zodra iemand zich ertegen verzet of het niet kan begrijpen, gelden de regels voor onvrijwillige zorg uit de Wet zorg en dwang: alleen als het echt niet anders kan, zo licht mogelijk, en vastgelegd in het zorgplan met de betrokken zorgverleners.

De vuistregel: technologie moet vrijheid vergroten, niet vervangen wat menselijke aandacht hoort te doen. Bespreek het dus altijd met de casemanager, en noteer wat er is afgesproken.$t$);

select public.wegwijzer_seed_link('technologie-en-veiligheid', 1, 'Dementie.nl: hulpmiddelen en technologie', 'https://dementie.nl');
select public.wegwijzer_seed_link('technologie-en-veiligheid', 2, 'Alzheimer Nederland', 'https://www.alzheimer-nederland.nl');
select public.wegwijzer_seed_link('technologie-en-veiligheid', 3, 'Dwang in de zorg: wanneer is het onvrijwillige zorg', 'https://www.dwangindezorg.nl');

-- ===========================================================================
-- THEMA: beslissen voor een ander
-- ===========================================================================

select public.wegwijzer_seed_module(
  'regelen', 'geldzaken-veilig-regelen', 'Bankzaken en financieel misbruik voorkomen',
  'Bankzaken voor een ander doen begint vaak klein en gaat vaak net niet goed: een geleende pinpas, een onduidelijke opname. Hoe je het netjes regelt en misbruik herkent.',
  array[
    'Regel een bankvolmacht bij de bank zelf; banken accepteren zelden een onderhandse machtiging.',
    'Geef nooit pinpas en pincode af, ook niet binnen de familie; dat is de norm, geen wantrouwen.',
    'Houd een simpele administratie bij en deel die jaarlijks met de andere betrokkenen.',
    'Vermoed je financieel misbruik, bel dan Veilig Thuis: 0800-2000, gratis en ook voor advies.'
  ],
  array['Burgerlijk Wetboek 3, titel 3'],
  array['bankzaken', 'bankvolmacht', 'pinpas', 'geld opnemen', 'financieel misbruik', 'ouderenmishandeling', 'ontspoorde zorg', 'veilig thuis', 'geld verdwijnt', 'tweede rekeninghouder'],
  5, 6, false
);

select public.wegwijzer_seed_sectie('geldzaken-veilig-regelen', 1, 'stappen', 'Zo regel je bankzaken netjes', $t$Maak een afspraak bij de bank, samen met degene om wie het gaat, en vraag een bankvolmacht aan; elke grote bank heeft daar een eigen formulier en werkwijze voor.
Kies bewust wat de gemachtigde mag: alleen betalen en overboeken, of ook sparen en beleggen.
Zet vaste lasten zoveel mogelijk op automatische incasso.
Spreek een limiet af voor pinnen en overboeken, en een tweede paar ogen bij grote bedragen.
Word je gemachtigde, houd dan bonnetjes en een kort overzicht bij: datum, bedrag, waarvoor.
Wordt zelf beslissen echt te moeilijk, kijk dan naar het levenstestament of bewind; een bankvolmacht is de lichtste vorm, geen eindstation.$t$);

select public.wegwijzer_seed_sectie('geldzaken-veilig-regelen', 2, 'letop', 'Signalen van financieel misbruik', $t$Financieel misbruik van ouderen komt veel voor, en meestal is de dader een bekende. Signalen: geld of spullen die verdwijnen, onverklaarbare opnames, een nieuwe "beste vriend" die zich met de financiën bemoeit, plotselinge wijzigingen in testament of machtigingen, rekeningen die onbetaald blijven terwijl er genoeg geld is, of iemand die nooit meer alleen op bezoek mag komen.

Ook goedbedoelde zorg kan ontsporen: wie zelf krap zit en dagelijks de boodschappen voorschiet, glijdt soms ongemerkt af naar lenen zonder te vragen. Duidelijke afspraken beschermen iedereen, ook jou.$t$);

select public.wegwijzer_seed_sectie('geldzaken-veilig-regelen', 3, 'vraag', 'Wat doe ik bij een vermoeden', $t$Bel Veilig Thuis op 0800-2000. Dat is gratis, kan anoniem, en je hoeft geen bewijs te hebben: ook voor advies over een niet-pluisgevoel ben je er aan het juiste adres. Zij denken mee over de volgende stap en kunnen zo nodig onderzoek doen.

Praktisch kun je zelf al veel: vraag als familie gezamenlijke inzage in de rekening, laat de bank meekijken naar vreemde transacties, en leg vermoedens vast met datum en omschrijving. Bij een strafbaar feit, zoals diefstal of afpersing, kun je aangifte doen bij de politie.$t$);

select public.wegwijzer_seed_link('geldzaken-veilig-regelen', 1, 'Veilig Thuis: advies en meldpunt, 0800-2000', 'https://veiligthuis.nl');
select public.wegwijzer_seed_link('geldzaken-veilig-regelen', 2, 'Goedvertegenwoordigd.nl: machtigingen en bewind', 'https://goedvertegenwoordigd.nl');
select public.wegwijzer_seed_link('geldzaken-veilig-regelen', 3, 'Notaris.nl: levenstestament en volmacht', 'https://www.notaris.nl');

-- ===========================================================================
-- THEMA: zorg thuis regelen
-- ===========================================================================

select public.wegwijzer_seed_module(
  'zorg-thuis', 'palliatieve-zorg-thuis', 'Palliatieve en terminale zorg thuis',
  'Als genezen niet meer kan, verschuift de zorg naar kwaliteit van leven. Thuis sterven kan bijna altijd, met de huisarts als spil, extra wijkverpleging en vrijwilligers die waken.',
  array[
    'De huisarts coördineert palliatieve zorg thuis; bespreek wensen vroeg, niet pas in de laatste week.',
    'In de terminale fase kan de wijkverpleging fors opschalen, tot nachtzorg en waken aan toe.',
    'Opgeleide vrijwilligers (VPTZ) waken thuis, zodat jij kunt slapen; een hospice kan als thuis niet gaat.',
    'Denk ook aan jezelf: langdurend zorgverlof, en gratis geestelijke verzorging thuis voor jullie allebei.'
  ],
  array['Zorgverzekeringswet', 'Wet langdurige zorg'],
  array['palliatief', 'palliatieve zorg', 'terminaal', 'terminale zorg', 'stervensfase', 'thuis sterven', 'hospice', 'bijna-thuis-huis', 'waken', 'nachtzorg', 'laatste fase', 'levenseinde zorg'],
  6, 6, true
);

select public.wegwijzer_seed_sectie('palliatieve-zorg-thuis', 1, 'uitleg', 'Wat palliatieve zorg is', $t$Palliatieve zorg is alle zorg als genezen niet meer het doel is: pijn en benauwdheid verlichten, angst en onrust opvangen, en de tijd die er is zo goed mogelijk maken. Die fase kan maanden of zelfs jaren duren; de terminale fase is het laatste stuk, als het overlijden binnen enkele maanden verwacht wordt.

De huisarts is thuis de spil: die stemt af met de wijkverpleging, regelt medicatie voor als het moeilijk wordt en komt vaker langs. Vraag ook naar het palliatief team van de regio; huisartsen kunnen dat altijd om advies vragen.$t$);

select public.wegwijzer_seed_sectie('palliatieve-zorg-thuis', 2, 'stappen', 'Zo regel je de laatste fase thuis', $t$Bespreek met de huisarts wat jullie willen: thuis blijven, wel of niet naar het ziekenhuis, wensen rond het levenseinde.
Vraag de wijkverpleging om de indicatie uit te breiden; in de terminale fase kan dat tot intensieve zorg, ook 's nachts.
Vraag een terminaliteitsverklaring als die nodig is voor extra zorg of verlof.
Schakel VPTZ-vrijwilligers in om te waken, zodat jij en de familie ook slapen.
Regel praktisch alvast: een hoog-laagbed via de uitleen, medicatie in huis voor de laatste dagen, telefoonnummers voor de nacht.
Regel je eigen verlof op het werk; kortdurend of langdurend zorgverlof is hier precies voor bedoeld.$t$);

select public.wegwijzer_seed_sectie('palliatieve-zorg-thuis', 3, 'uitleg', 'Hospice en bijna-thuis-huis', $t$Kan of wil iemand niet thuis sterven, dan is er het hospice of bijna-thuis-huis: een huiselijke plek met zorg dichtbij, waar familie altijd welkom is en kan blijven logeren. De zorg wordt grotendeels vergoed; vaak geldt een eigen bijdrage per dag, en soms helpt de aanvullende verzekering daarbij.

Wachtlijsten verschillen sterk per regio. Oriënteer je op tijd, ook als jullie eigenlijk thuis willen blijven; het is een geruststelling om een plan B te hebben.$t$);

select public.wegwijzer_seed_sectie('palliatieve-zorg-thuis', 4, 'letop', 'Vergeet jezelf niet', $t$Waken sloopt. Accepteer hulp van de kring, laat vrijwilligers nachten overnemen en durf te slapen als een ander waakt. Verdriet begint vaak al vóór het overlijden; ook daarvoor kun je terecht bij de huisarts, het steunpunt of een geestelijk verzorger.

Geestelijke verzorging thuis, een gesprek over zingeving en afscheid met een opgeleide begeleider, is er ook voor naasten en is thuis vaak kosteloos beschikbaar.$t$);

select public.wegwijzer_seed_link('palliatieve-zorg-thuis', 1, 'Over palliatieve zorg: alles over de laatste levensfase', 'https://overpalliatievezorg.nl');
select public.wegwijzer_seed_link('palliatieve-zorg-thuis', 2, 'VPTZ: vrijwilligers palliatieve terminale zorg', 'https://www.vptz.nl');
select public.wegwijzer_seed_link('palliatieve-zorg-thuis', 3, 'Thuisarts.nl: nadenken over het levenseinde', 'https://www.thuisarts.nl/levenseinde');
select public.wegwijzer_seed_link('palliatieve-zorg-thuis', 4, 'Geestelijke verzorging thuis', 'https://geestelijkeverzorging.nl');

-- ---------------------------------------------------------------------------

select public.wegwijzer_seed_module(
  'zorg-thuis', 'na-ziekenhuisopname', 'Uit het ziekenhuis: herstel en vervolgzorg',
  'Het ziekenhuis wil snel ontslaan, maar thuis moet het wel kunnen. De transferverpleegkundige regelt vervolgzorg; zeg eerlijk wat jij wel en niet kunt opvangen.',
  array[
    'Meld je bij de transferverpleegkundige zodra opname of ontslag in beeld komt.',
    'Kan het thuis even niet, dan is er het eerstelijnsverblijf (ELV): tijdelijk bed met verzorging.',
    'Moet er gericht gerevalideerd worden, dan is er geriatrische revalidatiezorg (GRZ).',
    'Zeg eerlijk wat jij aankunt; "thuis met mantelzorg" is geen automatisme.'
  ],
  array['Zorgverzekeringswet'],
  array['ziekenhuis', 'ontslag ziekenhuis', 'transferverpleegkundige', 'eerstelijnsverblijf', 'elv', 'revalidatie', 'grz', 'herstellen', 'tijdelijk bed', 'naar huis na operatie', 'gebroken heup'],
  5, 7, false
);

select public.wegwijzer_seed_sectie('na-ziekenhuisopname', 1, 'uitleg', 'De drie routes na ontslag', $t$Naar huis met extra zorg: de transferverpleegkundige of het transferbureau van het ziekenhuis regelt wijkverpleging, hulpmiddelen en zo nodig huishoudelijke hulp; de eerste dagen thuis zijn dan het spannendst.

Eerstelijnsverblijf (ELV): een tijdelijk bed in bijvoorbeeld een zorghotel of verpleeghuislocatie voor wie medisch gezien niet meer in het ziekenhuis hoeft, maar thuis nog niet redt. Het valt onder de zorgverzekering; houd rekening met het eigen risico.

Geriatrische revalidatiezorg (GRZ): gericht revalideren na bijvoorbeeld een beroerte of gebroken heup, met fysiotherapie en een behandelplan, meestal enkele weken tot maanden, daarna alsnog naar huis.$t$);

select public.wegwijzer_seed_sectie('na-ziekenhuisopname', 2, 'stappen', 'Zo voorkom je een wankel ontslag', $t$Vraag bij opname meteen wie de transferverpleegkundige is en zeg dat je betrokken wilt worden bij het ontslag.
Vertel concreet wat jij thuis wél en niet kunt: tillen, nachten, dagelijkse verzorging.
Vraag om een ontslaggesprek waarin de vervolgzorg zwart op wit staat: wie komt er, vanaf wanneer, hoe vaak.
Controleer vóór het ontslag of hulpmiddelen en medicatie geregeld zijn, en of de huisarts is geïnformeerd.
Gaat het thuis toch mis, bel dan de huisarts en de wijkverpleging; opschalen of alsnog een ELV-bed kan ook na ontslag.$t$);

select public.wegwijzer_seed_sectie('na-ziekenhuisopname', 3, 'letop', 'Je hoeft geen ja te zeggen', $t$"Het gaat wel met wat mantelzorg" is snel gezegd door een arts die het bed nodig heeft. Maar jouw belastbaarheid telt mee in wat verantwoord is. Als jij aangeeft dat het thuis niet kan, moet er een ander plan komen; laat je niet naar huis praten met een situatie waarvan je weet dat die binnen een week vastloopt.

Zeg het hardop, vraag om de transferverpleegkundige en laat noteren wat je hebt gezegd. Dat voelt streng, maar voorkomt een crisis en een heropname.$t$);

select public.wegwijzer_seed_link('na-ziekenhuisopname', 1, 'Rijksoverheid: zorg en ondersteuning thuis', 'https://www.rijksoverheid.nl/themas/familie-zorg-en-gezondheid/zorg-en-ondersteuning-thuis');
select public.wegwijzer_seed_link('na-ziekenhuisopname', 2, 'Patiëntenfederatie Nederland', 'https://www.patientenfederatie.nl');
select public.wegwijzer_seed_link('na-ziekenhuisopname', 3, 'Regelhulp: ondersteuning voor mantelzorgers', 'https://www.regelhulp.nl/mantelzorgers/ondersteuning-en-advies');

-- ---------------------------------------------------------------------------

select public.wegwijzer_seed_module(
  'zorg-thuis', 'medicijnen-goed-regelen', 'Medicijnen goed en veilig regelen',
  'Hoe meer medicijnen, hoe meer er mis kan gaan. De apotheek kan veel uit handen nemen: een baxterrol, bezorging, en een jaarlijkse controle of alles nog samen gaat.',
  array[
    'Een baxterrol (medicatierol) zet alle medicijnen per innamemoment in één zakje.',
    'Vraag de apotheek om een medicatiebeoordeling bij vijf of meer medicijnen.',
    'De wijkverpleging kan aanreiken of toedienen als zelf innemen niet meer lukt.',
    'Verstop medicijnen nooit in het eten zonder overleg; dat valt onder onvrijwillige zorg.'
  ],
  array['Zorgverzekeringswet'],
  array['medicijnen', 'medicatie', 'baxter', 'baxterrol', 'medicijnrol', 'apotheek', 'pillen vergeten', 'medicatiebeoordeling', 'medicijnen klaarzetten', 'dispenser'],
  4, 8, false
);

select public.wegwijzer_seed_sectie('medicijnen-goed-regelen', 1, 'uitleg', 'Wat de apotheek kan regelen', $t$De baxterrol is de grootste ontlasting: alle medicijnen per dag en per tijdstip in aparte zakjes, wekelijks geleverd. Vergissen wordt bijna onmogelijk en jij hoeft geen doosjes meer te beheren. De apotheek stemt de rol af met de huisarts en past hem aan als er iets verandert.

Daarnaast: bezorgen aan huis, een herhaalservice die zelf in de gaten houdt wanneer iets op is, en synchronisatie zodat niet elke week iets anders op is.$t$);

select public.wegwijzer_seed_sectie('medicijnen-goed-regelen', 2, 'stappen', 'Zo krijg je grip', $t$Vraag de apotheek om een actueel medicatieoverzicht en neem dat mee naar elke arts en elk ziekenhuisbezoek.
Gebruikt iemand vijf of meer medicijnen, vraag dan om een medicatiebeoordeling: apotheker en huisarts lopen dan alles na op nut, dosering en combinaties.
Vraag naar de baxterrol als het beheer thuis rommelig wordt.
Lukt innemen op tijd niet, vraag de wijkverpleegkundige dan om aanreiken of toedienen mee te nemen in de indicatie; een medicijndispenser met alarm kan een tussenstap zijn.
Meld bijwerkingen en gestopte medicijnen altijd bij apotheek én huisarts, dan klopt het overzicht overal.$t$);

select public.wegwijzer_seed_sectie('medicijnen-goed-regelen', 3, 'letop', 'Weigeren is geen inname-probleem', $t$Weigert iemand structureel medicijnen, los dat dan niet op met fijnmalen of verstoppen in de appelmoes. Medisch kan dat gevaarlijk zijn, en het is zorg tegen iemands wil: daarvoor gelden de regels van de Wet zorg en dwang zodra er professionele zorg betrokken is.

Bespreek het met de huisarts of casemanager. Vaak is er een alternatief: een ander innamemoment, een andere vorm, of soms de conclusie dat een middel gemist kan worden.$t$);

select public.wegwijzer_seed_link('medicijnen-goed-regelen', 1, 'Apotheek.nl: medicijnen en service van de apotheek', 'https://www.apotheek.nl');
select public.wegwijzer_seed_link('medicijnen-goed-regelen', 2, 'Thuisarts.nl', 'https://www.thuisarts.nl');
select public.wegwijzer_seed_link('medicijnen-goed-regelen', 3, 'Dwang in de zorg: medicatie en onvrijwillige zorg', 'https://www.dwangindezorg.nl');

-- ===========================================================================
-- THEMA: zorgen voor jezelf
-- ===========================================================================

select public.wegwijzer_seed_module(
  'jezelf', 'jonge-mantelzorgers', 'Jonge mantelzorgers: kinderen die mee zorgen',
  'Groeit er een kind op in een gezin waar gezorgd wordt, dan zorgt dat kind mee, zichtbaar of onzichtbaar. Waar je op let en hoe je voorkomt dat een kind stilletjes overbelast raakt.',
  array[
    'Ook kinderen en jongeren zijn mantelzorger als thuis iemand ziek is; vaak zonder dat iemand het zo noemt.',
    'Signalen: altijd moe, schoolwerk dat inzakt, vrienden afzeggen, nergens meer zin in, overal verantwoordelijk voor voelen.',
    'Informeer school of studie; een mentor die het weet kan enorm veel schelen.',
    'Het steunpunt mantelzorg heeft vaak apart aanbod voor jonge mantelzorgers.'
  ],
  array['Wmo 2015, artikel 2.3.2'],
  array['jonge mantelzorger', 'kind zorgt', 'kinderen', 'jongeren', 'school', 'broertje', 'zusje', 'opgroeien met zorg', 'kind van ouder met dementie', 'parentificatie'],
  5, 5, false
);

select public.wegwijzer_seed_sectie('jonge-mantelzorgers', 1, 'uitleg', 'Waarom het vaak onzichtbaar is', $t$Kinderen die opgroeien met een ziek gezinslid vinden hun situatie normaal: ze weten niet beter. Ze helpen in het huishouden, letten op een broertje of zusje, houden moeder in de gaten, en maken zich zorgen die ze niet uitspreken om niemand te belasten.

Dat maakt niet elke taak schadelijk; meehelpen hoort bij een gezin. Het gaat mis als de zorg structureel te groot wordt voor de leeftijd, of als een kind zich verantwoordelijk gaat voelen voor het welzijn van een ouder. Dat heet parentificatie, en het laat sporen na tot ver in de volwassenheid.$t$);

select public.wegwijzer_seed_sectie('jonge-mantelzorgers', 2, 'stappen', 'Wat je als gezin kunt doen', $t$Benoem het: "jij zorgt ook mee, en dat zien we". Erkenning alleen al lucht op.
Vraag regelmatig hoe het met het kind zelf gaat, los van de zieke; en accepteer ook "gewoon goed" als antwoord.
Informeer de mentor op school of de studiebegeleider; vraag om begrip bij deadlines en om een oogje in het zeil.
Houd vrije tijd vrij: sport, vrienden en niks doen zijn geen luxe maar noodzaak.
Meld het gezin bij het steunpunt mantelzorg; veel steunpunten hebben activiteiten en maatjes speciaal voor jonge mantelzorgers.
Zorg dat de zorgtaken van het kind ter sprake komen in het Wmo-gesprek; het hele gezin telt mee in het onderzoek.$t$);

select public.wegwijzer_seed_sectie('jonge-mantelzorgers', 3, 'vraag', 'Wanneer moet ik me echt zorgen maken', $t$Als een kind langdurig somber of prikkelbaar is, op school terugvalt, niet meer met vrienden afspreekt of lichamelijke klachten houdt zonder duidelijke oorzaak. Praat er dan over met de huisarts; die kan meedenken en zo nodig verwijzen.

En let op de stille kinderen: het kind dat "zo goed helpt" en nooit klaagt, heeft soms het meeste last. Vraag juist dat kind wat het zelf nodig heeft.$t$);

select public.wegwijzer_seed_link('jonge-mantelzorgers', 1, 'MantelzorgNL: jonge mantelzorgers', 'https://www.mantelzorg.nl');
select public.wegwijzer_seed_link('jonge-mantelzorgers', 2, 'MIND: voor jongeren en naasten', 'https://mindplatform.nl');
select public.wegwijzer_seed_link('jonge-mantelzorgers', 3, 'Regelhulp: ondersteuning voor mantelzorgers', 'https://www.regelhulp.nl/mantelzorgers/ondersteuning-en-advies');

-- ---------------------------------------------------------------------------
-- Alle onderwerpen zijn in deze ronde nagelopen en van bronnen voorzien.
-- ---------------------------------------------------------------------------
update public.guide_modules set bijgewerkt_op = current_date;

-- Hulpfuncties voor het vullen weer opruimen.
drop function if exists public.wegwijzer_seed_module(text, text, text, text, text[], text[], text[], integer, integer, boolean);
drop function if exists public.wegwijzer_seed_sectie(text, integer, text, text, text);
drop function if exists public.wegwijzer_seed_link(text, integer, text, text);

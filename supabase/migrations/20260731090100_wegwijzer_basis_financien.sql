-- Wegwijzer, inhoud 1 van 4: het zorgstelsel en geldzaken.
-- Bedragen staan met het jaartal erbij; ze veranderen vrijwel elk jaar.
-- Bijgewerkt: juli 2026.

-- ===========================================================================
-- THEMA: hoe zit het zorgstelsel in elkaar
-- ===========================================================================

select public.wegwijzer_seed_module(
  'basis', 'wat-is-mantelzorg', 'Wat is mantelzorg, en wat niet',
  'Zorgen voor iemand uit je omgeving die dat langere tijd nodig heeft. Het verschil met vrijwilligerswerk en met betaalde zorg bepaalt op welke regelingen je recht hebt.',
  array[
    'Mantelzorg is onbetaalde zorg die voortkomt uit een persoonlijke band, niet uit een baan of een dienst.',
    'Je kiest er meestal niet voor, het overkomt je: dat is precies het verschil met vrijwilligerswerk.',
    'Voor veel regelingen telt "meer dan acht uur per week" of "langer dan drie maanden".'
  ],
  array['Wmo 2015, artikel 1.1.1'],
  array['mantelzorg', 'wat is mantelzorg', 'definitie', 'zorgen voor mijn moeder', 'zorgen voor mijn man', 'onbetaalde zorg', 'informele zorg'],
  4, 1, true
);

select public.wegwijzer_seed_sectie('wat-is-mantelzorg', 1, 'uitleg', 'De omschrijving in de wet', $t$De Wmo 2015 omschrijft mantelzorg als hulp aan iemand met wie je een persoonlijke band hebt, die rechtstreeks voortvloeit uit die band en die verder gaat dan de gebruikelijke hulp die huisgenoten elkaar geven.

Drie dingen vallen op. Het gaat om een bestaande band: partner, ouder, kind, buurvrouw of goede vriend. Het is onbetaald. En het gaat verder dan normaal: boodschappen doen voor je zieke buurman is aardig, maar elke dag steunkousen aantrekken, medicijnen klaarzetten en 's nachts wakker liggen is zorg.$t$);

select public.wegwijzer_seed_sectie('wat-is-mantelzorg', 2, 'uitleg', 'Het verschil met vrijwilligerswerk', $t$Een vrijwilliger kiest een organisatie, tekent voor een aantal uur en kan stoppen. Bij mantelzorg is er geen keuze vooraf en meestal ook geen einddatum. Daarom bestaan er aparte regelingen: zorgverlof op je werk, ondersteuning vanuit de gemeente en vergoedingen die alleen voor deze situatie gelden.

In deze app zorg je vaak samen: jij houdt het overzicht als beheerder, de buddy's uit de kring nemen losse taken over. Dat maakt de zorg lichter, maar verandert niets aan je rechten.$t$);

select public.wegwijzer_seed_sectie('wat-is-mantelzorg', 3, 'wet', 'Grenzen die in regelingen terugkomen', $t$Veel regelingen hangen aan twee getallen. Voor een woning in de tuin en voor sommige gemeentelijke regelingen geldt vaak: minimaal acht uur zorg per week. Voor de mantelzorgwaardering en voor ondersteuning vanuit de gemeente kijkt men meestal naar drie maanden of langer.

Die grenzen staan niet allemaal in de wet zelf. Gemeenten mogen ze in hun eigen verordening invullen, dus ze verschillen per gemeente. Vraag altijd na wat jouw gemeente hanteert.$t$);

select public.wegwijzer_seed_sectie('wat-is-mantelzorg', 4, 'letop', 'Gebruikelijke hulp telt niet mee', $t$Gemeenten hanteren het begrip "gebruikelijke hulp": de zorg die huisgenoten normaal gesproken voor elkaar doen. Samen koken, de was draaien en boodschappen halen voor je partner valt daaronder. Daar krijg je geen ondersteuning voor.

Zodra de zorg langdurig, intensief of lichamelijk zwaar wordt, is het geen gebruikelijke hulp meer. Benoem dat expliciet in het gesprek met de gemeente, anders wordt het over het hoofd gezien.$t$);

select public.wegwijzer_seed_link('wat-is-mantelzorg', 1, 'Regelhulp: informatie voor wie zorgt', 'https://www.regelhulp.nl/mantelzorgers');
select public.wegwijzer_seed_link('wat-is-mantelzorg', 2, 'MantelzorgNL', 'https://www.mantelzorg.nl');

-- ---------------------------------------------------------------------------

select public.wegwijzer_seed_module(
  'basis', 'welke-wet', 'Welke wet hoort bij jouw situatie',
  'Wmo, Wlz, Zorgverzekeringswet of Jeugdwet: elke vorm van zorg valt onder een andere wet, met een ander loket, een andere eigen bijdrage en een ander soort hulp.',
  array[
    'Zorg thuis met verpleging of verzorging: Zorgverzekeringswet, via de wijkverpleegkundige.',
    'Ondersteuning en hulpmiddelen om thuis te blijven wonen: Wmo, via de gemeente.',
    '24 uur per dag zorg in de buurt nodig: Wlz, via het CIZ.',
    'Zorg voor een kind tot 18 jaar: Jeugdwet, via de gemeente.'
  ],
  array['Wmo 2015', 'Wet langdurige zorg', 'Zorgverzekeringswet', 'Jeugdwet'],
  array['welke wet', 'wmo', 'wlz', 'zvw', 'zorgverzekeringswet', 'jeugdwet', 'wet maatschappelijke ondersteuning', 'wet langdurige zorg', 'waar moet ik zijn', 'welk loket'],
  6, 2, true
);

select public.wegwijzer_seed_sectie('welke-wet', 1, 'uitleg', 'Vier wetten, vier loketten', $t$Nederland verdeelt zorg over vier wetten. Het loket verschilt, en daarmee ook wie beslist en wat je betaalt.

De Zorgverzekeringswet (Zvw) gaat over medische zorg: de huisarts, het ziekenhuis, medicijnen en wijkverpleging aan huis. Je zorgverzekeraar betaalt.

De Wet maatschappelijke ondersteuning (Wmo 2015) gaat over meedoen en thuis blijven wonen: huishoudelijke hulp, dagbesteding, een traplift, vervoer, en ook ondersteuning voor jou als beheerder. De gemeente beslist.

De Wet langdurige zorg (Wlz) is voor mensen die blijvend 24 uur per dag zorg in de nabijheid nodig hebben. Het CIZ beslist, daarna kies je tussen een verpleeghuis of zorg thuis vanuit dit budget.

De Jeugdwet gaat over hulp aan kinderen tot 18 jaar. Ook hier beslist de gemeente.$t$);

select public.wegwijzer_seed_sectie('welke-wet', 2, 'stappen', 'Zo vind je in drie vragen het juiste loket', $t$Is er 24 uur per dag toezicht of zorg dichtbij nodig, blijvend? Dan is het de Wlz: bel het CIZ.
Gaat het om verpleging of verzorging aan het lichaam (wondzorg, steunkousen, wassen, medicijnen)? Dan is het de Zorgverzekeringswet: bel de wijkverpleging of vraag de huisarts.
Gaat het om het huishouden, vervoer, dagbesteding, aanpassingen in huis of ondersteuning voor jou? Dan is het de Wmo: meld het bij de gemeente.$t$);

select public.wegwijzer_seed_sectie('welke-wet', 3, 'letop', 'De Wlz sluit de andere wetten grotendeels uit', $t$Zodra iemand een Wlz-indicatie heeft, vervalt het recht op de meeste Wmo-voorzieningen en op wijkverpleging vanuit de zorgverzekering. Alles zit dan in het Wlz-pakket.

Twee uitzonderingen die vaak vergeten worden: de rolstoel en de woningaanpassing blijven bij thuiswonen meestal via de Wmo lopen, en vervoer regel je apart. Vraag dit na vóór de indicatie ingaat, zodat je niet ineens zonder traplift zit.$t$);

select public.wegwijzer_seed_sectie('welke-wet', 4, 'uitleg', 'Wat betaal je waar', $t$Bij de Zorgverzekeringswet geldt het verplicht eigen risico (385 euro in 2026), maar wijkverpleging en de huisarts vallen daar juist buiten.

Bij de Wmo betaal je een eigen bijdrage via het CAK. In 2026 is dat nog een vast bedrag per maand, ongeacht je inkomen.

Bij de Wlz betaal je een inkomensafhankelijke eigen bijdrage, die fors kan oplopen. Het CAK rekent die uit op basis van inkomen en vermogen van twee jaar terug.$t$);

select public.wegwijzer_seed_link('welke-wet', 1, 'Regelhulp: welke zorg valt onder welke wet', 'https://www.regelhulp.nl/onderwerpen/zorg-organiseren');
select public.wegwijzer_seed_link('welke-wet', 2, 'CIZ: Wlz-indicatie aanvragen', 'https://www.ciz.nl');

-- ---------------------------------------------------------------------------

select public.wegwijzer_seed_module(
  'basis', 'hulp-aanvragen-gemeente', 'Hulp aanvragen bij de gemeente',
  'Van melding tot besluit: het keukentafelgesprek, het persoonlijk plan dat je vooraf mag indienen en de termijnen waar de gemeente zich aan moet houden.',
  array[
    'Je doet eerst een melding; daarna heeft de gemeente zes weken voor het onderzoek.',
    'Je mag binnen zeven dagen na de melding een persoonlijk plan indienen, en de gemeente moet dat gebruiken.',
    'Na het onderzoek dien je pas de echte aanvraag in; dan volgt binnen twee weken een besluit.',
    'Vraag om een schriftelijk verslag van het gesprek en teken niets wat niet klopt.'
  ],
  array['Wmo 2015, artikel 2.3.2', 'Wmo 2015, artikel 2.3.5'],
  array['keukentafelgesprek', 'wmo aanvragen', 'melding doen', 'persoonlijk plan', 'gesprek gemeente', 'wmo loket', 'onderzoek gemeente', 'aanvraag indienen'],
  7, 3, true
);

select public.wegwijzer_seed_sectie('hulp-aanvragen-gemeente', 1, 'uitleg', 'Melding en aanvraag zijn twee verschillende dingen', $t$Veel mensen denken dat ze meteen iets aanvragen. In de Wmo werkt het in twee stappen. Eerst doe je een melding: een telefoontje, mail of formulier waarin je zegt dat het thuis niet meer lukt. Daarna doet de gemeente onderzoek, meestal via een gesprek bij je thuis. Dat onderzoek mag maximaal zes weken duren.

Pas na dat onderzoek dien je de aanvraag in. Vanaf dat moment heeft de gemeente nog twee weken om te beslissen. Het is verstandig de melding schriftelijk of per mail te doen, zodat de datum vaststaat.$t$);

select public.wegwijzer_seed_sectie('hulp-aanvragen-gemeente', 2, 'stappen', 'Het persoonlijk plan: jouw sterkste kaart', $t$Doe de melding en noteer de datum.
Schrijf binnen zeven dagen een persoonlijk plan: wat er speelt, wat er al geprobeerd is, wat jij denkt dat nodig is.
Stuur het plan naar de gemeente en vraag om een ontvangstbevestiging.
De gemeente moet het plan betrekken bij het onderzoek. Dat staat in de wet.
Neem het plan mee naar het gesprek en loop het punt voor punt langs.$t$);

select public.wegwijzer_seed_sectie('hulp-aanvragen-gemeente', 3, 'uitleg', 'Het gesprek bij je thuis', $t$Het gesprek gaat over de hele situatie: wat lukt nog, wat niet, wie helpt er al, en hoe houdbaar is dat. Je mag altijd iemand meenemen: een familielid, een buddy uit de kring of een gratis cliëntondersteuner.

Zorg dat jouw eigen belasting op tafel komt. De gemeente moet onderzoeken of jij het volhoudt en of jij ondersteuning nodig hebt. Dat gebeurt alleen als je het zegt. Benoem concreet: hoe vaak sta je 's nachts op, hoeveel uur per week ben je kwijt, wat gaat er mis als jij twee weken wegval.$t$);

select public.wegwijzer_seed_sectie('hulp-aanvragen-gemeente', 4, 'letop', 'Vraag om het verslag', $t$Na het gesprek maakt de gemeente een verslag. Vraag daar altijd om, ook als het niet automatisch wordt aangeboden. Klopt er iets niet, teken dan niet voor akkoord maar stuur je correcties schriftelijk terug.

Het verslag is de basis voor het besluit. Wat er niet in staat, telt straks niet mee.$t$);

select public.wegwijzer_seed_sectie('hulp-aanvragen-gemeente', 5, 'vraag', 'Wat als de gemeente te traag is', $t$Duurt het langer dan zes weken plus twee weken, dan kun je de gemeente schriftelijk in gebreke stellen. Reageert ze binnen twee weken daarna nog niet, dan kan ze een dwangsom verschuldigd zijn.

Bij spoed hoef je niet te wachten. De gemeente moet dan een spoedvoorziening treffen, ook als het onderzoek nog loopt.$t$);

select public.wegwijzer_seed_link('hulp-aanvragen-gemeente', 1, 'Rijksoverheid: ondersteuning vanuit de Wmo', 'https://www.rijksoverheid.nl/onderwerpen/zorg-en-ondersteuning-thuis');

-- ---------------------------------------------------------------------------

select public.wegwijzer_seed_module(
  'basis', 'clientondersteuning', 'Gratis hulp van een cliëntondersteuner',
  'Een onafhankelijke cliëntondersteuner denkt met je mee, gaat mee naar het gesprek en kent de regels. Het is gratis, je hebt er recht op en je hebt geen verwijzing nodig.',
  array[
    'Iedereen heeft recht op een onafhankelijke cliëntondersteuner, gratis.',
    'De gemeente moet je hier zelfs actief op wijzen vóór het onderzoek begint.',
    'Hij werkt niet voor de gemeente, maar staat naast jou.',
    'Ook voor de Wlz bestaat cliëntondersteuning, dan via het zorgkantoor.'
  ],
  array['Wmo 2015, artikel 2.2.4', 'Wmo 2015, artikel 2.3.2 lid 3'],
  array['clientondersteuner', 'cliëntondersteuning', 'onafhankelijke ondersteuning', 'MEE', 'iemand mee naar gesprek', 'gratis hulp', 'adviseur gemeente'],
  4, 4, false
);

select public.wegwijzer_seed_sectie('clientondersteuning', 1, 'uitleg', 'Wat doet zo iemand', $t$Een cliëntondersteuner kent de wetten, de gemeentelijke verordening en de weg. Hij helpt je op een rij zetten wat je nodig hebt, gaat mee naar het keukentafelgesprek, leest het verslag mee en helpt bij bezwaar.

Belangrijk: hij is onafhankelijk. Hij wordt betaald uit gemeenschapsgeld, maar mag geen belang hebben bij de uitkomst. Vaak zijn het organisaties als MEE of een lokale welzijnsorganisatie.$t$);

select public.wegwijzer_seed_sectie('clientondersteuning', 2, 'wet', 'De gemeente moet je erop wijzen', $t$In de Wmo staat dat de gemeente ervoor moet zorgen dat cliëntondersteuning beschikbaar is, en dat ze je vóór het onderzoek moet vertellen dat je er gebruik van kunt maken.

Gebeurt dat niet, dan is dat een gebrek in de procedure. Noem het in je bezwaar als het besluit tegenvalt.$t$);

select public.wegwijzer_seed_sectie('clientondersteuning', 3, 'stappen', 'Zo regel je het', $t$Bel het Wmo-loket van je gemeente en vraag naar onafhankelijke cliëntondersteuning.
Noteer welke organisatie het is en maak rechtstreeks een afspraak.
Doe dit vóór het keukentafelgesprek, niet erna.
Heeft de zorgvrager een Wlz-indicatie? Bel dan het zorgkantoor; daar loopt de cliëntondersteuning.$t$);

select public.wegwijzer_seed_link('clientondersteuning', 1, 'Regelhulp: onafhankelijke cliëntondersteuning', 'https://www.regelhulp.nl/onderwerpen/clientondersteuning');

-- ---------------------------------------------------------------------------

select public.wegwijzer_seed_module(
  'basis', 'bezwaar-en-klacht', 'Niet eens met het besluit',
  'Afgewezen of te weinig toegekend? Je hebt zes weken om bezwaar te maken. Een klacht over de bejegening loopt via een andere route dan een bezwaar tegen het besluit.',
  array[
    'Bezwaar: binnen zes weken na de datum op het besluit, schriftelijk.',
    'Bezwaar maken is gratis; beroep bij de rechtbank kost griffierecht.',
    'Bij spoed kun je de rechter om een voorlopige voorziening vragen.',
    'Een klacht gaat over hoe je behandeld bent, een bezwaar over de inhoud van het besluit.'
  ],
  array['Algemene wet bestuursrecht, artikel 6:7', 'Wmo 2015, artikel 2.1.3'],
  array['bezwaar', 'afgewezen', 'klacht', 'beroep', 'niet eens met besluit', 'bezwaarschrift', 'ombudsman', 'te weinig uren'],
  5, 5, false
);

select public.wegwijzer_seed_sectie('bezwaar-en-klacht', 1, 'uitleg', 'Zes weken, en die termijn is hard', $t$Onderaan het besluit staat een datum. Vanaf die datum heb je zes weken om bezwaar te maken. Die termijn is streng: te laat is meestal niet-ontvankelijk.

Heb je meer tijd nodig om je argumenten op papier te zetten, dien dan eerst een pro-formabezwaar in: een korte brief waarin je zegt dat je bezwaar maakt en dat de onderbouwing volgt. Je krijgt dan uitstel.$t$);

select public.wegwijzer_seed_sectie('bezwaar-en-klacht', 2, 'stappen', 'Wat zet je in je bezwaarschrift', $t$Je naam, adres en de datum.
Om welk besluit het gaat: kenmerk en datum van het besluit.
Waarom je het er niet mee eens bent, punt voor punt.
Wat je wél wilt: hoeveel uur, welke voorziening.
Onderbouwing: het persoonlijk plan, een brief van de huisarts, het gespreksverslag.
Je handtekening, en de vraag om gehoord te worden.$t$);

select public.wegwijzer_seed_sectie('bezwaar-en-klacht', 3, 'uitleg', 'Klacht of bezwaar', $t$Ging het gesprek onprettig, werd je niet serieus genomen of kreeg je geen verslag? Dat is een klacht. Die dien je in bij de gemeente zelf; komt daar niets uit, dan bij de Nationale ombudsman of de gemeentelijke ombudsman.

Klopt de uitkomst niet (te weinig uren, verkeerde voorziening, afwijzing)? Dat is een bezwaar. Beide kunnen naast elkaar lopen.$t$);

select public.wegwijzer_seed_sectie('bezwaar-en-klacht', 4, 'letop', 'Blijf de zorg intussen regelen', $t$Een bezwaar schort het besluit niet op. Loopt de zorg af terwijl je in bezwaar bent, vraag dan om een voorlopige voorziening bij de rechtbank, of vraag de gemeente om de oude indicatie door te laten lopen tot er een beslissing is.

Zet dat verzoek altijd op papier.$t$);

select public.wegwijzer_seed_link('bezwaar-en-klacht', 1, 'Juridisch Loket: bezwaar maken', 'https://www.juridischloket.nl');

-- ===========================================================================
-- THEMA: geld en regelingen
-- ===========================================================================

select public.wegwijzer_seed_module(
  'financien', 'mantelzorgwaardering', 'Mantelzorgwaardering van de gemeente',
  'Elke gemeente moet een jaarlijkse blijk van waardering regelen voor wie voor een inwoner zorgt. Hoogte en vorm bepaalt de gemeente zelf: geld, een bon of een dagje uit.',
  array[
    'De gemeente van de zorgvrager betaalt, niet die van jou.',
    'Bedrag en vorm verschillen sterk: van 50 tot enkele honderden euro''s, soms een bon.',
    'Je moet het bijna altijd zelf aanvragen, vaak met een deadline in het najaar.',
    'De landelijke regeling uit het verleden bestaat niet meer; het loopt volledig via de gemeente.'
  ],
  array['Wmo 2015, artikel 2.1.6'],
  array['mantelzorgwaardering', 'mantelzorgcompliment', 'waardering', 'vergoeding gemeente', 'jaarlijkse vergoeding', 'geld voor mantelzorg', 'cadeaubon'],
  4, 1, true
);

select public.wegwijzer_seed_sectie('mantelzorgwaardering', 1, 'wet', 'Wat de wet voorschrijft', $t$Artikel 2.1.6 van de Wmo 2015 verplicht elke gemeente om bij verordening te regelen op welke wijze zij een jaarlijkse blijk van waardering geeft aan degenen die zorgen voor een inwoner van die gemeente.

De wet zegt dus wél dat het moet, maar niet hoeveel en niet in welke vorm. Daardoor lopen de bedragen enorm uiteen.$t$);

select public.wegwijzer_seed_sectie('mantelzorgwaardering', 2, 'letop', 'De gemeente van de ander telt', $t$Woon jij in Utrecht en je moeder in Zwolle, dan vraag je de waardering aan bij Zwolle. Het gaat om de woonplaats van degene die de zorg krijgt.

Zorg je voor twee mensen in twee gemeenten, dan kun je in beide gemeenten aanvragen.$t$);

select public.wegwijzer_seed_sectie('mantelzorgwaardering', 3, 'stappen', 'Zo vraag je het aan', $t$Zoek op de site van de gemeente van de zorgvrager op "mantelzorgwaardering".
Kijk naar de voorwaarden: vaak minimaal drie maanden zorg en meer dan acht uur per week.
Let op de aanvraagperiode; veel gemeenten sluiten in oktober of november.
Vul het formulier in; meestal moet de zorgvrager meetekenen.
Geen regeling te vinden? Bel het Wmo-loket of het steunpunt mantelzorg, zij weten het.$t$);

select public.wegwijzer_seed_sectie('mantelzorgwaardering', 4, 'vraag', 'Moet ik er belasting over betalen', $t$Nee. Een blijk van waardering vanuit de Wmo is geen inkomen uit werk en is onbelast. Het telt ook niet mee voor de toeslagen.

Heb je een bijstandsuitkering, dan geldt sinds 1 januari 2026 dat vergoedingen die je voor deze zorg ontvangt niet meer op je uitkering worden gekort. Meld het voor de zekerheid wel bij je gemeente.$t$);

-- ---------------------------------------------------------------------------

select public.wegwijzer_seed_module(
  'financien', 'pgb', 'Persoonsgebonden budget (pgb)',
  'Met een pgb koop je zelf zorg in, in plaats van zorg te krijgen die de gemeente of het zorgkantoor heeft ingekocht. Het kan uit vier wetten komen en vraagt administratie.',
  array[
    'Een pgb bestaat in de Wmo, de Wlz, de Zorgverzekeringswet en de Jeugdwet.',
    'Het geld gaat niet naar je rekening: de SVB betaalt je zorgverleners uit (trekkingsrecht).',
    'Je moet kunnen uitleggen waarom zorg in natura niet volstaat, en een budgetplan maken.',
    'Een familielid mag betaald worden uit een pgb, maar niet zomaar: leg het goed vast.'
  ],
  array['Wmo 2015, artikel 2.3.6', 'Wet langdurige zorg, artikel 3.3.3'],
  array['pgb', 'persoonsgebonden budget', 'zelf zorg inkopen', 'budgetplan', 'SVB', 'trekkingsrecht', 'zorg in natura', 'betaald krijgen voor zorg'],
  7, 2, true
);

select public.wegwijzer_seed_sectie('pgb', 1, 'uitleg', 'Pgb of zorg in natura', $t$Bij zorg in natura kiest de gemeente of het zorgkantoor de aanbieder, en die regelt alles. Bij een pgb kies jij zelf wie de zorg geeft, wanneer en hoe. Dat geeft vrijheid, bijvoorbeeld als de zorg op onregelmatige tijden nodig is of als iemand vertrouwd gezicht wil.

De prijs is administratie: zorgovereenkomsten, urenbriefjes, een budgetplan en verantwoording. Reken op enkele uren per maand.$t$);

select public.wegwijzer_seed_sectie('pgb', 2, 'stappen', 'Van aanvraag tot uitbetaling', $t$Vraag de voorziening aan bij het juiste loket (gemeente, CIZ of zorgverzekeraar) en geef aan dat je een pgb wilt.
Motiveer waarom zorg in natura niet passend is; dit is de stap waarop het vaakst wordt afgewezen.
Maak een budgetplan: wie levert welke zorg, hoeveel uur, tegen welk tarief.
Toon aan dat je het beheer aankan, zelf of met een gewaarborgde hulp.
Na toekenning sluit je zorgovereenkomsten via de SVB.
Je dient maandelijks facturen of urenbriefjes in; de SVB betaalt rechtstreeks uit.$t$);

select public.wegwijzer_seed_sectie('pgb', 3, 'uitleg', 'Een familielid betalen uit het pgb', $t$Dat mag, en het gebeurt veel. Er zit wel een rem op. Gemeenten mogen een lager tarief hanteren voor iemand uit het sociale netwerk, en in de Wlz gelden aparte regels en maximumbedragen.

Leg altijd een zorgovereenkomst vast, ook binnen de familie. Zonder overeenkomst betaalt de SVB niet uit. Houd er ook rekening mee dat betaling gevolgen kan hebben voor toeslagen, een uitkering en de inkomstenbelasting.$t$);

select public.wegwijzer_seed_sectie('pgb', 4, 'letop', 'Bedenk vooraf wat er gebeurt als jij uitvalt', $t$Het pgb valt of staat bij de budgethouder. Kan de zorgvrager het beheer niet zelf, dan moet er een vertegenwoordiger zijn: de gewaarborgde hulp in de Wlz.

Regel dat op tijd, en zet in het budgetplan wie het overneemt als jij ziek wordt. Dat voorkomt dat de zorg stilvalt op het slechtst denkbare moment.$t$);

select public.wegwijzer_seed_sectie('pgb', 5, 'vraag', 'Kan ik een pgb combineren met zorg in natura', $t$Binnen de Wmo en de Wlz kan dat vaak: een deel in natura, een deel als pgb. Dat heet een gedeeltelijk pgb of, in de Wlz, een modulair pakket thuis.

Handig als de dagbesteding prima geregeld is via een aanbieder, maar je de persoonlijke verzorging liever zelf inkoopt.$t$);

select public.wegwijzer_seed_link('pgb', 1, 'Rijksoverheid: persoonsgebonden budget', 'https://www.rijksoverheid.nl/onderwerpen/pgb');
select public.wegwijzer_seed_link('pgb', 2, 'SVB: pgb-administratie', 'https://www.svb.nl/nl/pgb');
select public.wegwijzer_seed_link('pgb', 3, 'Per Saldo, vereniging van budgethouders', 'https://www.pgb.nl');

-- ---------------------------------------------------------------------------

select public.wegwijzer_seed_module(
  'financien', 'eigen-bijdrage', 'Eigen bijdrage en eigen risico',
  'Wat kost zorg zelf? De Wmo kent in 2026 nog een vast maandbedrag, de Wlz een inkomensafhankelijke bijdrage, en de zorgverzekering een eigen risico met belangrijke uitzonderingen.',
  array[
    'Wmo in 2026: 21,80 euro per maand, ongeacht inkomen. Vanaf 2027 wordt dit inkomensafhankelijk.',
    'Wlz: inkomensafhankelijk, gebaseerd op inkomen en vermogen van twee jaar terug.',
    'Eigen risico 2026: 385 euro. Huisarts, wijkverpleging en casemanagement vallen er buiten.',
    'Het CAK int alle eigen bijdragen; bij betalingsproblemen kun je een regeling treffen.'
  ],
  array['Wmo 2015, artikel 2.1.4a', 'Besluit langdurige zorg'],
  array['eigen bijdrage', 'eigen risico', 'CAK', 'abonnementstarief', 'wat kost het', 'kosten zorg', 'maandbedrag', 'rekening CAK'],
  6, 3, true
);

select public.wegwijzer_seed_sectie('eigen-bijdrage', 1, 'uitleg', 'De Wmo: een vast bedrag per maand', $t$Voor bijna alle Wmo-maatwerkvoorzieningen geldt het abonnementstarief: één vast bedrag per maand, hoeveel voorzieningen je ook hebt en hoe hoog je inkomen ook is. In 2026 is dat maximaal 21,80 euro per maand.

Gemeenten mogen een lager bedrag hanteren of bepaalde groepen vrijstellen, bijvoorbeeld huishoudens met een minimuminkomen. Kijk dus altijd ook naar de eigen regeling van je gemeente.$t$);

select public.wegwijzer_seed_sectie('eigen-bijdrage', 2, 'wet', 'Wat er verandert per 2027', $t$Het kabinet vervangt het abonnementstarief door een inkomensafhankelijke eigen bijdrage voor Wmo-maatwerkvoorzieningen. De invoering is uitgesteld naar 1 januari 2027.

Wat je gaat betalen hangt dan af van je inkomen. De precieze staffels worden nog uitgewerkt. Houd hier rekening mee als je nu een voorziening aanvraagt die jaren doorloopt.$t$);

select public.wegwijzer_seed_sectie('eigen-bijdrage', 3, 'uitleg', 'De Wlz: een stuk hoger', $t$Bij zorg vanuit de Wet langdurige zorg betaal je een inkomensafhankelijke bijdrage. Eerst de lage bijdrage, na verloop van tijd (meestal na vier maanden verblijf in een instelling) de hoge bijdrage, die tot honderden euro's per maand kan oplopen.

Het CAK rekent met inkomen en vermogen van twee jaar geleden. Is het inkomen sindsdien flink gedaald, vraag dan om een herberekening op basis van het actuele inkomen.$t$);

select public.wegwijzer_seed_sectie('eigen-bijdrage', 4, 'letop', 'Waar je géén eigen risico over betaalt', $t$Het verplicht eigen risico is 385 euro in 2026, maar geldt niet voor alles. Buiten het eigen risico vallen onder meer: de huisarts, wijkverpleging, casemanagement bij dementie, verloskundige zorg en zorg uit het aanvullend pakket.

Medicijnen, ziekenhuiszorg, bloedonderzoek en hulpmiddelen vallen er wél onder. Een verwijzing van de huisarts naar het ziekenhuis kost dus wel eigen risico.$t$);

select public.wegwijzer_seed_sectie('eigen-bijdrage', 5, 'vraag', 'De rekening kan niet betaald worden, wat nu', $t$Bel het CAK en vraag om een betalingsregeling; dat kan telefonisch en levert geen incassokosten op.

Kijk daarnaast naar de gemeentelijke minimaregelingen: veel gemeenten kennen bijzondere bijstand voor de eigen bijdrage, of een collectieve zorgverzekering voor minima waarin de eigen bijdrage is meeverzekerd.$t$);

select public.wegwijzer_seed_link('eigen-bijdrage', 1, 'CAK: eigen bijdrage berekenen', 'https://www.hetcak.nl');

-- ---------------------------------------------------------------------------

select public.wegwijzer_seed_module(
  'financien', 'zorgkosten-belasting', 'Zorgkosten aftrekken van de belasting',
  'Extra kosten door ziekte of beperking kunnen aftrekbaar zijn als specifieke zorgkosten: reiskosten naar de arts, dieet, extra kleding, hulpmiddelen en extra gezinshulp.',
  array[
    'Alleen het deel boven het drempelbedrag is aftrekbaar; dat drempelbedrag hangt af van je inkomen.',
    'Je mag ook kosten aftrekken die je voor een ander betaalt, als die persoon dat zelf niet kan.',
    'Reiskosten naar arts of ziekenhuis tellen mee, ook met de eigen auto.',
    'Eigen risico en eigen bijdragen zijn juist niet aftrekbaar.'
  ],
  array['Wet inkomstenbelasting 2001, afdeling 6.5'],
  array['belasting', 'aftrekbaar', 'zorgkosten', 'specifieke zorgkosten', 'aangifte', 'belastingaangifte', 'dieetkosten', 'reiskosten arts', 'drempelbedrag', 'teruggave'],
  6, 4, false
);

select public.wegwijzer_seed_sectie('zorgkosten-belasting', 1, 'uitleg', 'Wat je mag opvoeren', $t$Aftrekbaar zijn onder meer: voorgeschreven medicijnen, hulpmiddelen die niet vergoed worden (zoals steunzolen of een gehoorapparaat), extra kosten voor kleding en beddengoed, een medisch voorgeschreven dieet volgens vaste bedragen, reiskosten naar arts en ziekenhuis, en extra gezinshulp.

Ook kosten van behandelingen die niet vergoed worden en de vervoerskosten om de zieke te bezoeken in het ziekenhuis of verpleeghuis kunnen meetellen.$t$);

select public.wegwijzer_seed_sectie('zorgkosten-belasting', 2, 'letop', 'Wat juist niet aftrekbaar is', $t$Het verplicht eigen risico, de eigen bijdrage aan het CAK, de premie van je zorgverzekering en de kosten van een bril of contactlenzen zijn níét aftrekbaar.

Ook kosten die je vergoed hebt gekregen tellen niet mee. Het gaat steeds om wat je zelf, definitief, kwijt bent.$t$);

select public.wegwijzer_seed_sectie('zorgkosten-belasting', 3, 'wet', 'Het drempelbedrag in 2026', $t$Alleen het deel van je zorgkosten boven een drempel is aftrekbaar. Zonder fiscale partner is die drempel in 2026 minimaal 166 euro, en bij een drempelinkomen tussen 9.681 en 51.411 euro is het 1,65 procent van dat inkomen. Met fiscale partner is het minimum 332 euro. Boven 51.411 euro drempelinkomen komt daar 5,75 procent bovenop.

Doe je online aangifte, dan rekent de Belastingdienst de drempel automatisch uit.$t$);

select public.wegwijzer_seed_sectie('zorgkosten-belasting', 4, 'voorbeeld', 'Betalen voor een ander', $t$Je betaalt de fysiotherapie en de steunkousen van je vader, omdat hij het zelf niet kan betalen en jij je daar moreel toe verplicht voelt. Dan mag je die kosten in jouw aangifte opvoeren.

Bewaar de bonnen en betaalbewijzen, en zorg dat de betaling van jouw rekening is gegaan. Dat is het bewijs dat de Belastingdienst wil zien.$t$);

select public.wegwijzer_seed_sectie('zorgkosten-belasting', 5, 'vraag', 'Ik betaal weinig belasting, heeft aftrek dan zin', $t$Vaak wel. Als de aftrek hoger is dan je inkomen kun je in aanmerking komen voor de tegemoetkoming specifieke zorgkosten, die de Belastingdienst automatisch uitbetaalt.

Je kunt bovendien tot vijf jaar terug een correctie indienen als je de aftrek eerder vergat.$t$);

select public.wegwijzer_seed_link('zorgkosten-belasting', 1, 'Belastingdienst: overzicht aftrekbare zorgkosten', 'https://www.belastingdienst.nl/wps/wcm/connect/nl/belastingaangifte/content/overzicht-zorgkosten-2026');
select public.wegwijzer_seed_link('zorgkosten-belasting', 2, 'Meerkosten.nl: rekenhulp zorgkosten', 'https://meerkosten.nl');

-- ---------------------------------------------------------------------------

select public.wegwijzer_seed_module(
  'financien', 'uitkering-en-inwonen', 'Uitkering, kostendelersnorm en inwonen',
  'Ga je bij elkaar wonen om de zorg vol te houden? Sinds 1 januari 2026 word je daarvoor niet meer gekort op de bijstand, en tellen vergoedingen en maaltijden niet mee.',
  array[
    'Per 1 januari 2026: tijdelijk inwonen om te zorgen leidt niet meer tot korting op de bijstand.',
    'Vergoedingen, giften en maaltijden die je voor de zorg krijgt tellen niet mee als inkomen.',
    'Giften tot 1.200 euro per jaar hoef je niet te melden.',
    'De kostendelersnorm geldt alleen voor huisgenoten van 27 jaar en ouder.'
  ],
  array['Participatiewet, artikel 22a', 'Participatiewet, artikel 31'],
  array['kostendelersnorm', 'bijstand', 'uitkering', 'inwonen', 'samenwonen', 'gekort', 'medebewoner', 'uitkering gekort', 'gaan samenwonen met moeder'],
  6, 5, true
);

select public.wegwijzer_seed_sectie('uitkering-en-inwonen', 1, 'uitleg', 'Wat de kostendelersnorm is', $t$Als er meer volwassenen in één huis wonen, gaat de bijstandsuitkering per persoon omlaag, omdat je kosten kunt delen. Bij twee volwassenen is dat 50 procent van de gehuwdennorm, bij drie 43,33 procent, bij vier 40 procent en bij vijf 38 procent.

Huisgenoten jonger dan 27 jaar tellen sinds 2023 niet mee. Ook studenten met studiefinanciering en kamerhuurders met een commercieel contract tellen niet als kostendeler.$t$);

select public.wegwijzer_seed_sectie('uitkering-en-inwonen', 2, 'wet', 'De verandering van 1 januari 2026', $t$Sinds 1 januari 2026 geldt: wie tijdelijk gaat inwonen bij iemand om voor die persoon te zorgen, wordt daarvoor niet meer gekort op de bijstandsuitkering. Ook inkomsten, vergoedingen of maaltijden die je vanwege die zorg krijgt, tellen niet mee voor de uitkering.

Daarnaast mag je giften ontvangen tot 1.200 euro per jaar zonder dat je die hoeft te melden. Boven dat bedrag meld je het bij de gemeente, die beoordeelt of het gevolgen heeft.$t$);

select public.wegwijzer_seed_sectie('uitkering-en-inwonen', 3, 'letop', 'Meld het altijd vooraf', $t$De nieuwe regels betekenen niet dat je niets hoeft te melden. Een verhuizing, een adreswijziging of inwoning moet je altijd doorgeven aan de gemeente en aan de instantie die je uitkering betaalt.

Doe het schriftelijk of via het klantportaal, en bewaar de bevestiging. Achteraf terugvorderen is een van de meest voorkomende problemen in dit soort situaties.$t$);

select public.wegwijzer_seed_sectie('uitkering-en-inwonen', 4, 'letop', 'Andere uitkeringen volgen niet automatisch', $t$De versoepeling geldt voor de bijstand (Participatiewet). Voor een AOW-uitkering, een Wajong-uitkering of een ANW-uitkering gelden eigen regels rond samenwonen en gezamenlijke huishouding.

Bij de AOW kan samenwonen betekenen dat je van een alleenstaandenuitkering naar de lagere gehuwdenuitkering gaat. Vraag dit vóór de verhuizing na bij de SVB.$t$);

select public.wegwijzer_seed_sectie('uitkering-en-inwonen', 5, 'vraag', 'En de huurtoeslag en zorgtoeslag', $t$Huurtoeslag kijkt naar het inkomen van alle bewoners. Gaat er iemand bij je wonen die geen (mede)huurder is, dan telt zijn inkomen meestal mee als medebewoner, wat de toeslag kan verlagen. Een uitzondering geldt in sommige gevallen voor inwonende kinderen.

Zorgtoeslag kijkt alleen naar jou en je toeslagpartner. Inwonen zonder partnerschap raakt de zorgtoeslag dus niet, maar samenwonen kan wel leiden tot toeslagpartnerschap. Reken het door met de proefberekening van de Belastingdienst vóór je verhuist.$t$);

select public.wegwijzer_seed_link('uitkering-en-inwonen', 1, 'Rijksoverheid: nieuwe regels bijstand 2026 en 2027', 'https://www.rijksoverheid.nl/onderwerpen/bijstand/nieuwe-regels-bijstand-2026-en-2027');
select public.wegwijzer_seed_link('uitkering-en-inwonen', 2, 'Belastingdienst: proefberekening toeslagen', 'https://www.belastingdienst.nl/wps/wcm/connect/nl/toeslagen/toeslagen');

-- ---------------------------------------------------------------------------

select public.wegwijzer_seed_module(
  'financien', 'dubbele-kinderbijslag', 'Dubbele kinderbijslag bij intensieve zorg',
  'Zorg je thuis voor een kind tussen 3 en 18 jaar dat intensieve zorg nodig heeft, dan kan de kinderbijslag verdubbelen. Met een Wlz-indicatie gaat het vaak automatisch.',
  array[
    'Voorwaarde: kind tussen 3 en 18 jaar, intensieve zorg nodig, minstens vier nachten per week thuis.',
    'Met een Wlz-indicatie sinds 1 juli 2024 gaat de toekenning automatisch.',
    'Zonder Wlz-indicatie vraagt de SVB advies aan het CIZ.',
    'Toekenning kan met terugwerkende kracht tot een half jaar.'
  ],
  array['Algemene Kinderbijslagwet, artikel 7a'],
  array['dubbele kinderbijslag', 'kinderbijslag', 'zorgkind', 'intensieve zorg kind', 'SVB', 'gehandicapt kind', 'extra kinderbijslag'],
  4, 6, false
);

select public.wegwijzer_seed_sectie('dubbele-kinderbijslag', 1, 'uitleg', 'Wanneer je er recht op hebt', $t$Je kind is tussen de 3 en 18 jaar, heeft intensieve zorg nodig en woont minstens vier nachten per week bij jou. Er moet een Wlz-indicatie zijn, of een positief advies van het CIZ.

Woont je kind doordeweeks elders, bijvoorbeeld op een zorginstelling, dan kan het nog steeds, maar moet je aantonen dat je voldoende aan het onderhoud bijdraagt. In 2026 gaat het om minimaal 1.434 euro per kwartaal.$t$);

select public.wegwijzer_seed_sectie('dubbele-kinderbijslag', 2, 'stappen', 'Zo vraag je het aan', $t$Kijk eerst of je kind een Wlz-indicatie heeft die is afgegeven op of na 1 juli 2024; dan krijg je de dubbele kinderbijslag automatisch.
Zo niet, vraag de dubbele kinderbijslag aan bij de SVB.
De SVB vraagt advies aan het CIZ; je krijgt van het CIZ een vragenlijst thuisgestuurd.
Vul die zo concreet mogelijk in: beschrijf een gemiddelde dag, uur voor uur.
Binnen acht weken na je aanvraag krijg je bericht.$t$);

select public.wegwijzer_seed_sectie('dubbele-kinderbijslag', 3, 'letop', 'Vraag ook naar extra kinderbijslag', $t$Naast de dubbele kinderbijslag bestaat er een extra tegemoetkoming voor thuiswonende kinderen die intensieve zorg nodig hebben. Die krijg je niet automatisch bij de dubbele kinderbijslag: dat is een aparte aanvraag bij de SVB.

Vraag er expliciet naar, want hij wordt vaak gemist.$t$);

select public.wegwijzer_seed_link('dubbele-kinderbijslag', 1, 'SVB: dubbele kinderbijslag', 'https://www.svb.nl/nl/kinderbijslag/dubbele-kinderbijslag');

-- ---------------------------------------------------------------------------

select public.wegwijzer_seed_module(
  'financien', 'erfenis-en-schenken', 'Erfenis, schenken en de erfbelasting',
  'Een veelgehoord misverstand: er zou een fiscale vrijstelling zijn voor wie zorgt. Die bestaat sinds 2015 niet meer. Wat er wél kan, en waar je op moet letten.',
  array[
    'De verhoogde partnervrijstelling voor een inwonend kind dat zorgt is per 2015 afgeschaft.',
    'Ouders en kinderen kunnen fiscaal nooit partners zijn, ook niet bij samenwonen.',
    'Zorg je voor iemand die geen familie in de rechte lijn is, dan kan een notarieel samenlevingscontract wél tot partnervrijstelling leiden.',
    'Betaal je kosten voor de ander? Leg vast of het een gift, een lening of een voorschot is.'
  ],
  array['Successiewet 1956, artikel 1a', 'Successiewet 1956, artikel 32'],
  array['erfbelasting', 'erfenis', 'schenken', 'vrijstelling', 'nalatenschap', 'testament', 'mantelzorgcompliment erfbelasting', 'partnervrijstelling', 'schenkbelasting'],
  6, 7, false
);

select public.wegwijzer_seed_sectie('erfenis-en-schenken', 1, 'letop', 'De vrijstelling die niet meer bestaat', $t$Tot 2015 kon een inwonend kind dat voor een ouder zorgde en een mantelzorgcompliment ontving, aanspraak maken op de hoge partnervrijstelling in de erfbelasting. Die koppeling is met de invoering van de Wmo 2015 vervallen en is niet in een andere vorm teruggekomen.

Kom je deze regeling nog tegen op internet, dan lees je verouderde informatie. Reken er niet mee.$t$);

select public.wegwijzer_seed_sectie('erfenis-en-schenken', 2, 'wet', 'Waarom een kind geen fiscale partner kan zijn', $t$De Successiewet sluit bloedverwanten in de rechte lijn uit als partner voor de erfbelasting. Een kind erft dus altijd als kind, met de kindvrijstelling, ook als het jarenlang inwoonde en zorgde.

Zorg je voor iemand die géén familie in de rechte lijn is, bijvoorbeeld een tante, een buurvrouw of een vriend, dan kan het anders liggen: met een notarieel samenlevingscontract en een gezamenlijke huishouding kan de partnervrijstelling in beeld komen. Laat dat door een notaris beoordelen.$t$);

select public.wegwijzer_seed_sectie('erfenis-en-schenken', 3, 'uitleg', 'Wat je wél kunt regelen', $t$Er zijn legale manieren om rekening te houden met de zorg die iemand geeft. Denk aan een legaat in het testament, jaarlijks schenken binnen de vrijstelling, of een schuldigerkenning op papier bij de notaris.

Ook kun je afspreken dat gemaakte kosten worden verrekend met de nalatenschap. Zet zulke afspraken op papier, liefst bij de notaris, en vertel het de andere erfgenamen. Onduidelijkheid hierover is een van de grootste oorzaken van ruzie na een overlijden.$t$);

select public.wegwijzer_seed_sectie('erfenis-en-schenken', 4, 'letop', 'Let op de rekening-courant met de zorgvrager', $t$Veel mensen betalen jarenlang boodschappen, kleding en rekeningen voor iemand voor. Zonder administratie is dat achteraf niet te bewijzen, en kan de Belastingdienst het als schenking zien.

Houd een simpel overzicht bij: datum, bedrag, waarvoor, en of het een gift of een voorschot is. Een gedeelde spreadsheet is genoeg.$t$);

select public.wegwijzer_seed_sectie('erfenis-en-schenken', 5, 'vraag', 'Mag ik geld opnemen van de rekening van mijn vader', $t$Alleen met een geldige machtiging of volmacht, en alleen voor uitgaven die in zijn belang zijn. Gebruik nooit contant geld zonder bonnetje.

Wordt er later bewind ingesteld of overlijdt hij, dan moet je kunnen laten zien waar het geld heen ging. Zie het onderwerp over volmacht en levenstestament voor hoe je dit netjes regelt.$t$);

select public.wegwijzer_seed_link('erfenis-en-schenken', 1, 'Belastingdienst: erf- en schenkbelasting', 'https://www.belastingdienst.nl/wps/wcm/connect/nl/erfbelasting/erfbelasting');
select public.wegwijzer_seed_link('erfenis-en-schenken', 2, 'Notaris.nl', 'https://www.notaris.nl');

-- Wegwijzer, inhoud 3 van 4: dementie en beslissen voor een ander.
-- Bijgewerkt: juli 2026.

-- ===========================================================================
-- THEMA: dementie
-- ===========================================================================

select public.wegwijzer_seed_module(
  'dementie', 'dementie-herkennen', 'De eerste signalen en de diagnose',
  'Vergeetachtigheid alleen is nog geen dementie. Wat je kunt opmerken, hoe je het bespreekbaar maakt en hoe de weg naar een diagnose loopt.',
  array[
    'Niet het vergeten zelf is het signaal, maar dat het dagelijks leven eronder lijdt.',
    'De huisarts is de eerste stap; die kan doorverwijzen naar de geheugenpoli.',
    'Een diagnose geeft toegang tot begeleiding, regelingen en de casemanager.',
    'Regel juridische zaken zolang iemand nog wilsbekwaam is: dat wordt vaak te lang uitgesteld.'
  ],
  array['Zorgstandaard Dementie'],
  array['dementie', 'alzheimer', 'vergeetachtig', 'geheugenproblemen', 'diagnose', 'geheugenpoli', 'dement', 'verward', 'signalen dementie', 'beginnende dementie'],
  6, 1, true
);

select public.wegwijzer_seed_sectie('dementie-herkennen', 1, 'uitleg', 'Waar je op let', $t$Iedereen vergeet weleens een naam. Bij dementie gaat het verder: afspraken die structureel wegvallen, hetzelfde verhaal binnen een half uur opnieuw, moeite met vertrouwde handelingen zoals koken of pinnen, de weg kwijtraken in bekende omgeving, of woorden niet meer kunnen vinden.

Vaak zijn de eerste signalen niet het geheugen maar het gedrag: initiatief dat wegvalt, prikkelbaarheid, achterdocht, of het vermijden van drukke situaties. Post die zich opstapelt en rekeningen die blijven liggen zijn een klassiek en praktisch signaal.$t$);

select public.wegwijzer_seed_sectie('dementie-herkennen', 2, 'stappen', 'Van vermoeden naar diagnose', $t$Schrijf twee tot drie weken op wat je opvalt, met datum en voorbeeld. Concreet gedrag zegt meer dan "het gaat achteruit".
Bespreek het met de persoon zelf, in rustige bewoordingen: "ik merk dat je vaker de weg kwijtraakt, zullen we het laten nakijken".
Maak samen een afspraak bij de huisarts en ga mee; vraag om een dubbele afspraak.
De huisarts doet lichamelijk onderzoek en een eerste geheugentest, en sluit andere oorzaken uit.
Zo nodig volgt verwijzing naar de geheugenpoli van het ziekenhuis of naar een specialist ouderengeneeskunde.
Vraag na de diagnose meteen om een casemanager dementie.$t$);

select public.wegwijzer_seed_sectie('dementie-herkennen', 3, 'letop', 'Andere oorzaken eerst uitsluiten', $t$Verwardheid en vergeetachtigheid kunnen ook komen door een blaasontsteking, uitdroging, een tekort aan vitamine B12, een traag werkende schildklier, depressie, gehoorverlies of bijwerkingen van medicijnen. Sommige daarvan zijn goed te behandelen.

Een plotselinge verwardheid binnen dagen is bovendien meestal een delier, geen dementie. Dat is een medisch spoedgeval: bel dan dezelfde dag de huisarts.$t$);

select public.wegwijzer_seed_sectie('dementie-herkennen', 4, 'letop', 'Regel het juridische nu', $t$Zolang iemand begrijpt wat hij tekent, kan hij zelf een volmacht of levenstestament regelen. Zodra dat niet meer kan, moet alles via de kantonrechter, wat trager, duurder en onpersoonlijker is.

Dit is de meest gemaakte fout in dit hele onderwerp: wachten tot het echt nodig is. Zie de onderwerpen over volmacht en over mentorschap.$t$);

select public.wegwijzer_seed_link('dementie-herkennen', 1, 'Alzheimer Nederland', 'https://www.alzheimer-nederland.nl');
select public.wegwijzer_seed_link('dementie-herkennen', 2, 'Alzheimer Telefoon, dag en nacht bereikbaar', 'https://www.alzheimer-nederland.nl/alzheimertelefoon');

-- ---------------------------------------------------------------------------

select public.wegwijzer_seed_module(
  'dementie', 'casemanager-dementie', 'De casemanager dementie',
  'Een vaste begeleider die met je meedenkt vanaf de diagnose: hij kent de weg, regelt hulp en is er ook voor jou. Vergoed uit de basisverzekering, zonder eigen risico.',
  array[
    'Vergoed vanuit de basisverzekering, als onderdeel van de wijkverpleging.',
    'Je betaalt geen eigen risico en geen eigen bijdrage.',
    'Aanvragen kan via de huisarts of rechtstreeks via de wijkverpleegkundige.',
    'De casemanager begeleidt uitdrukkelijk ook jou als beheerder, niet alleen de zieke.'
  ],
  array['Zorgverzekeringswet', 'Zorgstandaard Dementie'],
  array['casemanager', 'casemanagement dementie', 'dementieverpleegkundige', 'begeleiding dementie', 'wie helpt mij', 'vaste contactpersoon', 'dementieconsulent'],
  4, 2, true
);

select public.wegwijzer_seed_sectie('casemanager-dementie', 1, 'uitleg', 'Wat hij doet', $t$De casemanager is een gespecialiseerde verpleegkundige die je vanaf de diagnose volgt. Hij legt uit wat er gebeurt, denkt mee over dagindeling en veiligheid, regelt dagbesteding of thuiszorg, schakelt met de huisarts, en helpt bij het moment waarop thuis wonen niet meer gaat.

Hij is er nadrukkelijk ook voor jou: hoe houd je het vol, wanneer schakel je respijtzorg in, hoe ga je om met gedrag dat je niet begrijpt.$t$);

select public.wegwijzer_seed_sectie('casemanager-dementie', 2, 'stappen', 'Zo krijg je er een', $t$Vraag het aan de huisarts, direct na of zelfs al rond de diagnose.
Of bel zelf een thuiszorgorganisatie in de buurt en vraag naar casemanagement dementie.
De wijkverpleegkundige stelt de indicatie; een verwijzing van de huisarts is meestal niet verplicht.
Vraag je zorgverzekeraar welke aanbieders in jouw regio zijn gecontracteerd.
Klikt het niet, vraag dan om een andere casemanager. Dat mag.$t$);

select public.wegwijzer_seed_sectie('casemanager-dementie', 3, 'letop', 'Wachtlijsten zijn er wel', $t$In veel regio's is er een wachtlijst. Blijf niet wachten: vraag intussen bij het regionale dementienetwerk naar een dementieconsulent of ondersteuning vanuit de gemeente, en meld je bij een Alzheimer Café in de buurt.

Zet jezelf hoe dan ook alvast op de lijst. Terugtrekken kan altijd.$t$);

select public.wegwijzer_seed_link('casemanager-dementie', 1, 'Dementienetwerk: casemanagement in jouw regio', 'https://dementienetwerk.nl');

-- ---------------------------------------------------------------------------

select public.wegwijzer_seed_module(
  'dementie', 'omgaan-met-verandering', 'Omgaan met veranderend gedrag',
  'Boosheid, achterdocht, dwalen, dezelfde vraag voor de twintigste keer. Waarom het gebeurt en wat er in de praktijk helpt.',
  array[
    'Gedrag is communicatie: er zit bijna altijd een behoefte of een prikkel achter.',
    'Corrigeren en bewijzen leveren werkt averechts; meegaan in de beleving werkt meestal wel.',
    'Vaste ritmes, rust en herkenbaarheid halen de spanning eruit.',
    'Verandert gedrag plotseling, denk dan eerst aan pijn, infectie of medicatie.'
  ],
  array[]::text[],
  array['gedrag', 'boos', 'agressie', 'achterdocht', 'dwalen', 'onrust', 'herhalen', 'schelden', 'ontkennen', 'omgaan met dementie', 'communicatie dementie'],
  6, 3, false
);

select public.wegwijzer_seed_sectie('omgaan-met-verandering', 1, 'uitleg', 'Waarom het gebeurt', $t$Bij dementie verdwijnt langzaam het vermogen om de wereld te ordenen. Wat overblijft is gevoel: veiligheid of onveiligheid, erbij horen of buitengesloten worden. Gedrag dat wij "lastig" noemen, is meestal een poging om iets op te lossen: houvast zoeken, weg willen uit een situatie die niet klopt, of aandacht vragen voor iets wat pijn doet.

Achterdocht over gestolen spullen komt vaak voort uit het niet meer kunnen terugvinden ervan. Dwalen komt vaak voort uit een oud, vertrouwd doel: naar het werk, naar huis, de kinderen ophalen.$t$);

select public.wegwijzer_seed_sectie('omgaan-met-verandering', 2, 'stappen', 'Wat in de praktijk helpt', $t$Ga niet in discussie en lever geen bewijs; erken het gevoel: "wat vervelend dat je je portemonnee niet kunt vinden, ik zoek mee".
Stel één vraag tegelijk, in korte zinnen, en geef tijd om te antwoorden.
Houd vaste tijden aan voor opstaan, eten en naar bed; ritme geeft rust.
Beperk prikkels: zet de tv uit als je praat, laat niet iedereen tegelijk langskomen.
Leid af in plaats van te verbieden: samen koffiezetten in plaats van "je mag niet naar buiten".
Schrijf op wanneer het misgaat; vaak zie je na een week een patroon, bijvoorbeeld vermoeidheid aan het eind van de middag.$t$);

select public.wegwijzer_seed_sectie('omgaan-met-verandering', 3, 'letop', 'Plotselinge verandering is een medisch signaal', $t$Wordt iemand binnen enkele dagen veel onrustiger, angstiger of suffer, dan is dat zelden "de dementie die verergert". Denk aan pijn, een blaasontsteking, verstopping, uitdroging, een val of een nieuw medicijn.

Bel dan de huisarts. Onbehandelde pijn is een van de meest gemiste oorzaken van onrust.$t$);

select public.wegwijzer_seed_sectie('omgaan-met-verandering', 4, 'voorbeeld', 'Steeds naar huis willen, terwijl ze thuis is', $t$"Ik wil naar huis" gaat meestal niet over het gebouw, maar over een gevoel van veiligheid dat weg is. Uitleggen dat ze thuis is helpt niet en maakt het vaak erger.

Wat wel werkt: bevestigen ("je wilt naar huis, naar je moeder"), meegaan in het verhaal, en dan afleiden naar iets vertrouwds: samen thee zetten, een fotoalbum, een jas aan en een rondje om het blok en weer terug.$t$);

select public.wegwijzer_seed_link('omgaan-met-verandering', 1, 'Alzheimer Nederland: omgaan met dementie', 'https://www.alzheimer-nederland.nl/dementie/omgaan-met-dementie');

-- ---------------------------------------------------------------------------

select public.wegwijzer_seed_module(
  'dementie', 'wet-zorg-en-dwang', 'Wet zorg en dwang: wat mag wel en niet',
  'Deur op slot, medicijnen door de appelmoes, cameratoezicht: zorg waar iemand zich tegen verzet heet onvrijwillige zorg. Daar gelden strikte regels voor, ook thuis.',
  array[
    'Uitgangspunt is "nee, tenzij": onvrijwillige zorg mag alleen als het echt niet anders kan.',
    'De wet geldt ook thuis, niet alleen in het verpleeghuis.',
    'Er moet een stappenplan worden doorlopen, met externe deskundigen erbij.',
    'Er is een gratis, onafhankelijke cliëntenvertrouwenspersoon Wzd waar jij ook terecht kunt.'
  ],
  array['Wet zorg en dwang psychogeriatrische en verstandelijk gehandicapte cliënten'],
  array['wet zorg en dwang', 'wzd', 'onvrijwillige zorg', 'dwang', 'deur op slot', 'vrijheidsbeperking', 'medicijnen verstoppen', 'fixatie', 'camera', 'gedwongen opname', 'bopz'],
  6, 4, false
);

select public.wegwijzer_seed_sectie('wet-zorg-en-dwang', 1, 'wet', 'Wat onvrijwillige zorg is', $t$De Wet zorg en dwang geldt sinds 2020 voor mensen met dementie of een verstandelijke beperking. Onvrijwillige zorg is zorg waar de cliënt of zijn vertegenwoordiger niet mee instemt, of waartegen de cliënt zich verzet.

Voorbeelden: de voordeur op slot, een bedhek, medicatie die het gedrag beïnvloedt, cameratoezicht, beperken van bezoek, of eten en drinken toedienen tegen de wil. Ook thuis, ook door familie, valt dit onder de wet zodra er beroepsmatige zorg bij betrokken is.$t$);

select public.wegwijzer_seed_sectie('wet-zorg-en-dwang', 2, 'uitleg', 'Nee, tenzij', $t$Het uitgangspunt is dat onvrijwillige zorg niet mag. Alleen als er ernstig nadeel dreigt en er geen enkel alternatief is, mag het, zo kort en licht mogelijk, en met een concreet plan om het weer af te bouwen.

Voordat het mag, moet een stappenplan worden doorlopen: overleg met de zorgverantwoordelijke, een deskundige van een andere discipline, en bij langer durende maatregelen een externe deskundige. De Wzd-functionaris ziet erop toe.$t$);

select public.wegwijzer_seed_sectie('wet-zorg-en-dwang', 3, 'stappen', 'Wat je kunt doen als je het er niet mee eens bent', $t$Vraag om het zorgplan en om de onderbouwing van de maatregel; die moet op papier staan.
Vraag welke alternatieven zijn geprobeerd en waarom die niet werkten.
Vraag naar de afbouwafspraken en de evaluatiedatum.
Schakel de cliëntenvertrouwenspersoon Wzd in: gratis, onafhankelijk, en ook voor familie.
Kom je er niet uit, dien dan een klacht in bij de klachtencommissie onvrijwillige zorg.$t$);

select public.wegwijzer_seed_sectie('wet-zorg-en-dwang', 4, 'letop', 'Ook als familie zit je aan regels vast', $t$De verleiding is groot om zelf de deur op slot te doen of medicijnen door het eten te verstoppen. Als er professionele zorg betrokken is, moet dat in het zorgplan staan en het stappenplan doorlopen zijn.

Doe dit dus niet op eigen houtje, maar bespreek het met de casemanager of de huisarts. Zij kunnen het netjes vastleggen, en jou beschermen tegen verwijten achteraf.$t$);

select public.wegwijzer_seed_link('wet-zorg-en-dwang', 1, 'Dwang in de zorg: informatie over de Wzd', 'https://www.dwangindezorg.nl');

-- ---------------------------------------------------------------------------

select public.wegwijzer_seed_module(
  'dementie', 'naar-het-verpleeghuis', 'Wlz-indicatie en de stap naar het verpleeghuis',
  'Als thuis wonen niet meer gaat: hoe je een Wlz-indicatie aanvraagt bij het CIZ, welke keuzes je daarna hebt en hoe de wachtlijst werkt.',
  array[
    'De Wlz-indicatie vraag je aan bij het CIZ; dat mag ook zonder verwijzing.',
    'Het CIZ beslist in principe binnen zes weken, bij spoed veel sneller.',
    'Met een indicatie kun je kiezen: opname, of zorg thuis via vpt, mpt of pgb.',
    'Wachten kan lang duren; vraag naar overbruggingszorg en actieve wachtstatus.'
  ],
  array['Wet langdurige zorg, artikel 3.2.1'],
  array['verpleeghuis', 'wlz', 'ciz', 'indicatie', 'opname', 'wachtlijst', 'zorgprofiel', 'niet meer thuis', 'zorgkantoor', 'volledig pakket thuis', 'vpt', 'mpt'],
  7, 5, true
);

select public.wegwijzer_seed_sectie('naar-het-verpleeghuis', 1, 'uitleg', 'Wanneer de Wlz aan de orde is', $t$De Wet langdurige zorg is bedoeld voor mensen die blijvend 24 uur per dag zorg in de nabijheid of permanent toezicht nodig hebben. Bij dementie is dat vaak het geval als iemand niet meer alleen gelaten kan worden.

Het CIZ kijkt naar de blijvende behoefte, niet naar wat er nu toevallig geregeld is. Dat jij het nu nog opvangt, betekent niet dat de indicatie wordt afgewezen; het gaat om wat er nodig zou zijn zonder jou.$t$);

select public.wegwijzer_seed_sectie('naar-het-verpleeghuis', 2, 'stappen', 'De aanvraag bij het CIZ', $t$Vraag aan via de site van het CIZ, of bel; de huisarts of casemanager kan helpen.
Voeg medische informatie bij: de diagnose, brieven van de specialist, het zorgplan.
Beschrijf een gewone dag en een gewone nacht, uur voor uur, inclusief wat jij doet.
Het CIZ neemt contact op voor een gesprek, meestal telefonisch of thuis.
Binnen zes weken volgt het besluit met een zorgprofiel.
Neem daarna contact op met het zorgkantoor voor de uitvoering.$t$);

select public.wegwijzer_seed_sectie('naar-het-verpleeghuis', 3, 'uitleg', 'Je hoeft niet meteen te verhuizen', $t$Met een Wlz-indicatie kun je kiezen. Opname in een instelling is één optie. Daarnaast bestaat het volledig pakket thuis (alle zorg thuis geleverd door één aanbieder), het modulair pakket thuis (losse onderdelen) en het pgb, waarmee je de zorg zelf inkoopt.

Combineren kan ook. Veel mensen kiezen eerst voor zorg thuis en verhuizen later. De indicatie blijft geldig, dus je hoeft de aanvraag niet opnieuw te doen.$t$);

select public.wegwijzer_seed_sectie('naar-het-verpleeghuis', 4, 'uitleg', 'Wachten, en wat je in de tussentijd kunt vragen', $t$Na de indicatie kies je een voorkeurslocatie. Sta je op een wachtlijst, geef dan aan dat je "actief wachtend" bent als opname op korte termijn nodig is; dat is iets anders dan wachten uit voorkeur.

Vraag het zorgkantoor om overbruggingszorg: extra thuiszorg, dagbesteding of logeeropvang tot er plek is. Daar heb je recht op, en het wordt lang niet altijd uit zichzelf aangeboden.$t$);

select public.wegwijzer_seed_sectie('naar-het-verpleeghuis', 5, 'letop', 'Denk aan de eigen bijdrage', $t$Bij opname betaal je een inkomens- en vermogensafhankelijke eigen bijdrage, die na verloop van tijd overgaat van de lage naar de hoge bijdrage. Die kan flink oplopen.

Laat het CAK vooraf een proefberekening maken, zeker als er een eigen woning of spaargeld is. Bij een sterk gedaald inkomen kun je om herberekening vragen.$t$);

select public.wegwijzer_seed_link('naar-het-verpleeghuis', 1, 'CIZ: Wlz-indicatie aanvragen', 'https://www.ciz.nl');
select public.wegwijzer_seed_link('naar-het-verpleeghuis', 2, 'Zorgkaart Nederland: verpleeghuizen vergelijken', 'https://www.zorgkaartnederland.nl');

-- ===========================================================================
-- THEMA: beslissen voor een ander
-- ===========================================================================

select public.wegwijzer_seed_module(
  'regelen', 'wilsbekwaamheid', 'Wilsbekwaam of niet, en wie beslist er dan',
  'Wilsbekwaamheid is geen aan-uitknop: het gaat per beslissing. Wie er mag beslissen als iemand het zelf niet meer kan, staat in een vaste volgorde in de wet.',
  array[
    'Wilsbekwaamheid wordt per beslissing beoordeeld, niet in het algemeen.',
    'Een diagnose dementie betekent niet automatisch wilsonbekwaam.',
    'De wet kent een vaste rangorde van vertegenwoordigers.',
    'De arts beoordeelt of iemand een specifieke beslissing kan overzien.'
  ],
  array['Burgerlijk Wetboek 7, artikel 465 (WGBO)'],
  array['wilsbekwaam', 'wilsonbekwaam', 'beslissen', 'vertegenwoordiger', 'wie beslist', 'toestemming geven', 'namens iemand', 'wgbo'],
  5, 1, false
);

select public.wegwijzer_seed_sectie('wilsbekwaamheid', 1, 'uitleg', 'Per beslissing bekeken', $t$Iemand kan prima begrijpen dat hij een pilletje krijgt tegen de pijn, en tegelijk niet meer overzien wat het betekent om het huis te verkopen. Daarom wordt wilsbekwaamheid steeds beoordeeld voor die ene beslissing, op dat moment.

De vraag is telkens: begrijpt iemand de informatie, kan hij de gevolgen overzien, en kan hij een keuze maken en die uitleggen. De behandelend arts beoordeelt dit bij medische beslissingen; de notaris doet dat bij een akte.$t$);

select public.wegwijzer_seed_sectie('wilsbekwaamheid', 2, 'wet', 'De rangorde van vertegenwoordigers', $t$Kan iemand een beslissing niet zelf nemen, dan bepaalt de wet wie dat wel mag, in deze volgorde: de curator of mentor die de rechter benoemde; anders de persoon die schriftelijk gemachtigd is (bijvoorbeeld in een levenstestament); anders de echtgenoot of partner; anders een ouder, kind, broer of zus.

De eerste die er is en die het wil doen, is de vertegenwoordiger. Zijn er meerdere kinderen, dan is er geen automatische rangorde: dat is precies waarom een schriftelijke machtiging zo waardevol is.$t$);

select public.wegwijzer_seed_sectie('wilsbekwaamheid', 3, 'letop', 'Ook een vertegenwoordiger betrekt de persoon zelf', $t$Een vertegenwoordiger beslist niet in plaats van, maar zo veel mogelijk samen met. De zorgverlener moet de persoon zelf blijven informeren op een manier die past, en verzet serieus nemen.

Verzet iemand zich tegen een ingrijpende behandeling, dan mag die in principe niet worden uitgevoerd, ook al geeft de vertegenwoordiger toestemming. Dat is een belangrijke bescherming, geen formaliteit.$t$);

select public.wegwijzer_seed_sectie('wilsbekwaamheid', 4, 'vraag', 'Kan ik nog een volmacht laten tekenen', $t$Dat kan zolang iemand die specifieke akte begrijpt. Een notaris zal dat zelf toetsen en zo nodig een arts om een oordeel vragen.

Wacht er niet mee. Bij een beginnende dementie is dit vaak nog goed mogelijk; een half jaar later niet meer. Dan resteert alleen de route via de kantonrechter.$t$);

-- ---------------------------------------------------------------------------

select public.wegwijzer_seed_module(
  'regelen', 'volmacht-en-levenstestament', 'Volmacht en levenstestament',
  'Met een levenstestament wijst iemand zélf aan wie zijn zaken regelt als hij dat niet meer kan. Dat scheelt een gang naar de rechter en veel discussie in de familie.',
  array[
    'Een testament gaat over na het overlijden, een levenstestament over de periode daarvóór.',
    'Je regelt er twee dingen in: geldzaken en beslissingen over zorg.',
    'Een notarieel levenstestament wordt opgenomen in het centraal register en wordt breed geaccepteerd.',
    'Banken accepteren een zelfgeschreven volmacht vaak niet; kies bij vermogen voor de notaris.'
  ],
  array['Burgerlijk Wetboek 3, titel 3 (volmacht)'],
  array['levenstestament', 'volmacht', 'machtiging', 'notaris', 'bankzaken regelen', 'zaakwaarnemer', 'gemachtigde', 'papieren regelen', 'testament'],
  6, 2, true
);

select public.wegwijzer_seed_sectie('volmacht-en-levenstestament', 1, 'uitleg', 'Het verschil met een testament', $t$Een testament regelt wat er na het overlijden gebeurt. Een levenstestament regelt de periode daarvóór: wie mag de bankzaken doen, het huis verkopen, de belastingaangifte indienen, en wie beslist er over medische behandelingen en de verhuizing naar een verpleeghuis.

Het is een notariële akte, en wordt opgenomen in het Centraal Levenstestamentenregister. Zorgverleners, banken en instanties kunnen zo controleren dat hij bestaat.$t$);

select public.wegwijzer_seed_sectie('volmacht-en-levenstestament', 2, 'stappen', 'Wat je erin laat opnemen', $t$Wie de gemachtigde is, en wie de reserve als die persoon uitvalt.
Of de gemachtigde alleen mag handelen of alleen samen met een ander.
Vanaf wanneer de volmacht werkt: meteen, of pas bij een verklaring van een arts.
Geldzaken: bankrekeningen, verkoop van de woning, schenkingen, belastingzaken.
Zorg: wie beslist over behandelingen, opname en levenseinde.
Praktische wensen: huisdier, woning, uitvaart, welke zorginstelling wel of niet.
Of de gemachtigde verantwoording moet afleggen, en aan wie.$t$);

select public.wegwijzer_seed_sectie('volmacht-en-levenstestament', 3, 'letop', 'Een briefje van de keukentafel is niet genoeg', $t$Een onderhandse volmacht, dus zelfgeschreven en ondertekend, is juridisch geldig, maar banken, notarissen en verzekeraars accepteren hem vaak niet, zeker niet bij grotere bedragen of bij verkoop van een woning.

Is er een eigen woning, spaargeld of een onderneming, kies dan voor de notaris. De kosten zijn beperkt vergeleken met wat een bewindvoering jaarlijks kost.$t$);

select public.wegwijzer_seed_sectie('volmacht-en-levenstestament', 4, 'letop', 'Leg verantwoording vast, ook binnen de familie', $t$Word je gemachtigde, houd dan een eenvoudige administratie bij: wat er binnenkwam, wat eruit ging, waarvoor. Deel dat één of twee keer per jaar met de andere kinderen.

Dat is geen wantrouwen maar zelfbescherming. De meeste conflicten over geld tussen broers en zussen ontstaan niet door fraude, maar door onduidelijkheid.$t$);

select public.wegwijzer_seed_link('volmacht-en-levenstestament', 1, 'Notaris.nl: levenstestament', 'https://www.notaris.nl/levenstestament');

-- ---------------------------------------------------------------------------

select public.wegwijzer_seed_module(
  'regelen', 'mentorschap-bewind-curatele', 'Mentorschap, bewind en curatele',
  'Als er geen volmacht is en iemand kan zijn zaken niet meer overzien, benoemt de kantonrechter een beschermer. Bewind gaat over geld, mentorschap over zorg, curatele over allebei.',
  array[
    'Bewind: geldzaken. Mentorschap: zorg en behandeling. Curatele: beide, en het zwaarst.',
    'Je vraagt het aan bij de kantonrechter; een advocaat is niet nodig.',
    'Er zijn eenmalige griffiekosten en meestal een jaarlijkse beloning voor de bewindvoerder.',
    'Curatele wordt openbaar gepubliceerd; bewind en mentorschap alleen op verzoek.'
  ],
  array['Burgerlijk Wetboek 1, titel 16, 19 en 20'],
  array['mentorschap', 'bewind', 'bewindvoering', 'curatele', 'kantonrechter', 'onder bewind stellen', 'beschermingsbewind', 'financien overnemen', 'rechter aanvragen'],
  6, 3, false
);

select public.wegwijzer_seed_sectie('mentorschap-bewind-curatele', 1, 'uitleg', 'Welke maatregel waarvoor', $t$Bewind is bedoeld voor mensen die hun financiën niet meer kunnen overzien. De bewindvoerder beheert het geld en de bezittingen; de persoon blijft verder handelingsbekwaam.

Mentorschap gaat over persoonlijke zaken: verzorging, verpleging, behandeling en begeleiding. De mentor beslist daarover, zo veel mogelijk samen met de betrokkene.

Curatele is de zwaarste maatregel: geld én persoonlijke zaken, en de persoon wordt handelingsonbekwaam. Die wordt alleen ingezet als het echt niet anders kan.$t$);

select public.wegwijzer_seed_sectie('mentorschap-bewind-curatele', 2, 'stappen', 'Zo vraag je het aan', $t$Download het aanvraagformulier van rechtspraak.nl voor de gewenste maatregel.
Laat het zo mogelijk mede ondertekenen door de betrokkene en door de andere kinderen; dat voorkomt een zitting vol discussie.
Voeg een medische verklaring bij van een arts die niet de behandelend arts is.
Stuur het naar de rechtbank in het arrondissement waar de betrokkene woont.
De kantonrechter houdt meestal een zitting, vaak op locatie als iemand niet kan reizen.
Na benoeming leg je jaarlijks rekening en verantwoording af bij de rechtbank.$t$);

select public.wegwijzer_seed_sectie('mentorschap-bewind-curatele', 3, 'uitleg', 'Familie of een professional', $t$Een familielid kan bewindvoerder of mentor worden; dat is gratis, afgezien van de griffiekosten. Een professionele bewindvoerder rekent een jaarlijkse beloning, die bij een laag inkomen vaak via de bijzondere bijstand vergoed wordt.

Kies bewust. Familie is goedkoper en dichterbij, maar de combinatie van zorgen, beslissen en verantwoorden is zwaar en kan de verhouding met broers en zussen belasten.$t$);

select public.wegwijzer_seed_sectie('mentorschap-bewind-curatele', 4, 'letop', 'Een levenstestament gaat meestal voor', $t$Is er een geldig levenstestament, dan zal de kantonrechter terughoudend zijn met het instellen van bewind of mentorschap. De wens van de betrokkene zelf weegt zwaar.

Dat is precies het argument om het levenstestament op tijd te regelen: het houdt de zeggenschap in de familie en scheelt jaarlijkse verantwoording aan de rechtbank.$t$);

select public.wegwijzer_seed_link('mentorschap-bewind-curatele', 1, 'Rechtspraak.nl: curatele, bewind en mentorschap', 'https://www.rechtspraak.nl/Onderwerpen/curatele-bewind-en-mentorschap');

-- ---------------------------------------------------------------------------

select public.wegwijzer_seed_module(
  'regelen', 'wilsverklaring-en-behandelverbod', 'Wilsverklaring, behandelverbod en het levenseinde',
  'Op papier vastleggen welke behandelingen iemand niet meer wil. Een schriftelijk behandelverbod moet een arts opvolgen; een euthanasieverzoek is een verzoek, geen recht.',
  array[
    'Een schriftelijk behandelverbod is bindend voor de arts.',
    'Een euthanasieverklaring is een verzoek; geen arts is verplicht eraan mee te werken.',
    'Bespreek de verklaring met de huisarts en laat hem in het dossier opnemen.',
    'Herhaal het gesprek: bij dementie telt hoe iemand er nú over praat ook mee.'
  ],
  array['Burgerlijk Wetboek 7, artikel 450 lid 3', 'Wet toetsing levensbeëindiging op verzoek'],
  array['wilsverklaring', 'behandelverbod', 'euthanasie', 'niet reanimeren', 'levenseinde', 'reanimatiepenning', 'palliatieve sedatie', 'donorcodicil', 'niet meer behandelen'],
  6, 4, false
);

select public.wegwijzer_seed_sectie('wilsverklaring-en-behandelverbod', 1, 'wet', 'Het behandelverbod is bindend', $t$In de wet staat dat een arts een schriftelijke wilsverklaring waarin een behandeling wordt geweigerd, moet opvolgen als de patiënt zelf niet meer kan beslissen. Alleen met gegronde redenen mag hij daarvan afwijken.

Zo'n verklaring moet dus concreet zijn. "Ik wil niet aan de slangen" is te vaag. Schrijf op om welke situaties het gaat: geen ziekenhuisopname meer, geen antibiotica bij een longontsteking, geen sondevoeding, niet reanimeren.$t$);

select public.wegwijzer_seed_sectie('wilsverklaring-en-behandelverbod', 2, 'uitleg', 'Euthanasie ligt anders', $t$Een euthanasieverklaring legt vast dat iemand onder bepaalde omstandigheden om levensbeëindiging vraagt. Maar geen arts is verplicht daaraan mee te werken; het blijft een verzoek, dat aan strikte zorgvuldigheidseisen moet voldoen.

Bij dementie is dit extra ingewikkeld: een arts moet ook op het moment zelf kunnen vaststellen dat er sprake is van ondraaglijk en uitzichtloos lijden. Bespreek dit daarom vroeg en herhaald met de huisarts, en leg de gesprekken vast.$t$);

select public.wegwijzer_seed_sectie('wilsverklaring-en-behandelverbod', 3, 'stappen', 'Zo maak je het bruikbaar', $t$Gebruik een model, bijvoorbeeld van de Patiëntenfederatie of de NVVE, en maak het concreet.
Laat de verklaring dateren en ondertekenen door de persoon zelf.
Bespreek hem met de huisarts en vraag of hij in het dossier wordt opgenomen.
Geef een kopie aan de vertegenwoordiger en aan de kinderen.
Neem hem mee bij ziekenhuisopname; ga er niet vanuit dat men hem kent.
Herbevestig hem elke één tot twee jaar met een nieuwe datum en handtekening.$t$);

select public.wegwijzer_seed_sectie('wilsverklaring-en-behandelverbod', 4, 'letop', 'Niet reanimeren in acute situaties', $t$In een noodsituatie heeft de ambulance geen tijd om papieren te zoeken. Wil iemand echt niet gereanimeerd worden, dan is een zichtbaar niet-reanimerenpenning of een goed vindbare verklaring bij de voordeur belangrijk.

Bespreek ook met de thuiszorg en het verpleeghuis wat er moet gebeuren, en of het in hun dossier staat.$t$);

select public.wegwijzer_seed_link('wilsverklaring-en-behandelverbod', 1, 'Thuisarts.nl: wilsverklaring', 'https://www.thuisarts.nl');

-- ---------------------------------------------------------------------------

select public.wegwijzer_seed_module(
  'regelen', 'dossier-en-privacy', 'Informatie krijgen en het dossier inzien',
  'Artsen mogen niet zomaar met je praten, ook al zorg je dagelijks. Hoe je wel aan informatie komt, en welke rechten een vertegenwoordiger heeft.',
  array[
    'Het beroepsgeheim geldt ook richting familie; toestemming van de patiënt is de sleutel.',
    'Als vertegenwoordiger heb je recht op de informatie die je nodig hebt om te beslissen.',
    'Laat vastleggen wie contactpersoon is en dat er informatie gedeeld mag worden.',
    'Je mag als naaste altijd informatie gééven aan een arts, ook zonder toestemming.'
  ],
  array['Burgerlijk Wetboek 7, artikel 457 en 465 (WGBO)', 'Algemene verordening gegevensbescherming'],
  array['dossier', 'inzage', 'privacy', 'beroepsgeheim', 'arts wil niets zeggen', 'medische gegevens', 'contactpersoon', 'informatie krijgen', 'avg'],
  5, 5, false
);

select public.wegwijzer_seed_sectie('dossier-en-privacy', 1, 'uitleg', 'Waarom je niets te horen krijgt', $t$Zorgverleners hebben een beroepsgeheim. Zonder toestemming van de patiënt mogen zij geen medische informatie delen, ook niet met een echtgenoot of kind dat dag en nacht zorgt.

De oplossing is simpel en wordt vaak vergeten: laat de patiënt, zolang dat kan, opnemen in het dossier wie de contactpersoon is en dat er met die persoon informatie gedeeld mag worden. Eén zin bij de huisarts kan je jaren gedoe besparen.$t$);

select public.wegwijzer_seed_sectie('dossier-en-privacy', 2, 'wet', 'De rechten van een vertegenwoordiger', $t$Kan iemand zelf niet meer beslissen, dan heeft de vertegenwoordiger recht op de informatie die nodig is om die beslissingen te kunnen nemen, en op inzage in het dossier voor zover dat daarvoor nodig is.

Dat is dus geen vrijbrief voor het hele dossier. Een arts mag informatie achterhouden die niets met de beslissing te maken heeft, of die de patiënt uitdrukkelijk niet wilde delen.$t$);

select public.wegwijzer_seed_sectie('dossier-en-privacy', 3, 'stappen', 'Praktisch regelen', $t$Laat de zorgvrager bij de huisarts, het ziekenhuis en de thuiszorg vastleggen wie contactpersoon is.
Vraag om een korte notitie in het dossier dat informatie met jou gedeeld mag worden.
Neem bij afspraken je machtiging of levenstestament mee.
Vraag na elk gesprek om een schriftelijke samenvatting of gebruik het patiëntenportaal.
Ben je vertegenwoordiger, zeg dat er dan expliciet bij; anders weten ze het niet.$t$);

select public.wegwijzer_seed_sectie('dossier-en-privacy', 4, 'vraag', 'Mag ik zelf iets vertellen aan de arts', $t$Ja, altijd. Het beroepsgeheim beperkt wat de arts aan jou vertelt, niet wat jij aan de arts vertelt.

Merk je dat iemand thuis veel slechter functioneert dan tijdens het spreekuur, schrijf dat dan op en geef het af of mail het. Artsen zijn er blij mee, en het beïnvloedt de zorg vaak direct.$t$);

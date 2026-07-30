-- Wegwijzer, inhoud 2 van 4: wonen en werk.
-- Bijgewerkt: juli 2026.

-- ===========================================================================
-- THEMA: wonen en verbouwen
-- ===========================================================================

select public.wegwijzer_seed_module(
  'wonen', 'mantelzorgwoning', 'Mantelzorgwoning: een woning in de tuin of aan het huis',
  'Een aparte woonruimte bij je huis, zodat je dichtbij kunt zorgen zonder op elkaars lip te zitten. In veel gevallen mag dat zonder omgevingsvergunning, mits je aan de voorwaarden voldoet.',
  array[
    'Een verplaatsbare mantelzorgwoning tot 100 m2 in het achtererfgebied mag meestal vergunningvrij.',
    'Er moet een aantoonbare zorgbehoefte zijn, blijkend uit een verklaring van bijvoorbeeld huisarts of wijkverpleegkundige.',
    'Vergunningvrij betekent niet regelvrij: de bouwtechnische eisen gelden altijd.',
    'Als de zorg stopt, moet de woonfunctie weer weg; de verplaatsbare unit moet worden verwijderd.'
  ],
  array['Besluit bouwwerken leefomgeving (Bbl)', 'Omgevingswet'],
  array['mantelzorgwoning', 'mantelwoning', 'kangoeroewoning', 'zorgwoning', 'zorgunit', 'unit in de tuin', 'tiny house', 'prefab woning', 'aanbouw', 'bijgebouw', 'garage ombouwen', 'moeder in de tuin', 'vergunningvrij bouwen', 'mantelzorgverklaring'],
  8, 1, true
);

select public.wegwijzer_seed_sectie('mantelzorgwoning', 1, 'uitleg', 'Wat het is', $t$Een mantelzorgwoning is zelfstandige woonruimte bij een bestaande woning: een unit in de tuin, een aanbouw, een omgebouwde garage of een verbouwde zolder met eigen keuken, douche en toilet.

Het idee is nabijheid met behoud van privacy. Degene die zorg nodig heeft woont in de unit en jij in het hoofdhuis, of andersom: jij trekt in de unit en de zorgvrager blijft in het vertrouwde huis. Beide richtingen zijn toegestaan.$t$);

select public.wegwijzer_seed_sectie('mantelzorgwoning', 2, 'wet', 'Wanneer het vergunningvrij mag', $t$Sinds de Omgevingswet (2024) staan de regels in het Besluit bouwwerken leefomgeving. Voor een geheel of gedeeltelijk verplaatsbare mantelzorgvoorziening geldt: niet groter dan 100 m2, in het achtererfgebied, en op de grond.

Verder gelden de gewone maten voor bijbehorende bouwwerken: maximaal 5 meter hoog, en op meer dan 4 meter van het hoofdgebouw geldt een lagere dakrandhoogte. Ook mag niet het hele erf volgebouwd worden: er geldt een maximum aan bebouwd oppervlak in het achtererfgebied, waarbij bestaande schuren en garages meetellen.

Bouw je iets vasts in plaats van een verplaatsbare unit, dan gelden de normale grenzen voor bijbehorende bouwwerken en kan een vergunning wél nodig zijn.$t$);

select public.wegwijzer_seed_sectie('mantelzorgwoning', 3, 'stappen', 'Zo pak je het aan', $t$Bepaal eerst je achtererfgebied: het deel van het erf achter de voorgevelrooilijn, minimaal 1 meter achter de voorkant van het huis.
Tel op wat er al staat aan schuren, garages en overkappingen; dat telt mee voor het maximum.
Vraag een verklaring van de zorgbehoefte bij de huisarts, wijkverpleegkundige of een andere sociaal-medisch adviseur.
Bel het omgevingsloket van je gemeente en leg het plan voor; vraag om een schriftelijke bevestiging dat het vergunningvrij is.
Regel pas daarna de unit, de fundering, de aansluitingen en de verzekering.
Meld de nieuwe bewoner aan op het adres bij de gemeente.$t$);

select public.wegwijzer_seed_sectie('mantelzorgwoning', 4, 'letop', 'Vergunningvrij is niet regelvrij', $t$Ook zonder vergunning gelden de technische eisen: constructieve veiligheid, brandveiligheid, isolatie, ventilatie en daglicht. De gemeente kan hier achteraf op handhaven.

Daarnaast kunnen er andere regels spelen die vergunningvrij bouwen blokkeren: een monument, een beschermd stads- of dorpsgezicht, of regels van het waterschap. Ook je hypotheekverstrekker en opstalverzekeraar wil je vooraf informeren.$t$);

select public.wegwijzer_seed_sectie('mantelzorgwoning', 5, 'letop', 'Wat er gebeurt als de zorg stopt', $t$De vrijstelling hangt aan de zorg. Stopt die, bijvoorbeeld door verhuizing naar een verpleeghuis of door overlijden, dan mag de ruimte niet als zelfstandige woning blijven bestaan.

Bij een verplaatsbare unit betekent dat: verwijderen. Bij een aanbouw: de zelfstandige woonfunctie eruit halen, dus keuken en badkamer weg. Houd daar rekening mee in je investering, en vraag na of je gemeente een overgangstermijn hanteert.$t$);

select public.wegwijzer_seed_sectie('mantelzorgwoning', 6, 'vraag', 'Wat doet het met belastingen en toeslagen', $t$Een mantelzorgwoning op je eigen perceel verhoogt meestal de WOZ-waarde, en daarmee de onroerendezaakbelasting. De rente van een lening voor de bouw is niet altijd aftrekbaar; laat dat narekenen.

Voor huurtoeslag en de bijstand telt vooral wie er op welk adres staat ingeschreven en of er sprake is van een zelfstandige woning met eigen voorzieningen. Zie het onderwerp over inwonen voor de gevolgen.$t$);

select public.wegwijzer_seed_link('mantelzorgwoning', 1, 'Informatiepunt Leefomgeving: bouwregels mantelzorgwoning', 'https://iplo.nl/thema/toepassing-regels-praktijk/mantelzorgwoning/bouwregels/');
select public.wegwijzer_seed_link('mantelzorgwoning', 2, 'Omgevingsloket: vergunningcheck', 'https://omgevingswet.overheid.nl');

-- ---------------------------------------------------------------------------

select public.wegwijzer_seed_module(
  'wonen', 'inwonen-bij-elkaar', 'Samen in één huis gaan wonen',
  'Bij elkaar intrekken maakt zorgen makkelijker, maar raakt je adres, je toeslagen, je uitkering en soms je erfenis. Dit is de checklist om vooraf langs te lopen.',
  array[
    'Schrijf je altijd in op het juiste adres; dat is wettelijk verplicht.',
    'Huurtoeslag kijkt naar het inkomen van medebewoners, zorgtoeslag alleen naar toeslagpartners.',
    'Voor de bijstand geldt sinds 2026 een uitzondering voor tijdelijk inwonen om te zorgen.',
    'Bij de AOW kan samenwonen leiden tot een lagere uitkering; check dit vooraf bij de SVB.'
  ],
  array['Wet basisregistratie personen', 'Participatiewet, artikel 22a', 'Wet op de huurtoeslag'],
  array['inwonen', 'samenwonen', 'intrekken bij moeder', 'adres wijzigen', 'medebewoner', 'huurtoeslag', 'inschrijven gemeente', 'twee huishoudens'],
  6, 2, false
);

select public.wegwijzer_seed_sectie('inwonen-bij-elkaar', 1, 'stappen', 'De checklist vóór de verhuizing', $t$Reken met de proefberekening van de Belastingdienst door wat er met huurtoeslag en zorgtoeslag gebeurt.
Meld het bij de instantie die een uitkering betaalt: gemeente, UWV of SVB.
Schrijf je in op het nieuwe adres bij de gemeente, binnen vijf dagen na de verhuizing.
Geef de verhuizing door aan de zorgverzekeraar, de huisarts en de apotheek.
Bij een huurwoning: informeer de verhuurder en vraag naar medehuurderschap.
Bij een koopwoning: informeer de hypotheekverstrekker en de opstalverzekeraar.$t$);

select public.wegwijzer_seed_sectie('inwonen-bij-elkaar', 2, 'uitleg', 'Toeslagpartner of medebewoner', $t$Dat onderscheid bepaalt bijna alles. Een toeslagpartner is bijvoorbeeld je echtgenoot, geregistreerd partner, of iemand met wie je samen een kind hebt of een notarieel samenlevingscontract. Een ouder en een meerderjarig kind worden in principe géén toeslagpartners, tenzij het kind ouder is dan 27 en er andere partnerindicaties zijn.

Een medebewoner is iemand die op je adres staat maar geen partner is. Voor de huurtoeslag telt het inkomen van medebewoners wel mee, voor de zorgtoeslag niet.$t$);

select public.wegwijzer_seed_sectie('inwonen-bij-elkaar', 3, 'letop', 'Twee adressen op één perceel', $t$Bij een zelfstandige mantelzorgwoning met eigen voordeur, keuken en badkamer kan de gemeente een apart huisnummer toekennen. Dan zijn het twee huishoudens en blijft ieders toeslag apart.

Zonder eigen huisnummer wonen jullie formeel op één adres, met alle gevolgen voor toeslagen en uitkeringen. Vraag hier vroeg naar bij de gemeente; achteraf regelen is veel lastiger.$t$);

select public.wegwijzer_seed_sectie('inwonen-bij-elkaar', 4, 'vraag', 'Kan ik gewoon blijven staan op mijn oude adres', $t$Nee. Je moet ingeschreven staan waar je feitelijk woont. Blijf je op een oud adres staan om toeslagen te behouden, dan is dat fraude en volgt terugvordering plus boete.

Verblijf je afwisselend, dan geldt: het adres waar je het grootste deel van de tijd slaapt. Twijfel je, bel dan de gemeente en vraag om een schriftelijke uitleg.$t$);

-- ---------------------------------------------------------------------------

select public.wegwijzer_seed_module(
  'wonen', 'woning-aanpassen', 'De woning aanpassen via de Wmo',
  'Traplift, drempels weg, een douche in plaats van een bad, beugels of een verhoogd toilet: aanpassingen om thuis te kunnen blijven wonen lopen via de gemeente.',
  array[
    'De gemeente kijkt eerst of verhuizen goedkoper is; dat heet het primaat van verhuizen.',
    'Kleine, algemeen gebruikelijke aanpassingen betaal je meestal zelf.',
    'Vraag altijd naar een ergotherapeut die meekijkt; dat versterkt je aanvraag.',
    'Bij een huurwoning heb je toestemming van de verhuurder nodig.'
  ],
  array['Wmo 2015, artikel 2.3.5'],
  array['woningaanpassing', 'traplift', 'drempels', 'douche', 'badkamer aanpassen', 'beugels', 'verhoogd toilet', 'rolstoel in huis', 'verbouwen wmo', 'ergotherapeut'],
  5, 3, false
);

select public.wegwijzer_seed_sectie('woning-aanpassen', 1, 'uitleg', 'Wat de gemeente kan vergoeden', $t$Denk aan een traplift, een verhoogd toilet, beugels, het weghalen van drempels, een oprijplaat, een douchezitje, of het ombouwen van een badkamer tot een instapdouche. Bij grotere aanpassingen kan de gemeente ook een uitbouw of een slaapkamer beneden vergoeden.

De gemeente kiest de goedkoopst passende oplossing. Dat mag ook een tweedehands traplift zijn, of een oplossing die je zelf niet had bedacht, als hij het probleem oplost.$t$);

select public.wegwijzer_seed_sectie('woning-aanpassen', 2, 'letop', 'Het primaat van verhuizen', $t$Gemeenten mogen bepalen dat verhuizen naar een geschikte woning voorgaat op een dure aanpassing. Krijg je dat te horen, vraag dan naar de onderbouwing en breng je eigen argumenten in: de mantelzorg die vlakbij woont, het sociale netwerk in de buurt, de kosten en de haalbaarheid van verhuizen op hoge leeftijd.

Die argumenten moeten meegewogen worden. Zet ze op papier in je persoonlijk plan.$t$);

select public.wegwijzer_seed_sectie('woning-aanpassen', 3, 'stappen', 'Zo verhoog je de kans van slagen', $t$Vraag de huisarts of wijkverpleegkundige om een korte brief over de beperkingen.
Vraag om een ergotherapeut die thuis komt kijken; zijn advies weegt zwaar.
Beschrijf concreet wat er misgaat: hoe vaak valt iemand, wat lukt niet meer, wat doe jij nu om het op te vangen.
Maak foto's van de knelpunten en voeg ze bij.
Zet in je aanvraag ook wat er gebeurt als er niets gebeurt: opname, val, uitval van jou.$t$);

select public.wegwijzer_seed_sectie('woning-aanpassen', 4, 'vraag', 'En bij een huurwoning', $t$Voor aanpassingen aan een huurwoning is toestemming van de verhuurder nodig. Woningcorporaties werken hier meestal aan mee, zeker bij aanpassingen die de woning geschikter maken voor ouderen.

Vraag ook naar het "opplussen" van de woning: veel corporaties hebben eigen budgetten voor beugels, drempelhulpen en verlichting, buiten de Wmo om.$t$);

-- ---------------------------------------------------------------------------

select public.wegwijzer_seed_module(
  'wonen', 'verhuizen-en-urgentie', 'Verhuizen, urgentie en wachtlijsten',
  'Soms is een andere woning de beste oplossing. Met een urgentieverklaring krijg je voorrang, en sommige gemeenten kennen voorrang voor wie dichter bij de zorg wil wonen.',
  array[
    'Urgentie vraag je aan bij de gemeente of de woningcorporatie, met medische onderbouwing.',
    'Sommige regio''s kennen een mantelzorgurgentie: voorrang om dichter bij elkaar te wonen.',
    'Een seniorenwoning of gelijkvloerse woning kan sneller beschikbaar zijn dan je denkt.',
    'Wachttijd telt vaak zwaarder dan urgentie; schrijf je hoe dan ook vast in.'
  ],
  array['Huisvestingswet 2014'],
  array['urgentie', 'urgentieverklaring', 'verhuizen', 'voorrang woning', 'seniorenwoning', 'gelijkvloers', 'wachtlijst', 'woningcorporatie', 'dichterbij wonen'],
  5, 4, false
);

select public.wegwijzer_seed_sectie('verhuizen-en-urgentie', 1, 'uitleg', 'Wanneer urgentie kans maakt', $t$Urgentie is bedoeld voor mensen die door omstandigheden buiten hun schuld dringend andere woonruimte nodig hebben. Medische urgentie speelt als de huidige woning aantoonbaar ongeschikt is en aanpassen geen optie of te duur is.

Belangrijk: eerst wordt gekeken of de Wmo het probleem kan oplossen. Een afwijzing van een woningaanpassing is daarom vaak juist het bewijsstuk dat je nodig hebt bij de urgentieaanvraag.$t$);

select public.wegwijzer_seed_sectie('verhuizen-en-urgentie', 2, 'uitleg', 'Voorrang om dichter bij de zorg te wonen', $t$Een groeiend aantal gemeenten en woningcorporaties kent een vorm van voorrang voor mensen die willen verhuizen om zorg te kunnen geven of ontvangen. De namen verschillen: mantelzorgurgentie, zorgurgentie of maatwerk.

De voorwaarden zijn stevig: aantoonbare zorgrelatie, meestal langer dan een half jaar en meer dan acht uur per week, en een verklaring van een arts of wijkverpleegkundige. Vraag bij de corporatie na of de regeling bestaat, en onder welke naam.$t$);

select public.wegwijzer_seed_sectie('verhuizen-en-urgentie', 3, 'stappen', 'Praktisch', $t$Schrijf je in bij alle woningcorporaties in de regio, ook als je nog twijfelt; inschrijfduur telt.
Vraag bij de gemeente op welke gronden urgentie wordt toegekend.
Verzamel de onderbouwing: medische verklaring, afwijzing woningaanpassing, bewijs van de zorgrelatie.
Kijk naar woonvormen die minder in trek zijn: benedenwoningen, seniorencomplexen, hofjes.
Meld je ook bij particuliere seniorenwoningen en zorgcoöperaties in de regio.$t$);

-- ---------------------------------------------------------------------------

select public.wegwijzer_seed_module(
  'wonen', 'huurwoning-en-overlijden', 'Huurwoning: medehuur en wat er gebeurt bij overlijden',
  'Woon je in de huurwoning van degene voor wie je zorgt, dan is medehuurderschap het verschil tussen blijven wonen en binnen twee maanden eruit moeten.',
  array[
    'Zonder medehuurderschap mag je na het overlijden van de huurder nog zes maanden blijven.',
    'Medehuur vraag je samen aan bij de verhuurder; die kan weigeren, dan beslist de rechter.',
    'Voorwaarde is meestal een duurzame gemeenschappelijke huishouding van twee jaar of langer.',
    'Voor kinderen die voor een ouder zorgen is medehuur juridisch lastig, maar niet onmogelijk.'
  ],
  array['Burgerlijk Wetboek 7, artikel 267', 'Burgerlijk Wetboek 7, artikel 268'],
  array['medehuur', 'medehuurderschap', 'huurwoning', 'overlijden huurder', 'huis uit', 'blijven wonen', 'huurcontract overnemen', 'inwonend kind'],
  5, 5, false
);

select public.wegwijzer_seed_sectie('huurwoning-en-overlijden', 1, 'wet', 'De hoofdregel', $t$Overlijdt de huurder, dan zet iemand die medehuurder is de huur gewoon voort. Ben je geen medehuurder, dan mag je de huur nog zes maanden voortzetten. Daarna moet je eruit, tenzij de rechter anders beslist.

Binnen die zes maanden kun je de rechter vragen de huur te mogen voortzetten. Je moet dan aantonen dat er sprake was van een duurzame gemeenschappelijke huishouding en dat je de huur kunt betalen.$t$);

select public.wegwijzer_seed_sectie('huurwoning-en-overlijden', 2, 'letop', 'Waarom het voor kinderen lastig is', $t$Rechters gaan er van oudsher van uit dat een kind dat bij een ouder woont dat tijdelijk doet, op weg naar een eigen leven. Dat heet geen duurzame gemeenschappelijke huishouding.

Zorg je al jaren voor je ouder, deel je de kosten, staan de rekeningen mede op jouw naam en heb je geen andere woning, dan kan het beeld kantelen. Verzamel dan bewijs: bankafschriften, brieven, de zorgindicatie, verklaringen van de huisarts en de buren.$t$);

select public.wegwijzer_seed_sectie('huurwoning-en-overlijden', 3, 'stappen', 'Regel het nu, niet straks', $t$Vraag samen schriftelijk medehuurderschap aan bij de verhuurder.
Voeg bewijs bij: inschrijving op het adres, gedeelde kosten, duur van de situatie.
Weigert de verhuurder, dan kun je binnen drie maanden naar de kantonrechter.
Doe dit zolang de huurder nog leeft; achteraf is de bewijslast veel zwaarder.
Twijfel je, vraag gratis advies bij het Juridisch Loket of de Woonbond.$t$);

select public.wegwijzer_seed_link('huurwoning-en-overlijden', 1, 'Woonbond: medehuurderschap', 'https://www.woonbond.nl');

-- ===========================================================================
-- THEMA: werk en verlof
-- ===========================================================================

select public.wegwijzer_seed_module(
  'werk', 'zorgverlof-kort', 'Calamiteitenverlof en kortdurend zorgverlof',
  'Voor acute situaties en voor korte periodes van noodzakelijke zorg. Calamiteitenverlof is voor de eerste uren, kortdurend zorgverlof voor de dagen daarna, met minimaal 70 procent loon.',
  array[
    'Calamiteitenverlof: kort, voor onvoorziene situaties, met volledig loon.',
    'Kortdurend zorgverlof: maximaal tweemaal je wekelijkse uren per 12 maanden.',
    'Je krijgt minimaal 70 procent van je loon, ten minste het minimumloon.',
    'Je werkgever mag alleen weigeren bij een zwaarwegend bedrijfsbelang.'
  ],
  array['Wet arbeid en zorg, hoofdstuk 4'],
  array['zorgverlof', 'kortdurend zorgverlof', 'calamiteitenverlof', 'verlof opnemen', 'vrij vragen werk', 'ziek familielid', 'werkgever weigert verlof', '70 procent loon'],
  6, 1, true
);

select public.wegwijzer_seed_sectie('zorgverlof-kort', 1, 'uitleg', 'Calamiteitenverlof: de eerste uren', $t$Calamiteitenverlof is bedoeld voor onvoorziene situaties die je direct moet oplossen: je moeder is gevallen, de thuiszorg komt niet opdagen, je moet acuut mee naar de spoedeisende hulp.

Het duurt zo kort als nodig: van een paar uur tot een paar dagen. Je krijgt je loon volledig doorbetaald. Meld het zo snel mogelijk bij je werkgever, telefonisch mag.$t$);

select public.wegwijzer_seed_sectie('zorgverlof-kort', 2, 'wet', 'Kortdurend zorgverlof: de weken erna', $t$Kortdurend zorgverlof is voor noodzakelijke zorg aan een zieke naaste die je zelf moet geven. Per twaalf maanden heb je recht op maximaal tweemaal het aantal uren dat je per week werkt. Werk je 32 uur, dan is dat 64 uur.

Je werkgever betaalt minimaal 70 procent van je loon door, en ten minste het minimumloon. In sommige cao's staat een hoger percentage. Je mag het opnemen per uur, per dag of aaneengesloten.$t$);

select public.wegwijzer_seed_sectie('zorgverlof-kort', 3, 'uitleg', 'Voor wie mag je het opnemen', $t$Voor je partner, je kind of je ouder, maar ook voor een broer of zus, een grootouder, kleinkind, huisgenoot of iemand anders met wie je een sociale relatie hebt, zolang de zorg redelijkerwijs door jou gegeven moet worden.

Die laatste categorie is ruim: een goede vriendin of de buurvrouw kan er ook onder vallen. Je moet wel kunnen uitleggen waarom juist jij die zorg geeft.$t$);

select public.wegwijzer_seed_sectie('zorgverlof-kort', 4, 'stappen', 'Zo vraag je het aan', $t$Meld vooraf, of anders zo snel mogelijk, dat je zorgverlof opneemt.
Zeg erbij hoe lang je verwacht weg te zijn en om wie het gaat.
Je hoeft geen medische gegevens te delen; de werkgever mag achteraf wel om aannemelijke informatie vragen, zoals een afsprakenkaart.
Zet het daarna kort op de mail, zodat de datum vastligt.
Houd zelf bij hoeveel uur je hebt opgenomen; die uren tellen op binnen twaalf maanden.$t$);

select public.wegwijzer_seed_sectie('zorgverlof-kort', 5, 'letop', 'Weigeren mag bijna niet', $t$Bij kortdurend zorgverlof kan de werkgever alleen vooraf weigeren als het bedrijf daardoor in ernstige problemen komt: een zwaarwegend bedrijfs- of dienstbelang. Dat is een hoge drempel, en de werkgever moet het onderbouwen.

Wordt het geweigerd en ben je het er niet mee eens, schakel dan de vakbond, een bedrijfsarts of het Juridisch Loket in. Ga niet zonder overleg wegblijven; dat kan tot ontslag leiden.$t$);

select public.wegwijzer_seed_link('zorgverlof-kort', 1, 'Rijksoverheid: zorgverlof', 'https://www.rijksoverheid.nl/onderwerpen/zorgverlof');

-- ---------------------------------------------------------------------------

select public.wegwijzer_seed_module(
  'werk', 'langdurend-zorgverlof', 'Langdurend zorgverlof',
  'Voor een langere periode van zorg voor iemand die levensbedreigend ziek is, of die ziek of hulpbehoevend is. Maximaal zes keer je wekelijkse uren per jaar, in principe onbetaald.',
  array[
    'Maximaal zesmaal het aantal uren dat je per week werkt, per 12 maanden.',
    'In principe onbetaald, tenzij je cao iets anders regelt.',
    'Dien het verzoek minimaal twee weken van tevoren schriftelijk in.',
    'Je kunt het spreiden: hele dagen, halve dagen of losse uren, in overleg.'
  ],
  array['Wet arbeid en zorg, artikel 5:9', 'Wet arbeid en zorg, artikel 5:11'],
  array['langdurend zorgverlof', 'lang verlof', 'onbetaald verlof', 'zorgverlof aanvragen', 'terminale zorg', 'levensbedreigend ziek', 'minder werken tijdelijk'],
  5, 2, false
);

select public.wegwijzer_seed_sectie('langdurend-zorgverlof', 1, 'wet', 'De omvang en de voorwaarden', $t$Per twaalf maanden heb je recht op maximaal zes keer het aantal uren dat je per week werkt. Bij een 36-urige werkweek is dat 216 uur.

Het verlof is bedoeld voor de noodzakelijke zorg aan een partner, kind, ouder of andere naaste die levensbedreigend ziek is, dan wel ziek of hulpbehoevend. Het loon wordt in principe niet doorbetaald. Kijk altijd in je cao: sommige cao's kennen wel (gedeeltelijke) doorbetaling.$t$);

select public.wegwijzer_seed_sectie('langdurend-zorgverlof', 2, 'stappen', 'Zo dien je het in', $t$Schrijf een kort verzoek: om wie het gaat, waarom de zorg nodig is, hoeveel uur en in welke periode.
Dien het minimaal twee weken van tevoren in, schriftelijk of per mail.
Stel een verdeling voor: bijvoorbeeld elke vrijdag vrij gedurende een half jaar.
De werkgever reageert binnen een week; zonder reactie gaat het verlof in zoals gevraagd.
Bespreek meteen hoe je werk wordt overgenomen; dat maakt toestemming makkelijker.$t$);

select public.wegwijzer_seed_sectie('langdurend-zorgverlof', 3, 'letop', 'Denk aan de gevolgen voor je inkomen', $t$Onbetaald verlof betekent minder inkomen, en soms meer: het kan invloed hebben op je pensioenopbouw, je vakantiegeld en je WW-rechten. Ook je zorgtoeslag en huurtoeslag veranderen als je inkomen daalt, wat juist gunstig kan uitpakken.

Vraag je werkgever hoe de pensioenopbouw doorloopt, en pas je toeslagen aan zodra je inkomen wijzigt.$t$);

select public.wegwijzer_seed_sectie('langdurend-zorgverlof', 4, 'vraag', 'Kan de werkgever dit weigeren', $t$Ja, maar alleen op grond van een zwaarwegend bedrijfs- of dienstbelang, en dat moet worden onderbouwd. De werkgever mag ook voorstellen het verlof anders te spreiden.

Blijft het bij een weigering, vraag dan om de motivering op papier en schakel de vakbond of het Juridisch Loket in.$t$);

-- ---------------------------------------------------------------------------

select public.wegwijzer_seed_module(
  'werk', 'werktijden-aanpassen', 'Minder uren, andere tijden of thuiswerken',
  'De Wet flexibel werken geeft je het recht om te vragen of je arbeidsduur, werktijden of werkplek mogen veranderen. Reageert je werkgever niet op tijd, dan gaat je verzoek automatisch door.',
  array[
    'Je kunt vragen om aanpassing van uren, werktijden of werkplek.',
    'Voorwaarde: minimaal 26 weken in dienst, en de werkgever heeft 10 of meer werknemers.',
    'Dien het verzoek minimaal twee maanden van tevoren schriftelijk in.',
    'Reageert de werkgever niet op tijd, dan wordt het verzoek toegekend zoals gevraagd.'
  ],
  array['Wet flexibel werken'],
  array['minder werken', 'werktijden aanpassen', 'thuiswerken', 'uren verminderen', 'wet flexibel werken', 'parttime', 'andere werkdagen', 'flexibel werken'],
  5, 3, false
);

select public.wegwijzer_seed_sectie('werktijden-aanpassen', 1, 'wet', 'Wat de wet regelt', $t$Werk je 26 weken of langer bij een werkgever met tien of meer werknemers, dan kun je schriftelijk vragen om aanpassing van je arbeidsduur, je werktijden of je werkplek. Dien het verzoek minimaal twee maanden voor de gewenste ingangsdatum in.

De werkgever moet uiterlijk een maand voor de gewenste ingangsdatum schriftelijk beslissen. Doet hij dat niet, dan wordt je verzoek toegewezen zoals je het hebt gevraagd. Bij minder dan tien werknemers gelden andere, soepelere regels voor de werkgever.$t$);

select public.wegwijzer_seed_sectie('werktijden-aanpassen', 2, 'uitleg', 'Uren, tijden en plek zijn niet gelijk beschermd', $t$Een verzoek om minder of meer uren te werken kan de werkgever alleen afwijzen bij een zwaarwegend bedrijfs- of dienstbelang. Dat is een zware toets.

Voor werktijden geldt hetzelfde zware criterium. Voor de werkplek, dus thuiswerken, is de bescherming zwakker: de werkgever moet het verzoek overwegen en met je in gesprek gaan, maar mag het makkelijker afwijzen.$t$);

select public.wegwijzer_seed_sectie('werktijden-aanpassen', 3, 'stappen', 'Zo schrijf je het verzoek', $t$Zet erin wat je wilt: hoeveel uur, welke dagen, welke tijden of welke plek.
Zet erbij vanaf wanneer, minimaal twee maanden later.
Leg kort uit waarom, en wat je zelf hebt geregeld om het werk op te vangen.
Stel eventueel een proefperiode van drie maanden voor; dat verlaagt de drempel.
Mail het, en vraag om een ontvangstbevestiging.$t$);

select public.wegwijzer_seed_sectie('werktijden-aanpassen', 4, 'letop', 'Minder werken is bijna nooit terug te draaien', $t$Ga je structureel minder werken, dan daalt je inkomen, je pensioenopbouw en je opbouw van WW-rechten. Terugkeren naar je oude aantal uren is een nieuw verzoek, dat de werkgever opnieuw kan afwijzen.

Overweeg daarom eerst tijdelijke oplossingen: zorgverlof, een tijdelijke urenvermindering met een einddatum, of andere werktijden.$t$);

-- ---------------------------------------------------------------------------

select public.wegwijzer_seed_module(
  'werk', 'gesprek-met-werkgever', 'Het gesprek met je werkgever',
  'De meeste problemen op werk ontstaan doordat niemand het weet. Hoe je het gesprek voert, wat je wel en niet hoeft te vertellen, en wat een werkgever voor je kan regelen.',
  array[
    'Je bent niet verplicht medische details van een ander te delen.',
    'Kom met een voorstel, niet alleen met een probleem.',
    'Vraag naar de cao: veel cao''s kennen extra verlof of een zorgbudget.',
    'Zet afspraken op de mail, ook als het informeel geregeld is.'
  ],
  array['Arbeidsomstandighedenwet, artikel 3'],
  array['werkgever', 'gesprek werk', 'leidinggevende vertellen', 'cao', 'werk en zorg combineren', 'overbelast op werk', 'ziekmelden'],
  5, 4, false
);

select public.wegwijzer_seed_sectie('gesprek-met-werkgever', 1, 'stappen', 'Hoe je het gesprek voorbereidt', $t$Schrijf op wat er concreet speelt en hoe lang je verwacht dat het duurt.
Bedenk wat je nodig hebt: vaste vrije dagdelen, later beginnen, thuiswerken, tijdelijk minder uren.
Bedenk hoe het werk doorloopt: wie neemt wat over, wat kan wachten.
Kies een rustig moment, niet tussen twee vergaderingen door.
Vat na afloop af wat je hebt afgesproken en mail dat na.$t$);

select public.wegwijzer_seed_sectie('gesprek-met-werkgever', 2, 'uitleg', 'Wat je niet hoeft te vertellen', $t$Je hoeft geen diagnose, prognose of medische details van iemand anders te delen. "Mijn vader is ernstig ziek en ik ben de enige die de zorg kan regelen" is genoeg.

Je werkgever mag wel vragen of het verlof aannemelijk is, bijvoorbeeld met een afsprakenbevestiging van het ziekenhuis waarop de medische inhoud is weggelakt.$t$);

select public.wegwijzer_seed_sectie('gesprek-met-werkgever', 3, 'uitleg', 'Wat een werkgever kan regelen', $t$Naast de wettelijke verlofvormen kan een werkgever veel zelf: flexibele werktijden, thuiswerken, tijdelijk minder taken, een aangepast rooster, of verlofuren kopen. Veel cao's kennen bovendien extra zorgverlofdagen of een persoonlijk keuzebudget dat je in tijd kunt omzetten.

Vraag ook naar de bedrijfsmaatschappelijk werker of het mantelzorgbeleid; steeds meer organisaties hebben dat.$t$);

select public.wegwijzer_seed_sectie('gesprek-met-werkgever', 4, 'letop', 'Ziekmelden is geen oplossing', $t$Als het echt niet meer gaat, meld je dan ziek. Maar meld je niet ziek om de zorg te kunnen doen: dat is geen ziekte, en als het uitkomt kan het je baan kosten.

Ben je zelf overbelast, dan is dat wél een reden om de bedrijfsarts te bezoeken. Overbelasting is een gezondheidsprobleem, en de werkgever heeft een zorgplicht.$t$);

-- ---------------------------------------------------------------------------

select public.wegwijzer_seed_module(
  'werk', 'zzp-en-geen-werkgever', 'Zelfstandig, met uitkering of zonder werk',
  'De verlofregelingen gelden alleen voor werknemers. Werk je voor jezelf of heb je geen baan, dan zijn er andere routes.',
  array[
    'Zelfstandigen hebben geen recht op zorgverlof; alles loopt via je eigen planning en buffer.',
    'Met een WW-uitkering geldt een sollicitatieplicht, maar tijdelijke ontheffing is soms mogelijk.',
    'Zorg kan soms als vrijwilligerswerk of tegenprestatie gelden bij een bijstandsuitkering.',
    'Met een pgb kan de zorgvrager jou onder voorwaarden betalen voor de zorg die je geeft.'
  ],
  array['Werkloosheidswet', 'Participatiewet, artikel 9'],
  array['zzp', 'zelfstandige', 'ondernemer', 'ww', 'sollicitatieplicht', 'geen werk', 'uitkering en zorgen', 'ontheffing', 'betaald krijgen voor de zorg'],
  5, 5, false
);

select public.wegwijzer_seed_sectie('zzp-en-geen-werkgever', 1, 'uitleg', 'Zelfstandig ondernemer', $t$Zorgverlof bestaat niet voor zelfstandigen. Wat wel kan: je opdrachten tijdelijk terugbrengen, werken op andere tijden, of een arbeidsongeschiktheidsverzekering aanspreken als je zelf uitvalt door overbelasting.

Praktisch: informeer je vaste opdrachtgevers vroeg, spreek een lagere beschikbaarheid af in plaats van helemaal te stoppen, en houd je administratie bij, want een fors lager inkomen kan recht geven op meer toeslagen en soms op bijzondere bijstand.$t$);

select public.wegwijzer_seed_sectie('zzp-en-geen-werkgever', 2, 'uitleg', 'Met een WW-uitkering', $t$Je moet beschikbaar blijven voor werk en blijven solliciteren. In bijzondere situaties, bijvoorbeeld intensieve zorg voor een terminaal ziek familielid, kan het UWV tijdelijk ontheffing geven van de sollicitatieplicht.

Vraag dat schriftelijk aan, met onderbouwing. Stop niet zomaar met solliciteren; dat leidt tot een maatregel op je uitkering.$t$);

select public.wegwijzer_seed_sectie('zzp-en-geen-werkgever', 3, 'uitleg', 'Met een bijstandsuitkering', $t$Gemeenten mogen ontheffing van de arbeidsplicht geven aan wie zeer intensief voor een naaste zorgt. Dat is maatwerk en verschilt sterk per gemeente.

Sinds 1 januari 2026 geldt bovendien dat vergoedingen en maaltijden die je vanwege de zorg krijgt niet meer als inkomen worden gekort, en dat tijdelijk inwonen om te zorgen niet tot korting leidt. Bespreek je situatie met je klantmanager en vraag om een schriftelijke bevestiging.$t$);

select public.wegwijzer_seed_sectie('zzp-en-geen-werkgever', 4, 'vraag', 'Kan ik betaald worden voor de zorg die ik geef', $t$Dat kan als de zorgvrager een persoonsgebonden budget heeft. Je sluit dan een zorgovereenkomst via de SVB en wordt uitbetaald voor de uren die je levert.

Let op de gevolgen: die betaling is inkomen. Het telt mee voor de inkomstenbelasting, kan je toeslagen verlagen en heeft gevolgen voor een uitkering. Reken het vooraf door, en bespreek het met de gemeente of het UWV.$t$);

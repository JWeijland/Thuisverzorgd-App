# Privacybeleid Thuisverzorgd (CONCEPT — door jurist te toetsen)

*Versie 0.1 · concept van 28 juli 2026. Dit is een startpunt (besluit #18 uit de vragenronde) en is nog niet juridisch getoetst.*

## Wie zijn wij
Thuisverzorgd is een app die buurthulp organiseert rond mensen die thuis ondersteuning kunnen gebruiken. Verwerkingsverantwoordelijke: [bedrijfsnaam, KvK, adres invullen]. Contact: info@recapp-app.com.

## Welke gegevens we verwerken en waarom
| Gegevens | Doel | Grondslag |
|---|---|---|
| Naam, e-mailadres | Account en inloggen (magic link) | Uitvoering overeenkomst |
| Telefoonnummer (optioneel) | Bellen binnen een actieve taak of hulpvraag | Uitvoering overeenkomst |
| Profielfoto | Herkenning aan de deur binnen je kring | Uitvoering overeenkomst |
| ID-foto (alleen vrijwilligers, eenmalig) | Bevestigen dat je bent wie je zegt | Gerechtvaardigd belang (veiligheid) |
| Locatie | Kaart met hulpkringen en hulpvragen in de buurt | Toestemming |
| Kring-, taak- en chatgegevens | De kern van de dienst | Uitvoering overeenkomst |
| Meldingsvoorkeuren, device-token | Pushmeldingen | Toestemming |

## Zo gaan we met je gegevens om
- **ID-documenten bewaren we maximaal 30 dagen.** Daarna worden ze automatisch verwijderd; in onze administratie blijft alleen "geverifieerd: ja/nee" met datum staan. Het document is nooit zichtbaar voor andere gebruikers.
- **Je exacte adres of locatie is nooit zichtbaar zonder jouw toestemming.** Op de kaart tonen we alles op wijkniveau (ongeveer 1 kilometer afgerond). Pas als jij een hulpaanbod toestaat, ziet die ene persoon het adres.
- **Je telefoonnummer** is alleen zichtbaar voor de ander zolang er een actieve taak of hulpvraag loopt.
- **Kringgegevens** (rooster, chat, leden) zijn uitsluitend zichtbaar voor leden van die kring. Dit is technisch afgedwongen in de database (row level security).
- **Beheerders van Thuisverzorgd zien geen persoonsgegevens**, alleen geanonimiseerde, geaggregeerde cijfers (aantallen per maand, per wijk).
- Profielfoto's en documenten staan in afgeschermde opslag; toegang loopt via kortlopende, ondertekende links.

## Bewaartermijnen
Accountgegevens: zolang je account bestaat. ID-documenten: maximaal 30 dagen. Chat- en taakgeschiedenis: zolang de kring bestaat. Na verwijdering van je account wordt alles direct en definitief verwijderd (cascade), inclusief opgeslagen foto's.

## Jouw rechten
Je kunt je gegevens inzien via de app en je account op elk moment definitief verwijderen (Profiel → Account verwijderen). Daarnaast heb je recht op correctie, bezwaar, beperking en dataportabiliteit: mail info@recapp-app.com. Klachten kunnen bij de Autoriteit Persoonsgegevens.

## Derde partijen (verwerkers)
- **Supabase** (hosting database en opslag, EU-regio Frankfurt)
- **Expo** (pushmeldingen)
- **Apple / Google** (app-distributie, kaartweergave)
- [Later: Daily.co (videokennismaking), RevenueCat (abonnementen), Sentry (foutrapportage) — toevoegen zodra actief]

Met verwerkers sluiten we verwerkersovereenkomsten. Gegevens verlaten de EER niet, behalve waar dat voor pushbezorging technisch nodig is.

## Nog te doen vóór publicatie (jurist)
- [ ] Bedrijfsgegevens en DPIA-beoordeling
- [ ] Verwerkersovereenkomsten controleren
- [ ] Publiceren op een openbare URL (App Store-vereiste) en koppelen in App Store Connect

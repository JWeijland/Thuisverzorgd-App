# Fase 3 — App naar TestFlight

De app is upload-klaar. Volg deze stappen om hem in TestFlight te krijgen en
naar testers te sturen.

---

## Stap 1 — App-record aanmaken in App Store Connect

> **Waar:** https://appstoreconnect.apple.com → **Apps** → **＋** → **New App**

1. **Platform:** iOS
2. **Name:** `Thuisverzorgd` (of de naam die je in de store wilt — moet uniek zijn)
3. **Primary language:** Nederlands
4. **Bundle ID:** kies `com.JelleWeijland.Buddie-Care` uit de lijst
5. **SKU:** verzin iets, bijv. `thuisverzorgd-001`
6. **User Access:** Full Access
7. Klik **Create**.

---

## Stap 2 — Archiveren in Xcode

> **Waar:** Xcode

1. Bovenin bij het apparaat-dropdownmenu kies **Any iOS Device (arm64)**
   (niet een simulator — anders kun je niet archiveren).
2. Menu **Product → Archive**.
3. Wacht tot de build klaar is; het **Organizer**-venster opent.
4. Controleer dat **Automatically manage signing** aanstaat met je team
   (5QFB2FHYYQ). Bij de eerste keer regelt Xcode het distributiecertificaat zelf.

> Bij archiveren zet Xcode de push-omgeving automatisch op **productie** — dat is
> precies goed voor TestFlight. (De Edge Function valt zo nodig terug op sandbox.)

---

## Stap 3 — Uploaden naar App Store Connect

> **Waar:** Xcode → Organizer (na het archiveren)

1. Selecteer de zojuist gemaakte archive → **Distribute App**.
2. Kies **TestFlight & App Store Connect** (of **App Store Connect**) → **Distribute**.
3. Laat de standaardopties staan (Upload, Automatically manage signing) → **Upload**.
4. Wacht op "Upload Successful".

Daarna verschijnt de build in App Store Connect onder **TestFlight** met status
**Processing** (duurt meestal 5–30 min). Je krijgt een e-mail als hij klaar is.

---

## Stap 4 — Export compliance bevestigen

Na processing kan TestFlight vragen naar encryptie. Omdat
`ITSAppUsesNonExemptEncryption = NO` al is ingesteld, hoort dit automatisch
te gaan. Zo niet: kies **"None of the algorithms mentioned above"** / standaard
HTTPS-encryptie is vrijgesteld.

---

## Stap 5 — Testers uitnodigen

### Optie A — Interne testers (snelst, geen review)
> Tot 100 testers, moeten als gebruiker in je App Store Connect-account staan.

1. App Store Connect → je app → **TestFlight** → **Internal Testing**.
2. Maak een groep of gebruik de bestaande.
3. Voeg testers toe (ze moeten eerst onder **Users and Access** als gebruiker
   bestaan, met minimaal de rol "Developer" of "App Manager").
4. Selecteer de build → testers krijgen meteen een uitnodiging.
5. Zij installeren de **TestFlight**-app uit de App Store en accepteren de uitnodiging.

### Optie B — Externe testers (voor mensen buiten je team)
> Tot 10.000 testers via e-mail of een openbare link. Vereist een eenmalige
> **Beta App Review** (meestal < 1 dag) en wat testinformatie.

1. TestFlight → **External Testing** → maak een groep.
2. Vul in: **What to Test** (korte testinstructie) en de beta-beschrijving.
3. Voeg testers toe via e-mail, of zet **Public Link** aan en deel die link.
4. Dien de build in voor **Beta App Review**. Na goedkeuring kunnen ze testen.

> Voor externe tests is een **privacybeleid-URL** nodig (App Store Connect →
> App Information). Voor interne tests niet strikt vereist.

---

## Belangrijk voor de pushtest in TestFlight

- TestFlight-builds gebruiken **productie-APNs**. Onze Edge Function probeert
  productie en valt terug op sandbox, dus pushes werken in beide gevallen.
- Laat één tester inloggen als **buddy** (en meldingen toestaan), een ander als
  **ouder** die een hulpvraag maakt → de buddy hoort een push te krijgen.

---

## Volgende uploads

Voor elke nieuwe build moet je het buildnummer ophogen:
- Xcode → target → **General** → **Build** (of `CURRENT_PROJECT_VERSION` in
  Build Settings) → verhoog met 1 (1 → 2 → 3 …). De versie (1.0) mag gelijk blijven.

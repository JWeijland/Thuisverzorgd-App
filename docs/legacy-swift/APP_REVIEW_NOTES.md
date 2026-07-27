# App Store Connect — invulhulp voor TestFlight (externe review)

Twee dingen vul je in de webportal in voordat je externe testers kunt uitnodigen:
de **App Privacy**-vragenlijst en de **App Review Information**. Hieronder staat
precies wat je invult.

---

## A. Privacybeleid-URL

Host het bestand [`legal/privacybeleid.html`](legal/privacybeleid.html) en zet de URL
in **App Store Connect → App Information → Privacy Policy URL**.

**Snelste manier (GitHub Pages):**
1. Push de repo naar GitHub.
2. Repo → **Settings → Pages** → Source: `main` branch, map `/ (root)` → Save.
3. Na ~1 min is je URL bijv. `https://<gebruikersnaam>.github.io/<repo>/legal/privacybeleid.html`.

> Pas in het bestand het contact-e-mailadres aan als je een ander adres wilt tonen.

---

## B. App Privacy-vragenlijst

> **Waar:** App Store Connect → je app → **App Privacy** → **Get Started**.
> Voor elk gegeven hieronder: **Purpose = App Functionality**, **Linked to user = Yes**,
> **Used for tracking = No** (de app doet geen advertentie-tracking).

| Categorie (Apple) | Aanvinken | Toelichting |
|---|---|---|
| Contact Info → **Name** | Ja | Voor- en achternaam bij registratie. |
| Contact Info → **Email Address** | Ja | Inloggen / account. |
| Contact Info → **Phone Number** | Ja | Optioneel inloggen via sms-code. |
| Identifiers → **User ID** | Ja | Supabase-account-id. |
| Identifiers → **Device ID** | Ja | Pushtoken voor meldingen. |
| Location → **Precise Location** | Ja | Alleen bij inchecken (afstand tot adres). |
| User Content → **Photos or Videos** | Ja* | Selfie-check / QR-scan. |
| User Content → **Audio Data** | Ja* | Ingesproken hulpvraag (spraak → tekst). |
| User Content → **Other User Content** | Ja | Hulpvragen, notities, voorkeuren. |

\* **Foto's/Audio**: als deze de telefoon **niet** verlaten (alleen on-device verwerkt
en niet geüpload), mag je hier **No** antwoorden. Upload je selfies wél naar Supabase
(`check-in-selfies`), dan **Yes**. Kies wat klopt met je huidige implementatie.

**Tracking:** kies **"No, we do not use data for tracking."** (Er zit geen
advertentie-/analytics-SDK in de app.)

---

## C. App Review Information (Beta App Review)

> **Waar:** TestFlight → **Test Information** + bij het indienen van de externe groep.

**Sign-In nodig?** Ja. Geef een werkend testaccount:

```
Wijze van inloggen: e-mailadres + wachtwoord (in de app)
Demo-account e-mail: <maak 1 aan via Registreren in de app, bijv. review@thuisverzorgd.test>
Wachtwoord:          <kies een wachtwoord van min. 8 tekens>
```

> Tip: registreer dit account zelf één keer in de app (rol: **Buddy**) en zet in
> Supabase **Confirm email** uit, zodat de reviewer direct kan inloggen.

**Notes (plak dit in het opmerkingenveld):**

```
Thuisverzorgd is een gratis vrijwilligersplatform dat ouderen koppelt aan
vrijwillige buddy's voor gezelschap en lichte hulp. Er is geen betaling.

Inloggen: kies "Inloggen" en gebruik het demo-account hierboven (rol: buddy).
Of maak via "Registreren" zelf een account aan — kies een rol (oudere, buddy of
familie). E-mailbevestiging staat voor de beta uit, dus je kunt direct door.

De kern-flow:
1. Log in als buddy → je ziet open hulpvragen op de kaart.
2. (Optioneel) maak met een tweede account als "oudere" een hulpvraag aan
   (kies "Verder zonder koppelcode" om door te gaan) → die verschijnt bij de buddy.

Locatie/camera/microfoon worden alleen gevraagd bij de bijbehorende functie
(inchecken, selfie/QR, hulpvraag inspreken) en zijn niet verplicht om de app te
gebruiken.
```

**What to Test (externe groep):**

```
Registreren/inloggen, een rol kiezen, en de kern: als oudere een hulpvraag plaatsen
en als buddy die op de kaart zien en accepteren. Laat het ons weten als iets niet
werkt of onduidelijk is.
```

---

## D. Status van de "prototype"-elementen

Opgelost in de release-build:
- "Prototype"-tekst en demo-knoppen op het rolscherm → **verborgen** (`#if DEBUG`).
- "Demo overslaan" op het loginscherm → **verborgen** (`#if DEBUG`).
- "Wissel rol (prototype)" in profielen → vervangen door echte **"Uitloggen"**.
- Testcode-hint bij familie-koppelen → **verborgen** (`#if DEBUG`).
- VOG-onboardingtekst → herschreven zonder het woord "demo".

> Deze elementen verschijnen alleen nog in DEBUG-builds (op je eigen toestel via
> Xcode), niet in de TestFlight/Release-build.

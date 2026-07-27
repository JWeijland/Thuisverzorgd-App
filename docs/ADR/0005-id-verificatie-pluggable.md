# ADR-0005 — ID-verificatie: "geüpload = geverifieerd" in de pilot, pluggable voor later

**Status:** geaccepteerd (2026-07-27, besluit opdrachtgever)

**Context:** Vrijwilligers uploaden bij registratie eenmalig een ID-foto + profielfoto. Het ontwerp belooft: alleen de bevestiging wordt bewaard, niet het document. Opdrachtgever wil later een externe dienst aansluiten die legitimiteit automatisch verifieert.

**Keuze:** In de pilot zet een geslaagde upload `id_verified = true` + `id_verified_at` (automatisch). De ID-foto gaat naar een privé bucket met automatische verwijdering na 30 dagen (scheduled Edge Function); in de database staan nooit documenten. De verificatie loopt door één interface (`verifyIdentity(upload) → verified`), zodat een externe IDV-dienst (bijv. Onfido/Veriff) later alleen die implementatie vervangt.

**Alternatieven:** handmatige review (niemand om dat te doen — admin heeft bewust geen beheerconsole), direct een IDV-dienst (kosten + integratie te vroeg voor de pilot).

**Gevolg:** het beloofde privacymodel (boolean + timestamp, kortlopende opslag) staat vanaf dag één; de zwakte "upload zonder echte check" is een bewuste pilot-beperking, vastgelegd voor de latere IDV-integratie.

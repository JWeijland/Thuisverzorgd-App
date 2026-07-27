# ADR-0002 — Betalingen uitgesteld; entitlement-model nu al in de datalaag

**Status:** geaccepteerd (2026-07-27, besluit opdrachtgever)

**Context:** Het abonnement (€4,99/maand, ontgrendelt >2 vrijwilligers + extra functies) hoort bij de kern van het product, maar de opdrachtgever wil het echte betaalsysteem pas later implementeren.

**Keuze:** De `subscriptions`-tabel, de server-side afdwinging van de gratis limiet (2 vrijwilligers per kring) en het abonnementsscherm worden wél gebouwd. De daadwerkelijke betaling is een stub: "Start abonnement" activeert in de pilot direct het entitlement (of toont "binnenkort beschikbaar", te kiezen bij Fase 9). RevenueCat + Apple IAP + webhook volgen vóór publieke release.

**Alternatieven:** direct RevenueCat integreren (vertraagt de pilot, vereist App Store Connect-setup); limiet helemaal weglaten (dan klopt het productmodel niet en moet RLS later om).

**Gevolg:** het datamodel en de UI hoeven later niet om; alleen de betaalprovider wordt ingeplugd. Proefperiode (1 maand) en per-account-scope (alle kringen van de beheerder) staan vast.

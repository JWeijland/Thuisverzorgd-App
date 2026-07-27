-- ============================================================
-- Fase 13 — Werkende partner-koppelcodes (seed)
--
-- Draai dit ÉÉN keer in: Supabase → SQL Editor → New query → plak → Run.
-- Idempotent: bestaande codes worden niet gedupliceerd.
--
-- Dit zijn de codes waarmee een OUDERE binnenkomt (de toegangspoort op het
-- onboardingscherm). Ze spiegelen de demo-codes, zodat live en demo gelijk zijn.
-- Een admin kan in de app extra codes aanmaken (die komen er vanzelf bij).
-- ============================================================

INSERT INTO partner_codes (code, partner_name, partner_type, max_uses, is_active)
VALUES
    ('ZEIST2026',  'Gemeente Zeist',        'gemeente',        250,  TRUE),
    ('ZILVEREN50', 'Zilveren Kruis',        'zorgverzekeraar', NULL, TRUE),
    ('PHILIPS-MZ', 'Philips (mantelzorg)',  'werkgever',       100,  TRUE),
    ('TEST2026',   'Test / ontwikkeling',   'overig',          NULL, TRUE)
ON CONFLICT (code) DO NOTHING;

-- ============================================================
-- KLAAR.
-- ============================================================

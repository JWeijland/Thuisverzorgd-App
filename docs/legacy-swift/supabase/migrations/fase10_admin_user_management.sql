-- ============================================================
-- Fase 10 — Gebruikersbeheer voor admins
--
-- Draai dit ÉÉN keer in: Supabase → SQL Editor → New query → plak → Run.
-- Volledig idempotent.
--
-- Geeft admins het recht om ALLE profielen te lezen en de rol ervan te
-- wijzigen (promoveren tot admin/buddy/elderly/family) vanuit de app.
-- De fase9-trigger blijft gelden: alleen admins mogen rollen wijzigen.
-- ============================================================

-- Helper die checkt of de huidige gebruiker admin is.
-- SECURITY DEFINER → leest profiles zónder RLS, zodat een admin-policy ÓP
-- profiles geen oneindige recursie veroorzaakt.
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = (select auth.uid()) AND role = 'admin'
    );
$$;

-- Admin mag alle profielen lezen (naast "eigen profiel lezen").
DROP POLICY IF EXISTS "Admin kan alle profielen lezen" ON profiles;
CREATE POLICY "Admin kan alle profielen lezen" ON profiles
    FOR SELECT USING (public.is_admin());

-- Admin mag profielen bijwerken (o.a. de rol). De fase9-trigger
-- prevent_role_self_change staat rolwijziging door een admin toe.
DROP POLICY IF EXISTS "Admin kan profielen beheren" ON profiles;
CREATE POLICY "Admin kan profielen beheren" ON profiles
    FOR UPDATE USING (public.is_admin());

-- ============================================================
-- KLAAR. Admins kunnen nu in de app het gebruikersbeheer gebruiken.
-- ============================================================

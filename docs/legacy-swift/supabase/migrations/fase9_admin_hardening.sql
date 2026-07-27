-- ============================================================
-- Fase 9 — Beveiliging: voorkom dat iemand zichzelf admin maakt
--
-- Draai dit ÉÉN keer in: Supabase → SQL Editor → New query → plak → Run.
-- Volledig idempotent.
--
-- De policy "Eigen profiel updaten" staat toe dat een gebruiker zijn eigen
-- profielrij bijwerkt — inclusief de role-kolom. Zonder bescherming kan iemand
-- via de API zijn eigen role op 'admin' zetten. Deze trigger blokkeert het
-- wijzigen van role door gewone gebruikers.
--
-- Toegestaan blijft:
--   • jij in de SQL Editor / Table Editor (service role; auth.uid() is null)
--   • een bestaande admin die rollen beheert
-- ============================================================

CREATE OR REPLACE FUNCTION public.prevent_role_self_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    IF NEW.role IS DISTINCT FROM OLD.role THEN
        -- Alleen blokkeren bij een echte ingelogde gebruiker die geen admin is.
        -- (auth.uid() is null = dashboard/service role → toegestaan.)
        IF (select auth.uid()) IS NOT NULL
           AND NOT EXISTS (
               SELECT 1 FROM public.profiles
               WHERE id = (select auth.uid()) AND role = 'admin'
           )
        THEN
            RAISE EXCEPTION 'Je mag je eigen rol niet wijzigen.';
        END IF;
    END IF;
    RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_prevent_role_self_change ON profiles;
CREATE TRIGGER trg_prevent_role_self_change
    BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION public.prevent_role_self_change();

-- ============================================================
-- KLAAR. Een gewone gebruiker kan z'n role nu niet meer naar 'admin' zetten.
-- ============================================================

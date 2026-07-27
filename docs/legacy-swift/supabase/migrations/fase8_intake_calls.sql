-- ============================================================
-- Fase 8 — Live intake-videogesprek met wachtrij
--
-- Draai dit ÉÉN keer in: Supabase → SQL Editor → New query → plak → Run.
-- Volledig idempotent.
--
-- Een buddy (met geldige VOG, intake nog niet rond) start een
-- intake-videogesprek → komt in de wachtrij. Een admin ziet de wachtrij live,
-- neemt op, en keurt de intake goed. De videostream zelf wordt later gekoppeld
-- aan een provider (Daily/LiveKit/Agora); room_name is daar alvast voor.
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

DO $$ BEGIN
    CREATE TYPE call_status AS ENUM ('waiting', 'in_progress', 'completed', 'cancelled');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS intake_calls (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    buddy_id    UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    status      call_status NOT NULL DEFAULT 'waiting',
    room_name   TEXT NOT NULL,              -- voor de toekomstige videoprovider
    admin_id    UUID REFERENCES profiles(id) ON DELETE SET NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    started_at  TIMESTAMPTZ,
    ended_at    TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_intake_calls_status ON intake_calls(status, created_at);
CREATE INDEX IF NOT EXISTS idx_intake_calls_buddy  ON intake_calls(buddy_id);

ALTER TABLE intake_calls ENABLE ROW LEVEL SECURITY;

-- Buddy beheert zijn eigen gesprek; admins zien/sturen alles.
DROP POLICY IF EXISTS "Buddy start eigen gesprek"   ON intake_calls;
DROP POLICY IF EXISTS "Eigen gesprek of admin lezen" ON intake_calls;
DROP POLICY IF EXISTS "Eigen gesprek of admin bijwerken" ON intake_calls;

CREATE POLICY "Buddy start eigen gesprek" ON intake_calls
    FOR INSERT WITH CHECK (buddy_id = (select auth.uid()));

CREATE POLICY "Eigen gesprek of admin lezen" ON intake_calls
    FOR SELECT USING (
        buddy_id = (select auth.uid())
        OR EXISTS (SELECT 1 FROM profiles WHERE id = (select auth.uid()) AND role = 'admin')
    );

CREATE POLICY "Eigen gesprek of admin bijwerken" ON intake_calls
    FOR UPDATE USING (
        buddy_id = (select auth.uid())
        OR EXISTS (SELECT 1 FROM profiles WHERE id = (select auth.uid()) AND role = 'admin')
    );

-- Wachtrij-positie + totaal: een buddy mag (RLS) alleen z'n eigen rij zien,
-- dus de positie komt uit deze SECURITY DEFINER-functie (geeft alleen getallen,
-- geen gegevens van anderen). Positie alleen voor je eigen gesprek.
-- LET OP: 'position' is een gereserveerd woord in Postgres → kolom heet queue_position.
CREATE OR REPLACE FUNCTION public.intake_queue_status(p_call_id uuid)
RETURNS TABLE(queue_position int, total_waiting int)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = '' AS $$
DECLARE
    my_created timestamptz;
    my_status  public.call_status;
    my_buddy   uuid;
    is_admin   boolean;
BEGIN
    SELECT created_at, status, buddy_id INTO my_created, my_status, my_buddy
    FROM public.intake_calls WHERE id = p_call_id;

    total_waiting := (SELECT COUNT(*) FROM public.intake_calls WHERE status = 'waiting');
    is_admin := EXISTS (SELECT 1 FROM public.profiles WHERE id = (select auth.uid()) AND role = 'admin');

    IF my_status = 'waiting' AND (my_buddy = (select auth.uid()) OR is_admin) THEN
        queue_position := (SELECT COUNT(*) FROM public.intake_calls
                           WHERE status = 'waiting' AND created_at <= my_created);
    ELSE
        queue_position := 0;
    END IF;
    RETURN NEXT;
END $$;

-- Realtime aanzetten (voor toekomstige live-subscriptie; de app pollt nu).
DO $$ BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE intake_calls;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ============================================================
-- KLAAR.
-- ============================================================

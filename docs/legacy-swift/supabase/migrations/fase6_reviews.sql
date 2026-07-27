-- ============================================================
-- Fase 6 — Zorg dat de reviews-tabel bestaat (voor live beoordelingen)
--
-- Draai dit ÉÉN keer in: Supabase → SQL Editor → New query → plak → Run.
-- Volledig idempotent: als alles al bestaat, gebeurt er niets — veilig.
--
-- Dit hoort bij schema.sql. Draai het als je twijfelt of de reviews-tabel
-- er is (de app schrijft beoordelingen hiernaartoe; de trigger werkt de
-- buddy-rating + aantal voltooide bezoeken automatisch bij).
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ------------------------------------------------------------
-- Tabel
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS reviews (
    id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id      UUID REFERENCES tasks(id) ON DELETE CASCADE,
    reviewer_id  UUID REFERENCES profiles(id) ON DELETE CASCADE,
    reviewee_id  UUID REFERENCES profiles(id) ON DELETE CASCADE,
    stars        INTEGER NOT NULL CHECK (stars BETWEEN 1 AND 5),
    body         TEXT DEFAULT '',
    created_at   TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_reviews_reviewee ON reviews(reviewee_id);

-- ------------------------------------------------------------
-- Trigger: werk buddy-rating + aantal voltooide bezoeken bij na een review.
-- (search_path = '' + volledig gekwalificeerd → advisor-schoon.)
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.update_buddy_rating()
RETURNS TRIGGER LANGUAGE plpgsql SET search_path = '' AS $$
BEGIN
    UPDATE public.buddy_profiles
    SET rating_average = (
        SELECT ROUND(AVG(stars)::numeric, 1)
        FROM public.reviews
        WHERE reviewee_id = NEW.reviewee_id
    ),
    total_tasks = (
        SELECT COUNT(*)
        FROM public.tasks
        WHERE assigned_buddy_id = NEW.reviewee_id
          AND status = 'completed'
    )
    WHERE id = NEW.reviewee_id;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_update_buddy_rating ON reviews;
CREATE TRIGGER trg_update_buddy_rating
    AFTER INSERT ON reviews
    FOR EACH ROW EXECUTE FUNCTION public.update_buddy_rating();

-- ------------------------------------------------------------
-- RLS: iedereen mag reviews lezen; alleen de schrijver mag er één plaatsen.
-- ------------------------------------------------------------
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Reviews zijn publiek leesbaar" ON reviews;
DROP POLICY IF EXISTS "Elderly kan review plaatsen"   ON reviews;
CREATE POLICY "Reviews zijn publiek leesbaar" ON reviews FOR SELECT USING (TRUE);
CREATE POLICY "Elderly kan review plaatsen"   ON reviews FOR INSERT
    WITH CHECK (reviewer_id = (select auth.uid()));

-- ============================================================
-- KLAAR. Controleer in de Table Editor dat 'reviews' bestaat.
-- ============================================================

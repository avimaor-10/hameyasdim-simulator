-- ============================================================
-- שלב ד׳ · יצירת מערכת ניהול עסקאות שותפות חנן מור
-- סימולטור עסקת קומבינציה — מתחם המייסדים
-- v13 · מרץ 2026
-- ============================================================
-- קונטקסט:
-- מעבר ל-194 הבעלים בלשונית "בעלים — חתומים על הסכם ניהול",
-- קבוצת חנן מור רכשה 24 עסקאות שונות (סה"כ 56,947 מ"ר):
--   • 22 עסקאות CRM ישיר (44,106 מ"ר)
--   •  2 עסקאות מחוץ ל-CRM (12,841 מ"ר) — דנקנר/יצחקי, זייגרמן
-- חלקן רשומות בטאבו (✅), חלקן עדיין לא (📋), חלקן בתהליך (🔄).
-- מערכת זו מוצגת רק לאדמין — אין כניסת לקוח, אין בחירת מגרשים על ידי הלקוח.
-- האדמין מבצע בחירת מגרשים סחירים בנפרד ובמרוכז עבור כלל העסקאות.
-- ============================================================

-- ============================================================
-- 1. טבלת עסקאות (מקור אמת אדמיניסטרטיבי)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.partnership_deals (
  id                        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  deal_number               INTEGER NOT NULL,                 -- מס"ד 1-24 מהקובץ
  deal_name                 TEXT NOT NULL,                    -- "עסקת בן חורין", "עסקת מועלם" וכו׳
  gush                      INTEGER NOT NULL DEFAULT 3852,
  parcel                    INTEGER NOT NULL,
  area_sqm                  NUMERIC(12,3) NOT NULL,           -- שטח הכלול בייצוג (מ"ר)
  parcel_total_area         NUMERIC(12,2),                    -- סה"כ שטח החלקה
  percent_of_parcel         NUMERIC(6,3),                     -- אחוז מהחלקה
  status                    TEXT NOT NULL CHECK (status IN (
                              'הושלמה ונרשמה',
                              'הושלמה ולא נרשמה',
                              'בתהליך'
                            )),
  category                  TEXT NOT NULL CHECK (category IN (
                              'CRM',
                              'מחוץ ל-CRM'
                            )),
  -- מצביע על בעל החתום במקור שהוחלף בעסקה (אופציונלי).
  -- במקרה של עסקה שמחליפה מספר בעלים (כמו עסקת מועלם) — להשאיר NULL ולתעד ב-replaces_note.
  replaces_signed_owner_id  UUID REFERENCES public.signed_owners(id),
  replaces_note             TEXT,                              -- "מחליפה את משפחת מועלם (5 בעלים)" וכו׳
  registered_in_tabu        BOOLEAN GENERATED ALWAYS AS (status = 'הושלמה ונרשמה') STORED,
  is_active                 BOOLEAN DEFAULT TRUE,
  notes                     TEXT,
  source_version            TEXT DEFAULT 'v13 מרץ 2026',
  created_at                TIMESTAMPTZ DEFAULT NOW(),
  updated_at                TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.partnership_deals IS 'עסקאות רכישה/מכר של קבוצת חנן מור ושותפים — מנוהלות במרוכז על ידי אדמין';
COMMENT ON COLUMN public.partnership_deals.area_sqm IS 'שטח הכלול בייצוג. ערכים שליליים מייצגים תיקון/קיזוז (כמו ולנסיה פטורה מדמי ייזום).';
COMMENT ON COLUMN public.partnership_deals.replaces_signed_owner_id IS 'הבעלים המקורי שנגרע מ-signed_owners בעקבות העסקה (כשרלוונטי ויחיד).';

-- אינדקסים לחיפוש מהיר
CREATE INDEX IF NOT EXISTS idx_deals_parcel        ON public.partnership_deals(parcel) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_deals_status        ON public.partnership_deals(status);
CREATE INDEX IF NOT EXISTS idx_deals_category      ON public.partnership_deals(category);
CREATE INDEX IF NOT EXISTS idx_deals_replaces_owner ON public.partnership_deals(replaces_signed_owner_id) WHERE replaces_signed_owner_id IS NOT NULL;

-- ============================================================
-- 2. טבלת הקצאות מגרשים סחירים לעסקאות (האדמין בוחר במרוכז)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.deal_lot_allocations (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  deal_id          UUID NOT NULL REFERENCES public.partnership_deals(id) ON DELETE CASCADE,
  lot_id           INTEGER NOT NULL,                 -- מזהה מגרש סחיר (תואם PROJECT.lots ב-index.html)
  allocation_type  TEXT NOT NULL CHECK (allocation_type IN ('בעלות', 'שכירות')),
  allocated_area   NUMERIC(12,2) NOT NULL,           -- שטח שהוקצה במגרש זה
  notes            TEXT,
  created_at       TIMESTAMPTZ DEFAULT NOW(),
  updated_at       TIMESTAMPTZ DEFAULT NOW(),
  created_by       UUID REFERENCES auth.users(id) DEFAULT auth.uid()
);

COMMENT ON TABLE public.deal_lot_allocations IS 'הקצאת מגרשים סחירים עבור עסקאות חנן מור — נעשית על ידי האדמין בלבד';

CREATE INDEX IF NOT EXISTS idx_deal_alloc_deal_id ON public.deal_lot_allocations(deal_id);
CREATE INDEX IF NOT EXISTS idx_deal_alloc_lot_id  ON public.deal_lot_allocations(lot_id);

-- ============================================================
-- 3. טריגרים updated_at
-- ============================================================
DROP TRIGGER IF EXISTS partnership_deals_updated_at ON public.partnership_deals;
CREATE TRIGGER partnership_deals_updated_at
  BEFORE UPDATE ON public.partnership_deals
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS deal_lot_allocations_updated_at ON public.deal_lot_allocations;
CREATE TRIGGER deal_lot_allocations_updated_at
  BEFORE UPDATE ON public.deal_lot_allocations
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ============================================================
-- 4. RLS — אדמין בלבד (אין כניסת לקוח / קריאה ציבורית)
-- ============================================================
ALTER TABLE public.partnership_deals    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.deal_lot_allocations ENABLE ROW LEVEL SECURITY;

-- partnership_deals — אדמין בלבד לכל הפעולות
DROP POLICY IF EXISTS "deals_admin_all" ON public.partnership_deals;
CREATE POLICY "deals_admin_all" ON public.partnership_deals
  FOR ALL
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- deal_lot_allocations — אדמין בלבד
DROP POLICY IF EXISTS "deal_alloc_admin_all" ON public.deal_lot_allocations;
CREATE POLICY "deal_alloc_admin_all" ON public.deal_lot_allocations
  FOR ALL
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ============================================================
-- 5. View נוח לאדמין — סיכום עסקה כולל הקצאות
-- ============================================================
CREATE OR REPLACE VIEW public.partnership_deals_summary AS
SELECT
  d.id,
  d.deal_number,
  d.deal_name,
  d.gush,
  d.parcel,
  d.area_sqm,
  d.status,
  d.category,
  d.registered_in_tabu,
  d.replaces_signed_owner_id,
  d.replaces_note,
  COALESCE(SUM(a.allocated_area), 0)            AS total_allocated_area,
  d.area_sqm - COALESCE(SUM(a.allocated_area), 0) AS remaining_area,
  COUNT(a.id)                                    AS allocation_count
FROM public.partnership_deals d
LEFT JOIN public.deal_lot_allocations a ON a.deal_id = d.id
WHERE d.is_active = TRUE
GROUP BY d.id;

COMMENT ON VIEW public.partnership_deals_summary IS 'מבט אגרגטיבי של עסקאות + סטטוס הקצאת מגרשים סחירים';

-- ============================================================
-- סיום — טבלאות מוכנות. לאחר הרצת קובץ זה, הרץ:
--   sql-scripts/05_import_partnership_deals.sql
-- שיוסיף את 24 העסקאות מהקובץ "דוח_הסכמי_ניהול_ואיחוד_וחלוקה_v13"
-- ============================================================

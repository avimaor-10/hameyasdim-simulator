-- ============================================================
-- 91_create_landowner_preferences.sql  (16/05/2026)
-- ============================================================
-- 🎯 מטרה: ליצור טבלה שמאחסנת את העדפות המגרשים של בעלי קרקע.
--
-- 📐 מבנה:
--   כל בעל קרקע יכול לבחור 1-3 מגרשים מועדפים, בסדר עדיפות:
--   🥇 priority=1 (בחירה ראשונה)
--   🥈 priority=2 (בחירה שנייה)
--   🥉 priority=3 (בחירה שלישית)
--
-- 🔒 אבטחה (RLS):
--   - בעל קרקע יכול לראות/לערוך רק את ההעדפות שלו
--   - אדמין יכול לראות הכל (לצורך אנליזה ושיבוץ)
--
-- 📊 שימוש עתידי:
--   - אגרגציה של כל ההעדפות → אלגוריתם שיבוץ אופטימלי
--   - heatmap של פופולריות מגרשים
-- ============================================================


BEGIN;


-- ============================================================
-- צעד A: יצירת הטבלה
-- ============================================================
CREATE TABLE IF NOT EXISTS public.landowner_preferences (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  lot_id     INTEGER NOT NULL,
  priority   INTEGER NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- אילוצים: 39 מגרשים סחירים, 3 עדיפויות
  CONSTRAINT lot_id_range    CHECK (lot_id BETWEEN 1 AND 39),
  CONSTRAINT priority_range  CHECK (priority BETWEEN 1 AND 3),

  -- אדם לא יכול לבחור שני מגרשים לאותה עדיפות
  CONSTRAINT unique_user_priority UNIQUE (user_id, priority),

  -- אדם לא יכול לבחור אותו מגרש פעמיים (כעדיפות שונה)
  CONSTRAINT unique_user_lot UNIQUE (user_id, lot_id)
);


-- ============================================================
-- צעד B: אינדקסים לחיפושים מהירים
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_landowner_preferences_user
  ON public.landowner_preferences(user_id);

CREATE INDEX IF NOT EXISTS idx_landowner_preferences_lot
  ON public.landowner_preferences(lot_id, priority);


-- ============================================================
-- צעד C: טריגר לעדכון updated_at אוטומטי
-- ============================================================
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_landowner_preferences_updated_at
  ON public.landowner_preferences;

CREATE TRIGGER trg_landowner_preferences_updated_at
  BEFORE UPDATE ON public.landowner_preferences
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();


-- ============================================================
-- צעד D: הפעלת Row Level Security (RLS)
-- ============================================================
ALTER TABLE public.landowner_preferences ENABLE ROW LEVEL SECURITY;


-- ============================================================
-- צעד E: מדיניות גישה — בעל קרקע רואה רק את שלו
-- ============================================================
DROP POLICY IF EXISTS "users_see_own_preferences" ON public.landowner_preferences;

CREATE POLICY "users_see_own_preferences"
  ON public.landowner_preferences
  FOR SELECT
  USING (auth.uid() = user_id);


-- ============================================================
-- צעד F: מדיניות הכנסה/עדכון/מחיקה — בעל קרקע רק את שלו
-- ============================================================
DROP POLICY IF EXISTS "users_insert_own_preferences" ON public.landowner_preferences;
CREATE POLICY "users_insert_own_preferences"
  ON public.landowner_preferences
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "users_update_own_preferences" ON public.landowner_preferences;
CREATE POLICY "users_update_own_preferences"
  ON public.landowner_preferences
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "users_delete_own_preferences" ON public.landowner_preferences;
CREATE POLICY "users_delete_own_preferences"
  ON public.landowner_preferences
  FOR DELETE
  USING (auth.uid() = user_id);


-- ============================================================
-- צעד G: מדיניות אדמין — רואה הכל
-- ============================================================
DROP POLICY IF EXISTS "admins_see_all_preferences" ON public.landowner_preferences;
CREATE POLICY "admins_see_all_preferences"
  ON public.landowner_preferences
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role = 'admin'
    )
  );


-- ============================================================
-- שאילתת אימות — בדיקה שהטבלה והפוליסיס נוצרו
-- ============================================================
SELECT '✅ טבלה נוצרה' AS "סטטוס",
  (SELECT COUNT(*) FROM information_schema.tables
   WHERE table_schema = 'public' AND table_name = 'landowner_preferences') AS "טבלה קיימת",
  (SELECT COUNT(*) FROM pg_policies
   WHERE schemaname = 'public' AND tablename = 'landowner_preferences') AS "מספר מדיניות RLS";


COMMIT;


-- ============================================================
-- 📋 צפי תוצאות:
--   • טבלה קיימת: 1
--   • מספר מדיניות RLS: 5 (1 select user + 3 modify user + 1 select admin)
--
-- 🔄 פתיחה לעתיד:
--   • אם נחליט להרחיב ל-5 עדיפויות במקום 3 — לעדכן את CHECK priority_range
--   • אם נוסיף "הסבר/הערה לבחירה" — להוסיף עמודה notes TEXT
-- ============================================================

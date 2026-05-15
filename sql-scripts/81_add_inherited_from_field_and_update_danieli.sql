-- ============================================================
-- 81_add_inherited_from_field_and_update_danieli.sql  (15/05/2026)
-- ============================================================
-- 🎯 מטרה: ליצור תשתית לקישור הדדי בין יורש למוריש
--          ולמלא אותה ל-3 יורשי יהודה דניאלי ז"ל.
--
-- 🧠 המטרה האסטרטגית: רשימה של בעלי זכויות עם קישור בקליק אחד
--    מכל יורש לחותם המקורי שהוריש לו (= הוכחת "הנכנס בנעליו" בהסכם הניהול).
--
-- 📐 שני שלבים בעסקה אחת:
--   A. הוספת עמודה: inherited_from_id_number TEXT NULL
--      (ת.ז. של המוריש — החותם המקורי בשנת 2015)
--
--   B. מילוי 3 יורשי דניאלי:
--      • inherited_from_id_number = '002787430' (יהודה דניאלי ז"ל)
--      • master_2015_status = 'successor_to_2015_signer' (סטטוס מובנה)
--
-- 🔒 BEGIN ... COMMIT אוטומטי (אישור מראש).
-- ============================================================


BEGIN;


-- ============================================================
-- שלב A: הוספת העמודה
-- ============================================================
ALTER TABLE public.signed_owners
ADD COLUMN IF NOT EXISTS inherited_from_id_number TEXT NULL;

COMMENT ON COLUMN public.signed_owners.inherited_from_id_number
IS 'ת.ז./ח.פ. של המוריש (החותם המקורי בשנת 2015). כש-IS NOT NULL → הרשומה היא יורש שנכנס בנעלי המוריש בהסכם הניהול.';

-- אינדקס לחיפוש מהיר של "מי ירש ממי"
CREATE INDEX IF NOT EXISTS idx_signed_owners_inherited_from
ON public.signed_owners (inherited_from_id_number)
WHERE inherited_from_id_number IS NOT NULL;


-- ============================================================
-- שאילתה 1: לפני — סטטוס נוכחי
-- ============================================================
SELECT
  '📸 לפני' AS "שלב",
  s.owner_name AS "שם",
  s.id_number AS "ת.ז.",
  s.parcel AS "חלקה",
  COALESCE(s.master_2015_status, '(NULL)') AS "סטטוס",
  COALESCE(s.inherited_from_id_number, '(NULL)') AS "ירש מ-(ת.ז.)"
FROM public.signed_owners s
WHERE s.id_number IN ('058759978', '022728638', '024469033')
ORDER BY s.owner_name;


-- ============================================================
-- שלב B: עדכון 3 יורשי דניאלי
-- ============================================================
UPDATE public.signed_owners
SET
  master_2015_status = 'successor_to_2015_signer',
  inherited_from_id_number = '002787430'  -- יהודה דניאלי ז"ל
WHERE id_number IN ('058759978', '022728638', '024469033')
  AND parcel = 67
  AND is_active = TRUE;


-- ============================================================
-- שאילתה 2: אחרי — אימות
-- ============================================================
SELECT
  '✅ אחרי' AS "שלב",
  s.owner_name AS "שם",
  s.id_number AS "ת.ז.",
  s.parcel AS "חלקה",
  s.master_2015_status AS "סטטוס חדש",
  s.inherited_from_id_number AS "ירש מ-(ת.ז.)"
FROM public.signed_owners s
WHERE s.id_number IN ('058759978', '022728638', '024469033')
ORDER BY s.owner_name;


-- ============================================================
-- שאילתה 3: בדיקה — JOIN בין יורש למוריש (הצגת המוריש)
-- ============================================================
SELECT
  heir.owner_name AS "יורש",
  heir.id_number AS "ת.ז. יורש",
  heir.inherited_from_id_number AS "ת.ז. מוריש",
  signer.owner_name AS "שם המוריש",
  signer.is_active AS "מוריש פעיל?"
FROM public.signed_owners heir
LEFT JOIN public.signed_owners signer
  ON signer.id_number = heir.inherited_from_id_number
WHERE heir.inherited_from_id_number = '002787430'
ORDER BY heir.owner_name;


COMMIT;


-- ============================================================
-- 📋 צפי אחרי הרצה:
--   • עמודה חדשה: inherited_from_id_number (TEXT NULL)
--   • אינדקס חדש: idx_signed_owners_inherited_from
--   • 3 יורשי דניאלי: status='successor_to_2015_signer'
--                     inherited_from_id_number='002787430'
--   • JOIN בודק: לכל יורש מופיע השם של יהודה דניאלי ז"ל
--
-- ➡ אחרי הרצה — נעדכן את admin.html להציג קטע "ירשה מ-/הוריש ל-"
--   במודאל "👁 פרטים" של בעל הקרקע.
-- ============================================================

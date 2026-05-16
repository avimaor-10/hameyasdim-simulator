-- ============================================================
-- 98_downgrade_group_b_to_not_verified.sql  (16/05/2026)
-- ============================================================
-- 🎯 מטרה: תיקון סקריפט 96 — להוריד את 17 הרשומות שסומנו
--          'verified' בטעות (הם לא חתמו לפי האקסל).
--
-- 📐 לוגיקה:
--   • מסנן רק רשומות עם ההערה "(לא חתם - דרך שרשור)"
--     שהוסיף סקריפט 96 — אלה רק 17 הרשומות
--   • ורק אם inherited_from_id_number IS NULL —
--     אם בעתיד נוסיף שרשור מתועד, נחזיר ידנית ל-verified
--   • UPDATE: master_2015_status = 'not_verified'
--   • עדכון ההערה - להחליף את "(לא חתם - דרך שרשור)"
--     ל-"(לא חתם)" כי לא יודעים על שרשור
--
-- 🔒 לא נוגעים ברשומות אחרות:
--   • verified מאומת ידנית קודם → נשאר verified
--   • not_verified קודם → נשאר not_verified
--   • NULL → נשאר NULL
-- ============================================================


BEGIN;


-- ============================================================
-- שאילתה 1: לפני - הרשומות שיתעדכנו
-- ============================================================
SELECT '📸 לפני 98' AS "שלב",
  COUNT(*) AS "כמה ישתנו"
FROM public.signed_owners
WHERE is_active = TRUE
  AND master_2015_status = 'verified'
  AND master_2015_notes LIKE '%(לא חתם - דרך שרשור)%'
  AND inherited_from_id_number IS NULL;


-- ============================================================
-- צעד A: UPDATE — verified → not_verified
-- ============================================================
UPDATE public.signed_owners
SET
  master_2015_status = 'not_verified',
  master_2015_notes  = REPLACE(master_2015_notes,
                               '(לא חתם - דרך שרשור)',
                               '(לא חתם)')
WHERE is_active = TRUE
  AND master_2015_status = 'verified'
  AND master_2015_notes LIKE '%(לא חתם - דרך שרשור)%'
  AND inherited_from_id_number IS NULL;


-- ============================================================
-- שאילתה 2: אחרי - פיזור master_2015_status
-- ============================================================
SELECT '✅ אחרי 98' AS "שלב",
  COALESCE(master_2015_status, '(NULL)') AS "סטטוס",
  COUNT(*) AS "כמות"
FROM public.signed_owners
WHERE is_active = TRUE
GROUP BY master_2015_status
ORDER BY COUNT(*) DESC;


-- ============================================================
-- שאילתה 3: רשימת ה-not_verified החדשים (לאמת)
-- ============================================================
SELECT
  owner_name                    AS "שם ב-DB",
  id_number                     AS "ת״ז",
  parcel                        AS "חלקה",
  master_2015_status            AS "סטטוס",
  LEFT(master_2015_notes, 80)   AS "הערה (80 תווים)"
FROM public.signed_owners
WHERE is_active = TRUE
  AND master_2015_status = 'not_verified'
  AND master_2015_notes LIKE '%(לא חתם)%'
ORDER BY owner_name;


COMMIT;


-- ============================================================
-- 📋 צפי תוצאות:
--   • שאילתה 1: ~17 רשומות (אלה שיתעדכנו)
--   • שאילתה 2: עלייה ב-not_verified, ירידה מקבילה ב-verified
--   • שאילתה 3: 17 רשומות עם סטטוס not_verified + הערה ברורה
-- ============================================================

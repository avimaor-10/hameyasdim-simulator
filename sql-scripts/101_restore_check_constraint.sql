-- ============================================================
-- 101_restore_check_constraint.sql  (16/05/2026)
-- ============================================================
-- 🎯 מטרה: החזרת ה-CHECK constraint על master_2015_status
--          עם כל 6 הערכים הקיימים ב-DB:
--   1. verified                  — נחתם/אומת
--   2. not_verified              — לא נחתם (אישור ודאי)
--   3. not_checked               — לא נבדק עדיין (ערך ברירת מחדל)
--   4. needs_manual_check        — דורש בדיקה פיסית בקלסרים (חדש מ-100)
--   5. successor_to_2015_signer  — יורש/רוכש של חתום 2015
--   6. inherited_from_2015       — ירש מ-2015 (גרסה ישנה)
--
-- 🔍 רקע: בסקריפט 100 הסרנו את ה-constraint הישן (שאיפשר רק 3 ערכים)
--   כדי לאפשר UPDATE עם 'needs_manual_check'. עכשיו מחזירים אותו
--   עם כל הערכים הלגיטימיים שיש ב-DB.
--
-- 🔒 בטוח להריצה — רק מוסיף constraint, לא משנה נתונים.
-- ============================================================


BEGIN;


-- ============================================================
-- שאילתה 1: לפני - לוודא שכל הערכים תקפים
-- ============================================================
SELECT '📸 לפני 101' AS "שלב",
  COALESCE(master_2015_status, '(NULL)') AS "ערך",
  COUNT(*) AS "כמות"
FROM public.signed_owners
GROUP BY master_2015_status
ORDER BY COUNT(*) DESC;


-- ============================================================
-- צעד A: הוספת ה-CHECK constraint עם כל 6 הערכים
-- ============================================================
ALTER TABLE public.signed_owners
  DROP CONSTRAINT IF EXISTS signed_owners_master_2015_status_check;

ALTER TABLE public.signed_owners
  ADD CONSTRAINT signed_owners_master_2015_status_check
  CHECK (
    master_2015_status IS NULL
    OR master_2015_status IN (
      'verified',
      'not_verified',
      'not_checked',
      'needs_manual_check',
      'successor_to_2015_signer',
      'inherited_from_2015'
    )
  );


-- ============================================================
-- שאילתה 2: אחרי - לאמת שה-constraint חזר
-- ============================================================
SELECT '✅ אחרי 101' AS "שלב",
  conname AS "שם constraint",
  pg_get_constraintdef(oid) AS "הגדרה"
FROM pg_constraint
WHERE conname = 'signed_owners_master_2015_status_check';


COMMIT;


-- ============================================================
-- 📋 צפי תוצאות:
--   • שאילתה 1: 6 ערכים שונים עם הספירות שראינו
--   • שאילתה 2: שורה אחת עם ה-constraint החדש (6 ערכים מותרים)
--
-- 🎯 הצעד הבא:
--   1. בדיקה פיסית בקלסרים של 5 הבעלים שעדיין needs_manual_check
--   2. עדכון לפי הממצאים
--   3. שלב B3: יורשים ל-18 החתומים שאינם ב-DB
-- ============================================================

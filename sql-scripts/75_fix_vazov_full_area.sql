-- ============================================================
-- 75_fix_vazov_full_area.sql  (14/05/2026)
-- ============================================================
-- 🎯 מטרה: לתקן את חב' וזוב נכסים שמוצגת כ-5,285 מ"ר לאיחוד
--          (במקום 6,185 — agreement_area הרשום שלה).
--
-- 🔍 שני תיקונים:
--   A. ownership_category: 'partnership_buyer' → 'signed_with_us'
--      (כל שאר חברי הקבוצה הם 'signed_with_us', וזוב חריג)
--
--   B. מחיקת כל ה-deal_replaced_owners שמקושרים לחברי קבוצת יצחקי
--      (סקריפט 74 הסיר רק לעסקת יצחקי-דנקנר; ייתכן שיש עוד מעסקאות
--       וזוב/דסטא של השותפות שמקזזות 900 מ"ר עדיין).
--
-- 🔒 BEGIN ... COMMIT אוטומטי (אישור מראש מהמשתמש).
-- 🆔 קבוצת יצחקי: a990ed96-5b11-4d1a-9db1-89c76833af8b
-- ============================================================


BEGIN;


-- ============================================================
-- שאילתה 1: לפני — וזוב + קיזוזים פעילים
-- ============================================================
SELECT
  '📸 לפני' AS "שלב",
  s.owner_name AS "שם",
  s.id_number AS "ת.ז./ח.פ.",
  s.ownership_category AS "קטגוריה",
  s.agreement_area AS "agreement",
  s.unification_area AS "unification",
  (SELECT COUNT(*) FROM public.deal_replaced_owners dro WHERE dro.signed_owner_id = s.id) AS "deal_replacements"
FROM public.signed_owners s
WHERE s.family_group_id = 'a990ed96-5b11-4d1a-9db1-89c76833af8b'
  AND s.is_active = TRUE
ORDER BY s.parcel, s.agreement_area DESC NULLS LAST;


-- ============================================================
-- שאילתה 2: תיקון A — קטגוריה של וזוב
-- ============================================================
UPDATE public.signed_owners
SET ownership_category = 'signed_with_us'
WHERE id_number = '513435180'  -- חב' וזוב נכסים בע"מ
  AND family_group_id = 'a990ed96-5b11-4d1a-9db1-89c76833af8b'
  AND is_active = TRUE;


-- ============================================================
-- שאילתה 3: תיקון B — מחיקת כל ה-deal_replaced_owners
--           של חברי קבוצת יצחקי (בלי תלות בעסקה ספציפית)
-- ============================================================
DELETE FROM public.deal_replaced_owners
WHERE signed_owner_id IN (
  SELECT s.id
  FROM public.signed_owners s
  WHERE s.family_group_id = 'a990ed96-5b11-4d1a-9db1-89c76833af8b'
    AND s.is_active = TRUE
);


-- ============================================================
-- שאילתה 4: אימות — סטטוס סופי של חברי הקבוצה
-- ============================================================
SELECT
  '✅ אחרי' AS "שלב",
  s.owner_name AS "שם",
  s.id_number AS "ת.ז./ח.פ.",
  s.ownership_category AS "קטגוריה",
  s.agreement_area AS "agreement",
  s.unification_area AS "unification",
  (SELECT COUNT(*) FROM public.deal_replaced_owners dro WHERE dro.signed_owner_id = s.id) AS "deal_replacements"
FROM public.signed_owners s
WHERE s.family_group_id = 'a990ed96-5b11-4d1a-9db1-89c76833af8b'
  AND s.is_active = TRUE
ORDER BY s.parcel, s.agreement_area DESC NULLS LAST;


COMMIT;


-- ============================================================
-- 📋 צפי תוצאה:
--   • וזוב: קטגוריה = 'signed_with_us' (במקום 'partnership_buyer')
--   • כל החברים: deal_replacements = 0
--   • וזוב לאיחוד: יוצג כ-8,171 (unification_area override)
--   • סך הקבוצה בכרטיס יציג גבוה יותר (קרוב ל-13,698)
-- ============================================================

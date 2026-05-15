-- ============================================================
-- 88_mark_moalem_deceased_and_link_heirs.sql  (15/05/2026)
-- ============================================================
-- 🎯 מטרה: לטפל בקבוצת מועלם אליהו ז"ל ולסיים את 29 הקלות.
--
-- 📐 4 צעדים:
--   A. סימון מועלם אליהו (000755793) ב-7 חלקות כ-is_active=FALSE
--      (כולל חלקות 21 + 53 שעדיין TRUE)
--   B. סימון 4 רשומות "יורשי מועלם אליהו" (ת.ז.=NULL) כ-FALSE — כפילויות
--   C. תיקון רשומה עם ת.ז. שגויה "4/755793" בחלקה 21
--   D. קישור 25 יורשי "אליהו מועלם" → inherited_from='000755793'
--   E. קישור 3 יורשי "(יורש בוקסר)" → inherited_from='000156538'
--      (יפה בוקטר ילובסקי — "בוקסר" הוא שם נעוריה)
--
-- 🔒 BEGIN ... COMMIT אוטומטי.
-- ============================================================


BEGIN;


-- ============================================================
-- שאילתה 1: לפני
-- ============================================================
SELECT '📸 לפני' AS "שלב",
  COUNT(*) FILTER (WHERE id_number = '000755793' AND is_active = TRUE) AS "מועלם פעיל",
  COUNT(*) FILTER (WHERE id_number = '000755793' AND is_active = FALSE) AS "מועלם לא פעיל",
  COUNT(*) FILTER (WHERE id_number IS NULL AND owner_name ILIKE '%יורשי%מועלם%' AND is_active = TRUE) AS "כפילויות פעילות",
  COUNT(*) FILTER (WHERE id_number = '4/755793' AND is_active = TRUE) AS "ת.ז. שגויה",
  COUNT(*) FILTER (WHERE master_2015_notes ILIKE '%אליהו מועלם%' AND inherited_from_id_number IS NULL AND is_active = TRUE) AS "יורשים ללא קישור",
  COUNT(*) FILTER (WHERE owner_name ILIKE '%(יורש%בוקסר%)%' AND inherited_from_id_number IS NULL AND is_active = TRUE) AS "בוקסר ללא קישור"
FROM public.signed_owners;


-- ============================================================
-- צעד A: סימון מועלם אליהו (000755793) כ-FALSE בכל החלקות
-- ============================================================
UPDATE public.signed_owners
SET
  is_active = FALSE,
  master_2015_notes = 'מועלם אליהו ז"ל (נפטר לפני 04/01/2026). יורשים פעילים בקבוצה: מור חנן, מור יעקב, מור פנחס, מור נתנאל, מור גלעד, מועלם פרידה, מועלם מור שרון, סופר מור לימור, מנדל רויטל — לפי שטר ירושה 406/2026/1, נסחי חלקות 28+51+53.'
WHERE id_number = '000755793'
  AND is_active = TRUE;


-- ============================================================
-- צעד B: סימון 4 רשומות "יורשי מועלם" (ת.ז.=NULL) כ-FALSE
-- (אלו כפילויות סיכומיות — היורשים האישיים כבר ב-DB)
-- ============================================================
UPDATE public.signed_owners
SET
  is_active = FALSE,
  master_2015_notes = COALESCE(master_2015_notes, '') || ' [הוסר 15/05/2026: רשומה סיכומית — היורשים האישיים רשומים בנפרד עם קישור inherited_from_id_number=000755793]'
WHERE id_number IS NULL
  AND (owner_name ILIKE '%יורשי%מועלם%' OR owner_name ILIKE '%יורשים של מועלם%' OR owner_name ILIKE '%יורשי מועלם%')
  AND is_active = TRUE;


-- ============================================================
-- צעד C: תיקון ת.ז. שגויה "4/755793" בחלקה 21 → סימון כ-FALSE
-- (זו רשומה שגויה היסטורית של מועלם אליהו עם פורמט ת.ז. לקוי)
-- ============================================================
UPDATE public.signed_owners
SET
  is_active = FALSE,
  master_2015_notes = COALESCE(master_2015_notes, '') || ' [הוסר 15/05/2026: ת.ז. שגויה — הרשומה הנכונה היא 000755793 (מועלם אליהו ז"ל)]'
WHERE id_number = '4/755793'
  AND is_active = TRUE;


-- ============================================================
-- צעד D: קישור 25 יורשי "אליהו מועלם" — סטטוס + קישור הדדי
-- ============================================================
UPDATE public.signed_owners
SET
  inherited_from_id_number = '000755793',  -- מועלם אליהו ז"ל
  master_2015_status = 'successor_to_2015_signer'
WHERE master_2015_notes ILIKE '%אליהו מועלם%'
  AND inherited_from_id_number IS NULL
  AND is_active = TRUE;


-- ============================================================
-- צעד E: קישור 3 יורשי "(יורש בוקסר)" → יפה בוקטר ילובסקי
-- ============================================================
UPDATE public.signed_owners
SET
  inherited_from_id_number = '000156538',  -- יפה בוקטר ילובסקי ז"ל
  master_2015_notes = COALESCE(master_2015_notes, '') || ' [קושר 15/05/2026: "בוקסר" הוא שם נעוריה של יפה בוקטר ילובסקי ז"ל]'
WHERE (owner_name ILIKE '%(יורש%בוקסר%)%' OR owner_name ILIKE '%(יורשת%בוקסר%)%')
  AND inherited_from_id_number IS NULL
  AND is_active = TRUE;


-- ============================================================
-- שאילתה 2: אחרי — אימות
-- ============================================================
SELECT '✅ אחרי' AS "שלב",
  COUNT(*) FILTER (WHERE id_number = '000755793' AND is_active = TRUE) AS "מועלם פעיל",
  COUNT(*) FILTER (WHERE id_number = '000755793' AND is_active = FALSE) AS "מועלם לא פעיל",
  COUNT(*) FILTER (WHERE id_number IS NULL AND owner_name ILIKE '%יורשי%מועלם%' AND is_active = TRUE) AS "כפילויות פעילות",
  COUNT(*) FILTER (WHERE master_2015_notes ILIKE '%אליהו מועלם%' AND inherited_from_id_number = '000755793' AND is_active = TRUE) AS "יורשים מקושרים",
  COUNT(*) FILTER (WHERE owner_name ILIKE '%(יורש%בוקסר%)%' AND inherited_from_id_number = '000156538') AS "בוקסר מקושרים"
FROM public.signed_owners;


-- ============================================================
-- שאילתה 3: כמה עדיין נשארו ללא קישור (אמור להצטמצם)
-- ============================================================
SELECT
  COUNT(*) AS "נותרו ללא inherited_from",
  COUNT(*) FILTER (WHERE master_2015_notes IS NULL OR master_2015_notes = '') AS "ללא הערה כלל",
  COUNT(*) FILTER (WHERE master_2015_notes ILIKE '%אקסל%' OR master_2015_notes ILIKE '%משרשור%') AS "רק מקור הוספה"
FROM public.signed_owners
WHERE is_active = TRUE
  AND master_2015_status = 'successor_to_2015_signer'
  AND inherited_from_id_number IS NULL;


COMMIT;


-- ============================================================
-- 📋 צפי תוצאות:
--   • מועלם פעיל: 0 (במקום 2)
--   • מועלם לא פעיל: 8 (כולל 2 חדשים)
--   • כפילויות פעילות: 0 (במקום 4)
--   • יורשים מקושרים: ~25 (לפני 0)
--   • בוקסר מקושרים: 3 (לפני 0)
--   • נותרו ללא קישור: ~144 (במקום ~170)
-- ============================================================

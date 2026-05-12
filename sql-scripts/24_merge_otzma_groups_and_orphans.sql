-- ============================================================
-- 24_merge_otzma_groups_and_orphans.sql  (12/05/2026)
-- ============================================================
-- מטרה: 3 תיקונים שעלו אחרי איסוף הנתונים של רוכשי עוצמה:
--
--   1. איחוד 2 קבוצות עוצמה כפולות:
--      • ea392cf2-... "עוצמה קונקשיין ורוכשי יחידות קרקע מטעמה" (10/05/2026, רק עוצמה קונקשיין בה)
--      • c7fb1699-... "קבוצת רוכשי עוצמה - שרשור יניר/יוחננוף" (11/05/2026, 138 חברים)
--      → אבי אישר ב-12/05: השם הטוב הוא "קבוצת רוכשי עוצמה - שרשור יניר/יוחננוף" (c7fb1699).
--      → עוצמה קונקשיין תועבר מ-ea392cf2 ל-c7fb1699, ו-ea392cf2 תימחק.
--
--   2. תיקון 4 רשומות יתומות בעלים שכבר מקושרים לקבוצה ברשומות אחרות:
--      • דוידוביץ (זיצוב) אורה (000156151) → משפחת דוידוביץ אורה
--      • מועלם מור שרון (028706828) → משפחת מועלם - מור
--      • מור גלעד (043154855) → משפחת מועלם - מור
--      • מור יעקב (024870347) → משפחת מועלם - מור
--
--   3. תיקון יתומים נוספים שכל הרשומות שלהם מקושרות לרוכשי עוצמה דרך
--      ת"ז (אם נמצאים בקבוצת עוצמה אחרי האיחוד) → לקשר אוטומטית.
--
-- בטוח להריץ פעמיים — כל UPDATE עם תנאי הגבלתי.
-- ============================================================


-- ============================================================
-- שלב 1 — איחוד 2 קבוצות עוצמה
-- ============================================================
-- אבי אישר שהשם המועדף הוא "קבוצת רוכשי עוצמה - שרשור יניר/יוחננוף" (c7fb1699).
-- כל החברים של ea392cf2 (עוצמה קונקשיין בלבד, 4 רשומות) יעברו ל-c7fb1699.
-- הקבוצה ea392cf2 תימחק.

-- 1.1 העברת כל החברים מ-ea392cf2 ל-c7fb1699
UPDATE public.signed_owners
SET family_group_id = 'c7fb1699-7a86-4189-8341-19432edc2b85'
WHERE family_group_id = 'ea392cf2-0085-4e5e-9fe1-1fb7b5ba15ba';

-- 1.2 מחיקת הקבוצה הכפולה (אחרי שכל החברים יצאו)
DELETE FROM public.family_groups
WHERE id = 'ea392cf2-0085-4e5e-9fe1-1fb7b5ba15ba';


-- ============================================================
-- שלב 2 — תיקון 4 רשומות יתומות שזוהו ב-12/05/2026
-- ============================================================
-- לכל בעלים: קישור הרשומה היתומה לאותה קבוצה שיש לו ברשומות אחרות

UPDATE public.signed_owners s
SET family_group_id = (
  SELECT s2.family_group_id
  FROM public.signed_owners s2
  WHERE s2.id_number = s.id_number
    AND s2.family_group_id IS NOT NULL
  LIMIT 1
)
WHERE s.id_number IN (
  '000156151',  -- דוידוביץ (זיצוב) אורה
  '028706828',  -- מועלם מור שרון
  '043154855',  -- מור גלעד
  '024870347'   -- מור יעקב
)
  AND s.family_group_id IS NULL;


-- ============================================================
-- שלב 3 — תיקון אוטומטי של רשומות יתומות נוספות (כללי)
-- ============================================================
-- אם יש בעלים שכל הרשומות שלו יתומות (family_group_id IS NULL) — נשאיר אותו ככה,
-- כי לא ברור לאיזו קבוצה לשייך אותו (זה מקרה אמיתי של "ללא קבוצה").
--
-- אבל אם יש בעלים שיש לו לפחות רשומה אחת מקושרת לקבוצה — נקשר את שאר הרשומות
-- שלו לאותה קבוצה (כי זה בעלים אחד שצריך להיות בקבוצה אחת לוגית).

UPDATE public.signed_owners s
SET family_group_id = (
  SELECT s2.family_group_id
  FROM public.signed_owners s2
  WHERE s2.id_number = s.id_number
    AND s2.family_group_id IS NOT NULL
  LIMIT 1
)
WHERE s.family_group_id IS NULL
  AND s.is_active = TRUE
  AND s.id_number IS NOT NULL
  AND EXISTS (
    SELECT 1 FROM public.signed_owners s2
    WHERE s2.id_number = s.id_number
      AND s2.family_group_id IS NOT NULL
  );


-- ============================================================
-- שלב 4 — סימון 4 הרשומות הישנות של עוצמה קונקשיין כלא-פעילות
-- ============================================================
-- ב-DB יש 6 רשומות של "עוצמה קונקשיין בע"מ" (id_number=516607330):
--   4 רשומות "ישנות" — מייצגות את הקרקע שעוצמה רכשה מ-יניר/יוחננוף:
--     • חלקה 11: 3,571.33 מ"ר  (transition_type IS NULL)
--     • חלקה 13: 67.11 מ"ר     (transition_type IS NULL)
--     • חלקה 39: 10,000.00 מ"ר (transition_type IS NULL)
--     • חלקה 40: 4,914.00 מ"ר  (transition_type IS NULL)
--     סה"כ: 18,552.44 מ"ר (= כל מה ש-יניר/יוחננוף מכרו לפי התרשים)
--
--   2 רשומות "חדשות" — מייצגות את היתרה (סקריפט 23):
--     • חלקה 11: 30.33 מ"ר  (transition_type='sale_to_3rd_party')
--     • חלקה 13:  1.11 מ"ר  (transition_type='sale_to_3rd_party')
--     סה"כ: 31.44 מ"ר (= "נותר לעוצמה" לפי התרשים)
--
-- הקרקע כבר נמכרה ל-141 רוכשים → הספירה כפולה. נשאיר רק את היתרה כפעילה.

UPDATE public.signed_owners
SET
  is_active = FALSE,
  legal_notes = COALESCE(legal_notes || ' | ', '') ||
                'תיקון 12/05/2026: רשומה זו ייצגה את הקרקע שעוצמה קונקשיין רכשה מנועם יניר + יוחננוף. ' ||
                'הקרקע נמכרה כולה ל-141 רוכשים (4 חברות + 137 יחידים, סקריפט 23). ' ||
                'נותרה רק היתרה של 31.44 מ"ר בחלקות 11+13 (רשומות נפרדות עם sale_to_3rd_party). ' ||
                'is_active=FALSE כדי למנוע ספירה כפולה של אותה קרקע.'
WHERE id_number = '516607330'
  AND owner_name = 'עוצמה קונקשיין בע"מ'
  AND is_active = TRUE
  AND transition_type IS NULL  -- רק הרשומות הישנות (ללא סוג מעבר)
  AND parcel IN (11, 13, 39, 40);


-- ============================================================
-- שלב 5 — שאילתות אימות
-- ============================================================

-- 5.1 וידוא איחוד הקבוצות — אמורה להחזיר 1 קבוצה בלבד (עוצמה)
SELECT id, family_name, created_at::date AS created
FROM public.family_groups
WHERE family_name ILIKE '%עוצמה%' OR family_name ILIKE '%יוחננוף%' OR family_name ILIKE '%יניר%';

-- 5.2 וידוא קבוצת עוצמה — אמורה להראות ~141 חברים (138 + 3 רשומות עוצמה קונקשיין בע"מ)
SELECT
  fg.family_name,
  COUNT(s.id) AS records,
  COUNT(DISTINCT s.id_number) AS unique_members,
  ROUND(SUM(s.agreement_area)::numeric, 0) AS area_registered
FROM public.family_groups fg
LEFT JOIN public.signed_owners s ON s.family_group_id = fg.id AND s.is_active = TRUE
WHERE fg.id = 'c7fb1699-7a86-4189-8341-19432edc2b85'
GROUP BY fg.family_name;

-- 5.3 וידוא תיקון 4 הרשומות — אמורות להחזיר 0 (אין יתומות עם בעלים מקושרים)
SELECT
  s.id_number, s.owner_name, COUNT(*) AS orphan_records
FROM public.signed_owners s
WHERE s.id_number IN ('000156151', '028706828', '043154855', '024870347')
  AND s.family_group_id IS NULL
GROUP BY s.id_number, s.owner_name;

-- 5.4 סיכום יתומות כללי — כמה נשארו אחרי הניקוי
SELECT
  COUNT(*) AS total_orphan_records,
  COUNT(DISTINCT id_number) AS unique_orphan_owners,
  ROUND(SUM(agreement_area)::numeric, 0) AS total_area_orphan
FROM public.signed_owners
WHERE is_active = TRUE AND family_group_id IS NULL;

-- 5.5 פילוח סופי של כל הקבוצות (כולל area_in_unification אחרי מקדם השמאי)
WITH owner_areas AS (
  SELECT
    s.family_group_id,
    s.id_number,
    s.agreement_area,
    s.agreement_area * COALESCE(pm.participation_factor::numeric, 1) AS effective_area
  FROM public.signed_owners s
  LEFT JOIN public.parcels_meta pm ON pm.parcel = s.parcel
  WHERE s.is_active = TRUE
)
SELECT
  COALESCE(fg.family_name, '— ללא קבוצה —') AS group_name,
  COUNT(DISTINCT oa.id_number) AS unique_owners,
  COUNT(*) AS records,
  ROUND(SUM(oa.agreement_area)::numeric, 0) AS area_registered,
  ROUND(SUM(oa.effective_area)::numeric, 0) AS area_in_unification
FROM owner_areas oa
LEFT JOIN public.family_groups fg ON fg.id = oa.family_group_id
GROUP BY fg.family_name
ORDER BY area_registered DESC NULLS LAST;


-- 5.6 וידוא תיקון עוצמה קונקשיין — צפי: 2 רשומות פעילות (31.44 מ"ר), 4 לא-פעילות
SELECT
  parcel,
  ROUND(agreement_area::numeric, 2) AS area,
  is_active,
  transition_type
FROM public.signed_owners
WHERE id_number = '516607330' AND owner_name = 'עוצמה קונקשיין בע"מ'
ORDER BY parcel, is_active DESC;


-- ============================================================
-- צפי סופי:
--   • קבוצה אחת של עוצמה (c7fb1699) "קבוצת רוכשי עוצמה - שרשור יניר/יוחננוף"
--     עם ~141 רשומות פעילות (138 רוכשים + 2 רשומות יתרה של עוצמה קונקשיין)
--   • 4 רשומות "ללא קבוצה" שזוהו — תוקנו
--   • עוד רשומות "ללא קבוצה" שיש להן ת"ז עם קבוצה — תוקנו אוטומטית
--   • 4 רשומות ישנות של עוצמה קונקשיין (18,552 מ"ר היסטוריה) → is_active=FALSE
--   • הקבוצה מציגה: 18,512 (138 רוכשים) + 31.44 (יתרת עוצמה) ≈ 18,543 מ"ר
-- ============================================================

-- ============================================================
-- 58a_diag_four_mor_partners_sold_to_partnership.sql  (13/05/2026)
-- ============================================================
-- 🎯 מטרה: מציאת העסקה/ות שבה 4 השותפים מור מכרו לשותפות:
--          נתנאל מור, פנחס מור, מנדל רויטל, חנן מור (פרטי).
--
-- 🔄 תיקון מ-56b: השם הנכון "מנדל רויטל" (לא "חיטל"!)
--
-- 📋 הקשר:
--   • סך 4,541.67 מ"ר על חלקות 9, 18, 28, 34, 36, 51, 53
--   • הם מכרו לשותפות (קבוצת חנן מור / נדלן נדלן?)
--   • חייבים להופיע ב-partnership_deals כעסקת מכירה
--
-- 🔒 SELECT בלבד.
-- ============================================================


-- ============================================================
-- שאילתה 1: כל העסקאות עם השם "מור" או "רויטל" ב-partnership_deals
-- ============================================================
SELECT
  '🔍 עסקאות מור/רויטל ב-partnership_deals' AS "מדד",
  pd.deal_number AS "#",
  pd.deal_name AS "עסקה",
  pd.parcel AS "חלקה",
  ROUND(pd.area_sqm::numeric, 2) AS "שטח",
  pd.override_factor AS "override",
  pd.is_active AS "פעיל",
  fg.family_name AS "קבוצה",
  pd.notes AS "הערות"
FROM public.partnership_deals pd
LEFT JOIN public.family_groups fg ON fg.id = pd.family_group_id
WHERE
  pd.deal_name ILIKE '%נתנאל%'
  OR pd.deal_name ILIKE '%פנחס%'
  OR pd.deal_name ILIKE '%רויטל%'
  OR pd.deal_name ILIKE '%מנדל%'
  OR (pd.deal_name ILIKE '%מור%' AND pd.deal_name NOT ILIKE '%חנן מור השקעות%')
ORDER BY pd.deal_number;


-- ============================================================
-- שאילתה 2: כל העסקאות על 7 החלקות הרלוונטיות (9, 18, 28, 34, 36, 51, 53)
-- ============================================================
SELECT
  '🗺 כל העסקאות על 7 החלקות' AS "מדד",
  pd.deal_number AS "#",
  pd.deal_name AS "עסקה",
  pd.parcel AS "חלקה",
  ROUND(pd.area_sqm::numeric, 2) AS "שטח",
  pd.override_factor AS "override",
  pd.is_active AS "פעיל",
  fg.family_name AS "קבוצה"
FROM public.partnership_deals pd
LEFT JOIN public.family_groups fg ON fg.id = pd.family_group_id
WHERE pd.parcel IN (9, 18, 28, 34, 36, 51, 53)
  AND pd.is_active = TRUE
ORDER BY pd.parcel, pd.deal_number;


-- ============================================================
-- שאילתה 3: סיכום שטחי עסקאות לפי חלקה (האם 4,541.67 מ"ר מכוסה?)
-- ============================================================
SELECT
  '📊 סיכום שטחי עסקאות לפי חלקה' AS "מדד",
  pd.parcel AS "חלקה",
  COUNT(*) AS "עסקאות",
  ROUND(SUM(pd.area_sqm)::numeric, 2) AS "סך_שטח_עסקאות",
  STRING_AGG(pd.deal_name, ' | ') AS "שמות_עסקאות"
FROM public.partnership_deals pd
WHERE pd.parcel IN (9, 18, 28, 34, 36, 51, 53)
  AND pd.is_active = TRUE
GROUP BY pd.parcel
ORDER BY pd.parcel;


-- ============================================================
-- שאילתה 4: השוואת צפי האקסל (4 שותפים מור) מול עסקאות פעילות
-- ============================================================
SELECT
  '🎯 צפי 4 שותפים מור vs עסקאות פעילות' AS "מדד",
  expected.parcel_expected AS "חלקה",
  expected.expected_area AS "צפי_4_שותפים",
  COALESCE(deal.total_deals_area, 0) AS "סך_עסקאות_פעילות_בחלקה",
  CASE
    WHEN COALESCE(deal.total_deals_area, 0) >= expected.expected_area THEN '✅ מכוסה'
    WHEN COALESCE(deal.total_deals_area, 0) > 0 THEN '🟠 חלקי'
    ELSE '❌ חסר לגמרי'
  END AS "סטטוס"
FROM (VALUES
  (9, 228.14::numeric),
  (18, 420.76::numeric),
  (28, 1653.76::numeric),
  (34, 245.00::numeric),
  (36, 1.76::numeric),
  (51, 1507.53::numeric),
  (53, 484.72::numeric)
) AS expected(parcel_expected, expected_area)
LEFT JOIN LATERAL (
  SELECT SUM(pd.area_sqm) AS total_deals_area
  FROM public.partnership_deals pd
  WHERE pd.parcel = expected.parcel_expected
    AND pd.is_active = TRUE
) deal ON TRUE
ORDER BY expected.parcel_expected;


-- ============================================================
-- שאילתה 5: בדיקה בכיוון הפוך — האם מנדל רויטל כבר ב-signed_owners
-- (ייתכן שכן! בכתיב הנכון "רויטל")
-- ============================================================
SELECT
  '👤 רישומי 4 השותפים (כתיב נכון) ב-signed_owners' AS "מדד",
  s.owner_name AS "שם",
  s.id_number AS "ת_ז",
  s.parcel AS "חלקה",
  ROUND(s.agreement_area::numeric, 2) AS "שטח",
  s.is_active AS "פעיל",
  fg.family_name AS "קבוצה"
FROM public.signed_owners s
LEFT JOIN public.family_groups fg ON fg.id = s.family_group_id
WHERE
  s.owner_name ILIKE '%נתנאל מור%'
  OR s.owner_name ILIKE '%פנחס מור%'
  OR s.owner_name ILIKE '%מנדל רויטל%'
  OR s.owner_name ILIKE '%רויטל%מנדל%'
ORDER BY s.parcel, s.owner_name;


-- ============================================================
-- צפי תוצאות + מה לעשות הלאה:
--
-- 🎯 התרחישים האפשריים:
--
-- תרחיש A: שאילתה 1 מחזירה עסקאות עם 4 השותפים
--   → המכירה לשותפות כבר ב-DB. נצטרך רק להוסיף signed_owners עם is_active=FALSE
--     (כמו דרומי/בן דוד בסקריפט 56a)
--
-- תרחיש B: שאילתה 1 ריקה, אבל שאילתה 2 מראה עסקאות אחרות בחלקות
--   → אולי העסקה רשומה על שם שונה. נבחן את שמות העסקאות.
--
-- תרחיש C: גם שאילתה 1 וגם 2 ריקות לחלקות הרלוונטיות
--   → המכירה לא רשומה כעסקה. נצטרך:
--     • להוסיף עסקה ב-partnership_deals (עסקת 4 שותפים מור)
--     • להוסיף signed_owners עם is_active=FALSE
--
-- ➡️ תריץ ושלח את התוצאות. אז אבנה את סקריפט 58b המתאים לתרחיש.
-- ============================================================

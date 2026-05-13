-- ============================================================
-- 56b_diag_four_hanan_mor_partners.sql  (13/05/2026)
-- ============================================================
-- 🎯 מטרה: אבחון "4 השותפים מור" — נתנאל מור, פנחס מור, מנדל חיטל, חנן מור.
--          לפי האקסל v13, יש להם רישומים על חלקות 9, 18, 28, 34, 36, 51, 53
--          (סה"כ ~4,541 מ"ר). האם הם ב-DB? באיזו קבוצה? באיזה סטטוס?
--
-- 💡 הקבלה ל-"4 חברות פרטיות נדלן נדלן":
--   נדלן נדלן צד = 4 חברות → נתנאל/פנחס/מנדל/חנן = אנשים פרטיים שותפים
--   זה ה-"רישום על שם" של חלק מהקרקעות שחנן מור רכש בשותפות.
--
-- 🔒 SELECT בלבד.
-- ============================================================


-- ============================================================
-- שאילתה 1: חיפוש לפי שם
-- ============================================================
SELECT
  '👤 רישומי 4 השותפים מור ב-signed_owners' AS "מדד",
  s.owner_name AS "שם",
  s.id_number AS "ת_ז",
  s.parcel AS "חלקה",
  ROUND(s.agreement_area::numeric, 2) AS "שטח",
  s.is_active AS "פעיל",
  s.ownership_category AS "קטגוריה",
  fg.family_name AS "קבוצה"
FROM public.signed_owners s
LEFT JOIN public.family_groups fg ON fg.id = s.family_group_id
WHERE
  s.owner_name ILIKE '%נתנאל מור%'
  OR s.owner_name ILIKE '%פנחס מור%'
  OR s.owner_name ILIKE '%מנדל חיטל%'
  OR s.owner_name ILIKE '%חנן מור%'
  OR (s.owner_name ILIKE '%נתנאל%' AND s.owner_name ILIKE '%פנחס%')
ORDER BY s.parcel, s.owner_name;


-- ============================================================
-- שאילתה 2: חיפוש לפי שם — partnership_deals
-- ============================================================
SELECT
  '🤝 רישומי 4 השותפים מור ב-partnership_deals' AS "מדד",
  pd.deal_number AS "#",
  pd.deal_name AS "עסקה",
  pd.parcel AS "חלקה",
  ROUND(pd.area_sqm::numeric, 2) AS "שטח",
  pd.override_factor AS "override",
  pd.is_active AS "פעיל",
  fg.family_name AS "קבוצה"
FROM public.partnership_deals pd
LEFT JOIN public.family_groups fg ON fg.id = pd.family_group_id
WHERE
  pd.deal_name ILIKE '%נתנאל%'
  OR pd.deal_name ILIKE '%פנחס%'
  OR pd.deal_name ILIKE '%מנדל%'
  OR pd.deal_name ILIKE '%חיטל%'
  OR pd.deal_name ILIKE '%חנן מור%'
ORDER BY pd.deal_number;


-- ============================================================
-- שאילתה 3: סקירת קבוצות "חנן מור" — מה מכילות?
-- ============================================================
SELECT
  '📂 קבוצות חנן מור — פירוט מלא' AS "מדד",
  fg.family_name AS "קבוצה",
  fg.is_active AS "פעיל",
  (SELECT COUNT(*) FROM public.signed_owners s
   WHERE s.family_group_id = fg.id AND s.is_active = TRUE) AS "חברים_פעילים",
  (SELECT STRING_AGG(s.owner_name, ' | ') FROM public.signed_owners s
   WHERE s.family_group_id = fg.id AND s.is_active = TRUE) AS "שמות_חברים",
  (SELECT COUNT(*) FROM public.partnership_deals pd
   WHERE pd.family_group_id = fg.id AND pd.is_active = TRUE) AS "עסקאות_פעילות"
FROM public.family_groups fg
WHERE fg.family_name ILIKE '%חנן מור%'
   OR fg.family_name ILIKE '%מור השקעות%'
ORDER BY fg.family_name;


-- ============================================================
-- שאילתה 4: השוואה למה שהאקסל מצפה — חלקות וכמויות
-- ============================================================
-- צפי לפי האקסל v13:
--   חלקה  9: 228.14 מ"ר
--   חלקה 18: 420.76 מ"ר
--   חלקה 28: 1,653.76 מ"ר
--   חלקה 34: 245 מ"ר
--   חלקה 36: 1.76 מ"ר
--   חלקה 51: 1,507.53 מ"ר
--   חלקה 53: 484.72 מ"ר
--   ────────────────────
--   סה"כ: 4,541.67 מ"ר
SELECT
  '🎯 צפי vs מציאות' AS "מדד",
  parcel_expected AS "חלקה",
  expected_area AS "צפי_מהאקסל",
  COALESCE(actual.actual_area, 0) AS "בפועל_ב_DB",
  COALESCE(actual.actual_area, 0) - expected_area AS "הפרש"
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
  SELECT SUM(s.agreement_area) AS actual_area
  FROM public.signed_owners s
  WHERE s.parcel = expected.parcel_expected
    AND s.is_active = TRUE
    AND (
      s.owner_name ILIKE '%נתנאל מור%'
      OR s.owner_name ILIKE '%פנחס מור%'
      OR s.owner_name ILIKE '%מנדל חיטל%'
      OR (s.owner_name ILIKE '%חנן מור%' AND s.owner_name NOT ILIKE '%השקעות%')
    )
) actual ON TRUE
ORDER BY parcel_expected;


-- ============================================================
-- צפי תוצאות:
--   • שאילתה 1: יחזיר 0 שורות אם 4 השותפים מור אינם ב-DB
--   • שאילתה 2: יחזיר עסקאות (5%) של חנן מור השקעות (#24, #25, #27)
--   • שאילתה 3: יראה את "קבוצת חנן מור השקעות" (2 חברים: ארד+שירה)
--   • שאילתה 4: יראה כמה חסר לכל חלקה (אם השדה "בפועל" = 0 → 4 השותפים לא ב-DB)
-- ============================================================

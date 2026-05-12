-- ============================================================
-- 32_verify_hanan_mor_holdings.sql  (12/05/2026)
-- ============================================================
-- מטרה: וידוא קרקעות קבוצת חנן מור השקעות + שותפיה (אבי מאור, חנן מור)
-- וגם הקצאות אישיות לארד מאור ושירה מור שגב.
--
-- חשוב:
--   • "קבוצת חנן מור השקעות" = ישות עסקית עצמאית, נפרדת מ"קבוצת חנן מור"
--     היזמית ומ-"רוכשי שותפות נדלן נדלן קבוצת מור".
--
-- שותפים:
--   • אבי מאור (המשתמש)
--   • חנן מור (בנו של אליהו מועלם)
--
-- עסקאות מתועדות בקבוצת חנן מור השקעות:
--   • #24 — חלק חנן מור השקעות מעסקת זייגרמן (134 מ"ר)
--   • #25 — חלק חנן מור השקעות מעסקת וזוב לנדלן נדלן (300 מ"ר)
--   • #27 — חלק חנן מור השקעות מעסקת דרומי/בן דוד (147 מ"ר)
--   • סה"כ: 581 מ"ר
--
-- הקצאות אישיות פרטיות (לא בקבוצה):
--   • ארד מאור (75 מ"ר, חלקה 18, חלק בן דוד) — בנו של אבי מאור
--   • שירה מור שגב (75 מ"ר, חלקה 18, חלק בן דוד) — אשתו של חנן מור
-- ============================================================


-- ============================================================
-- שאילתה 1: עסקאות "קבוצת חנן מור השקעות" ב-partnership_deals
-- ============================================================
SELECT
  pd.deal_number AS "#",
  pd.deal_name AS "שם_עסקה",
  pd.parcel AS "חלקה",
  ROUND(pd.area_sqm::numeric, 2) AS "שטח_מר",
  pd.category AS "קטגוריה",
  pd.status AS "סטטוס",
  fg.family_name AS "קבוצה",
  pd.notes AS "הערות"
FROM public.partnership_deals pd
LEFT JOIN public.family_groups fg ON fg.id = pd.family_group_id
WHERE pd.is_active = TRUE
  AND (
    pd.deal_name ILIKE '%חנן מור השקעות%'
    OR fg.family_name ILIKE '%חנן מור השקעות%'
  )
ORDER BY pd.deal_number;


-- ============================================================
-- שאילתה 2: סיכום שטח של קבוצת חנן מור השקעות
-- ============================================================
SELECT
  fg.family_name AS "שם_קבוצה",
  COUNT(pd.id) AS "מספר_עסקאות",
  ROUND(SUM(pd.area_sqm)::numeric, 2) AS "סך_שטח_מר",
  ROUND((SUM(pd.area_sqm) / 1000.0)::numeric, 3) AS "סך_שטח_דונם"
FROM public.family_groups fg
LEFT JOIN public.partnership_deals pd ON pd.family_group_id = fg.id AND pd.is_active = TRUE
WHERE fg.family_name ILIKE '%חנן מור השקעות%'
GROUP BY fg.family_name;


-- ============================================================
-- שאילתה 3: ארד מאור + שירה מור שגב — הקצאות אישיות
-- ============================================================
SELECT
  s.parcel AS "חלקה",
  s.owner_name AS "שם",
  s.id_number AS "ת_ז",
  ROUND(s.agreement_area::numeric, 2) AS "שטח_מר",
  s.master_2015_status AS "מקור_2015",
  s.ownership_category AS "קטגוריה",
  fg.family_name AS "קבוצה",
  s.legal_notes AS "הערות"
FROM public.signed_owners s
LEFT JOIN public.family_groups fg ON fg.id = s.family_group_id
WHERE s.is_active = TRUE
  AND (
    s.owner_name ILIKE '%ארד מאור%'
    OR s.owner_name ILIKE '%מאור ארד%'
    OR s.owner_name ILIKE '%שירה מור%'
    OR s.owner_name ILIKE '%שירה%שגב%'
  )
ORDER BY s.owner_name, s.parcel;


-- ============================================================
-- שאילתה 4: אבי מאור + חנן מור — אם קיימים ב-signed_owners
-- ============================================================
SELECT
  s.parcel AS "חלקה",
  s.owner_name AS "שם",
  s.id_number AS "ת_ז",
  ROUND(s.agreement_area::numeric, 2) AS "שטח_מר",
  fg.family_name AS "קבוצה"
FROM public.signed_owners s
LEFT JOIN public.family_groups fg ON fg.id = s.family_group_id
WHERE s.is_active = TRUE
  AND (
    (s.owner_name ILIKE '%אבי מאור%' OR s.owner_name ILIKE '%מאור אבי%')
    OR (s.owner_name ILIKE '%חנן מור%' AND s.owner_name NOT ILIKE '%השקעות%')
  )
ORDER BY s.owner_name, s.parcel;


-- ============================================================
-- שאילתה 5: סיכום כולל — כל הקבוצות המקושרות לחנן מור
-- ============================================================
SELECT
  fg.family_name AS "שם_קבוצה",
  COUNT(DISTINCT s.id_number) AS "חתומים",
  COUNT(DISTINCT pd.id) AS "עסקאות",
  ROUND(COALESCE(SUM(DISTINCT s.agreement_area), 0)::numeric, 0) AS "שטח_חתומים",
  ROUND(COALESCE(SUM(pd.area_sqm), 0)::numeric, 0) AS "שטח_עסקאות"
FROM public.family_groups fg
LEFT JOIN public.signed_owners s ON s.family_group_id = fg.id AND s.is_active = TRUE
LEFT JOIN public.partnership_deals pd ON pd.family_group_id = fg.id AND pd.is_active = TRUE
WHERE fg.family_name ILIKE '%חנן מור%'
   OR fg.family_name ILIKE '%נדלן נדלן%'
   OR fg.family_name ILIKE '%נדל"ן נדל"ן%'
   OR fg.family_name ILIKE '%מועלם%'
GROUP BY fg.family_name
ORDER BY "שטח_עסקאות" DESC;


-- ============================================================
-- צפי תוצאות:
--   שאילתה 1: 3 עסקאות (#24=134, #25=300, #27=147) = 581 מ"ר
--   שאילתה 2: קבוצת חנן מור השקעות = 3 עסקאות, 581 מ"ר
--   שאילתה 3: ארד מאור 75 מ"ר חלקה 18 + שירה מור שגב 75 מ"ר חלקה 18
--   שאילתה 4: אבי + חנן עצמם — אולי לא ב-signed_owners (רק כשותפים בקבוצה)
--   שאילתה 5: סיכום של חנן מור השקעות + רוכשי שותפות + מועלם
-- ============================================================

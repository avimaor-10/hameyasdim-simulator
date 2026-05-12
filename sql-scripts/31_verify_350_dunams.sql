-- ============================================================
-- 31_verify_350_dunams.sql  (12/05/2026)
-- ============================================================
-- מטרה: וידוא ש-סך השטח הפעיל ב-DB ≈ 350,000 מ"ר (350 דונם)
-- שטח רשמי של תוכנית תמ"ל 3010:
--   • שטח תוכנית בשלמותה: 534,749 מ"ר
--   • שטח האיחוד והחלוקה: 461,466 מ"ר
--   • שטח חלקות משתתפות: 439,608 מ"ר (46 חלקות)
--
-- מה אנחנו מצפים לראות:
--   • סך agreement_area של signed_owners (פעילים) = ~350,000 מ"ר
--     (כי לא כל בעלי הקרקע במתחם חתמו איתנו — חלק מהם פרטיים)
-- ============================================================


-- ============================================================
-- שאילתה 1: סיכום שטח לפי קבוצת משפחה
-- ============================================================
WITH owner_stats AS (
  SELECT
    s.family_group_id,
    s.id_number,
    s.parcel,
    s.agreement_area,
    s.master_2015_status,
    s.ownership_category,
    s.is_active,
    pm.participation_factor::numeric AS pf
  FROM public.signed_owners s
  LEFT JOIN public.parcels_meta pm ON pm.parcel = s.parcel
  WHERE s.is_active = TRUE
)
SELECT
  COALESCE(fg.family_name, '— ללא קבוצה (יתומים) —') AS "שם_קבוצה",
  COUNT(DISTINCT os.id_number) AS "בעלים_ייחודיים",
  COUNT(*) AS "רשומות",
  ROUND(SUM(os.agreement_area)::numeric, 0) AS "שטח_רשום_מר",
  ROUND(SUM(os.agreement_area * COALESCE(os.pf, 1))::numeric, 0) AS "שטח_לאיחוד_מר"
FROM owner_stats os
LEFT JOIN public.family_groups fg ON fg.id = os.family_group_id
GROUP BY fg.family_name
ORDER BY SUM(os.agreement_area) DESC NULLS LAST;


-- ============================================================
-- שאילתה 2: סיכום שטח לפי `master_2015_status`
-- ============================================================
SELECT
  master_2015_status AS "סטטוס_מאסטר",
  COUNT(DISTINCT id_number) AS "בעלים_ייחודיים",
  COUNT(*) AS "רשומות",
  ROUND(SUM(agreement_area)::numeric, 0) AS "שטח_רשום_מר"
FROM public.signed_owners
WHERE is_active = TRUE
GROUP BY master_2015_status
ORDER BY SUM(agreement_area) DESC NULLS LAST;


-- ============================================================
-- שאילתה 3: סיכום שטח לפי `ownership_category`
-- ============================================================
SELECT
  ownership_category AS "קטגוריה",
  COUNT(DISTINCT id_number) AS "בעלים_ייחודיים",
  COUNT(*) AS "רשומות",
  ROUND(SUM(agreement_area)::numeric, 0) AS "שטח_רשום_מר"
FROM public.signed_owners
WHERE is_active = TRUE
GROUP BY ownership_category
ORDER BY SUM(agreement_area) DESC NULLS LAST;


-- ============================================================
-- שאילתה 4: שטח לפי חלקה (פעיל)
-- ============================================================
WITH parcel_totals AS (
  SELECT
    s.parcel,
    COUNT(DISTINCT s.id_number) AS unique_owners,
    SUM(s.agreement_area) AS our_area,
    pm.total_registered_area AS parcel_area,
    pm.participation_factor::numeric AS pf
  FROM public.signed_owners s
  LEFT JOIN public.parcels_meta pm ON pm.parcel = s.parcel
  WHERE s.is_active = TRUE
  GROUP BY s.parcel, pm.total_registered_area, pm.participation_factor
)
SELECT
  parcel AS "חלקה",
  unique_owners AS "בעלים",
  ROUND(our_area::numeric, 0) AS "השטח_שלנו",
  ROUND(parcel_area::numeric, 0) AS "שטח_חלקה",
  CASE
    WHEN parcel_area IS NOT NULL THEN
      ROUND((our_area * 100.0 / parcel_area)::numeric, 1) || '%'
    ELSE '—'
  END AS "אחוז_כיסוי",
  ROUND((parcel_area - our_area)::numeric, 0) AS "פער_מ_חלקה"
FROM parcel_totals
ORDER BY parcel;


-- ============================================================
-- שאילתה 5: סך הכל מסכם
-- ============================================================
SELECT
  '🎯 סיכום מצרפי' AS "מדד",
  COUNT(DISTINCT id_number) AS "בעלים_פעילים",
  COUNT(*) AS "רשומות_פעילות",
  ROUND(SUM(agreement_area)::numeric, 0) AS "סך_השטח_מר",
  ROUND(SUM(agreement_area)::numeric / 1000, 1) AS "סך_השטח_דונם"
FROM public.signed_owners
WHERE is_active = TRUE;


-- ============================================================
-- שאילתה 6: השוואה לתוכנית רשמית
-- ============================================================
SELECT
  '534,749 מ"ר' AS "שטח_תוכנית_כולל",
  '461,466 מ"ר' AS "שטח_איחוד_וחלוקה",
  '439,608 מ"ר' AS "שטח_46_חלקות_משתתפות",
  ROUND(SUM(agreement_area)::numeric, 0) || ' מ"ר' AS "השטח_שלנו_עכשיו",
  ROUND((SUM(agreement_area) / 439608.0 * 100)::numeric, 1) || '%' AS "אחוז_כיסוי"
FROM public.signed_owners
WHERE is_active = TRUE;


-- ============================================================
-- צפי תוצאות:
--   • שאילתה 5: ~350,000 מ"ר פעיל (~79% של 439,608)
--   • שאילתה 6: ~79% כיסוי מהשטח המשתתף
--   • שאילתה 1: קבוצת עוצמה תהיה הגדולה (~18,500 מ"ר)
--   • שאילתה 4: חלקות עם 100% כיסוי = בעלות מלאה איתנו
--     חלקות עם <80% = חסרים בעלים שלא חתמו (לא בעיה)
-- ============================================================

-- ============================================================
-- 33_signed_vs_unification.sql  (12/05/2026)
-- ============================================================
-- מטרה: לחשוף את ההבדל בין:
--   • "שטח חתום איתנו" = סך agreement_area של signed_owners פעילים
--   • "שטח נכנס לאיחוד וחלוקה" = השטח החתום × participation_factor של החלקה
--
-- מקדם השתתפות (participation_factor):
--   • 1.0 = החלקה משתתפת בשלמותה באיחוד (100%)
--   • <1.0 = חלק מהחלקה מחוץ ל"קו הכחול" (לא משתתף)
--
-- דוגמה: חלקה 46 משתתפת רק 95% → factor = 0.95
--   → בעלים עם 1,000 מ"ר רשום → 950 מ"ר נכנסים לאיחוד
-- ============================================================


-- ============================================================
-- שאילתה 1: סיכום מרכזי — שטח חתום vs שטח לאיחוד
-- ============================================================
WITH calc AS (
  SELECT
    s.parcel,
    s.agreement_area,
    COALESCE(pm.participation_factor::numeric, 1) AS pf,
    s.agreement_area * COALESCE(pm.participation_factor::numeric, 1) AS area_in_unification
  FROM public.signed_owners s
  LEFT JOIN public.parcels_meta pm ON pm.parcel = s.parcel
  WHERE s.is_active = TRUE
)
SELECT
  '🎯 סיכום מצרפי' AS "מדד",
  ROUND(SUM(agreement_area)::numeric, 0) || ' מ"ר' AS "שטח_חתום_איתנו",
  ROUND(SUM(area_in_unification)::numeric, 0) || ' מ"ר' AS "שטח_נכנס_לאיחוד",
  ROUND((SUM(agreement_area) - SUM(area_in_unification))::numeric, 0) || ' מ"ר' AS "הפרש_מחוץ_לקו_הכחול",
  ROUND((SUM(area_in_unification) / SUM(agreement_area) * 100)::numeric, 2) || '%' AS "אחוז_נכנס_לאיחוד",
  ROUND(SUM(agreement_area)::numeric / 1000, 1) || ' דונם' AS "חתום_בדונם",
  ROUND(SUM(area_in_unification)::numeric / 1000, 1) || ' דונם' AS "לאיחוד_בדונם"
FROM calc;


-- ============================================================
-- שאילתה 2: פירוט לפי חלקה — איפה יש "אובדן" שטח
-- ============================================================
WITH parcel_calc AS (
  SELECT
    s.parcel,
    COALESCE(pm.participation_factor::numeric, 1) AS pf,
    pm.total_registered_area AS parcel_total,
    pm.total_included_area AS parcel_included,
    SUM(s.agreement_area) AS our_area,
    SUM(s.agreement_area * COALESCE(pm.participation_factor::numeric, 1)) AS our_area_in_unification
  FROM public.signed_owners s
  LEFT JOIN public.parcels_meta pm ON pm.parcel = s.parcel
  WHERE s.is_active = TRUE
  GROUP BY s.parcel, pm.participation_factor, pm.total_registered_area, pm.total_included_area
)
SELECT
  parcel AS "חלקה",
  ROUND(pf::numeric * 100, 1) || '%' AS "מקדם_השתתפות",
  ROUND(our_area::numeric, 0) AS "השטח_שלנו_רשום",
  ROUND(our_area_in_unification::numeric, 0) AS "השטח_שלנו_לאיחוד",
  ROUND((our_area - our_area_in_unification)::numeric, 0) AS "אובדן_מקו_כחול",
  ROUND(parcel_total::numeric, 0) AS "סך_החלקה",
  ROUND(parcel_included::numeric, 0) AS "סך_שנכלל"
FROM parcel_calc
ORDER BY (our_area - our_area_in_unification) DESC, parcel;


-- ============================================================
-- שאילתה 3: לפי קבוצת משפחה — שטח חתום vs שטח לאיחוד
-- ============================================================
WITH group_calc AS (
  SELECT
    fg.family_name,
    s.id_number,
    s.agreement_area,
    s.agreement_area * COALESCE(pm.participation_factor::numeric, 1) AS area_in_unification
  FROM public.signed_owners s
  LEFT JOIN public.parcels_meta pm ON pm.parcel = s.parcel
  LEFT JOIN public.family_groups fg ON fg.id = s.family_group_id
  WHERE s.is_active = TRUE
)
SELECT
  COALESCE(family_name, '— ללא קבוצה —') AS "קבוצה",
  COUNT(DISTINCT id_number) AS "בעלים",
  ROUND(SUM(agreement_area)::numeric, 0) AS "שטח_חתום",
  ROUND(SUM(area_in_unification)::numeric, 0) AS "שטח_לאיחוד",
  ROUND((SUM(agreement_area) - SUM(area_in_unification))::numeric, 0) AS "הפרש"
FROM group_calc
GROUP BY family_name
ORDER BY SUM(area_in_unification) DESC NULLS LAST;


-- ============================================================
-- צפי תוצאות:
--   שאילתה 1:
--     שטח חתום ≈ 359,211 מ"ר
--     שטח לאיחוד ≈ 358,000 מ"ר (אובדן זניח של כמה אלפי מ"ר)
--
--   שאילתה 2:
--     רוב החלקות 100% (factor = 1.0)
--     חלקה 46 = 95% (אובדן 5%)
--     אולי עוד חלקה או שתיים עם השתתפות חלקית
-- ============================================================

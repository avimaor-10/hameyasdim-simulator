-- ============================================================
-- 68_diag_yitzhaki_area_breakdown.sql  (14/05/2026)
-- ============================================================
-- 🎯 מטרה: לאתר את הפער בין הצגת קבוצת יצחקי בכרטיס המשפחה
--          (10,209 מ"ר) לבין הבאקט 🟧 בקלף העליון (12,200 מ"ר).
--
-- 🔒 SELECT בלבד. בטוח לחלוטין. לא משנה כלום.
--
-- 🆔 קבוצת דודי יצחקי: a990ed96-5b11-4d1a-9db1-89c76833af8b
-- ============================================================


-- ============================================================
-- שאילתה 1: כל החתומים בקבוצת יצחקי — פירוט שטחים גולמי
-- (לראות agreement_area, unification_area, deducted_by_deal,
--  ו-participation_factor של החלקה)
-- ============================================================
SELECT
  s.owner_name AS "שם",
  s.id_number AS "ת.ז.",
  s.parcel AS "חלקה",
  ROUND(COALESCE(s.agreement_area, 0)::numeric, 2) AS "שטח הסכם",
  ROUND(COALESCE(s.unification_area, 0)::numeric, 2) AS "שטח איחוד",
  ROUND(COALESCE(s.deducted_by_deal, 0)::numeric, 2) AS "מקוזז ע''י עסקה",
  ROUND(COALESCE(pm.participation_factor, 1)::numeric, 4) AS "מקדם השמאי",
  s.ownership_category AS "קטגוריה"
FROM public.signed_owners s
LEFT JOIN public.parcels_meta pm ON pm.parcel = s.parcel
WHERE s.family_group_id = 'a990ed96-5b11-4d1a-9db1-89c76833af8b'
  AND s.is_active = TRUE
ORDER BY s.parcel, s.agreement_area DESC NULLS LAST;


-- ============================================================
-- שאילתה 2: כל העסקאות בקבוצת יצחקי
-- ============================================================
SELECT
  pd.deal_name AS "שם עסקה",
  pd.parcel AS "חלקה",
  ROUND(COALESCE(pd.area_sqm, 0)::numeric, 2) AS "שטח עסקה",
  ROUND(COALESCE(pd.override_factor, 0)::numeric, 4) AS "מקדם override",
  ROUND(COALESCE(pm.participation_factor, 1)::numeric, 4) AS "מקדם השמאי"
FROM public.partnership_deals pd
LEFT JOIN public.parcels_meta pm ON pm.parcel = pd.parcel
WHERE pd.family_group_id = 'a990ed96-5b11-4d1a-9db1-89c76833af8b'
  AND pd.is_active = TRUE
ORDER BY pd.parcel;


-- ============================================================
-- שאילתה 3: חישוב "בסגנון באקט" עבור כל חתום
-- (זה החישוב שהדשבורד עושה — buckets.dudi)
-- ============================================================
SELECT
  s.owner_name AS "שם",
  s.parcel AS "חלקה",
  ROUND(COALESCE(s.agreement_area, 0)::numeric, 2) AS "agArea",
  ROUND(COALESCE(s.unification_area, 0)::numeric, 2) AS "unifArea",
  ROUND(COALESCE(s.deducted_by_deal, 0)::numeric, 2) AS "deducted",
  ROUND(COALESCE(pm.participation_factor, 1)::numeric, 4) AS "factor",
  -- residual = max(0, agArea - deducted)
  ROUND(GREATEST(0, COALESCE(s.agreement_area, 0) - COALESCE(s.deducted_by_deal, 0))::numeric, 2) AS "residual",
  -- hasOverride = unifArea > 0 && |unifArea - agArea| > 0.01 && deducted < 0.01
  CASE
    WHEN COALESCE(s.unification_area, 0) > 0
         AND ABS(COALESCE(s.unification_area, 0) - COALESCE(s.agreement_area, 0)) > 0.01
         AND COALESCE(s.deducted_by_deal, 0) < 0.01
    THEN 'YES (override)'
    ELSE 'NO (factor)'
  END AS "מצב",
  -- eff = hasOverride ? unifArea : residual * factor
  ROUND(
    CASE
      WHEN COALESCE(s.unification_area, 0) > 0
           AND ABS(COALESCE(s.unification_area, 0) - COALESCE(s.agreement_area, 0)) > 0.01
           AND COALESCE(s.deducted_by_deal, 0) < 0.01
      THEN COALESCE(s.unification_area, 0)
      ELSE GREATEST(0, COALESCE(s.agreement_area, 0) - COALESCE(s.deducted_by_deal, 0))
           * COALESCE(pm.participation_factor, 1)
    END::numeric, 2
  ) AS "שטח אפקטיבי (באקט)"
FROM public.signed_owners s
LEFT JOIN public.parcels_meta pm ON pm.parcel = s.parcel
WHERE s.family_group_id = 'a990ed96-5b11-4d1a-9db1-89c76833af8b'
  AND s.is_active = TRUE
ORDER BY
  CASE
    WHEN COALESCE(s.unification_area, 0) > 0
         AND ABS(COALESCE(s.unification_area, 0) - COALESCE(s.agreement_area, 0)) > 0.01
         AND COALESCE(s.deducted_by_deal, 0) < 0.01
    THEN COALESCE(s.unification_area, 0)
    ELSE GREATEST(0, COALESCE(s.agreement_area, 0) - COALESCE(s.deducted_by_deal, 0))
         * COALESCE(pm.participation_factor, 1)
  END DESC;


-- ============================================================
-- שאילתה 4: סיכום — בדיוק מה שהבאקט מציג + פירוט לפי חלקה
-- ============================================================
WITH yitzhaki_signed AS (
  SELECT
    s.parcel,
    CASE
      WHEN COALESCE(s.unification_area, 0) > 0
           AND ABS(COALESCE(s.unification_area, 0) - COALESCE(s.agreement_area, 0)) > 0.01
           AND COALESCE(s.deducted_by_deal, 0) < 0.01
      THEN COALESCE(s.unification_area, 0)
      ELSE GREATEST(0, COALESCE(s.agreement_area, 0) - COALESCE(s.deducted_by_deal, 0))
           * COALESCE(pm.participation_factor, 1)
    END AS eff
  FROM public.signed_owners s
  LEFT JOIN public.parcels_meta pm ON pm.parcel = s.parcel
  WHERE s.family_group_id = 'a990ed96-5b11-4d1a-9db1-89c76833af8b'
    AND s.is_active = TRUE
)
SELECT
  '📊 סיכום באקט יצחקי' AS "מדד",
  parcel AS "חלקה",
  COUNT(*) AS "מס׳ חתומים",
  ROUND(SUM(eff)::numeric, 2) AS "סך שטח אפקטיבי",
  ROUND((SUM(eff) / 1000)::numeric, 2) AS "דונם"
FROM yitzhaki_signed
GROUP BY parcel
ORDER BY parcel;


-- ============================================================
-- שאילתה 5: השוואה ל-12.2 דונם בדשבורד
-- ============================================================
WITH yitzhaki_signed AS (
  SELECT
    CASE
      WHEN COALESCE(s.unification_area, 0) > 0
           AND ABS(COALESCE(s.unification_area, 0) - COALESCE(s.agreement_area, 0)) > 0.01
           AND COALESCE(s.deducted_by_deal, 0) < 0.01
      THEN COALESCE(s.unification_area, 0)
      ELSE GREATEST(0, COALESCE(s.agreement_area, 0) - COALESCE(s.deducted_by_deal, 0))
           * COALESCE(pm.participation_factor, 1)
    END AS eff
  FROM public.signed_owners s
  LEFT JOIN public.parcels_meta pm ON pm.parcel = s.parcel
  WHERE s.family_group_id = 'a990ed96-5b11-4d1a-9db1-89c76833af8b'
    AND s.is_active = TRUE
)
SELECT
  '🎯 השוואה' AS "מדד",
  COUNT(*) AS "מס׳ חתומים בקבוצה",
  ROUND(SUM(eff)::numeric, 2) AS "סך שטח אפקטיבי (מ״ר)",
  ROUND((SUM(eff) / 1000)::numeric, 2) AS "דונם",
  12200 AS "מה הדשבורד מציג",
  ROUND((SUM(eff) - 12200)::numeric, 2) AS "פער מהדשבורד"
FROM yitzhaki_signed;


-- ============================================================
-- צפי תוצאות:
--
-- שאילתה 1: 21 שורות של חתומים — בעיקר חלקה 19 (75 מ"ר כל אחד?)
--           אבל אולי גם 1-2 שורות עם שטח גדול בהרבה (יצחקי עצמו? ש.ר.ד.י?)
--
-- שאילתה 2: 1 שורה — עסקת יצחקי-דנקנר חלקה 14 (~14,152 מ"ר מקור)
--
-- שאילתה 3: 21 שורות עם פירוט מלא של החישוב לכל חתום
--           נראה לאן הולכים ה-10,653 מ"ר הנוספים — אילו רשומות יש להן
--           "שטח אפקטיבי" גבוה במיוחד?
--
-- שאילתה 4: סיכום לפי חלקה (כמה בחלקה 14, כמה בחלקה 19)
--
-- שאילתה 5: השוואה ל-12,200 מ"ר של הדשבורד.
--           אם הפער = 0 → הקוד מחשב נכון, הכרטיס המשפחה הוא זה ש"שוקר"
--           אם הפער ≠ 0 → יש שגיאה בקוד הבאקט
-- ============================================================

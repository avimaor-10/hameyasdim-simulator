-- ============================================================
-- 66_diag_move_tzlilikhin_goldman.sql  (14/05/2026)
-- ============================================================
-- 🎯 מטרה: לאמת השערה לפני UPDATE — האם 2 עסקאות (צלליכין + גולדמן)
--          הן הסיבה לפער בקבוצת 4 חברות פרטיות (6,260 → צריך 597)?
--
-- 🔒 SELECT בלבד. בטוח להריץ. לא משנה כלום.
--
-- 📐 הציפייה לפי האקסל המתוקן:
--   🔵 רוכשי שותפות נדלן נדלן קבוצת מור = 41,711 מ"ר (כעת 36,049)
--   🟠 קבוצת חנן מור השקעות           = 731 מ"ר ✅ (כעת 731 — תקין)
--   🟡 קבוצת 4 חברות פרטיות           = 597 מ"ר (כעת 6,260)
--
-- 🆔 IDs של 3 הקבוצות:
--   🔵 50ee16ff-4025-479d-af57-9f56d0489305 (רוכשי שותפות נדלן נדלן קבוצת מור)
--   🟡 f116cce6-ddd8-47ca-acd2-a92a2daa1442 (4 חברות פרטיות)
--   🟠 42687af3-4ee2-48f6-b1b7-5f74c4eae699 (חנן מור השקעות)
-- ============================================================


-- ============================================================
-- שאילתה 1: כל 5 העסקאות הנוכחיות בקבוצת 4 חברות פרטיות
-- (לאתר אילו "מלאות" ואילו "חלקיות")
-- ============================================================
SELECT
  '📋 כל העסקאות ב-🟡 4 חברות פרטיות' AS "מדד",
  pd.deal_number AS "#",
  pd.deal_name AS "שם עסקה",
  pd.parcel AS "חלקה",
  ROUND(pd.area_sqm::numeric, 2) AS "שטח"
FROM public.partnership_deals pd
WHERE pd.family_group_id = 'f116cce6-ddd8-47ca-acd2-a92a2daa1442'
  AND pd.is_active = TRUE
ORDER BY pd.area_sqm DESC NULLS LAST;


-- ============================================================
-- שאילתה 2: סיכום שטחים — מצב נוכחי (לפני העברה)
-- ============================================================
SELECT
  '📊 לפני העברה — מצב נוכחי' AS "שלב",
  fg.family_name AS "קבוצה",
  COUNT(pd.id) AS "מס׳ עסקאות",
  ROUND(SUM(pd.area_sqm)::numeric, 2) AS "סך שטח מ״ר",
  ROUND((SUM(pd.area_sqm) / 1000)::numeric, 2) AS "דונם"
FROM public.partnership_deals pd
JOIN public.family_groups fg ON fg.id = pd.family_group_id
WHERE pd.is_active = TRUE
  AND fg.id IN (
    '50ee16ff-4025-479d-af57-9f56d0489305',  -- 🔵
    'f116cce6-ddd8-47ca-acd2-a92a2daa1442',  -- 🟡
    '42687af3-4ee2-48f6-b1b7-5f74c4eae699'   -- 🟠
  )
GROUP BY fg.family_name
ORDER BY SUM(pd.area_sqm) DESC;


-- ============================================================
-- שאילתה 3: סימולציה — מה יהיה אחרי העברה של צלליכין + גולדמן
-- ============================================================
WITH proposed AS (
  SELECT
    pd.id,
    pd.area_sqm,
    CASE
      WHEN (pd.deal_name ILIKE '%צלליכין%' OR pd.deal_name ILIKE '%גולדמן%')
           AND pd.family_group_id = 'f116cce6-ddd8-47ca-acd2-a92a2daa1442'
        THEN '50ee16ff-4025-479d-af57-9f56d0489305'::uuid  -- העבר ל-🔵
      ELSE pd.family_group_id
    END AS new_family_group_id
  FROM public.partnership_deals pd
  WHERE pd.is_active = TRUE
)
SELECT
  '🔄 אחרי העברה — סימולציה' AS "שלב",
  fg.family_name AS "קבוצה",
  COUNT(*) AS "מס׳ עסקאות",
  ROUND(SUM(p.area_sqm)::numeric, 2) AS "סך שטח מ״ר",
  ROUND((SUM(p.area_sqm) / 1000)::numeric, 2) AS "דונם"
FROM proposed p
JOIN public.family_groups fg ON fg.id = p.new_family_group_id
WHERE p.new_family_group_id IN (
  '50ee16ff-4025-479d-af57-9f56d0489305',
  'f116cce6-ddd8-47ca-acd2-a92a2daa1442',
  '42687af3-4ee2-48f6-b1b7-5f74c4eae699'
)
GROUP BY fg.family_name
ORDER BY SUM(p.area_sqm) DESC;


-- ============================================================
-- שאילתה 4: בדיקה סופית — אילו עסקאות יועברו בפועל
-- (לוודא שזה בדיוק 2 עסקאות, צלליכין וגולדמן)
-- ============================================================
SELECT
  '🚚 העסקאות שיעברו' AS "מדד",
  pd.deal_number AS "#",
  pd.deal_name AS "שם עסקה",
  pd.parcel AS "חלקה",
  ROUND(pd.area_sqm::numeric, 2) AS "שטח",
  fg_old.family_name AS "מקבוצה",
  '🔵 רוכשי שותפות נדלן נדלן קבוצת מור' AS "לקבוצה"
FROM public.partnership_deals pd
LEFT JOIN public.family_groups fg_old ON fg_old.id = pd.family_group_id
WHERE pd.is_active = TRUE
  AND (pd.deal_name ILIKE '%צלליכין%' OR pd.deal_name ILIKE '%גולדמן%')
  AND pd.family_group_id = 'f116cce6-ddd8-47ca-acd2-a92a2daa1442';


-- ============================================================
-- שאילתה 5: השוואת ציפייה לתוצאה — האם הסימולציה תואמת?
-- ============================================================
WITH expected AS (
  SELECT * FROM (VALUES
    ('🔵 רוכשי שותפות נדלן נדלן קבוצת מור', 41711.00::numeric),
    ('🟡 קבוצת נדלן נדלן (4 חברות פרטיות)',    597.00::numeric),
    ('🟠 קבוצת חנן מור השקעות',                731.00::numeric)
  ) AS t(group_label, expected_area)
),
simulated AS (
  WITH proposed AS (
    SELECT
      pd.area_sqm,
      CASE
        WHEN (pd.deal_name ILIKE '%צלליכין%' OR pd.deal_name ILIKE '%גולדמן%')
             AND pd.family_group_id = 'f116cce6-ddd8-47ca-acd2-a92a2daa1442'
          THEN '50ee16ff-4025-479d-af57-9f56d0489305'::uuid
        ELSE pd.family_group_id
      END AS new_family_group_id
    FROM public.partnership_deals pd
    WHERE pd.is_active = TRUE
  )
  SELECT
    CASE
      WHEN new_family_group_id = '50ee16ff-4025-479d-af57-9f56d0489305'::uuid THEN '🔵 רוכשי שותפות נדלן נדלן קבוצת מור'
      WHEN new_family_group_id = 'f116cce6-ddd8-47ca-acd2-a92a2daa1442'::uuid THEN '🟡 קבוצת נדלן נדלן (4 חברות פרטיות)'
      WHEN new_family_group_id = '42687af3-4ee2-48f6-b1b7-5f74c4eae699'::uuid THEN '🟠 קבוצת חנן מור השקעות'
    END AS group_label,
    SUM(area_sqm) AS simulated_area
  FROM proposed
  WHERE new_family_group_id IN (
    '50ee16ff-4025-479d-af57-9f56d0489305',
    'f116cce6-ddd8-47ca-acd2-a92a2daa1442',
    '42687af3-4ee2-48f6-b1b7-5f74c4eae699'
  )
  GROUP BY new_family_group_id
)
SELECT
  '🎯 השוואה' AS "מדד",
  e.group_label AS "קבוצה",
  ROUND(e.expected_area, 2) AS "צפוי",
  ROUND(s.simulated_area::numeric, 2) AS "סימולציה",
  ROUND((s.simulated_area - e.expected_area)::numeric, 2) AS "פער",
  CASE
    WHEN ABS(s.simulated_area - e.expected_area) < 10 THEN '✅ תואם'
    WHEN ABS(s.simulated_area - e.expected_area) < 50 THEN '🟢 קרוב מאוד (פערים זניחים)'
    ELSE '⚠ פער משמעותי — בדיקה נדרשת'
  END AS "סטטוס"
FROM expected e
LEFT JOIN simulated s ON s.group_label = e.group_label
ORDER BY e.group_label;


-- ============================================================
-- צפי תוצאות מוצלחות:
--
-- שאילתה 1: 5 שורות — 2 "מלאות" (צלליכין 2,832 + גולדמן 2,832)
--           ו-3 "חלקיות" (חלק 4 חברות מוזוב/דרומי וכו')
--
-- שאילתה 2 (לפני): 🔵=36,049 · 🟡=6,260 · 🟠=731
-- שאילתה 3 (אחרי): 🔵=~41,713 · 🟡=~596 · 🟠=731
--
-- שאילתה 4: בדיוק 2 שורות (צלליכין + גולדמן)
--
-- שאילתה 5: כל 3 הקבוצות עם סטטוס '✅ תואם' או '🟢 קרוב מאוד'
--
-- ➡ אם הכל תקין — נמשיך לסקריפט 67 (UPDATE עם BEGIN/COMMIT)
-- ============================================================

-- ============================================================
-- 131_diagnose_6_buckets_dashboard.sql  (18/05/2026)
-- ============================================================
-- מטרה: לאמת את החלוקה ל-6 באקטים כפי שהדשבורד יחשב אותם,
--        ולוודא שאין כפילות בין "בבוררות" ל"לא בבוררות".
--
-- 🎯 הלוגיקה זהה לדשבורד (allocation_group_id), עם פיצול של
--     "חתומים פרטיים" (private) לפי monday_customer_type:
--        • "מיוצג" / "הרצוג" → באקט 5 (בבוררות)
--        • אחרת               → באקט 6 (לא בבוררות)
--
-- 🔒 SELECT בלבד — אין שינוי ב-DB.
-- ============================================================

WITH
-- ===== מזהי קבוצות הקצאה (זהה לדשבורד) =====
group_ids AS (
  SELECT
    '50ee16ff-4025-479d-af57-9f56d0489305'::uuid AS nadlan_id,
    'a990ed96-5b11-4d1a-9db1-89c76833af8b'::uuid AS dudi_id,
    '42687af3-4ee2-48f6-b1b7-5f74c4eae699'::uuid AS hanan_id,
    'f116cce6-ddd8-47ca-acd2-a92a2daa1442'::uuid AS four_cos_id
),
otzma_group AS (
  SELECT id FROM public.family_groups WHERE family_name ILIKE '%עוצמה%' LIMIT 1
),

-- ===== מקדמי השתתפות =====
parcel_factors AS (
  SELECT '20'::text AS parcel, 0.87456::numeric AS factor UNION ALL
  SELECT '21', 0.32839 UNION ALL
  SELECT '22', 0.01550 UNION ALL
  SELECT '26', 0.02729 UNION ALL
  SELECT '41', 0.03291 UNION ALL
  SELECT '42', 0.19021 UNION ALL
  SELECT '45', 0.55408 UNION ALL
  SELECT '46', 0.95035 UNION ALL
  SELECT '57', 0.86787
),

-- ===== signed_owners — סיווג כל בעל לבאקט =====
signed_classified AS (
  SELECT
    s.id,
    s.id_number,
    s.owner_name,
    s.parcel,
    s.allocation_group_id,
    s.monday_customer_type,
    s.ownership_category,
    COALESCE(s.unification_area, 0) * COALESCE(pf.factor, 1.0) AS eff_area,
    CASE
      WHEN s.allocation_group_id = (SELECT dudi_id FROM group_ids)   THEN 'dudi'
      WHEN s.allocation_group_id = (SELECT nadlan_id FROM group_ids) THEN 'nadlan'
      WHEN s.allocation_group_id = (SELECT id FROM otzma_group)      THEN 'otzma'
      WHEN s.allocation_group_id IN ((SELECT hanan_id FROM group_ids), (SELECT four_cos_id FROM group_ids)) THEN 'overflow'
      -- private — נפצל לפי monday_customer_type
      WHEN s.monday_customer_type ILIKE '%מיוצג%' OR s.monday_customer_type ILIKE '%הרצוג%' THEN 'arbitration'
      ELSE 'other'
    END AS bucket
  FROM public.signed_owners s
  LEFT JOIN parcel_factors pf ON pf.parcel = s.parcel::text
  WHERE s.is_active = TRUE
),

-- ===== partnership_deals — סיווג כל עסקה לבאקט =====
deals_classified AS (
  SELECT
    pd.id,
    pd.deal_name,
    pd.parcel,
    pd.allocation_group_id,
    pd.area_sqm * COALESCE(pf.factor, 1.0) AS eff_area,
    CASE
      WHEN pd.allocation_group_id = (SELECT dudi_id FROM group_ids)   THEN 'dudi'
      WHEN pd.allocation_group_id = (SELECT nadlan_id FROM group_ids) THEN 'nadlan'
      WHEN pd.allocation_group_id = (SELECT id FROM otzma_group)      THEN 'otzma'
      WHEN pd.allocation_group_id IN ((SELECT hanan_id FROM group_ids), (SELECT four_cos_id FROM group_ids)) THEN 'overflow'
      -- partnership_deals ללא חיתוך → "לא בבוררות" (חברות, לא אנשים בבוררות)
      ELSE 'other'
    END AS bucket
  FROM public.partnership_deals pd
  LEFT JOIN parcel_factors pf ON pf.parcel = pd.parcel::text
  WHERE pd.is_active = TRUE
),

-- ===== סיכום מאוחד =====
combined AS (
  SELECT bucket, eff_area, 'signed' AS source FROM signed_classified
  UNION ALL
  SELECT bucket, eff_area, 'deal'   AS source FROM deals_classified
)

-- ===== בלוק 1: סיכום 6 הבאקטים =====
SELECT
  'בלוק 1 — סיכום 6 באקטים' AS step,
  CASE bucket
    WHEN 'nadlan'      THEN '1. 🟦 רוכשי שותפות נדל"ן נדל"ן'
    WHEN 'overflow'    THEN '2. 🟣 עודפות (כובע 2)'
    WHEN 'dudi'        THEN '3. 🟧 קבוצת דודי יצחקי'
    WHEN 'otzma'       THEN '4. 🟪 קבוצת עוצמה'
    WHEN 'arbitration' THEN '5. 🟨 חתומים פרטיים — בבוררות (הרצוג)'
    WHEN 'other'       THEN '6. 🟩 חתומים פרטיים — לא בבוררות'
  END AS "באקט",
  COUNT(*)                                AS "מספר רשומות",
  ROUND(SUM(eff_area)::numeric, 0)        AS "שטח (מ""ר)",
  ROUND((SUM(eff_area) / 1000.0)::numeric, 2) AS "דונם",
  ROUND((SUM(eff_area) * 100.0 / NULLIF((SELECT SUM(eff_area) FROM combined), 0))::numeric, 1)::text || '%' AS "אחוז"
FROM combined
GROUP BY bucket
UNION ALL
SELECT
  'בלוק 1 — סיכום 6 באקטים',
  '═══ סה"כ ═══',
  COUNT(*),
  ROUND(SUM(eff_area)::numeric, 0),
  ROUND((SUM(eff_area) / 1000.0)::numeric, 2),
  '100.0%'
FROM combined
ORDER BY "באקט";

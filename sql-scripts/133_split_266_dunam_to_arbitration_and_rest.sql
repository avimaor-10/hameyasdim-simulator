-- ============================================================
-- 133_split_266_dunam_to_arbitration_and_rest.sql  (18/05/2026)
-- ============================================================
-- מטרה: לקחת את "חתומים פרטיים" (266.1 דונם בדשבורד) ולחלק אותם
--        ל-2 קטגוריות, רשומה אחר רשומה:
--           🟨 בבוררות (הרצוג)   = monday_customer_type 'מיוצג'/'הרצוג'
--           🟩 לא בבוררות         = כל השאר
--
-- 🔒 SELECT בלבד. אין שום שינוי ב-DB.
--
-- 🎯 אלה רק בעלים ש:
--    • is_active = TRUE
--    • allocation_group_id NULL או קבוצה שאיננה: נדל"ן, דודי, עוצמה,
--      חנן מור השקעות, 4 חברות פרטיות (כי 4 הראשונות כבר בקטגוריה אחרת)
-- ============================================================

WITH
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
excluded_alloc AS (
  SELECT nadlan_id AS id FROM group_ids UNION
  SELECT dudi_id           FROM group_ids UNION
  SELECT hanan_id          FROM group_ids UNION
  SELECT four_cos_id       FROM group_ids UNION
  SELECT id                FROM otzma_group
),

-- ===== כל הבעלים ב"266.1 הירוק" =====
green_owners AS (
  SELECT
    s.id,
    s.id_number,
    s.owner_name,
    s.parcel,
    s.monday_customer_type,
    s.ownership_category,
    s.unification_area,
    CASE
      WHEN s.monday_customer_type ILIKE '%מיוצג%' OR s.monday_customer_type ILIKE '%הרצוג%' THEN '🟨 בבוררות'
      ELSE '🟩 לא בבוררות'
    END AS bucket
  FROM public.signed_owners s
  WHERE s.is_active = TRUE
    AND (s.allocation_group_id IS NULL
         OR s.allocation_group_id NOT IN (SELECT id FROM excluded_alloc))
)

-- ===== בלוק 1: סיכום כללי =====
SELECT
  'בלוק 1 — סיכום פיצול' AS step,
  bucket                          AS "באקט",
  COUNT(*)                        AS "מספר רשומות",
  ROUND(SUM(unification_area)::numeric, 0) AS "שטח (מ""ר)",
  ROUND((SUM(unification_area) / 1000.0)::numeric, 2) AS "דונם"
FROM green_owners
GROUP BY bucket
UNION ALL
SELECT
  'בלוק 1 — סיכום פיצול',
  '═══ סה"כ ירוק ═══',
  COUNT(*),
  ROUND(SUM(unification_area)::numeric, 0),
  ROUND((SUM(unification_area) / 1000.0)::numeric, 2)
FROM green_owners
ORDER BY "באקט";

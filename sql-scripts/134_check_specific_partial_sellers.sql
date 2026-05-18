-- ============================================================
-- 134_check_specific_partial_sellers.sql  (18/05/2026)
-- ============================================================
-- מטרה: בדיקה ממוקדת של 11 הבעלים שהמשתמש ציין אתמול — האם הם
--        מסווגים כעת לבאקט "🟨 בבוררות" או "🟩 לא בבוררות" בדשבורד.
--
-- 🔒 SELECT בלבד. אין שום שינוי ב-DB.
-- ============================================================

SELECT
  s.id_number,
  s.owner_name,
  s.parcel,
  s.monday_customer_type AS "סיווג מנדיי",
  ROUND(s.unification_area::numeric, 0) AS "שטח (מ""ר)",
  CASE
    WHEN s.monday_customer_type ILIKE '%מיוצג%' OR s.monday_customer_type ILIKE '%הרצוג%'
      THEN '🟨 בבוררות'
    WHEN s.monday_customer_type ILIKE '%עוצמה%'
      THEN '🟪 עוצמה (לא רלוונטי)'
    ELSE '🟩 לא בבוררות'
  END AS "באקט בדשבורד",
  CASE
    WHEN s.monday_customer_type ILIKE '%מיוצג%' OR s.monday_customer_type ILIKE '%הרצוג%'
      THEN '✅ תקין'
    ELSE '⚠ אולי צריך עדכון ל-מיוצג הרצוג?'
  END AS "סטטוס"
FROM public.signed_owners s
WHERE s.is_active = TRUE
  AND (
       s.owner_name ILIKE '%זלץ%'
    OR s.owner_name ILIKE '%דרומי%'
    OR s.owner_name ILIKE '%בן דוד%'
    OR s.owner_name ILIKE '%ילובסקי%'
    OR s.owner_name ILIKE '%מועלם%'
    OR s.owner_name ILIKE '%זייגרמן%'
    OR s.owner_name ILIKE '%בן חורין%'
    OR s.owner_name ILIKE '%וזוב%'
    OR s.owner_name ILIKE '%מחלבות%'
    OR s.owner_name ILIKE '%מושה%'
    OR s.owner_name ILIKE '%דסטא%'
    OR s.owner_name ILIKE '%פלדמן%'
    OR s.owner_name ILIKE '%פיינשטיין%'
    OR s.owner_name ILIKE '%מורי%'  -- מורי מאיר (חלקה 6)
    OR s.owner_name ILIKE '%מוספי%' -- איל ומוספי (חלקה 6)
  )
ORDER BY
  CASE
    WHEN s.monday_customer_type ILIKE '%מיוצג%' OR s.monday_customer_type ILIKE '%הרצוג%' THEN 2
    WHEN s.monday_customer_type ILIKE '%עוצמה%' THEN 3
    ELSE 1  -- חריגים בראש
  END,
  s.owner_name,
  s.parcel;

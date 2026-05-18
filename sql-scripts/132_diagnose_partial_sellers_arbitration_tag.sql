-- ============================================================
-- 132_diagnose_partial_sellers_arbitration_tag.sql  (18/05/2026)
-- ============================================================
-- מטרה: לזהות בעלים שהמשתמש אמר שהם בבוררות (הרצוג) — כי הם
--        מכרו חלקית והשאר נשאר בבוררות — אבל ב-monday_customer_type
--        שלהם רשום משהו אחר (כמו "לקוח מקור").
--
-- 🎯 ההשלכה: בקוד הדשבורד החדש (6 באקטים), הקריטריון לבוררות הוא:
--    monday_customer_type ILIKE '%מיוצג%' OR '%הרצוג%'
--    אם בעל בבוררות אבל לא מסומן ככה — הוא ייכנס בטעות
--    לבאקט "🟩 לא בבוררות" במקום "🟨 בבוררות".
--
-- 🔒 SELECT בלבד — אין שינוי ב-DB.
-- ============================================================

-- ===== בלוק 1: בעלים שמופיעים בעסקאות שותפות (מכרו חלקית) =====
--        ועדיין is_active=TRUE — אלה אלה שצריכים להיות בבוררות
SELECT
  'בלוק 1 — מוכרים חלקית (יש להם גם עסקה וגם signed פעיל)' AS step,
  s.id_number,
  s.owner_name,
  s.parcel,
  s.is_active,
  s.monday_customer_type,
  CASE
    WHEN s.monday_customer_type ILIKE '%מיוצג%' OR s.monday_customer_type ILIKE '%הרצוג%' THEN '✅ בבוררות'
    WHEN s.monday_customer_type ILIKE '%עוצמה%' THEN '🟪 עוצמה'
    ELSE '⚠ לא בבוררות (צריך בדיקה!)'
  END AS "סטטוס לוגי",
  ROUND(s.agreement_area::numeric, 0)   AS agreement_area,
  ROUND(s.unification_area::numeric, 0) AS unification_area,
  pd.deal_number,
  pd.deal_name,
  ROUND(pd.area_sqm::numeric, 0) AS deal_area_sold
FROM public.signed_owners s
INNER JOIN public.partnership_deals pd ON pd.replaces_signed_owner_id = s.id
WHERE s.is_active = TRUE
  AND pd.is_active = TRUE
ORDER BY
  CASE
    WHEN s.monday_customer_type ILIKE '%מיוצג%' OR s.monday_customer_type ILIKE '%הרצוג%' THEN 2
    WHEN s.monday_customer_type ILIKE '%עוצמה%' THEN 3
    ELSE 1  -- חריגים בראש
  END,
  s.owner_name;


-- ===== בלוק 2: חיפוש ספציפי לפי שמות שהמשתמש ציין =====
SELECT
  'בלוק 2 — חיפוש שמות ספציפיים (אתמול אישרת שהם בבוררות)' AS step,
  s.id_number,
  s.owner_name,
  s.parcel,
  s.is_active,
  s.monday_customer_type,
  CASE
    WHEN s.monday_customer_type ILIKE '%מיוצג%' OR s.monday_customer_type ILIKE '%הרצוג%' THEN '✅ בבוררות'
    WHEN s.monday_customer_type ILIKE '%עוצמה%' THEN '🟪 עוצמה'
    ELSE '⚠ לא בבוררות (צריך בדיקה!)'
  END AS "סטטוס לוגי",
  ROUND(s.agreement_area::numeric, 0)   AS agreement_area,
  ROUND(s.unification_area::numeric, 0) AS unification_area
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
  )
ORDER BY s.owner_name, s.parcel;


-- ===== בלוק 3: סיכום — כמה "מוכרים חלקית" לא מסומנים בבוררות =====
SELECT
  'בלוק 3 — סיכום מספרי' AS step,
  COUNT(DISTINCT s.id_number) AS "מוכרים חלקית (סה""כ אנשים)",
  COUNT(DISTINCT s.id_number) FILTER (
    WHERE s.monday_customer_type ILIKE '%מיוצג%' OR s.monday_customer_type ILIKE '%הרצוג%'
  ) AS "מסומנים מיוצג/הרצוג",
  COUNT(DISTINCT s.id_number) FILTER (
    WHERE s.monday_customer_type ILIKE '%עוצמה%'
  ) AS "מסומנים עוצמה",
  COUNT(DISTINCT s.id_number) FILTER (
    WHERE COALESCE(s.monday_customer_type, '') NOT ILIKE '%מיוצג%'
      AND COALESCE(s.monday_customer_type, '') NOT ILIKE '%הרצוג%'
      AND COALESCE(s.monday_customer_type, '') NOT ILIKE '%עוצמה%'
  ) AS "⚠ לא מסומנים — צריך עדכון",
  ROUND(SUM(s.unification_area) FILTER (
    WHERE COALESCE(s.monday_customer_type, '') NOT ILIKE '%מיוצג%'
      AND COALESCE(s.monday_customer_type, '') NOT ILIKE '%הרצוג%'
      AND COALESCE(s.monday_customer_type, '') NOT ILIKE '%עוצמה%'
  )::numeric, 0) AS "שטח שיעבור בטעות מבוררות ל-'לא בוררות' (מ""ר)"
FROM public.signed_owners s
INNER JOIN public.partnership_deals pd ON pd.replaces_signed_owner_id = s.id
WHERE s.is_active = TRUE
  AND pd.is_active = TRUE;

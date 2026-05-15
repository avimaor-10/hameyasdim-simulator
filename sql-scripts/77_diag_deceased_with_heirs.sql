-- ============================================================
-- 77_diag_deceased_with_heirs.sql  (15/05/2026)
-- ============================================================
-- 🎯 מטרה: לאתר את כל הרשומות "ז"ל" שעדיין is_active=TRUE,
--          וצריכות להיות מסומנות לא-פעילות (כי היורשים כבר ב-DB).
--
-- 📚 העיקרון (מהזיכרון):
--   "ברשימת חתומים — רק לקוחות מקור + יורשיהם"
--   "אם היורשים כבר ב-DB → המוריש יסומן is_active = FALSE"
--   דוגמאות יישום: כץ אברהם, קובו לאה (סקריפט 62)
--
-- 🔒 SELECT בלבד. בטוח לחלוטין.
-- ============================================================


-- ============================================================
-- שאילתה 1: כל הרשומות "ז"ל" שעדיין פעילות
-- ============================================================
SELECT
  s.id AS "deceased_id",
  s.owner_name AS "שם המנוח",
  s.id_number AS "ת.ז.",
  s.parcel AS "חלקה",
  s.agreement_area AS "שטח",
  s.is_active AS "פעיל?",
  s.master_2015_status AS "סטטוס"
FROM public.signed_owners s
WHERE (s.owner_name ILIKE '%ז"ל%' OR s.owner_name ILIKE '%ז''ל%')
  AND s.is_active = TRUE
ORDER BY s.parcel, s.agreement_area DESC NULLS LAST;


-- ============================================================
-- שאילתה 2: עבור כל מנוח — חיפוש יורשים פוטנציאליים
-- (אנשים אחרים באותה חלקה עם שם משפחה דומה)
-- ============================================================
WITH deceased AS (
  SELECT id, owner_name, id_number, parcel, agreement_area
  FROM public.signed_owners
  WHERE (owner_name ILIKE '%ז"ל%' OR owner_name ILIKE '%ז''ל%')
    AND is_active = TRUE
)
SELECT
  d.owner_name AS "מנוח",
  d.parcel AS "חלקה",
  ROUND(d.agreement_area::numeric, 2) AS "שטח מנוח",
  s.owner_name AS "יורש פוטנציאלי",
  s.id_number AS "ת.ז. יורש",
  ROUND(s.agreement_area::numeric, 2) AS "שטח יורש"
FROM deceased d
LEFT JOIN public.signed_owners s
  ON s.parcel = d.parcel
  AND s.is_active = TRUE
  AND s.id != d.id
  AND s.owner_name NOT ILIKE '%ז"ל%'
  AND s.owner_name NOT ILIKE '%ז''ל%'
  AND (
    -- חפש לפי שם משפחה משותף (מילים זהות בשני השמות)
    s.owner_name ILIKE '%' || split_part(REPLACE(d.owner_name, ' ז"ל', ''), ' ', 1) || '%'
    OR s.owner_name ILIKE '%' || split_part(REPLACE(d.owner_name, ' ז''ל', ''), ' ', 1) || '%'
  )
ORDER BY d.parcel, d.owner_name, s.owner_name;


-- ============================================================
-- שאילתה 3: עבור כל מנוח — בדיקה אם סך שטחי היורשים = שטח המנוח
-- (אם תואם — אישור מובהק שהיורשים נכנסו בנעליו)
-- ============================================================
WITH deceased AS (
  SELECT id, owner_name, id_number, parcel, agreement_area
  FROM public.signed_owners
  WHERE (owner_name ILIKE '%ז"ל%' OR owner_name ILIKE '%ז''ל%')
    AND is_active = TRUE
)
SELECT
  d.owner_name AS "מנוח",
  d.parcel AS "חלקה",
  ROUND(d.agreement_area::numeric, 2) AS "שטח מנוח",
  COUNT(s.id) AS "מס' יורשים פוטנציאליים",
  ROUND(SUM(s.agreement_area)::numeric, 2) AS "סך שטח יורשים",
  ROUND((SUM(s.agreement_area) - d.agreement_area)::numeric, 2) AS "פער",
  CASE
    WHEN COUNT(s.id) = 0 THEN '❌ אין יורשים — אל תסמן כלא פעיל'
    WHEN ABS(SUM(s.agreement_area) - d.agreement_area) < 5 THEN '✅ יורשים תואמים — סמן כלא פעיל'
    ELSE '🟡 בדיקה — פער שטחים'
  END AS "המלצה"
FROM deceased d
LEFT JOIN public.signed_owners s
  ON s.parcel = d.parcel
  AND s.is_active = TRUE
  AND s.id != d.id
  AND s.owner_name NOT ILIKE '%ז"ל%'
  AND s.owner_name NOT ILIKE '%ז''ל%'
  AND (
    s.owner_name ILIKE '%' || split_part(REPLACE(d.owner_name, ' ז"ל', ''), ' ', 1) || '%'
    OR s.owner_name ILIKE '%' || split_part(REPLACE(d.owner_name, ' ז''ל', ''), ' ', 1) || '%'
  )
GROUP BY d.id, d.owner_name, d.parcel, d.agreement_area
ORDER BY d.parcel, d.owner_name;


-- ============================================================
-- 📋 צפי תוצאות:
--
-- שאילתה 1: רשימת כל המנוחים שעדיין is_active=TRUE
--           (בעקבות התצפית שלך — לפחות יהודה דניאלי, יפה ילובסקי)
--
-- שאילתה 2: לכל מנוח — אילו יורשים פוטנציאליים יש (אותה חלקה, שם משפחה דומה)
--
-- שאילתה 3: סיכום עם המלצה אוטומטית:
--   ✅ סמן כלא פעיל   — יורשים מאומתים (סך שטחים תואם)
--   ❌ אל תסמן       — אין יורשים ב-DB (המנוח נשאר פעיל לצורך תיעוד)
--   🟡 בדיקה ידנית   — יורשים יש, אבל פער שטחים חשוד
--
-- ➡ אחרי הריצה אבנה סקריפט 78 שמסמן את כל הנמצאים ב-"✅".
-- ============================================================

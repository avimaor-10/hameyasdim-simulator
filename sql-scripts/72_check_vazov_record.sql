-- ============================================================
-- 72_check_vazov_record.sql  (14/05/2026 — מתוקן)
-- ============================================================
-- 🎯 מטרה: לבדוק את הרשומה של חב' וזוב נכסים בע"מ
--          ID 513435180 כדי להבין למה השטח שלה מוצג כ-0.
--
-- 🔒 SELECT בלבד. בטוח לחלוטין.
-- ============================================================


-- ============================================================
-- שאילתה 1: כל הרשומות של וזוב ב-signed_owners
-- (כל העמודות — כדי לראות מה יש שם)
-- ============================================================
SELECT
  s.owner_name AS "שם",
  s.id_number AS "ת.ז./ח.פ.",
  s.parcel AS "חלקה",
  s.ownership_category AS "קטגוריה",
  ROUND(COALESCE(s.agreement_area, 0)::numeric, 2) AS "agreement_area",
  ROUND(COALESCE(s.unification_area, 0)::numeric, 2) AS "unification_area",
  fg.family_name AS "קבוצה משפטית",
  fg2.family_name AS "קבוצת הקצאה"
FROM public.signed_owners s
LEFT JOIN public.family_groups fg  ON fg.id  = s.family_group_id
LEFT JOIN public.family_groups fg2 ON fg2.id = s.allocation_group_id
WHERE s.id_number = '513435180'
   OR s.owner_name ILIKE '%וזוב%'
ORDER BY s.parcel, s.owner_name;


-- ============================================================
-- שאילתה 2: כל הרשומות של באבי (אליהו + ראובן)
-- ============================================================
SELECT
  s.owner_name AS "שם",
  s.id_number AS "ת.ז.",
  s.parcel AS "חלקה",
  s.ownership_category AS "קטגוריה",
  ROUND(COALESCE(s.agreement_area, 0)::numeric, 2) AS "agreement_area",
  ROUND(COALESCE(s.unification_area, 0)::numeric, 2) AS "unification_area",
  fg.family_name AS "קבוצה משפטית"
FROM public.signed_owners s
LEFT JOIN public.family_groups fg ON fg.id = s.family_group_id
WHERE s.id_number IN ('024493942', '027902063')
   OR s.owner_name ILIKE '%באבי%'
   OR s.owner_name ILIKE '%בבאי%'
ORDER BY s.id_number, s.parcel;


-- ============================================================
-- שאילתה 3: כל חברי קבוצת יצחקי בחלקה 14 — שטחים
-- ============================================================
SELECT
  s.owner_name AS "שם",
  s.id_number AS "ת.ז./ח.פ.",
  ROUND(COALESCE(s.agreement_area, 0)::numeric, 2) AS "ag_area",
  ROUND(COALESCE(s.unification_area, 0)::numeric, 2) AS "unif_area",
  s.ownership_category AS "קטגוריה"
FROM public.signed_owners s
WHERE s.family_group_id = 'a990ed96-5b11-4d1a-9db1-89c76833af8b'
  AND s.is_active = TRUE
  AND s.parcel = 14
ORDER BY s.agreement_area DESC NULLS LAST;


-- ============================================================
-- שאילתה 4: כל העמודות הקיימות בטבלת signed_owners
-- (לדעת מה יש לנו לעבוד איתו)
-- ============================================================
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'signed_owners'
ORDER BY ordinal_position;


-- ============================================================
-- 📋 צפי תוצאות:
--
-- שאילתה 1: 1-2 רשומות של וזוב — נראה מה ה-agreement_area
--           אם 0 → ההסבר; אם גדול → צריך לחפש דרך אחרת
--
-- שאילתה 2: 2 רשומות של באבי (אליהו + ראובן)
--
-- שאילתה 3: רשימת ~7 חברים בחלקה 14
--
-- שאילתה 4: רשימת כל העמודות הקיימות בטבלת signed_owners
-- ============================================================

-- ============================================================
-- 28_word_by_word_audit.sql  (12/05/2026 — עדכון 16:30)
-- ============================================================
-- מטרה: לזהות מקיפה של 18 ה"חסרים" — בכל דרך אפשרית.
--
-- 5 כיוונים שנבדקים בו זמנית לכל שם:
--   1. התאמת שם word-by-word ב-signed_owners (סדר שמות הפוך)
--   2. שייכות לעסקה ב-partnership_deals (כמוכר)
--   3. שייכות לקבוצת משפחה
--   4. צאצא/קרוב (כוכי בן גרא = קרוב של בן גרא עפרה)
--   5. סטטוס מאסטר ועדכון נדרש
--
-- בעקבות הצלבה ידנית: לפחות 6 מ-18 הם מוכרים בעסקאות
-- נדלן נדלן / דודי יצחקי, ולכן אולי קיימים ב-DB עם שטח מצומצם.
-- ============================================================

WITH master_missing AS (
  SELECT name, expected_parcels, expected_deal FROM (VALUES
    ('בן בסט טל', '5', NULL),
    ('בן גרא עפרה', '17', '#8 כוכי בן גרא'),
    ('בן חורין נורית', '28,51', '#1,#2 עסקת בן חורין'),
    ('בר שחר', '44', NULL),
    ('גולנדר אביאל', '44', NULL),
    ('דניאלי לביא', '68', NULL),
    ('הימן תמר', '49', NULL),
    ('זלץ דניאלה מאירה', '28,51', '#19,#20 עסקת גיל זלץ'),
    ('מיכאלי עמרי', '31', NULL),
    ('פיינשטין לימור', '13,31,49', NULL),
    ('פרסטנפלד יהודה', '44', NULL),
    ('פרסטנפלד תמר', '44', NULL),
    ('ראובן עמוס', '44', NULL),
    ('שביט אמנון', '51', NULL),
    ('שילוח אהודה', '28,51', NULL),
    ('שרוני ענבר מרים', '11,13,39,40', NULL),
    ('דנקר זהבה', '13,14', '#23 דודי יצחקי - דנקנר'),
    ('גולדמן משה', '17', '#18 עסקת גולדמן'),
    ('גולדמן תחיה', '17', '#18 עסקת גולדמן'),
    ('מורי רחל', '6', '#16 עסקת מורי/מוספי')
  ) AS m(name, expected_parcels, expected_deal)
),
master_words AS (
  SELECT name, expected_parcels, expected_deal,
    regexp_split_to_array(trim(name), '\s+') AS words
  FROM master_missing
),
-- בדיקה 1: התאמה word-by-word ב-signed_owners
db_match AS (
  SELECT DISTINCT ON (mw.name)
    mw.name AS master_name,
    s.id_number,
    s.owner_name AS db_owner_name,
    s.is_active,
    s.master_2015_status,
    s.ownership_category,
    s.parcel,
    s.agreement_area,
    fg.family_name
  FROM master_words mw
  JOIN public.signed_owners s ON (
    SELECT bool_and(s.owner_name LIKE '%' || w || '%')
    FROM unnest(mw.words) AS w
  )
  LEFT JOIN public.family_groups fg ON fg.id = s.family_group_id
  ORDER BY mw.name, s.is_active DESC NULLS LAST, s.agreement_area DESC NULLS LAST
),
-- בדיקה 2: שייכות לעסקה ב-partnership_deals (לפי שם)
deal_match AS (
  SELECT DISTINCT ON (mw.name)
    mw.name AS master_name,
    pd.deal_number,
    pd.deal_name,
    pd.parcel AS deal_parcel,
    pd.area_sqm AS deal_area,
    pd.category AS deal_category
  FROM master_words mw
  JOIN public.partnership_deals pd ON (
    pd.deal_name LIKE '%' || mw.words[1] || '%'  -- מתחיל בשם משפחה
    OR (cardinality(mw.words) > 1 AND pd.deal_name LIKE '%' || mw.words[2] || '%')
  )
  WHERE pd.is_active = TRUE
  ORDER BY mw.name, pd.deal_number
),
-- בדיקה 3: שייכות לקבוצת משפחה (לפי שם)
group_match AS (
  SELECT DISTINCT ON (mw.name)
    mw.name AS master_name,
    fg.family_name AS family_group_name
  FROM master_words mw
  JOIN public.family_groups fg ON (
    SELECT bool_or(fg.family_name LIKE '%' || w || '%')
    FROM unnest(mw.words) AS w
  )
  ORDER BY mw.name, fg.family_name
)
-- תוצאה סופית עם כל הכיוונים
SELECT
  mm.name AS "שם_מאסטר",
  mm.expected_parcels AS "חלקות_צפויות",
  mm.expected_deal AS "עסקה_צפויה",
  CASE
    WHEN dbm.id_number IS NOT NULL AND dbm.is_active THEN
      '🟢 פעיל ב-DB: ' || dbm.db_owner_name || ' (' || dbm.id_number || ')'
    WHEN dbm.id_number IS NOT NULL THEN
      '🟡 ב-DB אבל לא פעיל: ' || dbm.db_owner_name
    WHEN gm.family_group_name IS NOT NULL THEN
      '🟢 קבוצת משפחה: ' || gm.family_group_name
    ELSE
      '🔴 לא נמצא'
  END AS "סטטוס_בעלים",
  CASE
    WHEN dm.deal_number IS NOT NULL THEN
      'עסקה #' || dm.deal_number || ': ' || dm.deal_name || ' (חלקה ' || dm.deal_parcel || ', ' || ROUND(dm.deal_area::numeric) || ' מ"ר)'
    ELSE
      '—'
  END AS "עסקה_שותפות",
  dbm.master_2015_status AS "סטטוס_מאסטר_2015",
  dbm.ownership_category AS "קטגוריה",
  dbm.family_name AS "קבוצה_נוכחית_DB"
FROM master_missing mm
LEFT JOIN db_match dbm ON dbm.master_name = mm.name
LEFT JOIN deal_match dm ON dm.master_name = mm.name
LEFT JOIN group_match gm ON gm.master_name = mm.name
ORDER BY
  CASE
    WHEN dbm.id_number IS NOT NULL AND dbm.is_active THEN 1
    WHEN dbm.id_number IS NOT NULL THEN 2
    WHEN gm.family_group_name IS NOT NULL OR dm.deal_number IS NOT NULL THEN 3
    ELSE 4
  END,
  mm.name;


-- ============================================================
-- שאילתה משלימה: כל המוכרים בעסקאות נדלן נדלן/דודי יצחקי
-- ============================================================
-- מציגה לאיזו עסקה כל חתום מקור 2015 נמצא, אם בכלל
SELECT
  pd.deal_number AS "#",
  pd.deal_name AS "שם_עסקה",
  pd.parcel AS "חלקה",
  ROUND(pd.area_sqm::numeric) AS "שטח_עסקה",
  pd.category AS "קטגוריה",
  pd.status AS "סטטוס_עסקה",
  pd.notes AS "הערות"
FROM public.partnership_deals pd
WHERE pd.is_active = TRUE
ORDER BY pd.deal_number;

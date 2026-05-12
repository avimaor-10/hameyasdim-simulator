-- ============================================================
-- 26_smart_audit_master_2015.sql  (12/05/2026)
-- ============================================================
-- מטרה: אבחון חכם של 32 ה"חסרים" — בדיקה מ-5 כיוונים:
--   1. שם מדויק או דומה
--   2. וריאציות איות נפוצות (אורה=אלה, היימן=הימן, וכו')
--   3. ת"ז (אם ידועה)
--   4. קיום ב-family_groups (גם אם הבעלים עצמו לא ב-DB)
--   5. בדיקה לפי חלקה — אם יש בעלים אחר בחלקה הצפויה
--
-- תוצאה: סיווג מדויק של כל אחד מ-32 ה"חסרים":
--   🟢 טופל (וריאציה, יורש, או קבוצה)
--   🟠 חסר אמיתי — צריך להוסיף
-- ============================================================

WITH master_missing AS (
  -- 32 השמות שסקריפט 25 הציג כ-"חסרים לחלוטין"
  SELECT name, expected_parcels FROM (VALUES
    ('בן בסט טל', '5'),
    ('בן גרא עפרה', '17'),
    ('בן חורין נורית', '28,51'),
    ('בר שחר', '44'),
    ('גולדמן משה', '17'),
    ('גולדמן תחיה', '17'),
    ('גולנדר אביאל', '44'),
    ('דודיוביץ אורה', '13,16,49'),       -- וריאציה: דוידוביץ
    ('דניאלי לביא', '68'),
    ('דנקר זהבה', '13,14'),               -- וריאציה: דנקנר
    ('הימן תמר', '49'),                   -- וריאציה: היימן
    ('זלץ דניאלה מאירה', '28,51'),
    ('יוחננוף עירית', '11,13,39,40'),
    ('יניר נועם פלדמן', '11,13,39,40'),
    ('מורי רחל', '6'),
    ('מיכאלי עמרי', '31'),
    ('סטולר אורה', '8'),                  -- וריאציה: סטולר אלה
    ('פיינשטין לימור', '13,31,49'),
    ('פרסטנפלד יהודה', '44'),
    ('פרסטנפלד תמר', '44'),
    ('ראובן עמוס', '44'),
    ('שביט אמנון', '51'),
    ('שילוח אהודה', '28,51'),
    ('שרוני ענבר מרים', '11,13,39,40')
    -- חסרים 8 שמות שלא ראיתי בצילומים — אוסיף אם תשלח
  ) AS m(name, expected_parcels)
),
-- בדיקה 1: שם דומה ב-signed_owners (גם is_active=FALSE)
check_db_name AS (
  SELECT DISTINCT mm.name,
    s.owner_name AS db_name,
    s.id_number,
    s.is_active
  FROM master_missing mm
  JOIN public.signed_owners s ON (
    -- התאמת שם מורחבת — מטפלת בוריאציות
    s.owner_name ILIKE '%' || mm.name || '%'
    OR mm.name ILIKE '%' || s.owner_name || '%'
    OR (mm.name LIKE 'דודיוביץ%' AND s.owner_name LIKE 'דוידוביץ%')
    OR (mm.name LIKE 'דוידוביץ%' AND s.owner_name LIKE 'דודיוביץ%')
    OR (mm.name LIKE 'דנקר%' AND s.owner_name LIKE 'דנקנר%')
    OR (mm.name LIKE 'הימן%' AND s.owner_name LIKE 'היימן%')
    OR (mm.name LIKE 'סטולר אורה' AND s.owner_name LIKE 'סטולר אלה%')
    OR (mm.name LIKE 'פיינשטין%' AND s.owner_name LIKE 'פינשטיין%')
  )
),
-- בדיקה 2: שייכות לקבוצה (לפי שם)
check_family_group AS (
  SELECT DISTINCT mm.name,
    fg.family_name AS group_name
  FROM master_missing mm
  JOIN public.family_groups fg ON (
    fg.family_name ILIKE '%' || mm.name || '%'
    OR mm.name ILIKE '%' || fg.family_name || '%'
    -- וריאציות שמות משפחה
    OR (mm.name LIKE 'דודיוביץ%' AND fg.family_name LIKE '%דוידוביץ%')
    OR (mm.name LIKE 'גולדמן%' AND fg.family_name LIKE '%גולדמן%')
    OR (mm.name LIKE 'דנקר%' AND fg.family_name LIKE '%יצחקי%')
    OR (mm.name LIKE 'הימן%' AND fg.family_name LIKE '%היימן%')
    OR (mm.name LIKE 'יוחננוף%' AND fg.family_name LIKE '%עוצמה%')
    OR (mm.name LIKE 'יניר%' AND fg.family_name LIKE '%עוצמה%')
    OR (mm.name LIKE 'סטולר%' AND fg.family_name LIKE '%גלמן%')
    OR (mm.name LIKE 'פיינשטין%' AND fg.family_name LIKE '%פלדמן%')
    OR (mm.name LIKE 'בן חורין%' AND fg.family_name LIKE '%בוקסר%')
    OR (mm.name LIKE 'שילוח%' AND fg.family_name LIKE '%בוקסר%')
    OR (mm.name LIKE 'גרצברג%' AND fg.family_name LIKE '%בוקסר%')
    OR (mm.name LIKE 'זלץ%' AND fg.family_name LIKE '%זלץ%')
    OR (mm.name LIKE 'מורי%' AND fg.family_name LIKE '%מורי%')
  )
)
-- סיווג סופי לכל אחד מ-32 השמות
SELECT
  mm.name AS master_name,
  mm.expected_parcels AS חלקות_צפויות,
  CASE
    WHEN cdb.db_name IS NOT NULL AND cdb.is_active = TRUE THEN
      '🟢 פעיל ב-DB בשם דומה: ' || cdb.db_name
    WHEN cdb.db_name IS NOT NULL AND cdb.is_active = FALSE THEN
      '🟡 לא פעיל ב-DB: ' || cdb.db_name
    WHEN cfg.group_name IS NOT NULL THEN
      '🟢 קבוצת משפחה קיימת: ' || cfg.group_name
    ELSE
      '🔴 חסר אמיתי — דורש הוספה!'
  END AS סטטוס
FROM master_missing mm
LEFT JOIN check_db_name cdb ON cdb.name = mm.name
LEFT JOIN check_family_group cfg ON cfg.name = mm.name
ORDER BY
  CASE
    WHEN cdb.db_name IS NOT NULL AND cdb.is_active = TRUE THEN 1
    WHEN cdb.db_name IS NOT NULL AND cdb.is_active = FALSE THEN 2
    WHEN cfg.group_name IS NOT NULL THEN 3
    ELSE 4
  END,
  mm.name;


-- ============================================================
-- דוח נוסף: שאר 8 השמות שלא ראיתי בצילומים — אבקש הסקנה
-- ============================================================
-- אם יש 32 שמות במאסטר ובדקתי רק 24, חסרים 8.
-- השאילתה למטה מציגה את ה-8 הנוספים שלא ראיתי:

WITH master_2015 AS (
  SELECT unnest(ARRAY[
    'אטלן נועה','אלוני חיים','אשר נחום','אשר סמדר','בוקסר און','בוקסר משה',
    'בן בסט טל','בן גרא עפרה','בן דוד מרב','בן חורין נורית','בן טוב טל',
    'בר שחר','בראל רחל','ברקוביץ פלדמן רחל','גבאי מרדכי','גולדמן משה',
    'גולדמן תחיה','גולנדר אביאל','גרצברג ליאורה','דודיוביץ אורה',
    'דניאלי יהודה','דניאלי לביא','דניאלי עמוס','דנקר זהבה','דרומי אסתר',
    'דרורי אליהו','דרורי מיכל','הוכברג אורי','הוכברג דן','הוכברג נעמי',
    'הוכברג ענת','הימן דוד','הימן תמר','זייגרמן צבי','זייגרמן רונן',
    'זלץ דניאלה מאירה','חייט רות','חלף בן עמי','חלף שלמה','טחנאי משה',
    'טכקיזדה אייל','יוחננוף עירית','ילובסקי משה מאיר','יניר נועם פלדמן',
    'כץ רוחמה','לוין בוריס','לחגי משה','ליפ אייל','ליפ דביר','מועלם אליהו',
    'מועלם פרידה','מורי מאיר','מורי רחל','מיכאלי מיקי','מיכאלי עמרי',
    'מילוסלבסקי גרשון אורי','מילט אורנה רגינה','מילט גלוריה בטי','מסלוי איזיק',
    'מרקוויץ מרקוס','מרקוויץ רגינה','נאמן גלילה','סטולר אורה',
    'ספיר שלמה שלומי','פיינשטין לימור','פלדמן אהרון','פלדמן אמנון','פלדמן דוד',
    'פלדמן יוסף','פרסטנפלד יהודה','פרסטנפלד תמר','צלליכין רוחמה','צפירה יהודה',
    'קובו לאה','קפלן (ילובסקי) צפורה','ראובן עמוס','שביט אמנון','שביט שרון',
    'שילוח אהודה','שקד הדר','שרוני ענבר מרים','שריקר פסח'
  ]) AS name
)
SELECT m.name AS missing_master_name
FROM master_2015 m
WHERE NOT EXISTS (
  SELECT 1 FROM public.signed_owners s
  WHERE s.owner_name ILIKE '%' || m.name || '%'
     OR m.name ILIKE '%' || s.owner_name || '%'
)
ORDER BY m.name;

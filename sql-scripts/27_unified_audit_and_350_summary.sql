-- ============================================================
-- 27_unified_audit_and_350_summary.sql  (12/05/2026)
-- ============================================================
-- מטרה: סקריפט מאוחד שמחליף את כל הסקריפטים הקודמים לאבחון:
--   • שאילתה A: סיווג חכם של 32 ה"חסרים" (5 בדיקות)
--   • שאילתה B: סיכום 350 דונם — Sprint 1.5
--   • שאילתה C: בדיקת יתומים אחרי סקריפט 24
--   • שאילתה D: חוקת בעלים פעילים — לפי מקור (חתימה / יורש / רוכש משני / שותפות)
--   • שאילתה E: רשימה סופית של "חסרים אמיתיים" שצריך להוסיף ל-DB
--
-- שימוש בסופאבייס:
--   להריץ כל שאילתה בנפרד (לסמן את הבלוק בין שני "===" ולעשות Ctrl+Enter)
--   כל שאילתה מוחזרת ב-Results חדש.
-- ============================================================


-- ============================================================
-- שאילתה A — סיווג חכם של 32 ה"חסרים"
-- ============================================================
-- מחזירה את כל 32 השמות עם סיווג ל-4 קטגוריות
WITH master_missing AS (
  SELECT name, expected_parcels FROM (VALUES
    ('בן בסט טל', '5'),
    ('בן גרא עפרה', '17'),
    ('בן חורין נורית', '28,51'),
    ('בר שחר', '44'),
    ('גולדמן משה', '17'),
    ('גולדמן תחיה', '17'),
    ('גולנדר אביאל', '44'),
    ('דודיוביץ אורה', '13,16,49'),
    ('דניאלי לביא', '68'),
    ('דנקר זהבה', '13,14'),
    ('הימן תמר', '49'),
    ('זלץ דניאלה מאירה', '28,51'),
    ('יוחננוף עירית', '11,13,39,40'),
    ('יניר נועם פלדמן', '11,13,39,40'),
    ('מורי רחל', '6'),
    ('מיכאלי עמרי', '31'),
    ('סטולר אורה', '8'),
    ('פיינשטין לימור', '13,31,49'),
    ('פרסטנפלד יהודה', '44'),
    ('פרסטנפלד תמר', '44'),
    ('ראובן עמוס', '44'),
    ('שביט אמנון', '51'),
    ('שילוח אהודה', '28,51'),
    ('שרוני ענבר מרים', '11,13,39,40')
  ) AS m(name, expected_parcels)
),
-- בדיקה 1: שם דומה ב-signed_owners (כל הוריאציות)
check_db AS (
  SELECT mm.name AS master_name,
    string_agg(DISTINCT s.owner_name || ' (' || COALESCE(s.id_number, '?') || ', ' ||
                        CASE WHEN s.is_active THEN 'פעיל' ELSE 'לא פעיל' END || ')', ' | ') AS db_matches,
    bool_or(s.is_active) AS has_active,
    string_agg(DISTINCT COALESCE(fg.family_name, '—'), ', ') AS in_groups
  FROM master_missing mm
  LEFT JOIN public.signed_owners s ON (
    s.owner_name ILIKE '%' || mm.name || '%'
    OR mm.name ILIKE '%' || s.owner_name || '%'
    -- וריאציות איות
    OR (mm.name = 'דודיוביץ אורה' AND s.owner_name ILIKE 'דוידוביץ%אורה%')
    OR (mm.name = 'דודיוביץ אורה' AND s.owner_name ILIKE '%זיצוב%אורה%')
    OR (mm.name = 'דנקר זהבה' AND s.owner_name ILIKE 'דנקנר%')
    OR (mm.name = 'הימן תמר' AND s.owner_name ILIKE 'היימן%תמר%')
    OR (mm.name = 'סטולר אורה' AND s.owner_name ILIKE 'סטולר%אלה%')
    OR (mm.name = 'פיינשטין לימור' AND s.owner_name ILIKE 'פינשטיין%')
    OR (mm.name = 'פיינשטין לימור' AND s.owner_name ILIKE '%פלדמן%לימור%')
    OR (mm.name = 'שרוני ענבר מרים' AND s.owner_name ILIKE '%ענבר%')
    OR (mm.name = 'יוחננוף עירית' AND s.owner_name ILIKE '%יוחננוף%')
    OR (mm.name = 'יניר נועם פלדמן' AND s.owner_name ILIKE '%יניר%')
    OR (mm.name = 'יניר נועם פלדמן' AND s.owner_name ILIKE '%נועם%פלדמן%')
  )
  LEFT JOIN public.family_groups fg ON fg.id = s.family_group_id
  GROUP BY mm.name
),
-- בדיקה 2: שייכות לקבוצה לפי שם
check_grp AS (
  SELECT mm.name AS master_name,
    string_agg(DISTINCT fg.family_name, ' | ') AS group_matches
  FROM master_missing mm
  LEFT JOIN public.family_groups fg ON (
    fg.family_name ILIKE '%' || mm.name || '%'
    OR mm.name ILIKE '%' || fg.family_name || '%'
    OR (mm.name LIKE 'דודיוביץ%' AND fg.family_name ILIKE '%דוידוביץ%')
    OR (mm.name LIKE 'גולדמן%' AND fg.family_name ILIKE '%גולדמן%')
    OR (mm.name LIKE 'דנקר%' AND fg.family_name ILIKE '%יצחקי%')
    OR (mm.name LIKE 'הימן%' AND fg.family_name ILIKE '%היימן%')
    OR (mm.name LIKE 'יוחננוף%' AND fg.family_name ILIKE '%עוצמה%')
    OR (mm.name LIKE 'יניר%' AND fg.family_name ILIKE '%עוצמה%')
    OR (mm.name LIKE 'שרוני%' AND fg.family_name ILIKE '%עוצמה%')
    OR (mm.name LIKE 'סטולר%' AND fg.family_name ILIKE '%גלמן%')
    OR (mm.name LIKE 'פיינשטין%' AND fg.family_name ILIKE '%פלדמן%')
    OR (mm.name LIKE 'בן חורין%' AND fg.family_name ILIKE '%בוקסר%')
    OR (mm.name LIKE 'שילוח%' AND fg.family_name ILIKE '%בוקסר%')
    OR (mm.name LIKE 'זלץ%' AND fg.family_name ILIKE '%זלץ%')
    OR (mm.name LIKE 'מורי%' AND fg.family_name ILIKE '%מורי%')
  )
  GROUP BY mm.name
)
SELECT
  mm.name AS שם_מאסטר,
  mm.expected_parcels AS חלקות_צפויות,
  CASE
    WHEN cdb.has_active = TRUE THEN '🟢 פעיל ב-DB'
    WHEN cdb.db_matches IS NOT NULL AND cdb.has_active = FALSE THEN '🟡 קיים אבל לא פעיל'
    WHEN cgrp.group_matches IS NOT NULL THEN '🟢 בקבוצה'
    ELSE '🔴 חסר אמיתי'
  END AS סטטוס,
  cdb.db_matches AS התאמות_DB,
  cdb.in_groups AS שייך_לקבוצה,
  cgrp.group_matches AS קבוצה_לפי_שם
FROM master_missing mm
LEFT JOIN check_db cdb ON cdb.master_name = mm.name
LEFT JOIN check_grp cgrp ON cgrp.master_name = mm.name
ORDER BY
  CASE
    WHEN cdb.has_active = TRUE THEN 1
    WHEN cdb.db_matches IS NOT NULL THEN 2
    WHEN cgrp.group_matches IS NOT NULL THEN 3
    ELSE 4
  END,
  mm.name;


-- ============================================================
-- שאילתה B — סיכום 350 דונם (Sprint 1.5)
-- ============================================================
-- שטח כולל פעיל לפי קבוצה, יתומים, ולא-פעילים (לצרכי השוואה)
WITH stats AS (
  SELECT
    CASE
      WHEN s.is_active = FALSE THEN 'לא פעיל (היסטוריה)'
      WHEN s.family_group_id IS NULL THEN 'יתומים (ללא קבוצה)'
      ELSE COALESCE(fg.family_name, 'לא ידוע')
    END AS category,
    s.is_active,
    COUNT(*) AS records,
    COUNT(DISTINCT s.id_number) AS unique_owners,
    ROUND(SUM(s.agreement_area)::numeric, 0) AS area_m2,
    ROUND(SUM(s.agreement_area * COALESCE(pm.participation_factor::numeric, 1))::numeric, 0) AS area_in_unification
  FROM public.signed_owners s
  LEFT JOIN public.family_groups fg ON fg.id = s.family_group_id
  LEFT JOIN public.parcels_meta pm ON pm.parcel = s.parcel
  GROUP BY 1, 2
)
SELECT
  category AS קטגוריה,
  records AS רשומות,
  unique_owners AS בעלים_ייחודיים,
  area_m2 AS שטח_רשום_מר,
  area_in_unification AS שטח_לאיחוד_מר
FROM stats
ORDER BY
  CASE WHEN category = 'יתומים (ללא קבוצה)' THEN 1
       WHEN category = 'לא פעיל (היסטוריה)' THEN 99
       ELSE 50 END,
  area_m2 DESC;


-- ============================================================
-- שאילתה C — בדיקת יתומים סופית אחרי סקריפט 24
-- ============================================================
-- האם נשארו יתומים? כמה? איזה שטח?
SELECT
  COUNT(*) AS רשומות_יתומות,
  COUNT(DISTINCT id_number) AS בעלים_ייחודיים_יתומים,
  ROUND(SUM(agreement_area)::numeric, 0) AS שטח_יתומים_מר,
  ROUND((SUM(agreement_area) / NULLIF((SELECT SUM(agreement_area) FROM public.signed_owners WHERE is_active = TRUE), 0) * 100)::numeric, 1) AS אחוז_מסך_פעיל
FROM public.signed_owners
WHERE is_active = TRUE AND family_group_id IS NULL;


-- ============================================================
-- שאילתה D — חוקת בעלים פעילים לפי מקור
-- ============================================================
-- פילוח של master_2015_status — מי חתום מקורי, מי יורש, מי רוכש משני, וכו'
SELECT
  COALESCE(master_2015_status, 'לא מסווג') AS סטטוס_מקור,
  COALESCE(ownership_category, 'לא מסווג') AS קטגורית_בעלות,
  COUNT(*) AS רשומות,
  COUNT(DISTINCT id_number) AS בעלים_ייחודיים,
  ROUND(SUM(agreement_area)::numeric, 0) AS שטח_מר
FROM public.signed_owners
WHERE is_active = TRUE
GROUP BY master_2015_status, ownership_category
ORDER BY שטח_מר DESC;


-- ============================================================
-- שאילתה E — רשימה סופית של "חסרים אמיתיים"
-- ============================================================
-- שמות מ-2015 שאין להם זכר ב-DB ולא בקבוצות — צריך להוסיף ידנית
WITH master_missing AS (
  SELECT name FROM (VALUES
    ('בן בסט טל'), ('בן גרא עפרה'), ('בן חורין נורית'), ('בר שחר'),
    ('גולדמן משה'), ('גולדמן תחיה'), ('גולנדר אביאל'), ('דודיוביץ אורה'),
    ('דניאלי לביא'), ('דנקר זהבה'), ('הימן תמר'), ('זלץ דניאלה מאירה'),
    ('יוחננוף עירית'), ('יניר נועם פלדמן'), ('מורי רחל'), ('מיכאלי עמרי'),
    ('סטולר אורה'), ('פיינשטין לימור'), ('פרסטנפלד יהודה'), ('פרסטנפלד תמר'),
    ('ראובן עמוס'), ('שביט אמנון'), ('שילוח אהודה'), ('שרוני ענבר מרים')
  ) AS m(name)
)
SELECT mm.name AS שם_חסר
FROM master_missing mm
WHERE NOT EXISTS (
  SELECT 1 FROM public.signed_owners s
  WHERE s.owner_name ILIKE '%' || mm.name || '%'
     OR mm.name ILIKE '%' || s.owner_name || '%'
     OR (mm.name = 'דודיוביץ אורה' AND s.owner_name ILIKE 'דוידוביץ%')
     OR (mm.name = 'דנקר זהבה' AND s.owner_name ILIKE 'דנקנר%')
     OR (mm.name = 'הימן תמר' AND s.owner_name ILIKE 'היימן%')
     OR (mm.name = 'סטולר אורה' AND s.owner_name ILIKE 'סטולר%אלה%')
     OR (mm.name = 'פיינשטין לימור' AND s.owner_name ILIKE 'פינשטיין%')
)
AND NOT EXISTS (
  SELECT 1 FROM public.family_groups fg
  WHERE fg.family_name ILIKE '%' || mm.name || '%'
     OR (mm.name LIKE 'יוחננוף%' AND fg.family_name ILIKE '%עוצמה%')
     OR (mm.name LIKE 'יניר%' AND fg.family_name ILIKE '%עוצמה%')
     OR (mm.name LIKE 'שרוני%' AND fg.family_name ILIKE '%עוצמה%')
)
ORDER BY mm.name;


-- ============================================================
-- צפי תוצאות:
--
-- שאילתה A: 32 שורות עם סיווג —
--   ~20 צפויות 🟢 (פעיל ב-DB או בקבוצה)
--   ~8-12 צפויות 🔴 (חסר אמיתי, רוב הסיכוי בני זוג של חתום אחר)
--
-- שאילתה B: ~10 שורות לפי קבוצה —
--   קבוצת עוצמה (~141 חברים, ~18,543 מ"ר)
--   משפחת בוקסר, פלדמן, מועלם, מורי, גלמן, חנן מור השקעות, וכו'
--   סך הכל פעיל צפוי: ~350,000 מ"ר
--
-- שאילתה C: צפי <50 רשומות יתומות אחרי סקריפט 24 (אם נשארו)
--
-- שאילתה D: פילוח לפי מקור — verified / successor / partnership_buyer / וכו'
--
-- שאילתה E: רשימה קצרה של חסרים אמיתיים שצריך להוסיף
-- ============================================================

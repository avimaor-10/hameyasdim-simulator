-- ============================================================
-- 70_find_yitzhaki_chalka14_candidates.sql  (14/05/2026)
-- ============================================================
-- 🎯 מטרה: למצוא ב-DB את כל החתומים בחלקה 14 שאמורים להיות
--          בקבוצת ההקצאה של יצחקי, כדי שנדע מה למזג לפני העברה.
--
-- 📐 לפי האקסל "תחשיב דמי ייזום עסקת דנקנר דודי יצחקי":
--   • 6 ישויות-אם: וזוב, ולנסיה, דסטא, מחלבות, אליהו באבי, ראובן באבי
--   • 52 רוכשים פרטיים ישירים (~5,483 מ"ר)
--   • +חנן מור (2,000 מ"ר אופציה — אלה הם 2 דונם של השותפות)
--
-- 🔒 SELECT בלבד. בטוח לחלוטין.
-- 🆔 קבוצת יצחקי: a990ed96-5b11-4d1a-9db1-89c76833af8b
-- ============================================================


-- ============================================================
-- שאילתה 1: כל החתומים בחלקה 14 — תמונת מצב מלאה
-- (לפני כל פעולה — נראה מי על החלקה ובאיזו קבוצה)
-- ============================================================
SELECT
  '👥 חתומי חלקה 14 — מצב נוכחי' AS "מדד",
  s.owner_name AS "שם",
  s.id_number AS "ת.ז.",
  ROUND(COALESCE(s.agreement_area, 0)::numeric, 2) AS "שטח הסכם",
  COALESCE(fg.family_name, '⚠ ללא קבוצה') AS "קבוצה נוכחית",
  s.ownership_category AS "קטגוריה"
FROM public.signed_owners s
LEFT JOIN public.family_groups fg ON fg.id = s.family_group_id
WHERE s.parcel = 14
  AND s.is_active = TRUE
ORDER BY fg.family_name NULLS FIRST, s.agreement_area DESC NULLS LAST;


-- ============================================================
-- שאילתה 2: 6 הישויות-אם — חיפוש מדויק
-- (וזוב, ולנסיה, דסטא, מחלבות, באבי)
-- ============================================================
SELECT
  '🏢 ישויות-אם בחלקה 14' AS "מדד",
  s.owner_name AS "שם",
  s.id_number AS "ת.ז.",
  s.parcel AS "חלקה",
  ROUND(COALESCE(s.agreement_area, 0)::numeric, 2) AS "שטח",
  COALESCE(fg.family_name, '⚠ ללא קבוצה') AS "קבוצה נוכחית"
FROM public.signed_owners s
LEFT JOIN public.family_groups fg ON fg.id = s.family_group_id
WHERE s.is_active = TRUE
  AND (
    s.owner_name ILIKE '%וזוב%'
    OR s.owner_name ILIKE '%ולנסיה%'
    OR s.owner_name ILIKE '%דסטא%'
    OR s.owner_name ILIKE '%מחלבות%'
    OR s.owner_name ILIKE '%באבי%'
  )
ORDER BY s.owner_name;


-- ============================================================
-- שאילתה 3: כל העסקאות בחלקה 14
-- ============================================================
SELECT
  '🏢 עסקאות בחלקה 14' AS "מדד",
  pd.deal_number AS "#",
  pd.deal_name AS "שם עסקה",
  ROUND(COALESCE(pd.area_sqm, 0)::numeric, 2) AS "שטח",
  COALESCE(fg.family_name, '⚠ ללא קבוצה') AS "קבוצה"
FROM public.partnership_deals pd
LEFT JOIN public.family_groups fg ON fg.id = pd.family_group_id
WHERE pd.parcel = 14
  AND pd.is_active = TRUE
ORDER BY pd.area_sqm DESC NULLS LAST;


-- ============================================================
-- שאילתה 4: חיפוש 52 הרוכשים הישירים — לפי תבניות שם מפתח
-- (משתמש בשמות-מפתח שצפויים להופיע ב-DB)
-- ============================================================
WITH expected_buyers AS (
  SELECT * FROM (VALUES
    ('מקמל'),
    ('TRORATO'),
    ('חסון'),
    ('לוינר'),
    ('שרמן'),
    ('יהושוע לוי'),
    ('מיכאל לוי'),
    ('שירה לוי'),
    ('ליאון יחזקאל'),
    ('מנשה אבני'),
    ('יובל כהן'),
    ('מייזליק'),
    ('חוגי'),
    ('מדמון'),
    ('סנדיאל'),
    ('אייל בן דוד'),
    ('ביגון'),
    ('שגיב שפיר'),
    ('אלדן דורון'),
    ('בר דוד'),
    ('אוקנין'),
    ('אריק'),
    ('טל וגלית'),
    ('אפרת מוריה'),
    ('אוריאל ונעמי'),
    ('גולבסקי'),
    ('אי.סי.יו'),
    ('ברנהולץ'),
    ('עמית לבנון'),
    ('תבק'),
    ('נתנאל אזולאי'),
    ('אליחן'),
    ('סננס'),
    ('דורון סנדרס'),
    ('עידו אדיב'),
    ('קובי תמם'),
    ('גל רובין'),
    ('אלפסי'),
    ('מורן לוי'),
    ('ז.י.כ פרויקטים'),
    ('עוזיאל לוי'),
    ('עטאר'),
    ('אולשטיין'),
    ('אלאדין'),
    ('גדעון פלד'),
    ('צח איילת'),
    ('בן זקן'),
    ('תומר יוסף אזולאי'),
    ('אטיאס'),
    ('קניאל'),
    ('חגג'),
    ('רודובסקי')
  ) AS t(name_part)
)
SELECT
  '🔍 חיפוש 52 הרוכשים הישירים' AS "מדד",
  eb.name_part AS "חיפוש",
  s.owner_name AS "שם ב-DB",
  s.id_number AS "ת.ז.",
  s.parcel AS "חלקה",
  ROUND(COALESCE(s.agreement_area, 0)::numeric, 2) AS "שטח",
  COALESCE(fg.family_name, '⚠ ללא קבוצה') AS "קבוצה"
FROM expected_buyers eb
LEFT JOIN public.signed_owners s
  ON s.is_active = TRUE
  AND s.parcel = 14
  AND s.owner_name ILIKE '%' || eb.name_part || '%'
LEFT JOIN public.family_groups fg ON fg.id = s.family_group_id
ORDER BY
  CASE WHEN s.owner_name IS NULL THEN 0 ELSE 1 END,  -- חסרים בראש
  eb.name_part;


-- ============================================================
-- שאילתה 5: סיכום קבוצות בחלקה 14
-- ============================================================
SELECT
  '📊 סיכום קבוצות חלקה 14' AS "מדד",
  COALESCE(fg.family_name, '⚠ ללא קבוצה') AS "קבוצה",
  COUNT(s.id) AS "מס׳ חתומים",
  ROUND(SUM(COALESCE(s.agreement_area, 0))::numeric, 2) AS "סך שטחי הסכם"
FROM public.signed_owners s
LEFT JOIN public.family_groups fg ON fg.id = s.family_group_id
WHERE s.parcel = 14
  AND s.is_active = TRUE
GROUP BY fg.family_name
ORDER BY SUM(COALESCE(s.agreement_area, 0)) DESC NULLS LAST;


-- ============================================================
-- 📋 צפי תוצאות:
--
-- שאילתה 1: רשימת כל החתומים בחלקה 14 (סדר לפי קבוצה)
--           - יציג מי כבר ביצחקי, מי בקבוצות אחרות, מי "ללא קבוצה"
--
-- שאילתה 2: 6 שורות (אם כל הישויות-אם קיימות)
--           אם פחות → חסר אחת/יותר
--
-- שאילתה 3: עסקאות חלקה 14 — בעיקר:
--           - עסקת וזוב (1,500 מ"ר) — צריך להיות בנדל"ן נדל"ן
--           - עסקת דסטא מחלבות (500 מ"ר) — צריך להיות בנדל"ן נדל"ן
--
-- שאילתה 4: 52 שורות לפחות. NULL בשם DB = חיפוש שלא מצא תאמה
--
-- שאילתה 5: התפלגות לפי קבוצה. צפוי שיהיו ב-"ללא קבוצה" / קבוצות אחרות
--           שצריכות לעבור לקבוצת יצחקי.
--
-- ➡ אחרי הריצה — תשלח צילום של שאילתות 2 ו-5 (האחרונות בעורך).
-- ➡ נחליט יחד מי להעביר לקבוצת יצחקי בסקריפט 71.
-- ============================================================

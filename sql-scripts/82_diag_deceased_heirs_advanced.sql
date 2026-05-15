-- ============================================================
-- 82_diag_deceased_heirs_advanced.sql  (15/05/2026)
-- ============================================================
-- 🎯 מטרה: לזהות יורשים אפשריים של 6 הנפטרים הנותרים
--          (סקריפט 77 לא מצא להם יורשים אוטומטית).
--
-- 📚 הקשר: סקריפט 77 חיפש "אותה חלקה + שם משפחה דומה".
--          הוא לא מצא כי:
--           • לא תמיד היורשים בעלי שם משפחה זהה (חתן/אישה)
--           • לא תמיד באותה חלקה
--           • לפעמים יש 'successor_to_2015_signer' בלי קשר ברור למוריש
--
-- 📐 שלוש אסטרטגיות חיפוש:
--   A. רשומות עם successor_to_2015_signer באותה חלקה (כל שם)
--   B. רשומות שבשם או הערה מופיע שם המוריש
--   C. רשומות שהשם של הנפטר מופיע אצלן בשם בסוגריים (לדוגמה: "ביזיהל דוד (יורש בוקסר)")
--
-- 🔒 SELECT בלבד. בטוח לחלוטין.
-- ============================================================


-- ============================================================
-- שאילתה 1: רשימת המנוחים שעדיין is_active=TRUE
-- ============================================================
SELECT
  s.id AS "id",
  s.owner_name AS "שם המנוח",
  s.id_number AS "ת.ז.",
  s.parcel AS "חלקה",
  s.agreement_area AS "שטח",
  COALESCE(s.master_2015_status, '(NULL)') AS "סטטוס"
FROM public.signed_owners s
WHERE (s.owner_name ILIKE '%ז"ל%' OR s.owner_name ILIKE '%ז''ל%')
  AND s.is_active = TRUE
ORDER BY s.parcel, s.owner_name;


-- ============================================================
-- שאילתה 2 (אסטרטגיה A): יורשים אפשריים — אותה חלקה + successor_to_2015_signer
-- (מי בכלל יורש מ-2015 באותה חלקה? שאלה רחבה יותר מ-77)
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
  ROUND(s.agreement_area::numeric, 2) AS "שטח יורש",
  COALESCE(LEFT(s.master_2015_notes, 60), '') AS "הערה (60 תווים)"
FROM deceased d
JOIN public.signed_owners s
  ON s.parcel = d.parcel
  AND s.is_active = TRUE
  AND s.master_2015_status = 'successor_to_2015_signer'
  AND s.inherited_from_id_number IS NULL  -- עוד לא מקושר
  AND s.id != d.id
ORDER BY d.parcel, d.owner_name, s.owner_name;


-- ============================================================
-- שאילתה 3 (אסטרטגיה B): רשומות שבשם או הערה מופיע שם המוריש
-- (אם הנפטר הוא "בוקסר משה ז"ל", חפש "בוקסר" אצל יורשים)
-- ============================================================
WITH deceased AS (
  SELECT
    id,
    owner_name,
    id_number,
    parcel,
    -- חישוב שם בלי "ז"ל" — להשתמש לחיפוש
    REPLACE(REPLACE(owner_name, ' ז"ל', ''), ' ז''ל', '') AS clean_name,
    -- חישוב שם המשפחה (המילה הראשונה)
    split_part(REPLACE(REPLACE(owner_name, ' ז"ל', ''), ' ז''ל', ''), ' ', 1) AS family_lastname
  FROM public.signed_owners
  WHERE (owner_name ILIKE '%ז"ל%' OR owner_name ILIKE '%ז''ל%')
    AND is_active = TRUE
)
SELECT
  d.owner_name AS "מנוח",
  d.family_lastname AS "שם משפחה",
  d.parcel AS "חלקת מנוח",
  s.owner_name AS "יורש פוטנציאלי",
  s.id_number AS "ת.ז. יורש",
  s.parcel AS "חלקת יורש",
  COALESCE(s.master_2015_status, '(NULL)') AS "סטטוס",
  COALESCE(LEFT(s.master_2015_notes, 60), '') AS "הערה"
FROM deceased d
JOIN public.signed_owners s
  ON s.is_active = TRUE
  AND s.id != d.id
  AND s.owner_name NOT ILIKE '%ז"ל%'
  AND s.owner_name NOT ILIKE '%ז''ל%'
  AND (
    -- שם המנוח מופיע בשם היורש
    s.owner_name ILIKE '%' || d.family_lastname || '%'
    -- או שם המנוח (בלי ז"ל) מופיע בהערה
    OR s.master_2015_notes ILIKE '%' || d.clean_name || '%'
  )
ORDER BY d.parcel, d.owner_name, s.parcel, s.owner_name;


-- ============================================================
-- שאילתה 4 (אסטרטגיה C): נפטרים → יורש מ-2015 + שם המוריש בסוגריים
-- (לדוגמה: "ביזיהל דוד (יורש בוקסר)" → המוריש "בוקסר")
-- ============================================================
SELECT
  s.owner_name AS "יורש",
  s.id_number AS "ת.ז.",
  s.parcel AS "חלקה",
  s.agreement_area AS "שטח",
  COALESCE(s.inherited_from_id_number, '(NULL)') AS "מקושר ל-ת.ז."
FROM public.signed_owners s
WHERE s.is_active = TRUE
  AND s.master_2015_status = 'successor_to_2015_signer'
  AND s.inherited_from_id_number IS NULL  -- עוד לא מקושר
  AND s.owner_name ILIKE '%(יורש%'  -- שם המוריש בסוגריים
ORDER BY s.parcel, s.owner_name
LIMIT 30;


-- ============================================================
-- 📋 צפי תוצאות:
--   שאילתה 1: ~6 רשומות של מנוחים שעדיין is_active=TRUE
--   שאילתה 2: ירש 'successor_to_2015_signer' באותה חלקה כמו המנוח
--             → המועמדים הראשונים להיות יורשיו
--   שאילתה 3: שם המשפחה של המנוח מופיע בשם או בהערה אצל יורשים
--             → מועמדים נוספים, אולי בחלקות אחרות
--   שאילתה 4: יורשים עם "(יורש X)" בשם → צריך לזהות מי X
--
-- ➡ אחרי הריצה — נחליט לאיזה מנוח יש יורש מוכח, ונחבר ידנית.
-- ============================================================

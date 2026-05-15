-- ============================================================
-- 87_add_clara_heyman_heir.sql  (15/05/2026)
-- ============================================================
-- 🎯 מטרה: להוסיף את היימן קלרה (014777221) ל-DB כיורשת
--          שלישית של תמר היימן ז"ל.
--
-- 📜 רקע: לפי נסח טאבו חלקה 31 (שטר 19589/2026/1, 29/04/2026),
--    היימן קלרה ירשה 1/48 = 463.96/3 ≈ 463.96 מ"ר בחלקה 31.
--    היא טרם הוזנה ל-DB כי הירושה צעירה מאוד (פחות מ-3 שבועות).
--
-- 📐 שלב 1: לבדוק שדות חובה של signed_owners ולהשתמש בערכי ברירת מחדל
--    זהים לאחי הימן רן/דוד (כדי לשמור על עקביות).
--
-- ⚠ הסקריפט מבצע INSERT — לוודא שאין כפילות לפני!
-- ============================================================


BEGIN;


-- ============================================================
-- שאילתה 1: בדיקה — האם היימן קלרה כבר ב-DB?
-- ============================================================
SELECT
  '🔍 בדיקה לפני' AS "שלב",
  COUNT(*) AS "כמות רשומות קיימות"
FROM public.signed_owners
WHERE id_number = '014777221';


-- ============================================================
-- שאילתה 2: צילום של רשומת הימן דוד (כתבנית — נשתמש באותם ערכים)
-- ============================================================
SELECT
  '📋 תבנית (הימן דוד)' AS "שלב",
  owner_name, parcel, agreement_area, family_group_id,
  ownership_category, legal_status, master_2015_status
FROM public.signed_owners
WHERE id_number = '051194918' AND parcel = 31 AND is_active = TRUE
LIMIT 1;


-- ============================================================
-- שאילתה 3: הוספת היימן קלרה — חלקות 13, 31, 49
-- (3 רשומות נפרדות, כמו אחיה)
-- ============================================================
INSERT INTO public.signed_owners (
  owner_name,
  id_number,
  parcel,
  agreement_area,
  is_active,
  ownership_category,
  legal_status,
  master_2015_status,
  inherited_from_id_number,
  master_2015_notes,
  family_group_id
)
SELECT
  'היימן קלרה',
  '014777221',
  p.parcel,
  p.area,
  TRUE,
  COALESCE(template.ownership_category, 'signed_with_us'),
  COALESCE(template.legal_status, 'normal'),
  'successor_to_2015_signer',
  '000156320',  -- תמר היימן ז"ל
  'ירשה מ-תמר היימן ז"ל (ת.ז. 000156320). חלקה 1/3 (שטר 19589/2026/1 מתאריך 29/04/2026, נסח טאבו חלקה 31).',
  template.family_group_id
FROM (VALUES
  (13, 3.15),
  (31, 463.96),
  (49, 5.76)
) AS p(parcel, area)
LEFT JOIN LATERAL (
  SELECT family_group_id, ownership_category, legal_status
  FROM public.signed_owners
  WHERE id_number = '051194918' AND parcel = p.parcel AND is_active = TRUE
  LIMIT 1
) AS template ON TRUE
WHERE NOT EXISTS (
  -- הגנה מפני כפילות — לא להכניס אם כבר קיים
  SELECT 1 FROM public.signed_owners s
  WHERE s.id_number = '014777221' AND s.parcel = p.parcel
);


-- ============================================================
-- שאילתה 4: אימות — אחרי הוספה
-- ============================================================
SELECT
  '✅ אחרי' AS "שלב",
  s.owner_name AS "שם",
  s.id_number AS "ת.ז.",
  s.parcel AS "חלקה",
  s.agreement_area AS "שטח",
  s.is_active AS "פעיל?",
  s.master_2015_status AS "סטטוס",
  s.inherited_from_id_number AS "ירש מ-"
FROM public.signed_owners s
WHERE s.id_number = '014777221'
ORDER BY s.parcel;


-- ============================================================
-- שאילתה 5: סיכום סופי של 3 יורשי תמר היימן
-- ============================================================
SELECT
  '👥 כל יורשי תמר היימן' AS "שלב",
  s.owner_name AS "שם",
  s.id_number AS "ת.ז.",
  s.parcel AS "חלקה",
  s.agreement_area AS "שטח",
  s.inherited_from_id_number AS "ירש מ-"
FROM public.signed_owners s
WHERE s.inherited_from_id_number = '000156320'
  AND s.is_active = TRUE
ORDER BY s.parcel, s.owner_name;


COMMIT;


-- ============================================================
-- 📋 צפי אחרי הרצה:
--   • 3 רשומות חדשות של היימן קלרה בחלקות 13, 31, 49
--   • שאילתה 5: 9 רשומות (3 יורשים × 3 חלקות) מקושרות לתמר היימן
--   • חישוב: 3 × (3.15 + 463.96 + 5.76) = 3 × 472.87 = 1,418.61 ≈ 1,418.58 (סה"כ שטחי תמר)
-- ============================================================

-- ============================================================
-- 135_update_gil_zlich_to_arbitration.sql  (18/05/2026)
-- ============================================================
-- מטרה: עדכון monday_customer_type של גיל זלץ מ-"לקוח מקור" ל-
--        "מיוצג הרצוג" (אישור משתמש 18/05/2026).
--
-- 🎯 הרשומות שיתעדכנו (2):
--    • גיל זלץ — ת.ז. 022811897 — חלקה 28 (600 מ"ר)
--    • גיל זלץ — ת.ז. 022811897 — חלקה 51 (600 מ"ר)
--
-- 🛡 בטיחות:
--    • UPDATE רץ ב-TRANSACTION עם ROLLBACK ברירת מחדל
--    • אם הבדיקה ב-SELECT אחרי העדכון מציגה 2 רשומות "מיוצג הרצוג" —
--      תשנה ל-COMMIT;
--    • אחרת — תשאיר ROLLBACK; כדי לבטל הכל
--
-- ⚠ השפעה על הדשבורד אחרי COMMIT:
--    • 🟨 בבוררות:    138.3 → 139.5 דונם (+1.2)
--    • 🟩 לא בבוררות: 127.8 → 126.6 דונם (-1.2)
--    • סה"כ נשאר 266.1 ולא משתנה
-- ============================================================

BEGIN;

-- ===== שלב 1: הצגת מצב נוכחי לפני העדכון =====
SELECT
  'לפני העדכון' AS step,
  id,
  id_number,
  owner_name,
  parcel,
  monday_customer_type,
  ROUND(unification_area::numeric, 0) AS unification_area
FROM public.signed_owners
WHERE id_number = '022811897'
  AND owner_name ILIKE '%גיל זלץ%'
  AND is_active = TRUE;

-- ===== שלב 2: ביצוע העדכון =====
UPDATE public.signed_owners
SET monday_customer_type = 'מיוצג הרצוג',
    master_2015_notes = COALESCE(master_2015_notes, '') ||
      ' | סקריפט 135 (18/05/2026): עודכן ל-"מיוצג הרצוג" לפי אישור משתמש'
WHERE id_number = '022811897'
  AND owner_name ILIKE '%גיל זלץ%'
  AND is_active = TRUE
  AND (monday_customer_type ILIKE '%לקוח מקור%' OR monday_customer_type IS NULL);

-- ===== שלב 3: הצגת מצב אחרי העדכון =====
SELECT
  'אחרי העדכון' AS step,
  id,
  id_number,
  owner_name,
  parcel,
  monday_customer_type,
  ROUND(unification_area::numeric, 0) AS unification_area
FROM public.signed_owners
WHERE id_number = '022811897'
  AND owner_name ILIKE '%גיל זלץ%'
  AND is_active = TRUE;

-- ============================================================
-- 🎯 החלטה — אחרי הרצה, בדוק את התוצאות:
-- ============================================================
-- אם רואה 2 רשומות עם "מיוצג הרצוג" → תרוץ:    COMMIT;
-- אם משהו לא נראה תקין       → תרוץ:    ROLLBACK;
-- ============================================================

ROLLBACK;  -- ברירת מחדל בטוחה — שינוי ל-COMMIT אם הבדיקה תקינה

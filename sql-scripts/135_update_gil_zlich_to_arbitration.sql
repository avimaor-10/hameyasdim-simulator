-- ============================================================
-- 135_update_gil_zlich_to_arbitration.sql  (18/05/2026)
-- ============================================================
-- מטרה: עדכון monday_customer_type של גיל זלץ ל-"מיוצג הרצוג".
--
-- 🎯 הסיבה: גיל זלץ הוא יורש של אמו זלץ דניאלה-מאירה ז"ל
--           (ת.ז. 156293) — שמופיעה ברשימת התובעים בבוררות
--           (נספח 2, עמוד 9). היורש נכנס בנעלי המוריש —
--           לכן גיל זלץ גם בבוררות הרצוג.
--
-- רשומות שיתעדכנו (2):
--    • גיל זלץ — ת.ז. 022811897 — חלקה 28 (600 מ"ר)
--    • גיל זלץ — ת.ז. 022811897 — חלקה 51 (600 מ"ר)
-- ============================================================

UPDATE public.signed_owners
SET monday_customer_type = 'מיוצג הרצוג',
    master_2015_notes = COALESCE(master_2015_notes, '') ||
      ' | סקריפט 135 (18/05/2026): "לקוח מקור" → "מיוצג הרצוג" '
      || '(יורש של זלץ דניאלה-מאירה ז"ל מרשימת התובעים בבוררות)'
WHERE id_number = '022811897'
  AND owner_name ILIKE '%גיל זלץ%'
  AND is_active = TRUE
  AND (monday_customer_type ILIKE '%לקוח מקור%' OR monday_customer_type IS NULL);

-- אימות התוצאה
SELECT id_number, owner_name, parcel, monday_customer_type,
       ROUND(unification_area::numeric, 0) AS area
FROM public.signed_owners
WHERE id_number = '022811897'
  AND is_active = TRUE;

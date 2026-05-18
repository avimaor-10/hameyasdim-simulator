-- ============================================================
-- 137_update_dan_kobo_to_arbitration.sql  (18/05/2026)
-- ============================================================
-- מטרה: עדכון דן קובו ל-"מיוצג הרצוג" — נשאר NULL אחרי סקריפט 136.
--
-- 🎯 הסיבה: דן קובו (ת.ז. 030461561) הוא יורש של קובו לאה ז"ל
--           (שורה 20 ברשימת 32 התובעים).
--
-- רשומה שתתעדכן (1):
--    • דן קובו — ת.ז. 030461561 — חלקה 46 (104 מ"ר)
-- ============================================================

UPDATE public.signed_owners
SET monday_customer_type = 'מיוצג הרצוג',
    master_2015_notes = COALESCE(master_2015_notes, '') ||
      ' | סקריפט 137 (18/05/2026): NULL → "מיוצג הרצוג" '
      || '(יורש קובו לאה ז"ל, מרשימת התובעים בבוררות)'
WHERE id_number = '030461561'
  AND is_active = TRUE;

-- אימות
SELECT id_number, owner_name, parcel, monday_customer_type,
       ROUND(unification_area::numeric, 0) AS area
FROM public.signed_owners
WHERE id_number = '030461561';

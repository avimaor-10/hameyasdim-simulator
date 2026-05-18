-- ============================================================
-- 136_update_kobo_heirs_to_arbitration.sql  (18/05/2026)
-- ============================================================
-- מטרה: עדכון 3 יורשי קובו לאה ז"ל ל-"מיוצג הרצוג".
--
-- 🎯 הסיבה: קובו לאה ז"ל (ת.ז. 0156147) ברשימת 32 התובעים
--           בבוררות הרצוג (נספח א', שורה 20). היא נפטרה —
--           ויורשיה (3 ילדים) נכנסים בנעליה.
--
-- רשומות שיתעדכנו (3 בעלים, אולי מספר חלקות לכל אחד):
--    • אייל קובו   — ת.ז. 022498299
--    • נוגה בנגר   — ת.ז. 001561489
--    • דן קובו     — ת.ז. 030461561
-- ============================================================

UPDATE public.signed_owners
SET monday_customer_type = 'מיוצג הרצוג',
    master_2015_notes = COALESCE(master_2015_notes, '') ||
      ' | סקריפט 136 (18/05/2026): עודכן ל-"מיוצג הרצוג" '
      || '(יורש של קובו לאה ז"ל — שורה 20 ברשימת התובעים בבוררות)'
WHERE id_number IN ('022498299', '001561489', '030461561')
  AND is_active = TRUE
  AND (monday_customer_type ILIKE '%לקוח מקור%'
       OR monday_customer_type ILIKE '%יורש%'
       OR monday_customer_type IS NULL);

-- אימות התוצאה
SELECT id_number, owner_name, parcel, monday_customer_type,
       ROUND(unification_area::numeric, 0) AS area
FROM public.signed_owners
WHERE id_number IN ('022498299', '001561489', '030461561')
  AND is_active = TRUE
ORDER BY owner_name, parcel;

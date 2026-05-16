-- ============================================================
-- 93_diag_unmatched_owners.sql  (16/05/2026)
-- ============================================================
-- 🎯 מטרה: סקריפט אבחנתי בלבד (לא משנה דבר) —
--          חיפוש "מי באקסל הקשר לא הותאם" בעזרת חיפוש פתוח
--          על מילה אחת ייחודית מתוך השם, כדי לדעת איך הם
--          נראים בפועל ב-DB ולבנות UPDATE מדויק בסקריפט 94.
--
-- 📐 שיטה:
--   • לכל שם מ-29 שלא הותאמו בסקריפט 92 → SELECT עם ILIKE
--     על המילה הכי ייחודית מהשם (לרוב שם משפחה)
--   • החזרת כל ההתאמות עם owner_name, id_number, area
-- ============================================================


-- ============================================================
-- 1. אורי גרשון מילוסבסקי
-- ============================================================
SELECT '1' AS "מס׳", 'מילוסבסקי' AS "מחפש", owner_name, id_number, owned_area
FROM public.signed_owners
WHERE owner_name ILIKE '%מילוסב%' AND is_active = TRUE;


-- ============================================================
-- 2. דוד היימן (תמר היימן)
-- ============================================================
SELECT '2' AS "מס׳", 'דוד היימן' AS "מחפש", owner_name, id_number, owned_area
FROM public.signed_owners
WHERE owner_name ILIKE '%היימן%' AND owner_name ILIKE '%דוד%' AND is_active = TRUE;


-- ============================================================
-- 3. מירב בן דויד (אולי "מרב בן דוד" ב-DB)
-- ============================================================
SELECT '3' AS "מס׳", 'בן דו(י)ד' AS "מחפש", owner_name, id_number, owned_area
FROM public.signed_owners
WHERE (owner_name ILIKE '%מירב%' OR owner_name ILIKE '%מרב%')
  AND (owner_name ILIKE '%בן דוד%' OR owner_name ILIKE '%בן דויד%')
  AND is_active = TRUE;


-- ============================================================
-- 4 + 5. רונן זיגרמן + צבי זיגרמן (אולי "זייגרמן" ב-DB)
-- ============================================================
SELECT '4-5' AS "מס׳", 'זי(י)גרמן' AS "מחפש", owner_name, id_number, owned_area
FROM public.signed_owners
WHERE (owner_name ILIKE '%זיגרמן%' OR owner_name ILIKE '%זייגרמן%')
  AND is_active = TRUE;


-- ============================================================
-- 6. עירית יוחננוף
-- ============================================================
SELECT '6' AS "מס׳", 'יוחננוף' AS "מחפש", owner_name, id_number, owned_area
FROM public.signed_owners
WHERE (owner_name ILIKE '%יוחנונוף%' OR owner_name ILIKE '%יוחננוף%')
  AND is_active = TRUE;


-- ============================================================
-- 7. נעם יניר פלדמן (יחיד עם השם "יניר" סביר ב-DB)
-- ============================================================
SELECT '7' AS "מס׳", 'יניר פלדמן' AS "מחפש", owner_name, id_number, owned_area
FROM public.signed_owners
WHERE owner_name ILIKE '%יניר%' AND is_active = TRUE;


-- ============================================================
-- 8. עוזי ורות חייט (2 אנשים — לחפש כל אחד בנפרד)
-- ============================================================
SELECT '8' AS "מס׳", 'חייט' AS "מחפש", owner_name, id_number, owned_area
FROM public.signed_owners
WHERE owner_name ILIKE '%חייט%' AND is_active = TRUE;


-- ============================================================
-- 9. מאירה דניאלה זלץ
-- ============================================================
SELECT '9' AS "מס׳", 'זלץ' AS "מחפש", owner_name, id_number, owned_area
FROM public.signed_owners
WHERE owner_name ILIKE '%זלץ%' AND is_active = TRUE;


-- ============================================================
-- 10. מירה יצחקי
-- ============================================================
SELECT '10' AS "מס׳", 'מירה יצחקי' AS "מחפש", owner_name, id_number, owned_area
FROM public.signed_owners
WHERE owner_name ILIKE '%יצחקי%' AND owner_name ILIKE '%מירה%' AND is_active = TRUE;


-- ============================================================
-- 11. רגינה ומרכוס מרקוויץ
-- ============================================================
SELECT '11' AS "מס׳", 'מרקוויץ/מרקוביץ' AS "מחפש", owner_name, id_number, owned_area
FROM public.signed_owners
WHERE (owner_name ILIKE '%מרקוויץ%' OR owner_name ILIKE '%מרקוביץ%')
  AND is_active = TRUE;


-- ============================================================
-- 12. צבי ועליזה שטיין (2 אנשים)
-- ============================================================
SELECT '12' AS "מס׳", 'שטיין' AS "מחפש", owner_name, id_number, owned_area
FROM public.signed_owners
WHERE owner_name ILIKE '%שטיין%' AND is_active = TRUE;


-- ============================================================
-- 13. שחר כץ + הדסה צפורה כץ
-- ============================================================
SELECT '13' AS "מס׳", 'כץ' AS "מחפש", owner_name, id_number, owned_area
FROM public.signed_owners
WHERE owner_name ILIKE '%כץ%' AND is_active = TRUE;


-- ============================================================
-- 14. אליעזר ונטורה + רחל ונטורה (2 אנשים)
-- ============================================================
SELECT '14' AS "מס׳", 'ונטורה' AS "מחפש", owner_name, id_number, owned_area
FROM public.signed_owners
WHERE owner_name ILIKE '%ונטורה%' AND is_active = TRUE;


-- ============================================================
-- 15. יהודית בטינה
-- ============================================================
SELECT '15' AS "מס׳", 'בטינה' AS "מחפש", owner_name, id_number, owned_area
FROM public.signed_owners
WHERE (owner_name ILIKE '%בטינה%' OR owner_name ILIKE '%יהודית%') AND is_active = TRUE;


-- ============================================================
-- 16-17. תמר/יהודה פרסתנפלד (אולי "פרסטנפלד" ת/ט)
-- ============================================================
SELECT '16-17' AS "מס׳", 'פרסט/תנפלד' AS "מחפש", owner_name, id_number, owned_area
FROM public.signed_owners
WHERE (owner_name ILIKE '%פרסתנפלד%' OR owner_name ILIKE '%פרסטנפלד%')
  AND is_active = TRUE;


-- ============================================================
-- 18. ג'וליה חכמון (ינקו)
-- ============================================================
SELECT '18' AS "מס׳", 'חכמון/ינקו' AS "מחפש", owner_name, id_number, owned_area
FROM public.signed_owners
WHERE (owner_name ILIKE '%חכמון%' OR owner_name ILIKE '%ינקו%' OR owner_name ILIKE '%ג''וליה%' OR owner_name ILIKE '%גוליה%')
  AND is_active = TRUE;


-- ============================================================
-- 19. יאיר שריקר + פסח שריקר
-- ============================================================
SELECT '19' AS "מס׳", 'שריקר' AS "מחפש", owner_name, id_number, owned_area
FROM public.signed_owners
WHERE owner_name ILIKE '%שריקר%' AND is_active = TRUE;


-- ============================================================
-- 20. שלמה סולומון שלומי ספיר (אולי שני אנשים)
-- ============================================================
SELECT '20' AS "מס׳", 'סולומון/ספיר' AS "מחפש", owner_name, id_number, owned_area
FROM public.signed_owners
WHERE (owner_name ILIKE '%סולומון%' OR owner_name ILIKE '%ספיר%')
  AND is_active = TRUE;


-- ============================================================
-- 21. אורי מרדכי הוכברג + נעמי + ענת הוכברג
-- ============================================================
SELECT '21' AS "מס׳", 'הוכברג' AS "מחפש", owner_name, id_number, owned_area
FROM public.signed_owners
WHERE owner_name ILIKE '%הוכברג%' AND is_active = TRUE;


-- ============================================================
-- 22-25. מילט אורנה / מילט בטי / לביא דניאלי / חנה דניאלי
-- ============================================================
SELECT '22-23' AS "מס׳", 'מילט' AS "מחפש", owner_name, id_number, owned_area
FROM public.signed_owners
WHERE owner_name ILIKE '%מילט%' AND is_active = TRUE;

SELECT '24-25' AS "מס׳", 'דניאלי' AS "מחפש", owner_name, id_number, owned_area
FROM public.signed_owners
WHERE owner_name ILIKE '%דניאלי%' AND is_active = TRUE;


-- ============================================================
-- 26-29. מועמדים נוספים שאני לא בטוח לגביהם — נחפש רחב
-- ============================================================
-- 26. אהרון ילו שביט + אמנון שביט
SELECT '26' AS "מס׳", 'שביט' AS "מחפש", owner_name, id_number, owned_area
FROM public.signed_owners
WHERE owner_name ILIKE '%שביט%' AND is_active = TRUE;

-- 27. משה ילובסקי
SELECT '27' AS "מס׳", 'ילובסקי' AS "מחפש", owner_name, id_number, owned_area
FROM public.signed_owners
WHERE owner_name ILIKE '%ילובסקי%' AND is_active = TRUE;

-- 28. רוחמה צלליכין
SELECT '28' AS "מס׳", 'צלליכין' AS "מחפש", owner_name, id_number, owned_area
FROM public.signed_owners
WHERE owner_name ILIKE '%צלליכין%' AND is_active = TRUE;

-- 29. כל מי שיש בו "ברקוביץ"
SELECT '29' AS "מס׳", 'ברקוביץ' AS "מחפש", owner_name, id_number, owned_area
FROM public.signed_owners
WHERE owner_name ILIKE '%ברקוביץ%' AND is_active = TRUE;


-- ============================================================
-- 📋 הוראות:
-- הרץ את כל הסקריפט (Run All)
-- העתק את התוצאות כצילום מסך / טקסט ושלח לי
-- מתוך התוצאות אבנה סקריפט 94 שעושה UPDATE מדויק
-- ============================================================

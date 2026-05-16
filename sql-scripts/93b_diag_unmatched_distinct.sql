-- ============================================================
-- 93b_diag_unmatched_distinct.sql  (16/05/2026)
-- ============================================================
-- 🎯 מטרה: גרסה מקוצרת של 93 — שורה אחת לכל (קבוצה, owner_name)
--          במקום מספר שורות לאותו אדם בחלקות שונות.
--          DISTINCT ON שם + סיכום שטח כולל.
-- ============================================================


WITH all_matches AS (
  SELECT '01' AS grp, 'מילוסבסקי' AS srch, owner_name, id_number, agreement_area
  FROM public.signed_owners
  WHERE owner_name ILIKE '%מילוסב%' AND is_active = TRUE

  UNION ALL
  SELECT '02', 'דוד היימן', owner_name, id_number, agreement_area
  FROM public.signed_owners
  WHERE owner_name ILIKE '%היימן%' AND owner_name ILIKE '%דוד%' AND is_active = TRUE

  UNION ALL
  SELECT '03', 'בן דו(י)ד מירב/מרב', owner_name, id_number, agreement_area
  FROM public.signed_owners
  WHERE (owner_name ILIKE '%מירב%' OR owner_name ILIKE '%מרב%')
    AND (owner_name ILIKE '%בן דוד%' OR owner_name ILIKE '%בן דויד%')
    AND is_active = TRUE

  UNION ALL
  SELECT '04', 'זי(י)גרמן', owner_name, id_number, agreement_area
  FROM public.signed_owners
  WHERE (owner_name ILIKE '%זיגרמן%' OR owner_name ILIKE '%זייגרמן%')
    AND is_active = TRUE

  UNION ALL
  SELECT '05', 'יוחננוף/יוחנונוף', owner_name, id_number, agreement_area
  FROM public.signed_owners
  WHERE (owner_name ILIKE '%יוחנונוף%' OR owner_name ILIKE '%יוחננוף%')
    AND is_active = TRUE

  UNION ALL
  SELECT '06', 'יניר', owner_name, id_number, agreement_area
  FROM public.signed_owners
  WHERE owner_name ILIKE '%יניר%' AND is_active = TRUE

  UNION ALL
  SELECT '07', 'חייט', owner_name, id_number, agreement_area
  FROM public.signed_owners
  WHERE owner_name ILIKE '%חייט%' AND is_active = TRUE

  UNION ALL
  SELECT '08', 'זלץ', owner_name, id_number, agreement_area
  FROM public.signed_owners
  WHERE owner_name ILIKE '%זלץ%' AND is_active = TRUE

  UNION ALL
  SELECT '09', 'מירה יצחקי', owner_name, id_number, agreement_area
  FROM public.signed_owners
  WHERE owner_name ILIKE '%יצחקי%' AND owner_name ILIKE '%מירה%' AND is_active = TRUE

  UNION ALL
  SELECT '10', 'מרקוויץ/מרקוביץ', owner_name, id_number, agreement_area
  FROM public.signed_owners
  WHERE (owner_name ILIKE '%מרקוויץ%' OR owner_name ILIKE '%מרקוביץ%')
    AND is_active = TRUE

  UNION ALL
  -- 11: שטיין — דפוס הדוק יותר כי שטיין מופיע ב"פינשטיין", "פיינשטיין"
  SELECT '11', 'שטיין (הדוק)', owner_name, id_number, agreement_area
  FROM public.signed_owners
  WHERE (owner_name ILIKE '% שטיין%' OR owner_name LIKE 'שטיין%')
    AND is_active = TRUE

  UNION ALL
  SELECT '12', 'כץ', owner_name, id_number, agreement_area
  FROM public.signed_owners
  WHERE owner_name ILIKE '%כץ%' AND is_active = TRUE

  UNION ALL
  SELECT '13', 'ונטורה', owner_name, id_number, agreement_area
  FROM public.signed_owners
  WHERE owner_name ILIKE '%ונטורה%' AND is_active = TRUE

  UNION ALL
  SELECT '14', 'בטינה/יהודית', owner_name, id_number, agreement_area
  FROM public.signed_owners
  WHERE (owner_name ILIKE '%בטינה%' OR owner_name ILIKE '%יהודית%') AND is_active = TRUE

  UNION ALL
  SELECT '15', 'פרסט/תנפלד', owner_name, id_number, agreement_area
  FROM public.signed_owners
  WHERE (owner_name ILIKE '%פרסתנפלד%' OR owner_name ILIKE '%פרסטנפלד%')
    AND is_active = TRUE

  UNION ALL
  SELECT '16', 'חכמון/ינקו/ג''וליה', owner_name, id_number, agreement_area
  FROM public.signed_owners
  WHERE (owner_name ILIKE '%חכמון%' OR owner_name ILIKE '%ינקו%' OR owner_name ILIKE '%ג''וליה%' OR owner_name ILIKE '%גוליה%')
    AND is_active = TRUE

  UNION ALL
  SELECT '17', 'שריקר', owner_name, id_number, agreement_area
  FROM public.signed_owners
  WHERE owner_name ILIKE '%שריקר%' AND is_active = TRUE

  UNION ALL
  SELECT '18', 'סולומון/ספיר', owner_name, id_number, agreement_area
  FROM public.signed_owners
  WHERE (owner_name ILIKE '%סולומון%' OR owner_name ILIKE '%ספיר%')
    AND is_active = TRUE

  UNION ALL
  SELECT '19', 'הוכברג', owner_name, id_number, agreement_area
  FROM public.signed_owners
  WHERE owner_name ILIKE '%הוכברג%' AND is_active = TRUE

  UNION ALL
  SELECT '20', 'מילט', owner_name, id_number, agreement_area
  FROM public.signed_owners
  WHERE owner_name ILIKE '%מילט%' AND is_active = TRUE

  UNION ALL
  SELECT '21', 'דניאלי', owner_name, id_number, agreement_area
  FROM public.signed_owners
  WHERE owner_name ILIKE '%דניאלי%' AND is_active = TRUE

  UNION ALL
  SELECT '22', 'שביט', owner_name, id_number, agreement_area
  FROM public.signed_owners
  WHERE owner_name ILIKE '%שביט%' AND is_active = TRUE

  UNION ALL
  SELECT '23', 'ילובסקי', owner_name, id_number, agreement_area
  FROM public.signed_owners
  WHERE owner_name ILIKE '%ילובסקי%' AND is_active = TRUE

  UNION ALL
  SELECT '24', 'צלליכין', owner_name, id_number, agreement_area
  FROM public.signed_owners
  WHERE owner_name ILIKE '%צלליכין%' AND is_active = TRUE

  UNION ALL
  SELECT '25', 'ברקוביץ', owner_name, id_number, agreement_area
  FROM public.signed_owners
  WHERE owner_name ILIKE '%ברקוביץ%' AND is_active = TRUE

  UNION ALL
  SELECT '26', 'חורין', owner_name, id_number, agreement_area
  FROM public.signed_owners
  WHERE owner_name ILIKE '%חורין%' AND is_active = TRUE
)
SELECT
  grp                  AS "קב׳",
  srch                 AS "מחפש",
  owner_name           AS "שם ב-DB",
  id_number            AS "ת״ז",
  COUNT(*)             AS "כמה רשומות",
  ROUND(SUM(agreement_area)::numeric, 2) AS "סך שטח (מ״ר)"
FROM all_matches
GROUP BY grp, srch, owner_name, id_number
ORDER BY grp, owner_name;

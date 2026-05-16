-- ============================================================
-- 103_link_moalem_eliyahu_parcel21_to_family.sql  (16/05/2026)
-- ============================================================
-- מטרה: לקשר את רשומת מועלם אליהו '4/755793' בחלקה 21
--        למשפחת "משפחת מועלם - מור" (family_group_id).
--
-- רקע: סקריפט 89 (15/05/2026) החזיר את הרשומה הזו ל-is_active=TRUE
--   אבל שכח להגדיר את family_group_id, ולכן היא לא מופיעה
--   במסך הניהול של המשפחה ב-admin (1,392.60 מ"ר חסרים).
--
-- אבחון לפני/אחרי כלול בסקריפט.
-- בטוח להריצה — UPDATE על שורה אחת בלבד.
-- ============================================================


BEGIN;


-- ============================================================
-- BEFORE: status of record 4/755793 in parcel 21
-- ============================================================
SELECT
  'BEFORE 103' AS step,
  s.id_number,
  s.owner_name,
  s.parcel,
  s.is_active,
  s.family_group_id,
  fg.family_name
FROM public.signed_owners s
LEFT JOIN public.family_groups fg ON fg.id = s.family_group_id
WHERE s.id_number = '4/755793'
  AND s.parcel = 21;


-- ============================================================
-- STEP A: link 4/755793 in parcel 21 to moalem-mor family
-- ============================================================
UPDATE public.signed_owners
SET
  family_group_id = '597f2061-5ece-4b81-a95d-31ed7d5ec97b',
  master_2015_notes = COALESCE(master_2015_notes, '') || ' | קושר למשפחת מועלם-מור 16/05/2026 (סקריפט 103) — היה NULL בטעות מאז סקריפט 89.'
WHERE id_number = '4/755793'
  AND parcel = 21
  AND family_group_id IS NULL;


-- ============================================================
-- AFTER: verify linkage
-- ============================================================
SELECT
  'AFTER 103' AS step,
  s.id_number,
  s.owner_name,
  s.parcel,
  s.is_active,
  s.family_group_id,
  fg.family_name
FROM public.signed_owners s
LEFT JOIN public.family_groups fg ON fg.id = s.family_group_id
WHERE s.id_number = '4/755793'
  AND s.parcel = 21;


-- ============================================================
-- SUMMARY: all active members of moalem-mor family
-- (should now be 10 members instead of 9)
-- ============================================================
SELECT
  s.id_number,
  s.owner_name,
  COUNT(*) AS rows_count,
  ROUND(SUM(s.agreement_area)::numeric, 2) AS total_area
FROM public.signed_owners s
WHERE s.family_group_id = '597f2061-5ece-4b81-a95d-31ed7d5ec97b'
  AND s.is_active = TRUE
GROUP BY s.id_number, s.owner_name
ORDER BY s.owner_name;


COMMIT;


-- ============================================================
-- EXPECTED RESULTS:
--   BEFORE: family_group_id = NULL, family_name = NULL
--   AFTER:  family_group_id = '597f2061-5ece-4b81-a95d-31ed7d5ec97b',
--           family_name = 'משפחת מועלם - מור'
--   SUMMARY: 10 members instead of 9
--            (moalem eliyahu added with 1 row, 1392.60 sqm)
-- ============================================================

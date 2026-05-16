-- ============================================================
-- 104_restore_moalem_eliyahu_parcel53.sql  (16/05/2026)
-- ============================================================
-- מטרה: להחזיר את רשומת מועלם אליהו (000755793) בחלקה 53
--        ל-is_active=TRUE — "פיצול אליהו 1/20 = 646.30 מ"ר" שלא חולק.
--
-- רקע (מאקסל v13 דוח איחוד וחלוקה + זיכרון 03/05/2026):
--   לפי הזיכרון: "5 חברים פעילים + 2 רשומות אליהו ז"ל (חלקות 21, 53)".
--   לפי האקסל v13 (שורה 180): מועלם אליהו, חלקה 53, 646.30 מ"ר באיחוד.
--   ב-DB נכון להיום: אליהו בחלקה 53 הוא is_active=FALSE (סקריפט 88 דרס אותו).
--   סקריפט 89 (15/05) תיקן את חלקה 21 בלבד. חלקה 53 נשכחה.
--
-- 📐 פעולה:
--   • UPDATE: 000755793 בחלקה 53 → is_active=TRUE
--   • הוספת הערה למסמך הירידה לפרטים
--
-- 🔒 בטוח להריצה — שורה אחת בלבד תושפע.
-- ============================================================


BEGIN;


-- ============================================================
-- BEFORE: סטטוס נוכחי של אליהו בחלקה 53
-- ============================================================
SELECT
  'BEFORE 104' AS step,
  s.id_number,
  s.owner_name,
  s.parcel,
  ROUND(s.agreement_area::numeric, 2)   AS agreement_area,
  ROUND(s.unification_area::numeric, 2) AS unification_area,
  s.is_active,
  s.is_signed,
  s.family_group_id,
  fg.family_name
FROM public.signed_owners s
LEFT JOIN public.family_groups fg ON fg.id = s.family_group_id
WHERE s.id_number = '000755793'
  AND s.parcel = 53;


-- ============================================================
-- STEP A: החזרת אליהו ב-53 ל-is_active=TRUE
-- ============================================================
UPDATE public.signed_owners
SET
  is_active = TRUE,
  master_2015_notes = COALESCE(master_2015_notes, '') ||
    ' | החזר 16/05/2026 (סקריפט 104): מועלם אליהו ז"ל — פיצול 1/20 בחלקה 53 (646.30 מ"ר) טרם חולק רשמית. הוא עדיין הבעלים הרשום בטאבו (שטר 9419/1976/2). תקין לפי אקסל v13 (שורה 180) ולפי הזיכרון של 03/05/2026. סקריפט 88 (15/05) דרס בטעות גם רשומה זו ל-FALSE; סקריפט 89 תיקן רק את חלקה 21 ושכח את 53.'
WHERE id_number = '000755793'
  AND parcel = 53
  AND is_active = FALSE;


-- ============================================================
-- AFTER: וידוא התיקון
-- ============================================================
SELECT
  'AFTER 104' AS step,
  s.id_number,
  s.owner_name,
  s.parcel,
  ROUND(s.agreement_area::numeric, 2)   AS agreement_area,
  ROUND(s.unification_area::numeric, 2) AS unification_area,
  s.is_active,
  s.is_signed,
  s.family_group_id,
  fg.family_name
FROM public.signed_owners s
LEFT JOIN public.family_groups fg ON fg.id = s.family_group_id
WHERE s.id_number = '000755793'
  AND s.parcel = 53;


-- ============================================================
-- SUMMARY: כל חברי מועלם-מור הפעילים (אמור להיות 11 עכשיו)
-- ============================================================
SELECT
  s.id_number,
  s.owner_name,
  COUNT(*)                                            AS rows_count,
  ROUND(SUM(s.agreement_area)::numeric, 2)            AS total_agreement,
  ROUND(SUM(s.unification_area)::numeric, 2)          AS total_union,
  STRING_AGG(s.parcel::text, ',' ORDER BY s.parcel)   AS parcels
FROM public.signed_owners s
WHERE s.family_group_id = '597f2061-5ece-4b81-a95d-31ed7d5ec97b'
  AND s.is_active = TRUE
GROUP BY s.id_number, s.owner_name
ORDER BY s.owner_name;


-- ============================================================
-- TOTALS: סכומי המשפחה
-- ============================================================
SELECT
  COUNT(*)                                            AS active_rows,
  COUNT(DISTINCT s.id_number)                         AS unique_ids,
  ROUND(SUM(s.agreement_area)::numeric, 2)            AS total_agreement_sqm,
  ROUND(SUM(s.unification_area)::numeric, 2)          AS total_union_sqm
FROM public.signed_owners s
WHERE s.family_group_id = '597f2061-5ece-4b81-a95d-31ed7d5ec97b'
  AND s.is_active = TRUE;


COMMIT;


-- ============================================================
-- צפי תוצאות:
--   BEFORE: 000755793 ב-53 → is_active=FALSE, 646.30 מ"ר
--   AFTER:  000755793 ב-53 → is_active=TRUE, 646.30 מ"ר
--   SUMMARY: אליהו יופיע ברשימת החברים הפעילים עם 2 רשומות:
--            • 4/755793 בחלקה 21 (1,392.60 מ"ר)
--            • 000755793 בחלקה 53 (646.30 מ"ר)
--   TOTALS: שטח הסכם מצרפי יגדל ב-646.30 ← אמור להגיע ~22,256 מ"ר
--           שטח לאיחוד מצרפי יגדל ב-646.30 ← אמור להגיע ~20,377 מ"ר
-- ============================================================

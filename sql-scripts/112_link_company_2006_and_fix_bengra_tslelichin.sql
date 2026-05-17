-- ============================================================
-- 112_link_company_2006_and_fix_bengra_tslelichin.sql  (17/05/2026)
-- ============================================================
-- מטרה: 2 תיקונים מבוססי שאילתות אבחון:
--
-- 1️⃣ קבוצת חנן מור השקעות 2006 בע"מ (513819573):
--    מקושרת ל-family_group "קבוצת חנן מור השקעות" + verified.
--    הסיבה: הקבוצה (42687af3-...) הוקמה ב-05/05/2026 אבל החברה
--    שהיא מקבל האופציה לא קושרה אליה. לכן היא מופיעה בנפרד במסך.
--
-- 2️⃣ בן גרא עפרה (000156180) + צלליכין רוחמה (000156179):
--    שתיהן מכרו לעסקאות שותפות (deal #8, #17). מקושרות נכון
--    ל-deal_replaced_owners. אבל unification_area = NULL.
--    מעדכנים ל-0 לאחידות עם דפוס מועלם (4 ילדים שמכרו).
--
-- 🔒 BEGIN ... COMMIT — בטוח להריצה.
-- ============================================================


BEGIN;


-- ============================================================
-- BEFORE
-- ============================================================
SELECT 'BEFORE 112' AS step,
  s.id_number, s.owner_name, s.parcel,
  ROUND(s.agreement_area::numeric, 3) AS agreement_area,
  ROUND(s.unification_area::numeric, 3) AS unification_area,
  s.is_active, s.master_2015_status, s.family_group_id, fg.family_name
FROM public.signed_owners s
LEFT JOIN public.family_groups fg ON fg.id = s.family_group_id
WHERE s.id_number IN ('513819573', '000156180', '000156179')
ORDER BY s.id_number;


-- ============================================================
-- STEP A: קישור חברת חנן מור השקעות 2006 (513819573)
--          לקבוצת "קבוצת חנן מור השקעות" + verified
-- ============================================================
UPDATE public.signed_owners
SET
  master_2015_status = 'verified',
  family_group_id = (
    SELECT id FROM public.family_groups
    WHERE family_name = 'קבוצת חנן מור השקעות' LIMIT 1
  ),
  master_2015_notes = COALESCE(master_2015_notes, '') ||
    CASE WHEN COALESCE(master_2015_notes, '') = '' THEN '' ELSE ' | ' END ||
    $note$קישור 17/05/2026 (סקריפט 112): קבוצת חנן מור השקעות 2006 בע"מ (513819573) קושרה ל-family_group "קבוצת חנן מור השקעות". הקבוצה הוקמה ב-05/05/2026 כישות עסקית עצמאית של חנן מור (השקעות נדל"ן ישירות), נפרדת מ"קבוצת חנן מור" היזמית. שותפים אישיים: אבי מאור + חנן מור. החברה היא מקבל האופציה ומחזיקה 581 מ"ר ב-3 עסקאות (134+300+147). master_2015_status עודכן ל-verified.$note$
WHERE id_number = '513819573';


-- ============================================================
-- STEP B: עדכון unification_area של בן גרא + צלליכין מ-NULL ל-0
--          (לאחידות עם דפוס מועלם — 4 ילדים שמכרו לעסקה)
-- ============================================================
UPDATE public.signed_owners
SET
  unification_area = 0,
  master_2015_notes = COALESCE(master_2015_notes, '') ||
    CASE WHEN COALESCE(master_2015_notes, '') = '' THEN '' ELSE ' | ' END ||
    $note$עדכון 17/05/2026 (סקריפט 112): unification_area עודכן מ-NULL ל-0. הבעלים מכרו את חלקם לעסקת שותפות (מקושר ב-deal_replaced_owners). agreement_area נשאר לתיעוד השטח המקורי בנסח.$note$
WHERE id_number IN ('000156180', '000156179');


-- ============================================================
-- AFTER
-- ============================================================
SELECT 'AFTER 112' AS step,
  s.id_number, s.owner_name, s.parcel,
  ROUND(s.agreement_area::numeric, 3) AS agreement_area,
  ROUND(s.unification_area::numeric, 3) AS unification_area,
  s.is_active, s.master_2015_status, s.family_group_id, fg.family_name
FROM public.signed_owners s
LEFT JOIN public.family_groups fg ON fg.id = s.family_group_id
WHERE s.id_number IN ('513819573', '000156180', '000156179')
ORDER BY s.id_number;


COMMIT;


-- ============================================================
-- צפי תוצאות:
--   513819573: family_group="קבוצת חנן מור השקעות", master=verified
--   000156180 + 000156179: unification_area = 0
-- ============================================================

-- ============================================================
-- 113_revert_company_2006_link.sql  (17/05/2026)
-- ============================================================
-- מטרה: ביטול הקישור השגוי של חברת חנן מור 2006 (513819573)
--        שנעשה בסקריפט 112.
--
-- 🚨 רקע — תיקון לטעות:
-- בסקריפט 112 קישרתי את החברה (513819573) ל"קבוצת חנן מור השקעות".
-- המשתמש הסביר שזה שגוי, כי לפי הכלל (זיכרון 05/05/2026 שורות 1069-1072):
--   "מה שחולץ ל-signed_owners = רק התוספת מעבר ל-5%.
--    ה-10% החובה נשאר בשותפות לצורכי הקצאה."
--
-- 49.84 מ"ר בחלקה 51 הם 5% חובה של עסקה כלשהי של "רוכשי שותפות
-- נדל"ן נדל"ן קבוצת מור", ולא תוספת מעבר ל-5%. לכן הוא לא היה
-- אמור להיות מקושר ל"קבוצת חנן מור השקעות" (שמכילה רק תוספת מעבר).
--
-- 📐 פעולה: is_active=FALSE + family_group_id=NULL.
-- master_2015_status נשאר verified (כי החברה אכן חתומה על ההסכם).
--
-- 🔒 BEGIN ... COMMIT — בטוח להריצה.
-- ============================================================


BEGIN;


-- BEFORE
SELECT 'BEFORE 113' AS step,
  s.id_number, s.owner_name, s.parcel,
  ROUND(s.agreement_area::numeric, 3) AS agreement_area,
  ROUND(s.unification_area::numeric, 3) AS unification_area,
  s.is_active, s.master_2015_status, s.family_group_id, fg.family_name
FROM public.signed_owners s
LEFT JOIN public.family_groups fg ON fg.id = s.family_group_id
WHERE s.id_number = '513819573';


-- STEP A: ביטול הקישור + is_active=FALSE
UPDATE public.signed_owners
SET is_active = FALSE,
    family_group_id = NULL,
    master_2015_notes = COALESCE(master_2015_notes, '') ||
      CASE WHEN COALESCE(master_2015_notes, '') = '' THEN '' ELSE ' | ' END ||
      $note$תיקון 17/05/2026 (סקריפט 113): סומן is_active=FALSE וביטול הקישור לקבוצת חנן מור השקעות (תיקון לטעות של סקריפט 112). הסיבה: 49.84 מ"ר בחלקה 51 הם 5% חובה של עסקה של "רוכשי שותפות נדל"ן נדל"ן קבוצת מור", ולא תוספת מעבר ל-5% של "קבוצת חנן מור השקעות". לפי הכלל (זיכרון 05/05/2026 שורות 1069-1072): רק תוספת מעבר ל-5% חולצת ל-signed_owners. ה-5% החובה נשארים בשותפות הראשית לצורכי הקצאה. ולכן רשומה זו לא היתה אמורה להיות פעילה ב-signed_owners.$note$
WHERE id_number = '513819573';


-- AFTER
SELECT 'AFTER 113' AS step,
  s.id_number, s.owner_name, s.parcel,
  ROUND(s.agreement_area::numeric, 3) AS agreement_area,
  s.is_active, s.master_2015_status, s.family_group_id, fg.family_name
FROM public.signed_owners s
LEFT JOIN public.family_groups fg ON fg.id = s.family_group_id
WHERE s.id_number = '513819573';


COMMIT;


-- ============================================================
-- תוצאות בפועל (17/05/2026):
--   513819573 → is_active=false, family_group=NULL, master=verified (נשאר)
-- ============================================================

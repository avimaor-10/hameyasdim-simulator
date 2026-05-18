-- ============================================================
-- 120_link_bendavid_drumi_to_partnership_deals.sql  (18/05/2026)
-- ============================================================
-- מטרה: השלמת deal_replaced_owners עבור 2 בעלים שמכרו לשותפות
--        אבל לא קושרו בטבלת deal_replaced_owners. זוהה כפער
--        בזיכרון (שורה 2151): "בן דוד מרב (055529945), דרומי
--        אסתר (050501121) — 0 עסקאות מקושרות (אבל בפועל מכרו!)"
--
-- 📐 רקע: שתיהן בקבוצת המשפחה "משפחת דרומי/בן דוד"
--    (daed64b5-b0e4-4320-a089-3abeeaff6e45). מכרו כל אחת
--    1,615 מ"ר לקבוצת רוכשי השותפות (חנן מור) ב-2 חלקות:
--      • חלקה 18: 1,122 מ"ר (כל החלקה) — is_active=FALSE
--      • חלקה 34: 493.33 מ"ר (כל החלקה) — is_active=FALSE
--
-- 📋 מקור: קובץ "השטחים שמכרו מרב בן דוד ואסתר דרומי לשותפות.xlsx"
--    בתיקיית הפרויקט. 22 רוכשים לכל מוכרת, כולל:
--    שירה שגב מור (אשת חנן מור), מאור ארד (בנו של אבי מאור),
--    קבוצת חנן השקעות 2006, ו-4 חברות נדלן נדלן.
--
-- 🎯 העסקאות לקישור (מתוך partnership_deals):
--    • חלקה 18: deal_number=3, "עסקת דרומי/בן דוד"
--      id = cc30532d-aac9-4d1a-8376-b96ee7ae3897
--    • חלקה 34: deal_number=4, "עסקת דרומי/בן דוד"
--      id = 9c738763-6625-4ba3-b970-a172d93ada5f
--
-- 📐 4 קישורים יוכנסו ל-deal_replaced_owners:
--    1. מרב בן דוד (055529945) חלקה 18 → deal #3
--    2. מרב בן דוד (055529945) חלקה 34 → deal #4
--    3. אסתר דרומי (050501121) חלקה 18 → deal #3
--    4. אסתר דרומי (050501121) חלקה 34 → deal #4
--
-- 🔒 BEGIN ... COMMIT — בטוח להריצה.
-- ============================================================


BEGIN;


-- ============================================================
-- BEFORE
-- ============================================================
SELECT 'BEFORE 120 — deal_replaced_owners' AS step,
  dro.id, dro.deal_id, dro.signed_owner_id, dro.notes
FROM public.deal_replaced_owners dro
JOIN public.signed_owners s ON s.id = dro.signed_owner_id
WHERE s.id_number IN ('055529945', '050501121');

SELECT 'BEFORE 120 — signed_owners חלקות 18+34' AS step,
  s.id, s.id_number, s.owner_name, s.parcel,
  ROUND(s.agreement_area::numeric, 3) AS agreement_area,
  s.is_active
FROM public.signed_owners s
WHERE s.id_number IN ('055529945', '050501121')
  AND s.parcel IN ('18', '34')
ORDER BY s.id_number, s.parcel;


-- ============================================================
-- STEP A: הוספת 4 קישורים ב-deal_replaced_owners
-- ============================================================

-- 1. מרב בן דוד חלקה 18 → deal #3
INSERT INTO public.deal_replaced_owners (deal_id, signed_owner_id, notes)
SELECT
  'cc30532d-aac9-4d1a-8376-b96ee7ae3897'::uuid,
  s.id,
  $note$קישור 18/05/2026 (סקריפט 120): מרב בן דוד (055529945) מכרה את כל חלקה 18 (1,122 מ"ר, כל החלק שלה) לקבוצת רוכשי השותפות "עסקת דרומי/בן דוד" (deal_number=3). הרשומה ב-signed_owners כבר is_active=FALSE + unification_area=0. מקור: קובץ "השטחים שמכרו מרב בן דוד ואסתר דרומי לשותפות.xlsx" — 22 רוכשים שונים קיבלו חלקים. בקבוצת משפחת דרומי/בן דוד (daed64b5-b0e4-4320-a089-3abeeaff6e45).$note$
FROM public.signed_owners s
WHERE s.id_number = '055529945'
  AND s.parcel = '18'
LIMIT 1;


-- 2. מרב בן דוד חלקה 34 → deal #4
INSERT INTO public.deal_replaced_owners (deal_id, signed_owner_id, notes)
SELECT
  '9c738763-6625-4ba3-b970-a172d93ada5f'::uuid,
  s.id,
  $note$קישור 18/05/2026 (סקריפט 120): מרב בן דוד (055529945) מכרה את כל חלקה 34 (493.33 מ"ר, כל החלק שלה) לקבוצת רוכשי השותפות "עסקת דרומי/בן דוד" (deal_number=4). הרשומה ב-signed_owners כבר is_active=FALSE + unification_area=0. סה"כ מכירה: 1,615.33 מ"ר (חלקות 18+34 ביחד). מקור: קובץ האקסל של השטחים. בקבוצת משפחת דרומי/בן דוד.$note$
FROM public.signed_owners s
WHERE s.id_number = '055529945'
  AND s.parcel = '34'
LIMIT 1;


-- 3. אסתר דרומי חלקה 18 → deal #3
INSERT INTO public.deal_replaced_owners (deal_id, signed_owner_id, notes)
SELECT
  'cc30532d-aac9-4d1a-8376-b96ee7ae3897'::uuid,
  s.id,
  $note$קישור 18/05/2026 (סקריפט 120): אסתר דרומי (050501121) מכרה את כל חלקה 18 (1,122 מ"ר, כל החלק שלה) לקבוצת רוכשי השותפות "עסקת דרומי/בן דוד" (deal_number=3). הרשומה ב-signed_owners כבר is_active=FALSE + unification_area=0. אסתר ומרב מכרו במשותף, סה"כ 2 × 1,615 = 3,230 מ"ר. בקבוצת משפחת דרומי/בן דוד (daed64b5-b0e4-4320-a089-3abeeaff6e45).$note$
FROM public.signed_owners s
WHERE s.id_number = '050501121'
  AND s.parcel = '18'
LIMIT 1;


-- 4. אסתר דרומי חלקה 34 → deal #4
INSERT INTO public.deal_replaced_owners (deal_id, signed_owner_id, notes)
SELECT
  '9c738763-6625-4ba3-b970-a172d93ada5f'::uuid,
  s.id,
  $note$קישור 18/05/2026 (סקריפט 120): אסתר דרומי (050501121) מכרה את כל חלקה 34 (493.33 מ"ר, כל החלק שלה) לקבוצת רוכשי השותפות "עסקת דרומי/בן דוד" (deal_number=4). הרשומה ב-signed_owners כבר is_active=FALSE + unification_area=0. סה"כ מכירת אסתר: 1,615.33 מ"ר (חלקות 18+34 ביחד). בקבוצת משפחת דרומי/בן דוד.$note$
FROM public.signed_owners s
WHERE s.id_number = '050501121'
  AND s.parcel = '34'
LIMIT 1;


-- ============================================================
-- STEP B: עדכון master_2015_notes ב-signed_owners (תיעוד הקישור)
-- ============================================================
UPDATE public.signed_owners
SET master_2015_notes = COALESCE(master_2015_notes, '') ||
      CASE WHEN COALESCE(master_2015_notes, '') = '' THEN '' ELSE ' | ' END ||
      $note$קישור deal_replaced_owners 18/05/2026 (סקריפט 120): רשומה זו מקושרת עכשיו לעסקת השותפות הרלוונטית בטבלת deal_replaced_owners. רקע: מרב בן דוד ואסתר דרומי מכרו במשותף 1,615 מ"ר כל אחת בחלקות 18+34 לרוכשי שותפות נדלן נדלן (כולל שירה שגב מור, מאור ארד, קבוצת חנן השקעות 2006, ו-4 חברות פרטיות). מקור הניתוח: קובץ אקסל "השטחים שמכרו מרב בן דוד ואסתר דרומי לשותפות.xlsx".$note$
WHERE id_number IN ('055529945', '050501121')
  AND parcel IN ('18', '34');


-- ============================================================
-- AFTER
-- ============================================================
SELECT 'AFTER 120 — deal_replaced_owners קישורים חדשים' AS step,
  dro.id AS link_id,
  s.id_number,
  s.owner_name,
  s.parcel,
  pd.deal_number,
  pd.deal_name,
  LEFT(dro.notes, 80) AS notes_preview
FROM public.deal_replaced_owners dro
JOIN public.signed_owners s ON s.id = dro.signed_owner_id
JOIN public.partnership_deals pd ON pd.id = dro.deal_id
WHERE s.id_number IN ('055529945', '050501121')
ORDER BY s.id_number, s.parcel;


-- ============================================================
-- SUMMARY: ספירת קישורים סופית
-- ============================================================
SELECT 'SUMMARY 120' AS step,
  s.id_number,
  s.owner_name,
  COUNT(dro.id) AS link_count,
  STRING_AGG(s.parcel || '→' || pd.deal_number::text, ', ' ORDER BY s.parcel) AS parcels_to_deals
FROM public.signed_owners s
LEFT JOIN public.deal_replaced_owners dro ON dro.signed_owner_id = s.id
LEFT JOIN public.partnership_deals pd ON pd.id = dro.deal_id
WHERE s.id_number IN ('055529945', '050501121')
GROUP BY s.id_number, s.owner_name;


COMMIT;


-- ============================================================
-- צפי תוצאות:
--   4 קישורים חדשים ב-deal_replaced_owners:
--     • 055529945 מרב בן דוד  חלקה 18 → deal #3 (עסקת דרומי/בן דוד)
--     • 055529945 מרב בן דוד  חלקה 34 → deal #4 (עסקת דרומי/בן דוד)
--     • 050501121 אסתר דרומי  חלקה 18 → deal #3
--     • 050501121 אסתר דרומי  חלקה 34 → deal #4
--
--   ב-signed_owners: 4 רשומות (חלקות 18+34 של 2 הבעלים) קיבלו
--   הערה ב-master_2015_notes על הקישור החדש.
--
-- 🎯 משמעות: עכשיו במסך admin אפשר יהיה לראות:
--    "מרב בן דוד מכרה לעסקה X" — לא רק "החלקה לא משתתפת באיחוד".
-- ============================================================

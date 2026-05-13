-- ============================================================
-- 56a_add_dromi_bendavid_sold_parcels.sql  (13/05/2026)
-- ============================================================
-- 🎯 מטרה: הוספת רישומי "דרומי אסתר" + "בן דוד מרב" על חלקות 18, 34.
--          הם רשומים בעסקה (מכירה לחנן מור #3 + #4) ב-"הושלמה ועדיין
--          לא נרשמה". מחויבים בדמי ייזום (הסכם צמוד לקרקע), אבל לא
--          תורמים לאיחוד (העסקה כבר תורמת).
--
-- 📋 מקור הנתונים (אקסל v13 — דוח איחוד וחלוקה):
--   • חלקה 18: דרומי אסתר + בן דוד מרב יחד 2,244 מ"ר → 1,122 כ"א
--   • חלקה 34: דרומי אסתר + בן דוד מרב יחד   986.66 מ"ר → 493.33 כ"א
--
-- 🔒 הגנות:
--   • is_active = FALSE (כמו צלליכין/גולדמן/קרן מרתון)
--   • WHERE NOT EXISTS — בטוח להריץ פעמיים
--   • family_group_id = משפחת דרומי/בן דוד הקיימת
-- ============================================================


-- ============================================================
-- שלב 1 — אבחון מקדים: מה כבר ב-DB
-- ============================================================
SELECT
  '🔍 לפני התיקון: דרומי + בן דוד הרשומים' AS "מדד",
  s.owner_name AS "שם",
  s.id_number AS "ת_ז",
  s.parcel AS "חלקה",
  ROUND(s.agreement_area::numeric, 2) AS "שטח",
  s.is_active AS "פעיל"
FROM public.signed_owners s
WHERE s.id_number IN ('055529945', '050501121')
ORDER BY s.owner_name, s.parcel;


-- ============================================================
-- שלב 2 — הוספת 4 רישומים חדשים (אם לא קיימים)
-- ============================================================
INSERT INTO public.signed_owners (
  owner_name, id_number, parcel, agreement_area, unification_area,
  is_active, is_signed, master_2015_status, ownership_category,
  family_group_id,
  legal_notes, source_version
)
SELECT * FROM (VALUES
  (
    'בן דוד מרב', '055529945', 18, 1122.00, 0.00,
    FALSE, TRUE, 'verified'::text, 'signed_with_us'::text,
    (SELECT id FROM public.family_groups WHERE family_name ILIKE '%דרומי%בן דוד%' LIMIT 1),
    'תיקון 56a (13/05/2026): מכרה את חלקה לקבוצת חנן מור בעסקת דרומי/בן דוד #3 ' ||
    '(2,244 מ"ר חלוקת חלקה 18, מתוכם 1,122 מ"ר חלק של בן דוד מרב). ' ||
    'הסטטוס בטאבו: "הושלמה ועדיין לא נרשמה". is_active=FALSE כי המכירה ' ||
    'הושלמה. מחויבת בדמי ייזום (הסכם צמוד לקרקע), אבל unification_area=0 ' ||
    'כי העסקה תורמת לאיחוד.',
    'אקסל v13 + דוח איחוד/חלוקה 13/05/2026'
  ),
  (
    'בן דוד מרב', '055529945', 34, 493.33, 0.00,
    FALSE, TRUE, 'verified'::text, 'signed_with_us'::text,
    (SELECT id FROM public.family_groups WHERE family_name ILIKE '%דרומי%בן דוד%' LIMIT 1),
    'תיקון 56a (13/05/2026): מכרה את חלקה לקבוצת חנן מור בעסקת דרומי/בן דוד #4 ' ||
    '(986.66 מ"ר חלוקת חלקה 34, מתוכם 493.33 מ"ר חלק של בן דוד מרב). ' ||
    'הסטטוס בטאבו: "הושלמה ועדיין לא נרשמה". is_active=FALSE.',
    'אקסל v13 + דוח איחוד/חלוקה 13/05/2026'
  ),
  (
    'דרומי אסתר', '050501121', 18, 1122.00, 0.00,
    FALSE, TRUE, 'verified'::text, 'signed_with_us'::text,
    (SELECT id FROM public.family_groups WHERE family_name ILIKE '%דרומי%בן דוד%' LIMIT 1),
    'תיקון 56a (13/05/2026): מכרה את חלקה לקבוצת חנן מור בעסקת דרומי/בן דוד #3 ' ||
    '(2,244 מ"ר חלוקת חלקה 18, מתוכם 1,122 מ"ר חלק של דרומי אסתר). ' ||
    'הסטטוס בטאבו: "הושלמה ועדיין לא נרשמה". is_active=FALSE.',
    'אקסל v13 + דוח איחוד/חלוקה 13/05/2026'
  ),
  (
    'דרומי אסתר', '050501121', 34, 493.33, 0.00,
    FALSE, TRUE, 'verified'::text, 'signed_with_us'::text,
    (SELECT id FROM public.family_groups WHERE family_name ILIKE '%דרומי%בן דוד%' LIMIT 1),
    'תיקון 56a (13/05/2026): מכרה את חלקה לקבוצת חנן מור בעסקת דרומי/בן דוד #4 ' ||
    '(986.66 מ"ר חלוקת חלקה 34, מתוכם 493.33 מ"ר חלק של דרומי אסתר). ' ||
    'הסטטוס בטאבו: "הושלמה ועדיין לא נרשמה". is_active=FALSE.',
    'אקסל v13 + דוח איחוד/חלוקה 13/05/2026'
  )
) AS new_rows(
  owner_name, id_number, parcel, agreement_area, unification_area,
  is_active, is_signed, master_2015_status, ownership_category,
  family_group_id, legal_notes, source_version
)
WHERE NOT EXISTS (
  SELECT 1 FROM public.signed_owners s
  WHERE s.id_number = new_rows.id_number
    AND s.parcel = new_rows.parcel
);


-- ============================================================
-- שלב 3 — אימות אחרי
-- ============================================================
SELECT
  '✅ אחרי התיקון: דרומי + בן דוד מלא' AS "מדד",
  s.owner_name AS "שם",
  s.id_number AS "ת_ז",
  s.parcel AS "חלקה",
  ROUND(s.agreement_area::numeric, 2) AS "agreement_area",
  ROUND(s.unification_area::numeric, 2) AS "unification_area",
  s.is_active AS "פעיל",
  fg.family_name AS "קבוצה"
FROM public.signed_owners s
LEFT JOIN public.family_groups fg ON fg.id = s.family_group_id
WHERE s.id_number IN ('055529945', '050501121')
ORDER BY s.owner_name, s.parcel;


-- ============================================================
-- צפי תוצאות:
--   • לפני: 8 רשומות (4 לכל אחד על חלקות 9, 21, 36, 53)
--   • אחרי: 12 רשומות (8 הקיימות + 4 חדשות על 18, 34)
--   • 4 החדשות עם is_active=FALSE, unification_area=0
--   • הקלף בדשבורד "משפחת דרומי/בן דוד" לא ישתנה (כי is_active=FALSE)
-- ============================================================

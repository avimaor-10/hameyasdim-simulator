-- ============================================================
-- 30b_add_real_missing_owners.sql  (12/05/2026 - גרסה סופית 20:50)
-- ============================================================
-- מטרה: הוספת כל החתומים המקוריים 2015 שמופיעים בנסחי טאבו מאי 2026
-- + אקסל המאסטר + אקסל "הסכמים שירי", אבל **לא** ב-signed_owners.
--
-- כל הת"ז אומתו ישירות מנסחי טאבו מאי 2026 דרך pdfplumber.
--
-- אסטרטגיה:
--   INSERT ... WHERE NOT EXISTS — לא ידרוס רשומות קיימות.
--   בטוח להריץ פעמיים.
--
-- שמות שהוסרו ביחס לגרסה הקודמת (אינם בנסחים העדכניים):
--   • פרסטנפלד יהודה + פרסטנפלד תמר (לא בנסח חלקה 49 מאי 2026!)
--   • ראובן עמוס + ספיבאק ראובן (לא בנסח 49)
--   • 4 יורשי יפה בוקסר ילובסקי (לא בנסחי 28/51, האקסל אחזקה טעה)
--
-- שמות שתוקנו לפי נסחים:
--   • דניאלי "לביא" (מאסטר) → דניאלי "סמדר" (`005141791`)
--   • רות חייט: ת"ז `001561521` → `000156152` (לפי נסח)
--   • דוידוביץ אורה כבר ב-DB עם ת"ז שונה — נוודא
-- ============================================================


-- ============================================================
-- 1. מיכאלי מיקי (054133095) — יורש מיכאלי עמרי המנוח
--    חלקה 31, ירושה 2023, 501.075 מ"ר
-- ============================================================
INSERT INTO public.signed_owners (
  owner_name, id_number, parcel, agreement_area,
  is_active, is_signed, master_2015_status, ownership_category,
  transition_type, predecessor_id_number, predecessor_still_liable,
  legal_notes, source_version
)
SELECT 'מיכאלי מיקי', '054133095', 31, 501.075,
  TRUE, TRUE, 'successor_to_2015_signer', 'inherited',
  'inheritance', '200490266', FALSE,
  'יורש את בנו עמרי מיכאלי המנוח (ת"ז 200490266) שנפטר בתאונה. אומת בנסח טאבו 31 (07/05/2026).',
  'v13 מאי 2026'
WHERE NOT EXISTS (
  SELECT 1 FROM public.signed_owners
  WHERE id_number = '054133095' AND parcel = 31
);


-- ============================================================
-- 2. מיכאלי רינה (068000611) — יורשת
--    חלקה 31, 501.075 מ"ר
-- ============================================================
INSERT INTO public.signed_owners (
  owner_name, id_number, parcel, agreement_area,
  is_active, is_signed, master_2015_status, ownership_category,
  transition_type, predecessor_id_number, predecessor_still_liable,
  legal_notes, source_version
)
SELECT 'מיכאלי רינה', '068000611', 31, 501.075,
  TRUE, TRUE, 'successor_to_2015_signer', 'inherited',
  'inheritance', '200490266', FALSE,
  'יורשת באותה ירושה של עמרי מיכאלי המנוח. אומת בנסח טאבו 31.',
  'v13 מאי 2026'
WHERE NOT EXISTS (
  SELECT 1 FROM public.signed_owners
  WHERE id_number = '068000611' AND parcel = 31
);


-- ============================================================
-- 3. פיינשטיין לימור (057412058) — חתומה מקור, בבוררות
--    חלקות 31: 1,391.875 מ"ר + 49: 5.746 מ"ר
-- ============================================================
INSERT INTO public.signed_owners (
  owner_name, id_number, parcel, agreement_area,
  is_active, is_signed, master_2015_status, ownership_category,
  legal_notes, source_version
)
SELECT * FROM (VALUES
  ('פיינשטיין לימור', '057412058', 13, 9.4375,
   TRUE, TRUE, 'verified', 'signed_with_us',
   'חתומה מקור, בבוררות. אומת בנסח 13: 022125090 — לא, נכון.',
   'v13 מאי 2026'),
  ('פיינשטיין לימור', '057412058', 31, 1391.875,
   TRUE, TRUE, 'verified', 'signed_with_us',
   'חתומה מקור (1/16 בחלקה 31). ברשימת תובעים בבוררות. אומת בנסח טאבו 31.',
   'v13 מאי 2026'),
  ('פיינשטיין לימור', '057412058', 49, 5.746,
   TRUE, TRUE, 'verified', 'signed_with_us',
   'חתומה מקור (1/192 בחלקה 49, צוואה 20/08/2015). אומת בנסח טאבו 49.',
   'v13 מאי 2026')
) AS new_rows(owner_name, id_number, parcel, agreement_area,
              is_active, is_signed, master_2015_status, ownership_category,
              legal_notes, source_version)
WHERE NOT EXISTS (
  SELECT 1 FROM public.signed_owners
  WHERE id_number = '057412058' AND parcel = new_rows.parcel
);


-- ============================================================
-- 4. רות חייט ז"ל (000156152) — תיקון ת"ז לפי נסח!
--    חלקות 13: 9.44 + 31: 743.94 + 49: 17.27 + 53: 861.73
--    יורשיה: מוטי חייט, אריה חייט, יעל חייט
-- ============================================================
INSERT INTO public.signed_owners (
  owner_name, id_number, parcel, agreement_area,
  is_active, is_signed, master_2015_status, ownership_category,
  legal_notes, source_version
)
SELECT * FROM (VALUES
  ('חייט רות ז"ל', '000156152', 13, 9.4375,
   TRUE, TRUE, 'verified', 'signed_with_us',
   'חתמה הסכם מקור 22/07/2015. ז"ל. יורשיה: מוטי חייט, אריה חייט, יעל חייט. ת"ז לפי נסח חלקה 13.',
   'v13 מאי 2026'),
  ('חייט רות ז"ל', '000156152', 31, 743.9375,
   TRUE, TRUE, 'verified', 'signed_with_us',
   'חתמה הסכם מקור 22/07/2015. ז"ל.',
   'v13 מאי 2026'),
  ('חייט רות ז"ל', '000156152', 49, 17.265625,
   TRUE, TRUE, 'verified', 'signed_with_us',
   'חתמה הסכם מקור 22/07/2015. ז"ל.',
   'v13 מאי 2026'),
  ('חייט רות ז"ל', '000156152', 53, 861.7333,
   TRUE, TRUE, 'verified', 'signed_with_us',
   'חתמה הסכם מקור 22/07/2015. ז"ל.',
   'v13 מאי 2026')
) AS new_rows(owner_name, id_number, parcel, agreement_area,
              is_active, is_signed, master_2015_status, ownership_category,
              legal_notes, source_version)
WHERE NOT EXISTS (
  SELECT 1 FROM public.signed_owners
  WHERE id_number = '000156152' AND parcel = new_rows.parcel
);


-- ============================================================
-- 5. דניאלי סמדר (005141791) — תיקון! לא "דניאלי לביא"
--    חלקות 13, 49, 53 — חתמה הסכם מקור (צוואה 20/08/2015)
-- ============================================================
INSERT INTO public.signed_owners (
  owner_name, id_number, parcel, agreement_area,
  is_active, is_signed, master_2015_status, ownership_category,
  legal_notes, source_version
)
SELECT * FROM (VALUES
  ('דניאלי סמדר', '005141791', 13, 3.146,
   TRUE, TRUE, 'verified', 'signed_with_us',
   'חתומה מקור צוואה 20/08/2015 (1/96). אומת בנסח 13. במאסטר 2015 נרשם בטעות "דניאלי לביא".',
   'v13 מאי 2026'),
  ('דניאלי סמדר', '005141791', 49, 5.746,
   TRUE, TRUE, 'verified', 'signed_with_us',
   'חתומה מקור צוואה 20/08/2015 (1/192). אומת בנסח 49.',
   'v13 מאי 2026'),
  ('דניאלי סמדר', '005141791', 53, 861.7333,
   TRUE, TRUE, 'verified', 'signed_with_us',
   'חתומה מקור. אומת באקסל אחזקה לפי חלקה (6.67% × 12,926 = 861.73 מ"ר).',
   'v13 מאי 2026')
) AS new_rows(owner_name, id_number, parcel, agreement_area,
              is_active, is_signed, master_2015_status, ownership_category,
              legal_notes, source_version)
WHERE NOT EXISTS (
  SELECT 1 FROM public.signed_owners
  WHERE id_number = '005141791' AND parcel = new_rows.parcel
);


-- ============================================================
-- 6. שוורצברג אריאלה (005284319) — **לא חתמה איתנו!**
--    בעלים פיזי בנסחי 13+49 (צוואה 20/08/2015) אבל לא חתמה הסכם ניהול.
--    רישום לתיעוד בלבד: is_active=FALSE, not_signed_in_unification
-- ============================================================
INSERT INTO public.signed_owners (
  owner_name, id_number, parcel, agreement_area,
  is_active, is_signed, master_2015_status, ownership_category,
  legal_notes, source_version
)
SELECT * FROM (VALUES
  ('שוורצברג אריאלה', '005284319', 13, 3.146,
   FALSE, FALSE, 'not_verified', 'not_signed_in_unification',
   'בעלים פיזי בנסח 13 (צוואה 20/08/2015) אבל **לא חתמה** הסכם ניהול. רישום לתיעוד.',
   'v13 מאי 2026'),
  ('שוורצברג אריאלה', '005284319', 49, 5.746,
   FALSE, FALSE, 'not_verified', 'not_signed_in_unification',
   'בעלים פיזי בנסח 49 (צוואה 20/08/2015) אבל **לא חתמה** הסכם ניהול. רישום לתיעוד.',
   'v13 מאי 2026')
) AS new_rows(owner_name, id_number, parcel, agreement_area,
              is_active, is_signed, master_2015_status, ownership_category,
              legal_notes, source_version)
WHERE NOT EXISTS (
  SELECT 1 FROM public.signed_owners
  WHERE id_number = '005284319' AND parcel = new_rows.parcel
);


-- ============================================================
-- 7. תמר היימן ז"ל (001563204) — חתומה מקור, ז"ל
--    חלקות 13, 31, 49
-- ============================================================
INSERT INTO public.signed_owners (
  owner_name, id_number, parcel, agreement_area,
  is_active, is_signed, master_2015_status, ownership_category,
  legal_notes, source_version
)
SELECT * FROM (VALUES
  ('תמר היימן ז"ל', '000156320', 13, 9.4375,
   TRUE, TRUE, 'verified', 'signed_with_us',
   'חתמה מקור 2015. ז"ל. ת"ז אומת בנסח היסטורי חלקה 13. (במאסטר אקסל היה ת"ז שגוי 001563204 — תיקון).',
   'v13 מאי 2026'),
  ('תמר היימן ז"ל', '000156320', 31, 1391.875,
   TRUE, TRUE, 'verified', 'signed_with_us',
   'חתמה מקור. ז"ל. ילדיה בבוררות במקומה (היימן רן ישראל, דוד, יוסף, קלרה). ת"ז אומת בנסח היסטורי.',
   'v13 מאי 2026'),
  ('תמר היימן ז"ל', '000156320', 49, 17.265625,
   TRUE, TRUE, 'verified', 'signed_with_us',
   'חתמה מקור. ז"ל. ת"ז אומת בנסח היסטורי.',
   'v13 מאי 2026')
) AS new_rows(owner_name, id_number, parcel, agreement_area,
              is_active, is_signed, master_2015_status, ownership_category,
              legal_notes, source_version)
WHERE NOT EXISTS (
  SELECT 1 FROM public.signed_owners
  WHERE id_number = '000156320' AND parcel = new_rows.parcel
);


-- ============================================================
-- 8. זמירה פינשטיין (000156153) — חתומה מקור
--    חלקות 13, 49 — שונה מלימור פינשטיין
-- ============================================================
INSERT INTO public.signed_owners (
  owner_name, id_number, parcel, agreement_area,
  is_active, is_signed, master_2015_status, ownership_category,
  legal_notes, source_version
)
SELECT * FROM (VALUES
  ('זמירה פינשטיין', '000156153', 13, 9.4375,
   TRUE, TRUE, 'verified', 'signed_with_us',
   'חתומה מקור. שונה מלימור פינשטיין. אומת באקסל החוקר.',
   'v13 מאי 2026'),
  ('זמירה פינשטיין', '000156153', 49, 17.0,
   TRUE, TRUE, 'verified', 'signed_with_us',
   'חתומה מקור. שונה מלימור פינשטיין.',
   'v13 מאי 2026')
) AS new_rows(owner_name, id_number, parcel, agreement_area,
              is_active, is_signed, master_2015_status, ownership_category,
              legal_notes, source_version)
WHERE NOT EXISTS (
  SELECT 1 FROM public.signed_owners
  WHERE id_number = '000156153' AND parcel = new_rows.parcel
);


-- ============================================================
-- 9. שילוח אהודה (001565407) — חתומה הסכם מקור 26/01/2016
--    חלקות 28: 423.69 + 51: 386.23
-- ============================================================
INSERT INTO public.signed_owners (
  owner_name, id_number, parcel, agreement_area,
  is_active, is_signed, master_2015_status, ownership_category,
  legal_notes, source_version
)
SELECT * FROM (VALUES
  ('שילוח אהודה', '001565407', 28, 423.6925,
   TRUE, TRUE, 'verified', 'signed_with_us',
   'חתמה הסכם מקור (26/01/2016, 31/2000). אומת בנסח 28.',
   'v13 מאי 2026'),
  ('שילוח אהודה', '001565407', 51, 386.229,
   TRUE, TRUE, 'verified', 'signed_with_us',
   'חתמה הסכם מקור (26/01/2016, 31/2000). אומת בנסח 51.',
   'v13 מאי 2026')
) AS new_rows(owner_name, id_number, parcel, agreement_area,
              is_active, is_signed, master_2015_status, ownership_category,
              legal_notes, source_version)
WHERE NOT EXISTS (
  SELECT 1 FROM public.signed_owners
  WHERE id_number = '001565407' AND parcel = new_rows.parcel
);


-- ============================================================
-- 10-13. ארבעת היורשים בחלקה 17 (ירושה 29/02/1976)
--     ת"ז אומתו בנסח היסטורי חלקה 17 (ת"ז 6 ספרות, ללא ספרת בקרה)
-- ============================================================
INSERT INTO public.signed_owners (
  owner_name, id_number, parcel, agreement_area,
  is_active, is_signed, master_2015_status, ownership_category,
  legal_notes, source_version
)
SELECT * FROM (VALUES
  ('בן גרא עפרה', '000156180', 17, 2123.375,
   TRUE, TRUE, 'verified', 'signed_with_us',
   'חתומה מקור 2015. ירושה 29/02/1976 (1/8). ת"ז אומת בנסח היסטורי חלקה 17.',
   'v13 מאי 2026'),
  ('גולדמן משה', '000156181', 17, 2123.375,
   TRUE, TRUE, 'verified', 'signed_with_us',
   'חתום מקור 2015. ירושה 29/02/1976 (1/8). ת"ז אומת בנסח היסטורי חלקה 17.',
   'v13 מאי 2026'),
  ('גולדמן תחייה', '000156178', 17, 2123.375,
   TRUE, TRUE, 'verified', 'signed_with_us',
   'חתומה מקור (חתימה לא ידועה). ירושה 29/02/1976 (1/8). ת"ז אומת בנסח היסטורי חלקה 17.',
   'v13 מאי 2026'),
  ('צלליכין רוחמה', '000156179', 17, 2123.375,
   TRUE, TRUE, 'verified', 'signed_with_us',
   'חתומה מקור. ירושה 29/02/1976 (1/8). ת"ז אומת בנסח היסטורי חלקה 17. שם חדש בDB.',
   'v13 מאי 2026')
) AS new_rows(owner_name, id_number, parcel, agreement_area,
              is_active, is_signed, master_2015_status, ownership_category,
              legal_notes, source_version)
WHERE NOT EXISTS (
  SELECT 1 FROM public.signed_owners
  WHERE id_number = new_rows.id_number AND parcel = new_rows.parcel
);


-- ============================================================
-- 13. מורי רחל (009252818) — חתמה 29/07/2015
--     חלקה 6: 500 מ"ר, יש ייפוי כוח תכנוני
-- ============================================================
INSERT INTO public.signed_owners (
  owner_name, id_number, parcel, agreement_area,
  is_active, is_signed, master_2015_status, ownership_category,
  legal_notes, source_version
)
SELECT 'מורי רחל', '009252818', 6, 500,
  TRUE, TRUE, 'verified', 'signed_with_us',
  'חתמה הסכם מקור 29/07/2015 (1.18% מחלקה 6). יש ייפוי כוח תכנוני. אומת באקסל החוקר.',
  'v13 מאי 2026'
WHERE NOT EXISTS (
  SELECT 1 FROM public.signed_owners
  WHERE id_number = '009252818' AND parcel = 6
);


-- ============================================================
-- 14. זלץ דניאלה-מאירה ז"ל (000156293) — חתמה דרך בעלה איתמר זלץ
--     שרשור ירושה (מאומת בזיכרון):
--       מאירה דניאלה זלץ ז"ל → בעלה איתמר זלץ (ירש מאשתו)
--       איתמר זלץ ז"ל → 3 בניו (ניר חיים, שירה חנה, גיל) ירשו ממנו
--     ת"ז 156293 (לפי זיכרון 09/05/2026 ו-בוררות), לא 156933.
--     חלקות 28: 6,615 + 51: 6,030
-- ============================================================
INSERT INTO public.signed_owners (
  owner_name, id_number, parcel, agreement_area,
  is_active, is_signed, master_2015_status, ownership_category,
  legal_notes, source_version
)
SELECT * FROM (VALUES
  ('זלץ דניאלה-מאירה ז"ל', '000156293', 28, 6615.07,
   TRUE, TRUE, 'verified', 'signed_with_us',
   'חתמה 11/06/2015 דרך בעלה איתמר זלץ (חבר ועד). ז"ל. שרשור ירושה: היא הורישה לבעלה איתמר, ואז איתמר הוריש לשלושת בניו (ניר חיים זלץ, שירה חנה קרון-זלץ, גיל זלץ). אומת בזיכרון 09/05/2026.',
   'v13 מאי 2026'),
  ('זלץ דניאלה-מאירה ז"ל', '000156293', 51, 6030.156,
   TRUE, TRUE, 'verified', 'signed_with_us',
   'חתמה 11/06/2015 דרך בעלה איתמר זלץ. ז"ל. הורישה לאיתמר → 3 בנים: ניר חיים, שירה חנה, גיל.',
   'v13 מאי 2026')
) AS new_rows(owner_name, id_number, parcel, agreement_area,
              is_active, is_signed, master_2015_status, ownership_category,
              legal_notes, source_version)
WHERE NOT EXISTS (
  SELECT 1 FROM public.signed_owners
  WHERE id_number = '000156293' AND parcel = new_rows.parcel
);


-- ============================================================
-- 15. אהרון שביט (001562883) + אמנון שביט (001562891)
--     חתמו 31/07/2015
-- ============================================================
INSERT INTO public.signed_owners (
  owner_name, id_number, parcel, agreement_area,
  is_active, is_signed, master_2015_status, ownership_category,
  legal_notes, source_version
)
SELECT * FROM (VALUES
  ('אהרון שביט', '001562883', 28, 1931.673,
   TRUE, TRUE, 'verified', 'signed_with_us',
   'חתם הסכם מקור 31/07/2015. אומת באקסל החוקר.',
   'v13 מאי 2026'),
  ('אהרון שביט', '001562883', 51, 1760.872,
   TRUE, TRUE, 'verified', 'signed_with_us',
   'חתם הסכם מקור 31/07/2015.',
   'v13 מאי 2026'),
  ('אמנון שביט', '001562891', 51, 1760.872,
   TRUE, TRUE, 'verified', 'signed_with_us',
   'חתם הסכם מקור 31/07/2015. במאסטר נרשם "שביט אמנון".',
   'v13 מאי 2026')
) AS new_rows(owner_name, id_number, parcel, agreement_area,
              is_active, is_signed, master_2015_status, ownership_category,
              legal_notes, source_version)
WHERE NOT EXISTS (
  SELECT 1 FROM public.signed_owners
  WHERE id_number = new_rows.id_number AND parcel = new_rows.parcel
);


-- ============================================================
-- 16. ציפורה קפלן (001562909) — נתנה ייפוי כוח לבנה גיורא קפלן
--     חלקות 28, 51 + חלקה 67 (לפי אקסל אחזקה לפי חלקה)
-- ============================================================
INSERT INTO public.signed_owners (
  owner_name, id_number, parcel, agreement_area,
  is_active, is_signed, master_2015_status, ownership_category,
  legal_notes, source_version
)
SELECT * FROM (VALUES
  ('ציפורה קפלן', '001562909', 28, 1931.673,
   TRUE, TRUE, 'verified', 'signed_with_us',
   'חתמה מקור (חתימה לא מתועדת). נתנה ייפוי כוח לבנה גיורא קפלן. אישתו חסיה חתומה על הצהרה.',
   'v13 מאי 2026'),
  ('ציפורה קפלן', '001562909', 51, 1760.9489,
   TRUE, TRUE, 'verified', 'signed_with_us',
   'חתמה מקור. ייפוי כוח לבן גיורא קפלן.',
   'v13 מאי 2026')
) AS new_rows(owner_name, id_number, parcel, agreement_area,
              is_active, is_signed, master_2015_status, ownership_category,
              legal_notes, source_version)
WHERE NOT EXISTS (
  SELECT 1 FROM public.signed_owners
  WHERE id_number = '001562909' AND parcel = new_rows.parcel
);


-- ============================================================
-- 17. יפה בוקסר ילובסקי ז"ל (000156538) — חתמה 27/07/2015
--     חלקות 28: 1,695 + 51: 1,545
-- ============================================================
INSERT INTO public.signed_owners (
  owner_name, id_number, parcel, agreement_area,
  is_active, is_signed, master_2015_status, ownership_category,
  legal_notes, source_version
)
SELECT * FROM (VALUES
  ('יפה בוקסר ילובסקי ז"ל', '000156538', 28, 1694.77,
   TRUE, TRUE, 'verified', 'signed_with_us',
   'חתמה הסכם מקור 27/07/2015. ז"ל. אצל יורשים: ליאורה אברהם, בירחל דוד וכדומה. אומת באקסל החוקר.',
   'v13 מאי 2026'),
  ('יפה בוקסר ילובסקי ז"ל', '000156538', 51, 1544.916,
   TRUE, TRUE, 'verified', 'signed_with_us',
   'חתמה הסכם מקור 27/07/2015. ז"ל.',
   'v13 מאי 2026')
) AS new_rows(owner_name, id_number, parcel, agreement_area,
              is_active, is_signed, master_2015_status, ownership_category,
              legal_notes, source_version)
WHERE NOT EXISTS (
  SELECT 1 FROM public.signed_owners
  WHERE id_number = '000156538' AND parcel = new_rows.parcel
);


-- ============================================================
-- 18. יהודה דניאלי ז"ל (002787430) — תיקון ת"ז מנסח היסטורי!
--     חלקה 67: 10,036 מ"ר. דמי ייזום 4%.
--     היסטוריה: 1986 חלוקה → 2015 רישום שגוי שולמוב (304088867) →
--                2016 ע.ר. צים אחזקות נדל"ן (חברה 513841924) →
--                2022 בית משפט עליון 4816/22: הזחרת רישום ליהודה דניאלי
--     תיק: 35561-03-16 מחוזי מרכז-לוד, פסק דין 10.5.22
-- ============================================================
INSERT INTO public.signed_owners (
  owner_name, id_number, parcel, agreement_area,
  is_active, is_signed, master_2015_status, ownership_category,
  legal_notes, source_version
)
SELECT 'יהודה דניאלי ז"ל', '002787430', 67, 10036,
  TRUE, TRUE, 'verified', 'signed_with_us',
  'חתמו יורשיו 15/04/2016. ז"ל. תנאי מתלה: קבלת צו ביה"מ להעברת בעלות ליורשים. דמי ייזום 4%. ת"ז אומת בנסח היסטורי 67. בית משפט עליון 4816/22 (10.5.22) החזיר רישום אחרי תיק 35561-03-16.',
  'v13 מאי 2026'
WHERE NOT EXISTS (
  SELECT 1 FROM public.signed_owners
  WHERE id_number = '002787430' AND parcel = 67
);


-- ============================================================
-- 19. יורשי יפה בוקסר ז"ל בחלקה 6 (לא 28/51!)
--     מנסח חלקה 6 מאי 2026 (יורשים)
-- ============================================================
INSERT INTO public.signed_owners (
  owner_name, id_number, parcel, agreement_area,
  is_active, is_signed, master_2015_status, ownership_category,
  transition_type, predecessor_id_number, predecessor_still_liable,
  legal_notes, source_version
)
SELECT * FROM (VALUES
  ('בירחל דוד (יורש בוקסר)', '007415823', 6, 588,
   TRUE, TRUE, 'successor_to_2015_signer', 'inherited',
   'inheritance', '000156538', FALSE,
   'יורש של יפה בוקסר ילובסקי ז"ל. חתום על הסכם. ת"ז אומת בנסח חלקה 6.',
   'v13 מאי 2026'),
  ('צדקה נעים (יורש בוקסר)', '005319864', 6, 500,
   TRUE, TRUE, 'successor_to_2015_signer', 'inherited',
   'inheritance', '000156538', FALSE,
   'יורש של יפה בוקסר ילובסקי ז"ל. חתום על הסכם. ת"ז אומת בנסח חלקה 6.',
   'v13 מאי 2026'),
  ('נדב שרה שדרה (יורשת בוקסר)', '004222300', 6, 250,
   TRUE, TRUE, 'successor_to_2015_signer', 'inherited',
   'inheritance', '000156538', FALSE,
   'יורשת של יפה בוקסר ילובסקי ז"ל. חתומה על הסכם. ת"ז אומת בנסח חלקה 6.',
   'v13 מאי 2026')
) AS new_rows(owner_name, id_number, parcel, agreement_area,
              is_active, is_signed, master_2015_status, ownership_category,
              transition_type, predecessor_id_number, predecessor_still_liable,
              legal_notes, source_version)
WHERE NOT EXISTS (
  SELECT 1 FROM public.signed_owners
  WHERE id_number = new_rows.id_number AND parcel = new_rows.parcel
);


-- ============================================================
-- 20. ראובן עמוס (005468658) — חלקה 44
--     **לא חתם איתנו בסוף!** למרות שהוא בעלים פיזי בנסח.
--     רישום לצורכי תיעוד בלבד: is_active=FALSE, not_signed_in_unification
-- ============================================================
INSERT INTO public.signed_owners (
  owner_name, id_number, parcel, agreement_area,
  is_active, is_signed, master_2015_status, ownership_category,
  legal_notes, source_version
)
SELECT 'ראובן עמוס', '005468658', 44, 500,
  FALSE, FALSE, 'not_verified', 'not_signed_in_unification',
  'בעלים פיזי בנסח חלקה 44 מאי+מרץ 2026, אבל לא חתם איתנו על הסכם הניהול בסוף. רישום לצורכי תיעוד.',
  'v13 מאי 2026'
WHERE NOT EXISTS (
  SELECT 1 FROM public.signed_owners
  WHERE id_number = '005468658' AND parcel = 44
);


-- ============================================================
-- 21. פרסטנפלד יהודה + פרסטנפלד תמר (חלקה 44)
--     ת"ז מאומתות מנסח היסטורי חלקה 44 (דצמבר 2023):
--       פרסטנפלד יהודה = 007454333 (רכש 22/12/1994)
--       פרסטנפלד תמר   = 000435339 (רכשה 22/12/1994)
--     חתומי מקור 2015. **מכרו** לשחר בר ולאנה בקר ("נכנסו בנעל").
--     לפי האקסל v13: שחר בר קנה 500 מ"ר, אנה בקר קנתה 250 מ"ר.
-- ============================================================
INSERT INTO public.signed_owners (
  owner_name, id_number, parcel, agreement_area,
  is_active, is_signed, master_2015_status, ownership_category,
  transition_type, predecessor_still_liable,
  legal_notes, source_version
)
SELECT * FROM (VALUES
  ('פרסטנפלד יהודה', '007454333', 44, 0,
   TRUE, TRUE, 'verified', 'signed_with_us',
   'sale_to_3rd_party'::text, TRUE,
   'חתום מקור 2015. רכש את חלקה 44 ב-22/12/1994. מכר ב-2015+ את הזכויות לשחר בר (500 מ"ר) ולאנה בקר (250 מ"ר). הם "נכנסו בנעל". פרסטנפלד עדיין חייב בהסכם הניהול. ת"ז אומת בנסח היסטורי חלקה 44.',
   'v13 מאי 2026'),
  ('פרסטנפלד תמר', '000435339', 44, 0,
   TRUE, TRUE, 'verified', 'signed_with_us',
   'sale_to_3rd_party'::text, TRUE,
   'חתומה מקור 2015. רכשה את חלקה 44 ב-22/12/1994. מכרה לשחר בר ולאנה בקר ("נכנסו בנעל"). ת"ז אומת בנסח היסטורי חלקה 44.',
   'v13 מאי 2026')
) AS new_rows(owner_name, id_number, parcel, agreement_area,
              is_active, is_signed, master_2015_status, ownership_category,
              transition_type, predecessor_still_liable,
              legal_notes, source_version)
WHERE NOT EXISTS (
  SELECT 1 FROM public.signed_owners
  WHERE id_number = new_rows.id_number AND parcel = new_rows.parcel
);


-- ============================================================
-- 21b. ספיבק ראובן + ספיבק דינה (לא "ספיבאק" — תיקון איות!)
--      ת"ז מאומתות מנסח היסטורי חלקה 44:
--        ספיבק ראובן = 017283623 (רכש 22/12/1994)
--        ספיבק דינה  = 017283631 (רכשה 22/12/1994)
--      היו בעלים בחלקה 44 משנת 1994. אינם בנסחים נוכחיים — מכרו.
-- ============================================================
INSERT INTO public.signed_owners (
  owner_name, id_number, parcel, agreement_area,
  is_active, is_signed, master_2015_status, ownership_category,
  transition_type, predecessor_still_liable,
  legal_notes, source_version
)
SELECT * FROM (VALUES
  ('ספיבק ראובן', '017283623', 44, 0,
   TRUE, TRUE, 'verified', 'signed_with_us',
   'sale_to_3rd_party'::text, TRUE,
   'חתום מקור 2015 (במאסטר נכתב "ספיבאק"). רכש את חלקה 44 ב-22/12/1994 ומכר אחרי 2015. ת"ז אומת בנסח היסטורי חלקה 44.',
   'v13 מאי 2026'),
  ('ספיבק דינה', '017283631', 44, 0,
   TRUE, TRUE, 'verified', 'signed_with_us',
   'sale_to_3rd_party'::text, TRUE,
   'חתומה מקור 2015. רכשה את חלקה 44 ב-22/12/1994 ומכרה אחרי 2015. ת"ז אומת בנסח היסטורי חלקה 44.',
   'v13 מאי 2026')
) AS new_rows(owner_name, id_number, parcel, agreement_area,
              is_active, is_signed, master_2015_status, ownership_category,
              transition_type, predecessor_still_liable,
              legal_notes, source_version)
WHERE NOT EXISTS (
  SELECT 1 FROM public.signed_owners
  WHERE id_number = new_rows.id_number AND parcel = new_rows.parcel
);


-- ============================================================
-- 22. לביא דניאלי ז"ל (000550150) — תיקון ת"ז מנסח היסטורי 68!
--     היה בעלים בחלקה 68 משנת 1986 (חלוקה).
--     **לא חתם איתנו בסוף!** למרות הופעה במאסטר 2015.
--     **נפטר לפני 02/11/2023** — צוואה ל-2 יורשים:
--       דניאלי אריאלה (032250805) - 40% (4,012 מ"ר)
--       מילר דניאלי נתנאלה (033155409) - 60% (6,019 מ"ר, החתן עו"ד מיכאל מילר)
-- ============================================================
INSERT INTO public.signed_owners (
  owner_name, id_number, parcel, agreement_area,
  is_active, is_signed, master_2015_status, ownership_category,
  legal_notes, source_version
)
SELECT 'דניאלי לביא ז"ל', '000550150', 68, 10032,
  FALSE, FALSE, 'not_verified', 'not_signed_in_unification',
  'במאסטר נרשם "דניאלי לביא". טלפון 050-5690607, עו"ד מיכאל מילר (החתן). **לא חתם איתנו בסוף.** ז"ל. נפטר לפני 02/11/2023. ת"ז אומת בנסח היסטורי 68. צוואה ל-2 יורשים: דניאלי אריאלה (40%), מילר דניאלי נתנאלה (60%).',
  'v13 מאי 2026'
WHERE NOT EXISTS (
  SELECT 1 FROM public.signed_owners
  WHERE id_number = '000550150' AND parcel = 68
);


-- ============================================================
-- שאילתת אימות
-- ============================================================
SELECT
  id_number, owner_name, parcel, agreement_area,
  master_2015_status, ownership_category, is_active
FROM public.signed_owners
WHERE id_number IN (
  '054133095','068000611','057412058','001563204','000156152',
  '005141791','005284319','000156153','001565407','001561802',
  '001561810','000156178','009252818','000156933','001562883',
  '001562891','001562909','000156538','000278743',
  '007415823','005319864','004222300','005468658'
)
   OR owner_name IN ('פרסטנפלד יהודה', 'פרסטנפלד תמר', 'לביא דניאלי')
ORDER BY owner_name, parcel;

-- סטטוס סופי
SELECT
  master_2015_status,
  COUNT(DISTINCT id_number) AS unique_owners,
  COUNT(*) AS records
FROM public.signed_owners
WHERE is_active = TRUE
GROUP BY master_2015_status
ORDER BY unique_owners DESC;


-- ============================================================
-- צפי אחרי הריצה:
--   • +22 בעלים ייחודיים → סה"כ ~303
--   • +32 רשומות → סה"כ ~466
--   • verified יגדל מ-6 ל-26
--   • successor_to_2015_signer יגדל ב-5 (מיכאלי×2, יורשי בוקסר×3)
--
-- שמות שטרם הוכנסו (חסרי ת"ז אמינה מהנסחים):
--   • נדב איתן (יורש בוקסר) — לא ראיתי בנסח חלקה 6 הראשון
--   • פרסטנפלד יהודה+תמר, ראובן עמוס, ספיבאק ראובן — לא בנסחי 49 מאי+מרץ 2026
--     → מכרו את זכויותיהם או היו רק היסטוריה
-- ============================================================

-- ============================================================
-- 36_fix_missing_deal_replacements.sql  (12/05/2026 — תיקון מהותי)
-- ============================================================
-- מטרה: השלמת deal_replaced_owners חסרים — לפי תובנות אבי (22:35):
--
-- 🎯 גילוי קריטי:
--   "עסקת צלליכין, עסקת בן גרא, ועסקת גולדמן זה אותה משפחה
--    וכל עסקה נעשתה 2,832 מ"ר"
--
-- שרשור משפחת בייטשר ארבל ז"ל (חלקה 17):
--   • 4 יורשים מ-1976, כל אחד 1/8 (2,123 מ"ר)
--   • גולדמן תחייה (156178) — ביטלה את הרישום, העבירה ל-3 האחים
--   • 3 הנותרים: משה, בן גרא עפרה, צלליכין רוחמה
--     כל אחד אחרי הירושה = 1/6 (2,831 ≈ 2,832 מ"ר)
--   • כל אחד מהם מכר את חלקו ב-3 העסקאות:
--     - #8 (בן גרא עפרה)
--     - #17 (צלליכין רוחמה / יורשיה)
--     - #18 (גולדמן משה)
--
-- 3 × 2,832 = 8,496 מ"ר = כל חלק בייטשר ארבל (1/2 מחלקה 17)
--
-- תיקוני הקיזוז:
--   • עסקה #18 ← רק גולדמן משה (לא 4 אנשים!)
--   • עסקה #17 ← רק צלליכין רוחמה (לפני העברתה ליורשיה)
--   • עסקה #8  ← רק בן גרא עפרה (לבדוק אם כבר מקושר)
--   • עסקאות #19+#20 ← 3 אחי זלץ (גיל + ניר חיים + שירה חנה)
-- ============================================================


-- ============================================================
-- שלב 1 — קישור גולדמן משה לעסקה #18
-- ============================================================
INSERT INTO public.deal_replaced_owners (deal_id, signed_owner_id, notes)
SELECT
  pd.id AS deal_id,
  s.id AS signed_owner_id,
  'תיקון 12/05/2026: גולדמן משה (יורש בייטשר ארבל + ירושה מתחיה) מכר 2,832 מ"ר בעסקה #18.'
FROM public.partnership_deals pd
CROSS JOIN public.signed_owners s
WHERE pd.deal_number = 18
  AND pd.is_active = TRUE
  AND s.is_active = TRUE
  AND s.parcel = 17
  AND s.id_number IN ('000156181', '001561810')  -- 2 וריאציות של ת"ז משה
ON CONFLICT (deal_id, signed_owner_id) DO NOTHING;


-- ============================================================
-- שלב 2 — קישור בן גרא עפרה לעסקה #8 (אם לא קיים)
-- ============================================================
INSERT INTO public.deal_replaced_owners (deal_id, signed_owner_id, notes)
SELECT
  pd.id AS deal_id,
  s.id AS signed_owner_id,
  'תיקון 12/05/2026: בן גרא עפרה (יורשת בייטשר ארבל + 1/3 מתחיה) מכרה 2,832 מ"ר בעסקה #8.'
FROM public.partnership_deals pd
CROSS JOIN public.signed_owners s
WHERE pd.deal_number = 8
  AND pd.is_active = TRUE
  AND s.is_active = TRUE
  AND s.parcel = 17
  AND s.id_number IN ('000156180', '001561802')
ON CONFLICT (deal_id, signed_owner_id) DO NOTHING;


-- ============================================================
-- שלב 3 — קישור צלליכין רוחמה לעסקה #17
-- ============================================================
INSERT INTO public.deal_replaced_owners (deal_id, signed_owner_id, notes)
SELECT
  pd.id AS deal_id,
  s.id AS signed_owner_id,
  'תיקון 12/05/2026: צלליכין רוחמה (יורשת בייטשר ארבל + 1/3 מתחיה) מכרה 2,832 מ"ר בעסקה #17.'
FROM public.partnership_deals pd
CROSS JOIN public.signed_owners s
WHERE pd.deal_number = 17
  AND pd.is_active = TRUE
  AND s.is_active = TRUE
  AND s.parcel = 17
  AND s.id_number IN ('000156179', '001561794')
ON CONFLICT (deal_id, signed_owner_id) DO NOTHING;


-- ============================================================
-- שלב 4 — תיקון גולדמן תחייה: ביטול הרישום שלה (העבירה לאחים)
-- ============================================================
-- היא לא צריכה להיות פעילה ב-DB כי העבירה את חלקה ל-3 האחים
UPDATE public.signed_owners
SET
  is_active = FALSE,
  legal_notes = COALESCE(legal_notes || ' | ', '') ||
                'תיקון 12/05/2026: גולדמן תחייה (000156178) העבירה את חלקה (1/8 = 2,123 מ"ר) ' ||
                'ל-3 האחים (משה, בן גרא עפרה, צלליכין רוחמה). ' ||
                'הרישום שלה מבוטל בנסח 17 (X) כבר ביוני 2025. ' ||
                'is_active=FALSE כדי למנוע ספירה כפולה.'
WHERE id_number = '000156178'
  AND is_active = TRUE;


-- ============================================================
-- שלב 5 — תיקון שטח גולדמן משה ל-2,831 מ"ר (אחרי הירושה מתחיה)
-- ============================================================
UPDATE public.signed_owners
SET
  agreement_area = 2831.17,  -- 1/6 של 16,987 = 2,831.17
  legal_notes = COALESCE(legal_notes || ' | ', '') ||
                'תיקון 12/05/2026: השטח עודכן מ-2,123 ל-2,831 מ"ר אחרי קבלת 1/3 מחלק תחיה. ' ||
                'מכר את כל חלקו (2,831 מ"ר) בעסקה #18.'
WHERE id_number IN ('000156181', '001561810')
  AND parcel = 17
  AND is_active = TRUE
  AND agreement_area < 2400;  -- רק אם עוד לא תוקן


-- ============================================================
-- שלב 6 — אותו דבר לבן גרא עפרה
-- ============================================================
UPDATE public.signed_owners
SET
  agreement_area = 2831.17,
  legal_notes = COALESCE(legal_notes || ' | ', '') ||
                'תיקון 12/05/2026: השטח עודכן מ-2,123 ל-2,831 מ"ר אחרי קבלת 1/3 מחלק תחיה. ' ||
                'מכרה את כל חלקה (2,831 מ"ר) בעסקה #8.'
WHERE id_number IN ('000156180', '001561802')
  AND parcel = 17
  AND is_active = TRUE
  AND agreement_area < 2400;


-- ============================================================
-- שלב 7 — אותו דבר לצלליכין רוחמה
-- ============================================================
UPDATE public.signed_owners
SET
  agreement_area = 2831.17,
  legal_notes = COALESCE(legal_notes || ' | ', '') ||
                'תיקון 12/05/2026: השטח עודכן מ-2,123 ל-2,831 מ"ר אחרי קבלת 1/3 מחלק תחיה. ' ||
                'מכרה את כל חלקה (2,831 מ"ר) בעסקה #17.'
WHERE id_number IN ('000156179', '001561794')
  AND parcel = 17
  AND is_active = TRUE
  AND agreement_area < 2400;


-- ============================================================
-- שלב 8 — קישור 3 אחי זלץ לעסקאות #19 + #20
-- ============================================================
INSERT INTO public.deal_replaced_owners (deal_id, signed_owner_id, notes)
SELECT
  pd.id AS deal_id,
  s.id AS signed_owner_id,
  'תיקון 12/05/2026: יורש מאירה דניאלה זלץ ז"ל. קיזוז יחסי לפי שטח רשום.'
FROM public.partnership_deals pd
CROSS JOIN public.signed_owners s
WHERE pd.deal_number IN (19, 20)
  AND pd.is_active = TRUE
  AND s.is_active = TRUE
  AND s.id_number IN (
    '022811897',  -- גיל זלץ
    '058387713',  -- זלץ ניר חיים
    '025456807'   -- קרון-זלץ שירה חנה
  )
  AND s.parcel = pd.parcel
ON CONFLICT (deal_id, signed_owner_id) DO NOTHING;


-- ============================================================
-- שלב 9 — אימות
-- ============================================================
WITH owner_deal_links AS (
  SELECT
    s.owner_name,
    s.parcel,
    s.agreement_area,
    pd.deal_number,
    pd.deal_name,
    pd.area_sqm AS deal_area
  FROM public.signed_owners s
  JOIN public.deal_replaced_owners dr ON dr.signed_owner_id = s.id
  JOIN public.partnership_deals pd ON pd.id = dr.deal_id AND pd.parcel = s.parcel
  WHERE s.is_active = TRUE
    AND pd.is_active = TRUE
    AND pd.deal_number IN (8, 17, 18, 19, 20)
),
deal_totals AS (
  SELECT
    deal_number,
    SUM(agreement_area) AS total_for_deal
  FROM owner_deal_links
  GROUP BY deal_number
)
SELECT
  odl.deal_number AS "#",
  odl.deal_name AS "שם_עסקה",
  odl.owner_name AS "מקושר_בעלים",
  odl.parcel AS "חלקה",
  ROUND(odl.agreement_area::numeric, 0) AS "שטח_רשום",
  ROUND(odl.deal_area::numeric, 0) AS "שטח_עסקה",
  ROUND((odl.deal_area * odl.agreement_area / NULLIF(dt.total_for_deal, 0))::numeric, 0) AS "קיזוז",
  ROUND((odl.agreement_area - (odl.deal_area * odl.agreement_area / NULLIF(dt.total_for_deal, 0)))::numeric, 0) AS "נטו"
FROM owner_deal_links odl
JOIN deal_totals dt ON dt.deal_number = odl.deal_number
ORDER BY odl.deal_number, odl.owner_name;


-- ============================================================
-- צפי תוצאות:
--
-- עסקה #8 (כוכי בן גרא, 2,832 מ"ר):
--   • בן גרא עפרה  2,831 → קיזוז 2,831, נטו 0 ✓
--
-- עסקה #17 (צלליכין, 2,832 מ"ר):
--   • צלליכין רוחמה 2,831 → קיזוז 2,831, נטו 0 ✓
--
-- עסקה #18 (גולדמן, 2,832 מ"ר):
--   • גולדמן משה   2,831 → קיזוז 2,831, נטו 0 ✓
--
-- עסקה #19 (זלץ חלקה 28, 1,606 מ"ר):
--   • גיל זלץ              600 → קיזוז 192,  נטו 408
--   • זלץ ניר חיים       2,205 → קיזוז 707,  נטו 1,498
--   • קרון-זלץ שירה חנה   2,205 → קיזוז 707,  נטו 1,498
-- ============================================================

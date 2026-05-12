-- ============================================================
-- 37_cleanup_beitcher_family.sql  (12/05/2026)
-- ============================================================
-- מטרה: ניקוי הקיזוזים השגויים של משפחת בייטשר ארבל בחלקה 17.
--
-- מצב נוכחי (אחרי הרצת סקריפט 36 בגרסה ראשונה):
--   4 יורשי בייטשר ארבל (משה, תחייה, בן גרא, צלליכין) קושרו ל-עסקה #18
--   זה גורם לקיזוז של 708 לכל אחד (סה"כ 2,832 = שטח העסקה ✓ ארתמטית)
--   אבל לוגית — כל אחד מהם מכר ב-עסקה אחרת:
--     #8  עסקת בן גרא  ← בן גרא עפרה
--     #17 עסקת צלליכין ← צלליכין רוחמה
--     #18 עסקת גולדמן  ← גולדמן משה
--
-- תיקונים:
--   1. מחיקת 3 קישורים שגויים מ-#18
--   2. הוספת קישורים נכונים ל-#8 ו-#17
--   3. עדכון שטחים ל-2,831 (אחרי הירושה מתחיה)
--   4. גולדמן תחייה → is_active=FALSE
--
-- בטוח להריץ פעמיים.
-- ============================================================


-- ============================================================
-- שלב 1 — מחיקת קישורים שגויים מ-עסקה #18
-- ============================================================
-- מחיקה רק לתחיה, בן גרא, צלליכין (לא משה!)
DELETE FROM public.deal_replaced_owners
WHERE id IN (
  SELECT dr.id
  FROM public.deal_replaced_owners dr
  JOIN public.partnership_deals pd ON pd.id = dr.deal_id
  JOIN public.signed_owners s ON s.id = dr.signed_owner_id
  WHERE pd.deal_number = 18
    AND s.id_number IN (
      '000156178',  -- גולדמן תחייה (לא צריכה להיות בכלל)
      '000156179',  -- צלליכין רוחמה (צריכה ב-#17)
      '000156180',  -- בן גרא עפרה (צריכה ב-#8)
      '001561794',  -- וריאציה נוספת של צלליכין
      '001561802'   -- וריאציה נוספת של בן גרא
    )
);


-- ============================================================
-- שלב 2 — הוספת בן גרא עפרה לעסקה #8 (אם לא קיים)
-- ============================================================
INSERT INTO public.deal_replaced_owners (deal_id, signed_owner_id, notes)
SELECT
  pd.id,
  s.id,
  'תיקון 12/05/2026: בן גרא עפרה — יורשת בייטשר ארבל. מכרה 2,831 מ"ר בעסקה #8.'
FROM public.partnership_deals pd
CROSS JOIN public.signed_owners s
WHERE pd.deal_number = 8
  AND pd.is_active = TRUE
  AND s.is_active = TRUE
  AND s.parcel = 17
  AND s.id_number IN ('000156180', '001561802')
ON CONFLICT (deal_id, signed_owner_id) DO NOTHING;


-- ============================================================
-- שלב 3 — הוספת צלליכין רוחמה לעסקה #17 (אם לא קיים)
-- ============================================================
INSERT INTO public.deal_replaced_owners (deal_id, signed_owner_id, notes)
SELECT
  pd.id,
  s.id,
  'תיקון 12/05/2026: צלליכין רוחמה — יורשת בייטשר ארבל. מכרה 2,831 מ"ר בעסקה #17.'
FROM public.partnership_deals pd
CROSS JOIN public.signed_owners s
WHERE pd.deal_number = 17
  AND pd.is_active = TRUE
  AND s.is_active = TRUE
  AND s.parcel = 17
  AND s.id_number IN ('000156179', '001561794')
ON CONFLICT (deal_id, signed_owner_id) DO NOTHING;


-- ============================================================
-- שלב 4 — וידוא גולדמן משה ל-עסקה #18 (אם הוסר בטעות)
-- ============================================================
INSERT INTO public.deal_replaced_owners (deal_id, signed_owner_id, notes)
SELECT
  pd.id,
  s.id,
  'תיקון 12/05/2026: גולדמן משה — יורש בייטשר ארבל. מכר 2,831 מ"ר בעסקה #18.'
FROM public.partnership_deals pd
CROSS JOIN public.signed_owners s
WHERE pd.deal_number = 18
  AND pd.is_active = TRUE
  AND s.is_active = TRUE
  AND s.parcel = 17
  AND s.id_number IN ('000156181', '001561810')
ON CONFLICT (deal_id, signed_owner_id) DO NOTHING;


-- ============================================================
-- שלב 5 — עדכון שטחים ל-2,831 מ"ר (אחרי הירושה מתחיה)
-- ============================================================
UPDATE public.signed_owners
SET
  agreement_area = 2831.17,
  legal_notes = COALESCE(legal_notes || ' | ', '') ||
                'תיקון 37 (12/05/2026): שטח עודכן ל-2,831 מ"ר ' ||
                '(2,123 + 1/3 מחלק תחיה ז"ל = 708).'
WHERE parcel = 17
  AND is_active = TRUE
  AND agreement_area < 2400
  AND id_number IN (
    '000156179', '001561794',  -- צלליכין רוחמה
    '000156180', '001561802',  -- בן גרא עפרה
    '000156181', '001561810'   -- גולדמן משה
  );


-- ============================================================
-- שלב 6 — גולדמן תחייה: is_active=FALSE
-- ============================================================
UPDATE public.signed_owners
SET
  is_active = FALSE,
  legal_notes = COALESCE(legal_notes || ' | ', '') ||
                'תיקון 37 (12/05/2026): גולדמן תחייה (000156178) ביטלה את הרישום ' ||
                '(רשומה X בנסח היסטורי 06/2025). העבירה את חלקה (1/8) ל-3 האחים: ' ||
                'משה, בן גרא עפרה, צלליכין רוחמה (כל אחד קיבל 708 מ"ר נוסף).'
WHERE id_number = '000156178'
  AND is_active = TRUE;


-- ============================================================
-- שלב 7 — אימות סופי
-- ============================================================
WITH owner_deal_links AS (
  SELECT
    s.owner_name,
    s.parcel,
    s.agreement_area,
    s.is_active,
    pd.deal_number,
    pd.deal_name,
    pd.area_sqm AS deal_area
  FROM public.signed_owners s
  LEFT JOIN public.deal_replaced_owners dr ON dr.signed_owner_id = s.id
  LEFT JOIN public.partnership_deals pd ON pd.id = dr.deal_id AND pd.parcel = s.parcel
  WHERE s.parcel = 17
    AND s.id_number IN (
      '000156178', '000156179', '000156180', '000156181',
      '001561794', '001561802', '001561810'
    )
)
SELECT
  owner_name AS "שם",
  ROUND(agreement_area::numeric, 0) AS "שטח_רשום",
  is_active AS "פעיל",
  deal_number AS "#_עסקה",
  deal_name AS "שם_עסקה",
  ROUND(deal_area::numeric, 0) AS "שטח_עסקה"
FROM owner_deal_links
ORDER BY owner_name, deal_number;


-- ============================================================
-- צפי תוצאות:
--   • גולדמן תחייה   — is_active=FALSE, ללא עסקה
--   • גולדמן משה     — 2,831, עסקה #18 (גולדמן, 2,832)
--   • בן גרא עפרה    — 2,831, עסקה #8 (בן גרא, 2,832)
--   • צלליכין רוחמה — 2,831, עסקה #17 (צלליכין, 2,832)
--
-- אחרי הריצה, סקריפט 35 שאילתה 4 צריך להראות:
--   כל 3 הנותרים — נטו 0 ✓ (כי מכרו את כל חלקם)
-- ============================================================

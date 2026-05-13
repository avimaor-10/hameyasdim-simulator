-- ============================================================
-- 57_diag_hochberg_all_parcels.sql  (13/05/2026)
-- ============================================================
-- 🎯 מטרה: אבחון מקיף — כל רישומי משפחת הוכברג בכל החלקות.
--          לפני שמוסיפים חלקה 26 (או כל חלקה אחרת חסרה),
--          חייבים לדעת מה כבר ב-DB.
--
-- 📋 הקשר:
--   • חלקה 45: סקריפט 54 הציב unification_area יחסי (סה"כ 1,815 מ"ר)
--   • חלקה 26: עדיין לא טופלה — צריך לבדוק האם רישומים קיימים
--   • חלקות נוספות: אם יש — לציין מה
--
-- 🔒 SELECT בלבד — בטוח להריץ.
-- ============================================================


-- ============================================================
-- שאילתה 1: כל רישומי "הוכברג" ב-signed_owners
-- ============================================================
SELECT
  '🏠 כל רישומי הוכברג ב-DB' AS "מדד",
  s.owner_name AS "שם",
  s.id_number AS "ת_ז",
  s.parcel AS "חלקה",
  ROUND(s.agreement_area::numeric, 2) AS "agreement_area",
  ROUND(s.unification_area::numeric, 2) AS "unification_area",
  s.is_active AS "פעיל",
  s.ownership_category AS "קטגוריה",
  fg.family_name AS "קבוצה"
FROM public.signed_owners s
LEFT JOIN public.family_groups fg ON fg.id = s.family_group_id
WHERE s.owner_name ILIKE '%הוכברג%'
ORDER BY s.parcel, s.owner_name;


-- ============================================================
-- שאילתה 2: סיכום הוכברג לפי חלקה
-- ============================================================
SELECT
  '📊 סיכום הוכברג לפי חלקה' AS "מדד",
  s.parcel AS "חלקה",
  COUNT(*) AS "רשומות",
  COUNT(*) FILTER (WHERE s.is_active = TRUE) AS "פעילות",
  ROUND(SUM(s.agreement_area)::numeric, 2) AS "סך_agreement",
  ROUND(SUM(s.unification_area)::numeric, 2) AS "סך_unification",
  ROUND(SUM(s.agreement_area) FILTER (WHERE s.is_active = TRUE)::numeric, 2) AS "agreement_פעיל"
FROM public.signed_owners s
WHERE s.owner_name ILIKE '%הוכברג%'
GROUP BY s.parcel
ORDER BY s.parcel;


-- ============================================================
-- שאילתה 3: קבוצת משפחת הוכברג — סקירה
-- ============================================================
SELECT
  '👨‍👩‍👧 קבוצת משפחת הוכברג' AS "מדד",
  fg.id AS "id_קבוצה",
  fg.family_name AS "שם_קבוצה",
  fg.is_active AS "פעיל",
  (SELECT COUNT(*) FROM public.signed_owners s
   WHERE s.family_group_id = fg.id) AS "סה_כ_חברים",
  (SELECT COUNT(*) FROM public.signed_owners s
   WHERE s.family_group_id = fg.id AND s.is_active = TRUE) AS "חברים_פעילים",
  (SELECT STRING_AGG(DISTINCT s.parcel::text, ', ' ORDER BY s.parcel::text)
   FROM public.signed_owners s
   WHERE s.family_group_id = fg.id AND s.is_active = TRUE) AS "חלקות_פעילות",
  (SELECT ROUND(SUM(s.agreement_area)::numeric, 2)
   FROM public.signed_owners s
   WHERE s.family_group_id = fg.id AND s.is_active = TRUE) AS "סך_agreement_פעיל"
FROM public.family_groups fg
WHERE fg.family_name ILIKE '%הוכברג%';


-- ============================================================
-- שאילתה 4: מה יש ב-DB על חלקה 26 (כל הבעלים)?
-- ============================================================
SELECT
  '🗺 כל הבעלים על חלקה 26' AS "מדד",
  s.owner_name AS "שם",
  s.id_number AS "ת_ז",
  ROUND(s.agreement_area::numeric, 2) AS "agreement",
  ROUND(s.unification_area::numeric, 2) AS "unification",
  s.is_active AS "פעיל",
  fg.family_name AS "קבוצה"
FROM public.signed_owners s
LEFT JOIN public.family_groups fg ON fg.id = s.family_group_id
WHERE s.parcel = 26
ORDER BY s.owner_name;


-- ============================================================
-- שאילתה 5: עסקאות שותפות על חלקה 26
-- ============================================================
SELECT
  '🤝 עסקאות שותפות בחלקה 26' AS "מדד",
  pd.deal_number AS "#",
  pd.deal_name AS "עסקה",
  ROUND(pd.area_sqm::numeric, 2) AS "שטח",
  pd.override_factor AS "override",
  pd.is_active AS "פעיל",
  fg.family_name AS "קבוצה"
FROM public.partnership_deals pd
LEFT JOIN public.family_groups fg ON fg.id = pd.family_group_id
WHERE pd.parcel = 26
ORDER BY pd.deal_number;


-- ============================================================
-- צפי תוצאות + מה לעשות הלאה:
--   • שאילתה 1+2: יראו אם יש רישומי הוכברג על חלקה 26 או לא
--   • שאילתה 3: יראה את משפחת הוכברג + מתי היא נוצרה (סקריפט 52)
--   • שאילתה 4+5: יראו את התמונה המלאה של חלקה 26
--
-- ➡️ אחרי שאתה רץ את זה, תשלח לי את הטבלאות ואני אגיד:
--    • איזה רישומי הוכברג חסרים על חלקה 26
--    • כמה מ"ר לכל בן
--    • האם צריך unification_area override (כמו חלקה 45)
-- ============================================================

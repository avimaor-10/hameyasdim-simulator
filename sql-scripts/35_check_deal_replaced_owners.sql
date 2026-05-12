-- ============================================================
-- 35_check_deal_replaced_owners.sql  (12/05/2026 — מתוקן)
-- ============================================================
-- מטרה: לבחון את מצב טבלת `deal_replaced_owners` ולוודא שכל
-- העסקאות מקושרות לבעלים שמכרו, כדי שהקיזוז יתבצע אוטומטית בדשבורד.
--
-- הסכמה:
--   deal_replaced_owners(id, deal_id, signed_owner_id, notes, created_at)
--   → אין עמודת replaced_area! החישוב פרופורציוני:
--     deduction_per_owner = deal.area_sqm × (owner.agreement_area / sum_of_all_replaced_owners)
-- ============================================================


-- ============================================================
-- שאילתה 1: כל הקיזוזים הקיימים — מי מקושר לאיזה עסקה
-- ============================================================
SELECT
  s.owner_name AS "שם_מוכר",
  s.id_number AS "ת_ז",
  s.parcel AS "חלקה",
  ROUND(s.agreement_area::numeric, 0) AS "שטח_רשום",
  pd.deal_number AS "#_עסקה",
  pd.deal_name AS "שם_עסקה",
  ROUND(pd.area_sqm::numeric, 0) AS "שטח_עסקה",
  pd.status AS "סטטוס_עסקה",
  dr.notes AS "הערות"
FROM public.deal_replaced_owners dr
LEFT JOIN public.signed_owners s ON s.id = dr.signed_owner_id
LEFT JOIN public.partnership_deals pd ON pd.id = dr.deal_id
ORDER BY pd.deal_number, s.owner_name;


-- ============================================================
-- שאילתה 2: מבט-על — איזה עסקאות עם/בלי קיזוזים
-- ============================================================
SELECT
  pd.deal_number AS "#",
  pd.deal_name AS "שם_עסקה",
  pd.parcel AS "חלקה",
  ROUND(pd.area_sqm::numeric, 0) AS "שטח_עסקה",
  pd.status AS "סטטוס",
  COUNT(dr.id) AS "מס_בעלים_מקושרים",
  CASE
    WHEN COUNT(dr.id) = 0 THEN '🔴 אין קיזוזים — אולי בעיה'
    ELSE '🟢 יש קיזוזים'
  END AS "מצב_קיזוז"
FROM public.partnership_deals pd
LEFT JOIN public.deal_replaced_owners dr ON dr.deal_id = pd.id
WHERE pd.is_active = TRUE
  AND pd.category IN ('CRM', 'מחוץ ל-CRM')
GROUP BY pd.deal_number, pd.deal_name, pd.parcel, pd.area_sqm, pd.status
ORDER BY pd.deal_number;


-- ============================================================
-- שאילתה 3: ספציפי — 4 יורשי בייטשר ארבל בחלקה 17
-- ============================================================
-- מי מקושר לעסקה #18 "עסקת גולדמן"?
SELECT
  s.id_number AS "ת_ז",
  s.owner_name AS "שם",
  ROUND(s.agreement_area::numeric, 0) AS "שטח_רשום",
  pd.deal_number AS "מקושר_לעסקה",
  pd.deal_name AS "שם_עסקה",
  ROUND(pd.area_sqm::numeric, 0) AS "שטח_עסקה"
FROM public.signed_owners s
LEFT JOIN public.deal_replaced_owners dr ON dr.signed_owner_id = s.id
LEFT JOIN public.partnership_deals pd ON pd.id = dr.deal_id
WHERE s.is_active = TRUE
  AND s.parcel = 17
  AND s.id_number IN (
    '000156178',  -- גולדמן תחייה
    '000156179',  -- צלליכין רוחמה
    '000156180',  -- בן גרא עפרה
    '000156181'   -- גולדמן משה
  )
ORDER BY s.owner_name;


-- ============================================================
-- שאילתה 4: חישוב הקיזוז המעשי לכל בעלים (פרופורציוני)
-- ============================================================
WITH owner_deal_links AS (
  SELECT
    s.id AS owner_id,
    s.id_number,
    s.owner_name,
    s.parcel,
    s.agreement_area,
    pd.id AS deal_id,
    pd.deal_number,
    pd.area_sqm AS deal_area,
    pd.deal_name
  FROM public.signed_owners s
  JOIN public.deal_replaced_owners dr ON dr.signed_owner_id = s.id
  JOIN public.partnership_deals pd ON pd.id = dr.deal_id AND pd.parcel = s.parcel
  WHERE s.is_active = TRUE
    AND pd.is_active = TRUE
),
deal_totals AS (
  SELECT
    deal_id,
    SUM(agreement_area) AS total_registered_for_deal
  FROM owner_deal_links
  GROUP BY deal_id
)
SELECT
  odl.owner_name AS "שם",
  odl.parcel AS "חלקה",
  ROUND(odl.agreement_area::numeric, 0) AS "שטח_רשום",
  odl.deal_number AS "#_עסקה",
  ROUND(odl.deal_area::numeric, 0) AS "שטח_עסקה_כולל",
  ROUND(dt.total_registered_for_deal::numeric, 0) AS "סך_רשום_מקושר",
  ROUND((odl.deal_area * odl.agreement_area / NULLIF(dt.total_registered_for_deal, 0))::numeric, 0) AS "קיזוז_יחסי",
  ROUND((odl.agreement_area - (odl.deal_area * odl.agreement_area / NULLIF(dt.total_registered_for_deal, 0)))::numeric, 0) AS "נטו_אחרי_קיזוז"
FROM owner_deal_links odl
JOIN deal_totals dt ON dt.deal_id = odl.deal_id
ORDER BY odl.parcel, odl.owner_name;


-- ============================================================
-- צפי תוצאות:
--   שאילתה 1: רשימת ה-deal_replaced_owners (אם יש)
--   שאילתה 2: רואים איזה עסקאות 🔴 בלי קיזוזים
--   שאילתה 3: מי מ-4 גולדמן מקושר לעסקה #18
--   שאילתה 4: החישוב המדויק של כמה כל בעלים מקוזז
-- ============================================================

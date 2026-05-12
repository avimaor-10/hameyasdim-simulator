-- ============================================================
-- 40_total_with_otzma_and_parcel14.sql  (12/05/2026)
-- ============================================================
-- מטרה: לאשר שהשטח הכולל לאיחוד **כולל** את:
--   1. עוצמה קונקשיין (141 רוכשים + יתרת חברה)
--   2. חלקה 14 — דודי יצחקי + 2,000 שעברו לנדל"ן נדל"ן
--
-- חשוב: יש כפילות אפשרית בחלקה 14:
--   #23 (דודי יצחקי) = 14,152 (כל החלקה)
--   #6 (דסטא) + #7 (וזוב) = 500 + 1,500 = 2,000
--   סה"כ = 16,152 — אבל חלקה היא רק 14,152!
--   צריך לוודא שהקיזוז עובד נכון.
-- ============================================================


-- ============================================================
-- שאילתה 1: עוצמה קונקשיין — מה ב-signed_owners?
-- ============================================================
SELECT
  '🟢 עוצמה קונקשיין' AS "סוג",
  COUNT(DISTINCT s.id_number) AS "בעלים",
  COUNT(*) AS "רשומות",
  ROUND(SUM(s.agreement_area)::numeric, 0) AS "שטח_רשום",
  ROUND(SUM(s.agreement_area * COALESCE(pm.participation_factor::numeric, 1))::numeric, 0) AS "שטח_לאיחוד"
FROM public.signed_owners s
LEFT JOIN public.parcels_meta pm ON pm.parcel = s.parcel
LEFT JOIN public.family_groups fg ON fg.id = s.family_group_id
WHERE s.is_active = TRUE
  AND (
    fg.family_name ILIKE '%עוצמה%'
    OR s.predecessor_id_number IN ('051181774', '007346166')  -- יניר, יוחננוף
    OR s.owner_name ILIKE '%עוצמה%'
  );


-- ============================================================
-- שאילתה 2: חלקה 14 — פירוט מלא
-- ============================================================
-- חתומים בחלקה 14 (כולל מי שמכר לשותפות)
SELECT
  '👤 חתומים' AS "סוג",
  s.owner_name AS "שם",
  ROUND(s.agreement_area::numeric, 0) AS "שטח_רשום",
  COALESCE((
    SELECT pd.deal_number::text || ' (' || pd.deal_name || ')'
    FROM public.deal_replaced_owners dr
    JOIN public.partnership_deals pd ON pd.id = dr.deal_id
    WHERE dr.signed_owner_id = s.id LIMIT 1
  ), '—') AS "מקושר_לעסקה"
FROM public.signed_owners s
WHERE s.parcel = 14 AND s.is_active = TRUE
UNION ALL
-- עסקאות בחלקה 14
SELECT
  '🏢 עסקה #' || pd.deal_number AS "סוג",
  pd.deal_name AS "שם",
  ROUND(pd.area_sqm::numeric, 0) AS "שטח_רשום",
  pd.status AS "מקושר_לעסקה"
FROM public.partnership_deals pd
WHERE pd.parcel = 14 AND pd.is_active = TRUE
ORDER BY 1, 3 DESC;


-- ============================================================
-- שאילתה 3: סיכום מצרפי סופי — כולל הכל
-- ============================================================
WITH signed_calc AS (
  SELECT
    s.id, s.parcel,
    s.agreement_area AS registered,
    pm.participation_factor::numeric AS pf,
    COALESCE((
      SELECT SUM(
        pd.area_sqm * s.agreement_area / NULLIF(
          (SELECT SUM(s2.agreement_area)
           FROM public.deal_replaced_owners dr2
           JOIN public.signed_owners s2 ON s2.id = dr2.signed_owner_id
           WHERE dr2.deal_id = pd.id AND s2.parcel = pd.parcel AND s2.is_active = TRUE),
          0)
      )
      FROM public.deal_replaced_owners dr
      JOIN public.partnership_deals pd ON pd.id = dr.deal_id AND pd.parcel = s.parcel
      WHERE dr.signed_owner_id = s.id AND pd.is_active = TRUE
    ), 0) AS deduction
  FROM public.signed_owners s
  LEFT JOIN public.parcels_meta pm ON pm.parcel = s.parcel
  WHERE s.is_active = TRUE
),
deals_calc AS (
  SELECT
    pd.id,
    pd.deal_number,
    pd.area_sqm AS deal_area,
    COALESCE(pd.override_factor::numeric, pm.participation_factor::numeric, 1) AS factor
  FROM public.partnership_deals pd
  LEFT JOIN public.parcels_meta pm ON pm.parcel = pd.parcel
  WHERE pd.is_active = TRUE
),
totals AS (
  SELECT
    SUM(registered) AS reg_gross,
    SUM(GREATEST(registered - deduction, 0)) AS reg_net,
    SUM(GREATEST(registered - deduction, 0) * COALESCE(pf, 1)) AS net_for_unif
  FROM signed_calc
),
deals_total AS (
  SELECT
    SUM(deal_area) AS deal_gross,
    SUM(deal_area * factor) AS deal_for_unif
  FROM deals_calc
)
SELECT
  ROUND(t.reg_gross::numeric, 0) AS "👤_חתומים_רשום_בטאבו",
  ROUND(t.reg_net::numeric, 0) AS "👤_חתומים_נטו_אחרי_קיזוז",
  ROUND(d.deal_gross::numeric, 0) AS "🏢_עסקאות_שותפות",
  ROUND((t.reg_net + d.deal_gross)::numeric, 0) AS "סך_רשום_כולל",
  ROUND((t.net_for_unif + d.deal_for_unif)::numeric, 0) AS "🎯_סך_לאיחוד_מר",
  ROUND((t.net_for_unif + d.deal_for_unif)::numeric / 1000, 1) AS "🎯_סך_לאיחוד_דונם",
  ROUND(((t.net_for_unif + d.deal_for_unif) / 439608.0 * 100)::numeric, 1) AS "אחוז_מ_439_דונם"
FROM totals t, deals_total d;

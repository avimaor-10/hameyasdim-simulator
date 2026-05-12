-- ============================================================
-- 39_total_managed_area.sql  (12/05/2026)
-- ============================================================
-- מטרה: לתת ודאות מלאה על השטח הכולל לאיחוד שקשור אלינו
-- מתוקף הסכם הניהול 2015 + כל העברות העסקאות.
--
-- המבנה הלוגי:
--
--   חתומי 2015 + יורשיהם (signed_owners)
--   - מינוס: מה שהם מכרו לשותפות (deal_replaced_owners)
--   = חתומים נטו (מה שעדיין בבעלותם המקורית)
--
--   + שותפויות (partnership_deals — הקונים)
--   = שטח כולל שתחת ניהולנו
--
-- כל זה × participation_factor של החלקה = השטח שנכנס לאיחוד וחלוקה
-- ============================================================


-- ============================================================
-- שאילתה 1: סיכום מצרפי — השטח הכולל לאיחוד
-- ============================================================
WITH signed_calc AS (
  SELECT
    s.id,
    s.parcel,
    s.agreement_area AS registered,
    pm.participation_factor::numeric AS pf,
    -- חישוב קיזוז מכל העסקאות שהבעלים הזה מקושר אליהן
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
signed_totals AS (
  SELECT
    SUM(registered) AS total_registered,
    SUM(GREATEST(registered - deduction, 0)) AS total_net,
    SUM(GREATEST(registered - deduction, 0) * COALESCE(pf, 1)) AS total_net_for_unification
  FROM signed_calc
),
partnership_totals AS (
  SELECT
    SUM(pd.area_sqm) AS total_deals_area,
    SUM(pd.area_sqm * COALESCE(
      pd.override_factor::numeric,
      pm.participation_factor::numeric,
      1
    )) AS total_deals_for_unification
  FROM public.partnership_deals pd
  LEFT JOIN public.parcels_meta pm ON pm.parcel = pd.parcel
  WHERE pd.is_active = TRUE
)
SELECT
  '🎯 שטח כולל שתחת ניהולנו' AS "מדד",
  '———————————————' AS "סוג",
  '——' AS "מ_ר",
  '——' AS "דונם",
  '——' AS "אחוז_מ_439_דונם"
UNION ALL
SELECT
  '👤 חתומים פעילים (טאבו רשום)',
  'גלמי',
  ROUND(s.total_registered::numeric, 0)::text || ' מ"ר',
  ROUND(s.total_registered::numeric / 1000, 1)::text || ' דונם',
  ROUND((s.total_registered / 439608.0 * 100)::numeric, 1)::text || '%'
FROM signed_totals s
UNION ALL
SELECT
  '👤 חתומים נטו (אחרי מכירה לשותפות)',
  'אחרי קיזוז',
  ROUND(s.total_net::numeric, 0)::text || ' מ"ר',
  ROUND(s.total_net::numeric / 1000, 1)::text || ' דונם',
  ROUND((s.total_net / 439608.0 * 100)::numeric, 1)::text || '%'
FROM signed_totals s
UNION ALL
SELECT
  '🏢 עסקאות שותפות (22+2 = 24)',
  'נדל"ן נדל"ן + דודי יצחקי',
  ROUND(p.total_deals_area::numeric, 0)::text || ' מ"ר',
  ROUND(p.total_deals_area::numeric / 1000, 1)::text || ' דונם',
  ROUND((p.total_deals_area / 439608.0 * 100)::numeric, 1)::text || '%'
FROM partnership_totals p
UNION ALL
SELECT
  '⭐ סה"כ נטו רשום (חתומים + שותפות)',
  'הכולל בטאבו',
  ROUND((s.total_net + p.total_deals_area)::numeric, 0)::text || ' מ"ר',
  ROUND((s.total_net + p.total_deals_area)::numeric / 1000, 1)::text || ' דונם',
  ROUND(((s.total_net + p.total_deals_area) / 439608.0 * 100)::numeric, 1)::text || '%'
FROM signed_totals s, partnership_totals p
UNION ALL
SELECT
  '🎯 ⭐ שטח לאיחוד וחלוקה (עם מקדם)',
  'הכי חשוב לעסק',
  ROUND((s.total_net_for_unification + p.total_deals_for_unification)::numeric, 0)::text || ' מ"ר',
  ROUND((s.total_net_for_unification + p.total_deals_for_unification)::numeric / 1000, 1)::text || ' דונם',
  ROUND(((s.total_net_for_unification + p.total_deals_for_unification) / 439608.0 * 100)::numeric, 1)::text || '%'
FROM signed_totals s, partnership_totals p;


-- ============================================================
-- שאילתה 2: פירוט לפי קבוצה — מי בנעל הסכם הניהול?
-- ============================================================
WITH owner_net AS (
  SELECT
    s.family_group_id,
    s.id_number,
    GREATEST(s.agreement_area - COALESCE((
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
    ), 0), 0) * COALESCE(pm.participation_factor::numeric, 1) AS net_for_unification
  FROM public.signed_owners s
  LEFT JOIN public.parcels_meta pm ON pm.parcel = s.parcel
  WHERE s.is_active = TRUE
),
deals_net AS (
  SELECT
    pd.family_group_id,
    SUM(pd.area_sqm * COALESCE(pd.override_factor::numeric, pm.participation_factor::numeric, 1)) AS deal_area
  FROM public.partnership_deals pd
  LEFT JOIN public.parcels_meta pm ON pm.parcel = pd.parcel
  WHERE pd.is_active = TRUE
  GROUP BY pd.family_group_id
)
SELECT
  COALESCE(fg.family_name, '— ללא קבוצה —') AS "קבוצה",
  COUNT(DISTINCT owner_net.id_number) AS "חתומים",
  ROUND(COALESCE(SUM(owner_net.net_for_unification), 0)::numeric, 0) AS "שטח_חתומים_לאיחוד",
  ROUND(COALESCE(MAX(deals_net.deal_area), 0)::numeric, 0) AS "שטח_עסקאות_לאיחוד",
  ROUND((COALESCE(SUM(owner_net.net_for_unification), 0) + COALESCE(MAX(deals_net.deal_area), 0))::numeric, 0) AS "סה_כ_לאיחוד"
FROM public.family_groups fg
LEFT JOIN owner_net ON owner_net.family_group_id = fg.id
LEFT JOIN deals_net ON deals_net.family_group_id = fg.id
GROUP BY fg.family_name
HAVING (COALESCE(SUM(owner_net.net_for_unification), 0) + COALESCE(MAX(deals_net.deal_area), 0)) > 0
ORDER BY "סה_כ_לאיחוד" DESC NULLS LAST;

-- ============================================================
-- 65_get_3_nadlan_groups_ids.sql  (14/05/2026)
-- ============================================================
-- 🎯 מטרה: לקבל את ה-id המדויק והשם המדויק של 3 קבוצות נדל"ן-נדל"ן
--          לטובת תיקון admin.html (אופציה א')
--
-- 🔒 SELECT בלבד.
-- ============================================================

SELECT
  fg.id,
  fg.family_name,
  fg.color,
  COUNT(pd.id) AS deals_count,
  ROUND(COALESCE(SUM(pd.area_sqm)::numeric, 0), 2) AS total_area_sqm,
  ROUND(COALESCE(SUM(pd.area_sqm)::numeric / 1000, 0), 2) AS total_dunam
FROM public.family_groups fg
LEFT JOIN public.partnership_deals pd
  ON pd.family_group_id = fg.id
  AND pd.is_active = TRUE
WHERE fg.family_name ILIKE '%נדלן%'
   OR fg.family_name ILIKE '%נדל"ן%'
   OR fg.family_name ILIKE '%חנן מור%'
   OR fg.family_name ILIKE '%חברות פרטיות%'
GROUP BY fg.id, fg.family_name, fg.color
ORDER BY total_area_sqm DESC NULLS LAST;

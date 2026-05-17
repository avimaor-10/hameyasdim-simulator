-- ============================================================
-- 106_diag_venturah_before_fix.sql  (17/05/2026)
-- ============================================================
-- אבחון אחרון לפני סקריפט איחוד 107.
-- מוצא: את 2 הרשומות של רחל + רשומה אפשרית של אליעזר ז"ל
-- ============================================================

SELECT
  s.id_number,
  s.owner_name,
  s.parcel,
  ROUND(s.agreement_area::numeric, 2)   AS agreement_area,
  ROUND(s.unification_area::numeric, 2) AS unification_area,
  s.is_active,
  s.is_signed,
  s.master_2015_status,
  s.family_group_id,
  s.inherited_from_id_number,
  COALESCE(LEFT(s.master_2015_notes, 80), '') AS notes
FROM public.signed_owners s
WHERE s.id_number IN ('005155132', '051551323', '007724915', '7724915')
   OR s.owner_name ILIKE '%ונטורה%'
   OR s.owner_name ILIKE '%ונטורה אליעזר%'
ORDER BY s.parcel, s.is_active DESC, s.id_number;

-- ============================================================
-- 105_diag_moalem_parcel21.sql  (16/05/2026)
-- ============================================================
-- אבחון מלא של חלקה 21 — לראות איך אליהו ופרידה רשומים ב-DB
-- ============================================================

-- 1) כל הרשומות במשפחת מועלם-מור בחלקה 21
SELECT
  s.id_number,
  s.owner_name,
  s.parcel,
  ROUND(s.agreement_area::numeric, 2)   AS agreement_area,
  ROUND(s.unification_area::numeric, 2) AS unification_area,
  s.is_active,
  s.is_signed,
  s.transition_type,
  COALESCE(LEFT(s.master_2015_notes, 80), '') AS notes
FROM public.signed_owners s
WHERE s.parcel = 21
  AND (s.id_number IN ('000755793', '4/755793', '6974462', '069744621')
       OR s.owner_name ILIKE '%מועלם%')
ORDER BY s.is_active DESC, s.id_number;

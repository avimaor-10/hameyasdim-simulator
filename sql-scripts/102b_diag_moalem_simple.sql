-- ============================================================
-- 102b_diag_moalem_simple.sql  (16/05/2026)
-- ============================================================
-- שאילתה אחת פשוטה - כל הרשומות של מועלם אליהו
-- (כדי להבין מה יש ב-DB לפני שמתקנים)
-- ============================================================

SELECT
  s.id_number,
  s.owner_name,
  s.parcel,
  ROUND(s.agreement_area::numeric, 2) AS area_sqm,
  s.is_active,
  s.is_signed,
  LEFT(COALESCE(s.master_2015_notes, ''), 100) AS notes_preview
FROM public.signed_owners s
WHERE s.id_number LIKE '%755793%'
   OR s.owner_name ILIKE '%מועלם%אליהו%'
ORDER BY s.parcel, s.is_active DESC, s.id_number;

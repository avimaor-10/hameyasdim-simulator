-- ============================================================
-- 102c - check family_group_id linkage for moalem eliyahu records
-- ============================================================

SELECT
  s.id_number,
  s.owner_name,
  s.parcel,
  s.is_active,
  s.family_group_id,
  fg.family_name
FROM public.signed_owners s
LEFT JOIN public.family_groups fg ON fg.id = s.family_group_id
WHERE s.id_number IN ('000755793', '4/755793')
ORDER BY s.parcel, s.is_active DESC;

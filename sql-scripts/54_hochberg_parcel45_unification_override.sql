-- ============================================================
-- 54_hochberg_parcel45_unification_override.sql  (13/05/2026)
-- ============================================================
-- 🎯 מטרה: הצבת `unification_area` ל-4 בני הוכברד בחלקה 45,
--          כך שהסכום הכולל = 1,815 מ"ר (במקום 4,406 × 55.4% = 2,441 שגוי).
--
-- 🧮 הלוגיקה (מהנסח + הסכמת אבי 14:24):
--    חלקה 45 — סך לאיחוד וחלוקה (השמאי): 10,103 מ"ר
--    מינוס: עסקה #21 (קרן מרתון, override=1):  8,288 מ"ר
--    ──────────────────────────────────────
--    יתרה לאיחוד מהוכברד:                    1,815 מ"ר ✅
--
--    יתרת הוכברד הכוללת:                     4,406 מ"ר
--    מתוכה נכנס לאיחוד:                      1,815 מ"ר (~41.19%)
--    מתוכה לא נכנס לאיחוד:                   2,591 מ"ר (כולל קדישא לא של הוכברד)
--
-- 🤝 הסכמת אבי 14:24:
--    "לא לגעת בחלוקה הפנימית — הם מנסים להסדיר את יחסי השטחים בינהם
--     וזה לא כמו רשום בנסח."
--    → לכן: unification_area של כל בן מחושב יחסית ל-agreement_area הנוכחי שלו.
--
-- 🔒 בטוח להריץ פעמיים — UPDATE עם תנאי + idempotent.
-- ============================================================


-- ============================================================
-- שלב 1 — מצב לפני: מה רשום ב-DB להוכברד בחלקה 45
-- ============================================================
SELECT
  '🔍 לפני התיקון — הוכברד בחלקה 45' AS "כותרת",
  s.owner_name AS "שם",
  s.id_number AS "ת_ז",
  ROUND(s.agreement_area::numeric, 2) AS "agreement_area",
  ROUND(s.unification_area::numeric, 2) AS "unification_area",
  s.legal_status AS "סטטוס_משפטי"
FROM public.signed_owners s
WHERE s.parcel = 45
  AND s.owner_name ILIKE 'הוכברג%'
  AND s.is_active = TRUE
ORDER BY s.owner_name;


-- ============================================================
-- שלב 2 — סך agreement_area הנוכחי של הוכברד בחלקה 45
-- ============================================================
SELECT
  '📊 סך agreement_area הוכברד בחלקה 45 (לבדיקה)' AS "כותרת",
  COUNT(*) AS "רשומות",
  ROUND(SUM(s.agreement_area)::numeric, 2) AS "סך_agreement_area",
  '~4,406 צפוי' AS "צפי"
FROM public.signed_owners s
WHERE s.parcel = 45
  AND s.owner_name ILIKE 'הוכברג%'
  AND s.is_active = TRUE;


-- ============================================================
-- שלב 3 — הצבת unification_area = agreement_area × (1815 / סך)
-- ============================================================
-- זה יבטיח שסכום unification_area של 4 בני הוכברד = בדיוק 1,815
-- בלי לגעת ב-agreement_area של כל אחד מהם.
UPDATE public.signed_owners
SET
  unification_area = ROUND(
    (agreement_area * 1815.0 / NULLIF(
      (SELECT SUM(agreement_area)
       FROM public.signed_owners
       WHERE parcel = 45
         AND owner_name ILIKE 'הוכברג%'
         AND is_active = TRUE),
      0
    ))::numeric,
    2
  ),
  legal_notes = COALESCE(legal_notes || ' | ', '') ||
                'תיקון 54 (13/05/2026): unification_area הוצב ידנית. ' ||
                'אלגוריתם ייחודי: השטח לאיחוד = 10,103 (השמאי) - 8,288 (עסקה #21 קרן מרתון) ' ||
                '= 1,815 מ"ר. החלוקה הפנימית בין 4 בני הוכברד יחסית ל-agreement_area ' ||
                '(לפי בקשת אבי — לא לגעת בחלוקה הפנימית כי הם מסדירים אותה).'
WHERE parcel = 45
  AND owner_name ILIKE 'הוכברג%'
  AND is_active = TRUE;


-- ============================================================
-- שלב 4 — אימות: מצב אחרי
-- ============================================================
SELECT
  '✅ אחרי התיקון — הוכברד בחלקה 45' AS "כותרת",
  s.owner_name AS "שם",
  s.id_number AS "ת_ז",
  ROUND(s.agreement_area::numeric, 2) AS "agreement_area",
  ROUND(s.unification_area::numeric, 2) AS "unification_area",
  ROUND((s.agreement_area - s.unification_area)::numeric, 2) AS "מחוץ_לאיחוד",
  ROUND((s.unification_area / NULLIF(s.agreement_area, 0) * 100)::numeric, 1) || '%' AS "אחוז_לאיחוד"
FROM public.signed_owners s
WHERE s.parcel = 45
  AND s.owner_name ILIKE 'הוכברג%'
  AND s.is_active = TRUE
ORDER BY s.owner_name;


-- ============================================================
-- שלב 5 — סיכום: סכום unification_area = 1,815?
-- ============================================================
SELECT
  '🎯 סיכום אחרי תיקון' AS "כותרת",
  COUNT(*) AS "רשומות",
  ROUND(SUM(s.agreement_area)::numeric, 0) AS "סך_agreement",
  ROUND(SUM(s.unification_area)::numeric, 0) AS "סך_unification",
  ROUND((SUM(s.agreement_area) - SUM(s.unification_area))::numeric, 0) AS "מחוץ_לאיחוד",
  CASE
    WHEN ROUND(SUM(s.unification_area)::numeric) = 1815 THEN '✅ מושלם'
    WHEN ABS(SUM(s.unification_area) - 1815) < 5 THEN '🟢 קרוב מאוד'
    ELSE '🟠 לבדוק'
  END AS "סטטוס"
FROM public.signed_owners s
WHERE s.parcel = 45
  AND s.owner_name ILIKE 'הוכברג%'
  AND s.is_active = TRUE;

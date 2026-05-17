-- ============================================================
-- 107_unify_venturah_rachel.sql  (17/05/2026)
-- ============================================================
-- מטרה: איחוד 4 רשומות ל-1 — ונטורה רחל בחלקה 19.
--
-- רקע (אישור משתמש 17/05/2026 + נסח עדכני + נסח היסטורי):
--   • אליעזר ורחל ונטורה רכשו ביחד ב-1993 (שטר 27263/1993/21).
--     250 מ"ר כל אחד.
--   • אליעזר חתם על הסכם הניהול המקורי (2015).
--   • אליעזר ז"ל (ת"ז 007724915) נפטר. רחל ירשה את חלקו דרך
--     צוואה ב-06/02/2022 (שטר 7994/2022/1).
--   • היום רחל מחזיקה לבדה 501.828 מ"ר בחלקה 19 (לפי DB).
--
-- מצב ב-DB לפני: 4 רשומות פעילות (כפול כפילות!):
--   2× 005155132 × 250 + 2× 051551323 × 250.91 = 1,001.82 מ"ר.
--
-- מצב נדרש אחרי: רשומה אחת פעילה של 051551323 עם 501.828 מ"ר.
-- שאר 3 הרשומות יסומנו is_active=FALSE עם הערה מתעדת.
-- אליעזר ז"ל לא נוסף כרשומה — מוזכר בהערות בלבד לתיעוד היסטוריה.
--
-- 🔒 BEGIN ... COMMIT — בטוח להריצה.
-- ============================================================


BEGIN;


-- ============================================================
-- BEFORE: צילום מצב לפני
-- ============================================================
SELECT
  'BEFORE 107' AS step,
  s.id_number,
  s.owner_name,
  s.parcel,
  ROUND(s.agreement_area::numeric, 3)   AS agreement_area,
  ROUND(s.unification_area::numeric, 3) AS unification_area,
  s.is_active,
  s.master_2015_status
FROM public.signed_owners s
WHERE s.id_number IN ('005155132', '051551323')
  AND s.parcel = 19
ORDER BY s.id_number;


-- ============================================================
-- STEP A: סימון כל 4 הרשומות הקיימות כ-FALSE זמנית
--          (זה מנקה את המצב הקיים — נחזיר אחת ל-TRUE בצעד הבא)
-- ============================================================
UPDATE public.signed_owners
SET is_active = FALSE
WHERE id_number IN ('005155132', '051551323')
  AND parcel = 19
  AND is_active = TRUE;


-- ============================================================
-- STEP B: בחירת רשומה אחת של 051551323 (הראשונה לפי id) והחזרתה
--          ל-TRUE עם שטח 501.828 + הערה מקיפה
-- ============================================================
WITH first_rachel AS (
  SELECT id
  FROM public.signed_owners
  WHERE id_number = '051551323'
    AND parcel = 19
  ORDER BY id
  LIMIT 1
)
UPDATE public.signed_owners
SET
  is_active                = TRUE,
  agreement_area           = 501.828,
  unification_area         = 501.828,
  inherited_from_id_number = '007724915',
  master_2015_status       = 'verified',
  master_2015_notes        =
    'ונטורה רחל ובעלה ונטורה אליעזר ז"ל (ת"ז 007724915) רכשו ביחד ' ||
    'ב-02/12/1993 (שטר 27263/1993/21), 250 מ"ר כל אחד = סה"כ 500 מ"ר. ' ||
    'אליעזר חתם על הסכם הניהול המקורי (2015). אליעזר נפטר ורחל ירשה ' ||
    'את חלקו דרך צוואה ב-06/02/2022 (שטר 7994/2022/1). ' ||
    'היום רחל מחזיקה לבדה 501.828 מ"ר בחלקה 19. ' ||
    'אליעזר לא רשום ב-DB כיוון שהירושה כבר נרשמה והוא הופיע רק בנסח ' ||
    'ההיסטורי. תיעוד היסטורי 17/05/2026 (סקריפט 107).'
WHERE id = (SELECT id FROM first_rachel);


-- ============================================================
-- STEP C: הוספת הערה ל-3 הרשומות העודפות (שנשארו FALSE)
-- ============================================================
UPDATE public.signed_owners
SET master_2015_notes = COALESCE(master_2015_notes, '') ||
  CASE WHEN COALESCE(master_2015_notes, '') = '' THEN '' ELSE ' | ' END ||
  'הוסר 17/05/2026 (סקריפט 107): כפילות שגויה של ונטורה רחל בחלקה 19. ' ||
  'הרשומה הפעילה היחידה היא 051551323 עם שטח כולל 501.828 מ"ר ' ||
  '(כולל ירושה מאליעזר ז"ל).'
WHERE id_number IN ('005155132', '051551323')
  AND parcel = 19
  AND is_active = FALSE;


-- ============================================================
-- AFTER: וידוא התיקון
-- ============================================================
SELECT
  'AFTER 107' AS step,
  s.id_number,
  s.owner_name,
  s.parcel,
  ROUND(s.agreement_area::numeric, 3)   AS agreement_area,
  ROUND(s.unification_area::numeric, 3) AS unification_area,
  s.is_active,
  s.is_signed,
  s.master_2015_status,
  s.inherited_from_id_number,
  COALESCE(LEFT(s.master_2015_notes, 100), '') AS notes
FROM public.signed_owners s
WHERE s.id_number IN ('005155132', '051551323')
  AND s.parcel = 19
ORDER BY s.is_active DESC, s.id_number;


-- ============================================================
-- SUMMARY: כמה רשומות פעילות נשארו לרחל
-- ============================================================
SELECT
  'FINAL COUNT' AS step,
  COUNT(*) FILTER (WHERE is_active = TRUE)  AS active_records,
  COUNT(*) FILTER (WHERE is_active = FALSE) AS inactive_records,
  ROUND(SUM(agreement_area) FILTER (WHERE is_active = TRUE)::numeric, 3)
    AS total_active_area
FROM public.signed_owners
WHERE id_number IN ('005155132', '051551323')
  AND parcel = 19;


COMMIT;


-- ============================================================
-- צפי תוצאות:
--   BEFORE: 4 פעילות (2× 005155132 × 250 + 2× 051551323 × 250.91)
--   AFTER:  1 פעילה (051551323 × 501.828) + 3 לא-פעילות
--   FINAL COUNT: active=1, inactive=3, total_active_area=501.828
-- ============================================================

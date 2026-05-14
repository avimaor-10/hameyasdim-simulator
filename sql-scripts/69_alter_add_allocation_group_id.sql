-- ============================================================
-- 69_alter_add_allocation_group_id.sql  (14/05/2026)
-- ============================================================
-- 🎯 מטרה: להוסיף שדה allocation_group_id ל-signed_owners ו-partnership_deals
--          + שדה fee_arrangement_notes ל-family_groups.
--
-- 📐 רקע (אופציה 🅰 שאושרה ע"י המשתמש):
--   הפרדה בין 2 שכבות:
--     • family_group_id      = קבוצה משפטית/חוזית (דמי ייזום)
--     • allocation_group_id  = קבוצה אופרטיבית (לשיבוץ — גמישה, אדמין שולט)
--
--   ברירת מחדל: allocation_group_id = family_group_id (עותק התחלתי לתאימות).
--   אדמין יכול לשנות בעתיד ידנית.
--
-- 🛡 מבנה: BEGIN; -- שינויים --; -- COMMIT;  (ידני ע"י המשתמש)
-- 🛡 הגנה: הסקריפט בודק AT END שכל הרשומות הקיימות קיבלו ערך.
-- ============================================================


BEGIN;


-- ============================================================
-- שאילתה 1: הוספת שדה allocation_group_id לטבלת signed_owners
-- ============================================================
ALTER TABLE public.signed_owners
  ADD COLUMN IF NOT EXISTS allocation_group_id UUID
  REFERENCES public.family_groups(id) ON DELETE SET NULL;

COMMENT ON COLUMN public.signed_owners.allocation_group_id IS
  'קבוצת הקצאה לשיבוץ — יכולה להיות שונה מ-family_group_id (שהיא קבוצה משפטית/חוזית). NULL = פרטי לשיבוץ.';


-- ============================================================
-- שאילתה 2: הוספת שדה allocation_group_id לטבלת partnership_deals
-- ============================================================
ALTER TABLE public.partnership_deals
  ADD COLUMN IF NOT EXISTS allocation_group_id UUID
  REFERENCES public.family_groups(id) ON DELETE SET NULL;

COMMENT ON COLUMN public.partnership_deals.allocation_group_id IS
  'קבוצת הקצאה לשיבוץ — יכולה להיות שונה מ-family_group_id (שהיא קבוצה משפטית/חוזית). NULL = פרטי לשיבוץ.';


-- ============================================================
-- שאילתה 3: הוספת שדה fee_arrangement_notes לטבלת family_groups
-- ============================================================
ALTER TABLE public.family_groups
  ADD COLUMN IF NOT EXISTS fee_arrangement_notes TEXT;

COMMENT ON COLUMN public.family_groups.fee_arrangement_notes IS
  'הערה טקסטואלית על סידור דמי הייזום הספציפי של הקבוצה (אם שונה מברירת המחדל).';


-- ============================================================
-- שאילתה 4: אתחול allocation_group_id = family_group_id לכל הרשומות
-- (תאימות לאחור — שום שינוי לוגי, רק עותק)
-- ============================================================
UPDATE public.signed_owners
SET allocation_group_id = family_group_id
WHERE allocation_group_id IS NULL
  AND family_group_id IS NOT NULL;

UPDATE public.partnership_deals
SET allocation_group_id = family_group_id
WHERE allocation_group_id IS NULL
  AND family_group_id IS NOT NULL;


-- ============================================================
-- שאילתה 5: סימון קבוצת יצחקי עם הערה על דמי הייזום הספציפי
-- ============================================================
UPDATE public.family_groups
SET fee_arrangement_notes = 'הסכם דמי ייזום ספציפי לחלקות 14 ו-19. כולל: וזוב, ולנסיה (פטור), משפחת באבי, מחלבות ודסטא, רוכשי זייגרמן. חריגים: 2 דונם מחלקה 14 שנמכרו לשותפות (הסכם המקורי), וחלק חנן מור השקעות מזייגרמן.'
WHERE id = 'a990ed96-5b11-4d1a-9db1-89c76833af8b';


-- ============================================================
-- שאילתה 6: ודא שהשינויים תקינים — מציג את המבנה החדש
-- ============================================================
SELECT
  '📋 signed_owners' AS "טבלה",
  COUNT(*) AS "סה״כ רשומות פעילות",
  COUNT(allocation_group_id) AS "עם allocation_group_id",
  COUNT(*) - COUNT(allocation_group_id) AS "ללא (NULL)",
  COUNT(family_group_id) AS "עם family_group_id"
FROM public.signed_owners
WHERE is_active = TRUE

UNION ALL

SELECT
  '📋 partnership_deals' AS "טבלה",
  COUNT(*) AS "סה״כ רשומות פעילות",
  COUNT(allocation_group_id) AS "עם allocation_group_id",
  COUNT(*) - COUNT(allocation_group_id) AS "ללא (NULL)",
  COUNT(family_group_id) AS "עם family_group_id"
FROM public.partnership_deals
WHERE is_active = TRUE;


-- ============================================================
-- שאילתה 7: ודא ש-fee_arrangement_notes נרשם
-- ============================================================
SELECT
  '✅ fee_arrangement_notes' AS "מדד",
  fg.family_name AS "קבוצה",
  fg.fee_arrangement_notes AS "הערת דמי ייזום"
FROM public.family_groups fg
WHERE fg.fee_arrangement_notes IS NOT NULL
ORDER BY fg.family_name;


-- ============================================================
-- 🛑 עצור! בדוק את התוצאות של שאילתות 6 ו-7:
-- ============================================================
-- שאילתה 6 צפויה:
--   signed_owners       — כל הרשומות עם allocation_group_id == family_group_id
--                         (ערך "ללא" שווה לרשומות ש-family_group_id שלהן NULL)
--   partnership_deals   — אותו דבר
--
-- שאילתה 7 צפויה:
--   1 שורה לפחות — קבוצת יצחקי עם ההערה שכתבנו
--
-- ⏯ אם הכל תקין — תוסיף שורה חדשה ותריץ:  COMMIT;
-- ⏯ אם משהו לא תקין    — תוסיף שורה חדשה ותריץ:  ROLLBACK;
--
-- ⚠ עד שתריץ COMMIT/ROLLBACK — השינוי לא נשמר.
-- ============================================================

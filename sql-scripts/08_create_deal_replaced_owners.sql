-- ============================================================
-- שלב ח׳ · קישור עסקאות שותפות לבעלים החתומים שהן מחליפות
-- ============================================================
-- מקור: דוח_הסכמי_ניהול_ואיחוד_וחלוקה_גוש_3852_v13.xlsx
--   לשונית "עסקאות שותפויות חנן מור" — עמודה D "בעל החלקה הרשום"
--
-- מטרת הקובץ:
--   חלק מהעסקאות (סטטוס "ולא נרשמה" או "בתהליך") עדיין רשומות בטאבו
--   על שם הבעלים המקורי. כשמסכמים את שטחי הבעלים והעסקאות ביחד,
--   נוצרת כפילות. הטבלה הזו מקשרת כל עסקה לבעלים שהיא מחליפה,
--   כדי שנוכל לחסר את שטח העסקה משטח הבעלים בחישובים.
--
-- מבנה רבים-לרבים: עסקה אחת יכולה להחליף מספר בעלים (לדוגמה ירושה
-- משותפת), ובעלים אחד יכול להופיע מאחורי מספר עסקאות.
-- ============================================================

-- 1. יצירת הטבלה
CREATE TABLE IF NOT EXISTS public.deal_replaced_owners (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  deal_id           UUID NOT NULL REFERENCES public.partnership_deals(id) ON DELETE CASCADE,
  signed_owner_id   UUID NOT NULL REFERENCES public.signed_owners(id) ON DELETE CASCADE,
  notes             TEXT,
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (deal_id, signed_owner_id)
);

CREATE INDEX IF NOT EXISTS idx_dro_deal  ON public.deal_replaced_owners(deal_id);
CREATE INDEX IF NOT EXISTS idx_dro_owner ON public.deal_replaced_owners(signed_owner_id);

-- 2. ניקוי לפני ייבוא חוזר
DELETE FROM public.deal_replaced_owners;

-- 3. מיפוי deal_number → רשימת שמות בעלים מקוריים (כפי שהוזנו באקסל)
--    כל זוג (deal_number, owner_name_pattern) ינסה להתאים לרשומה ב-signed_owners
WITH deal_owner_map AS (
  SELECT * FROM (VALUES
    -- (deal_number, owner_name_pattern, search_mode)
    -- search_mode: 'exact' = תואם בדיוק, 'fuzzy' = חיפוש חלקי לפי 2 מילים בלפחות
    (1,  'נורית בן חורין',                 'fuzzy'),
    (2,  'נורית בן חורין',                 'fuzzy'),
    (3,  'דרומי אסתר',                     'fuzzy'),
    (3,  'בן דוד מרב',                     'fuzzy'),
    (4,  'דרומי אסתר',                     'fuzzy'),
    (4,  'בן דוד מרב',                     'fuzzy'),
    (5,  'משה ילובסקי',                    'fuzzy'),
    (6,  'דסטא',                           'fuzzy'),  -- חברה
    (6,  'מחלבת המושבה',                   'fuzzy'),  -- חברה
    (7,  'וזוב',                           'fuzzy'),  -- חברה
    (8,  'עפרה בן גרא',                    'fuzzy'),
    (9,  'נתנאל מור',                      'fuzzy'),
    (9,  'פנחס מור',                       'fuzzy'),
    (9,  'מנדל רויטל',                     'fuzzy'),
    (9,  'חנן מור',                        'fuzzy'),
    (10, 'נתנאל מור',                      'fuzzy'),
    (10, 'פנחס מור',                       'fuzzy'),
    (10, 'מנדל רויטל',                     'fuzzy'),
    (10, 'חנן מור',                        'fuzzy'),
    (11, 'נתנאל מור',                      'fuzzy'),
    (11, 'פנחס מור',                       'fuzzy'),
    (11, 'מנדל רויטל',                     'fuzzy'),
    (11, 'חנן מור',                        'fuzzy'),
    (12, 'נתנאל מור',                      'fuzzy'),
    (12, 'פנחס מור',                       'fuzzy'),
    (12, 'מנדל רויטל',                     'fuzzy'),
    (12, 'חנן מור',                        'fuzzy'),
    (13, 'נתנאל מור',                      'fuzzy'),
    (13, 'פנחס מור',                       'fuzzy'),
    (13, 'מנדל רויטל',                     'fuzzy'),
    (13, 'חנן מור',                        'fuzzy'),
    (14, 'נתנאל מור',                      'fuzzy'),
    (14, 'פנחס מור',                       'fuzzy'),
    (14, 'מנדל רויטל',                     'fuzzy'),
    (14, 'חנן מור',                        'fuzzy'),
    (15, 'נתנאל מור',                      'fuzzy'),
    (15, 'פנחס מור',                       'fuzzy'),
    (15, 'מנדל רויטל',                     'fuzzy'),
    (15, 'חנן מור',                        'fuzzy'),
    (16, 'מורי איל',                       'fuzzy'),
    (16, 'מוספי אפרת',                     'fuzzy'),
    (17, 'צלליכין רות',                    'fuzzy'),
    (17, 'צלליכין סבו',                    'fuzzy'),
    (17, 'סמדר',                           'fuzzy'),
    (17, 'שושני אורלי',                    'fuzzy'),
    (18, 'משה גולדמן',                     'fuzzy'),
    (19, 'גיל זלץ',                        'fuzzy'),
    (20, 'גיל זלץ',                        'fuzzy'),
    (21, 'מרתון',                          'fuzzy'),  -- חברה
    (22, 'אמנון פלדמן',                    'fuzzy')
  ) AS t(deal_number, owner_pattern, search_mode)
),

-- 4. התאמת כל זוג ל-signed_owners (לפי שם המכיל את התבנית + חלקה זהה)
matches AS (
  SELECT
    pd.id   AS deal_id,
    so.id   AS signed_owner_id,
    pd.deal_number,
    pd.deal_name,
    pd.parcel,
    so.owner_name,
    so.id_number,
    so.agreement_area,
    dom.owner_pattern
  FROM deal_owner_map dom
  JOIN public.partnership_deals pd
    ON pd.deal_number = dom.deal_number
    AND pd.is_active = TRUE
  LEFT JOIN public.signed_owners so
    ON so.parcel = pd.parcel
    AND so.is_active = TRUE
    -- התאמה גמישה: שתי המילים העיקריות של התבנית צריכות להיות בשם הבעלים
    AND (
      so.owner_name ILIKE '%' || dom.owner_pattern || '%'
      OR (
        -- מקרה של שם הפוך (לדוגמה "פלדמן אמנון" מול "אמנון פלדמן")
        so.owner_name ILIKE '%' || split_part(dom.owner_pattern, ' ', 1) || '%'
        AND so.owner_name ILIKE '%' || split_part(dom.owner_pattern, ' ', 2) || '%'
      )
    )
)

-- 5. הכנסת ההתאמות (רק שורות עם signed_owner_id לא-NULL)
INSERT INTO public.deal_replaced_owners (deal_id, signed_owner_id, notes)
SELECT
  deal_id,
  signed_owner_id,
  'התאמה אוטומטית: תבנית "' || owner_pattern || '" → "' || owner_name || '"'
FROM matches
WHERE signed_owner_id IS NOT NULL
ON CONFLICT (deal_id, signed_owner_id) DO NOTHING;

-- ============================================================
-- 6. דוחות אימות
-- ============================================================

-- 6.1 התאמות מוצלחות — לפי עסקה
SELECT
  pd.deal_number      AS "מס' עסקה",
  pd.deal_name        AS "שם עסקה",
  pd.parcel           AS "חלקה",
  pd.area_sqm         AS "שטח עסקה",
  COUNT(dro.id)       AS "מס' בעלים מקוריים",
  STRING_AGG(so.owner_name, ', ' ORDER BY so.owner_name) AS "בעלים שזוהו"
FROM public.partnership_deals pd
LEFT JOIN public.deal_replaced_owners dro ON dro.deal_id = pd.id
LEFT JOIN public.signed_owners so          ON so.id      = dro.signed_owner_id
WHERE pd.is_active = TRUE
GROUP BY pd.deal_number, pd.deal_name, pd.parcel, pd.area_sqm
ORDER BY pd.deal_number;

-- 6.2 לא-נמצאים — תבניות שלא הצליחו להתאים לאף signed_owner
WITH deal_owner_map AS (
  SELECT * FROM (VALUES
    (1,  'נורית בן חורין'),
    (2,  'נורית בן חורין'),
    (3,  'דרומי אסתר'), (3, 'בן דוד מרב'),
    (4,  'דרומי אסתר'), (4, 'בן דוד מרב'),
    (5,  'משה ילובסקי'),
    (6,  'דסטא'), (6, 'מחלבת המושבה'),
    (7,  'וזוב'),
    (8,  'עפרה בן גרא'),
    (9,  'נתנאל מור'), (9, 'פנחס מור'), (9, 'מנדל רויטל'), (9, 'חנן מור'),
    (10, 'נתנאל מור'), (10, 'פנחס מור'), (10, 'מנדל רויטל'), (10, 'חנן מור'),
    (11, 'נתנאל מור'), (11, 'פנחס מור'), (11, 'מנדל רויטל'), (11, 'חנן מור'),
    (12, 'נתנאל מור'), (12, 'פנחס מור'), (12, 'מנדל רויטל'), (12, 'חנן מור'),
    (13, 'נתנאל מור'), (13, 'פנחס מור'), (13, 'מנדל רויטל'), (13, 'חנן מור'),
    (14, 'נתנאל מור'), (14, 'פנחס מור'), (14, 'מנדל רויטל'), (14, 'חנן מור'),
    (15, 'נתנאל מור'), (15, 'פנחס מור'), (15, 'מנדל רויטל'), (15, 'חנן מור'),
    (16, 'מורי איל'), (16, 'מוספי אפרת'),
    (17, 'צלליכין רות'), (17, 'צלליכין סבו'), (17, 'סמדר'), (17, 'שושני אורלי'),
    (18, 'משה גולדמן'),
    (19, 'גיל זלץ'),
    (20, 'גיל זלץ'),
    (21, 'מרתון'),
    (22, 'אמנון פלדמן')
  ) AS t(deal_number, owner_pattern)
)
SELECT
  dom.deal_number      AS "מס' עסקה",
  pd.deal_name         AS "שם עסקה",
  pd.parcel            AS "חלקה",
  dom.owner_pattern    AS "תבנית שלא נמצאה"
FROM deal_owner_map dom
JOIN public.partnership_deals pd ON pd.deal_number = dom.deal_number AND pd.is_active = TRUE
WHERE NOT EXISTS (
  SELECT 1 FROM public.signed_owners so
  WHERE so.parcel = pd.parcel
    AND so.is_active = TRUE
    AND (
      so.owner_name ILIKE '%' || dom.owner_pattern || '%'
      OR (
        so.owner_name ILIKE '%' || split_part(dom.owner_pattern, ' ', 1) || '%'
        AND so.owner_name ILIKE '%' || split_part(dom.owner_pattern, ' ', 2) || '%'
      )
    )
)
ORDER BY dom.deal_number, dom.owner_pattern;

-- 6.3 סיכום: סה"כ קישורים שנוצרו
SELECT
  COUNT(DISTINCT deal_id)         AS "מס' עסקאות עם קישור",
  COUNT(*)                        AS "סה״כ קישורים",
  (SELECT COUNT(*) FROM public.partnership_deals WHERE is_active = TRUE) AS "סה״כ עסקאות פעילות"
FROM public.deal_replaced_owners;

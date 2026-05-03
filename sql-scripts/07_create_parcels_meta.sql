-- ============================================================
-- שלב ז׳ · טבלת מידע על חלקות מקור — שטח רשום, נכלל, ומקדם השתתפות
-- ============================================================
-- מקור: נספח א' - שווי החלקות במצב הנכנס
-- אסף לוי / דניאל גב | תכנית תמ"ל 3010 | 01/03/2026
--
-- 45 חלקות בגוש 3852 משתתפות באיחוד וחלוקה — סה"כ 439,608 מ"ר נכלל
--   (439,400 מ"ר חקלאי + 208 מ"ר דרך)
--
-- מקדם השתתפות = שטח_נכלל / שטח_רשום
-- כל בעלי החלקה מצומצמים בפרופורציה אחידה לפי המקדם הזה
-- ============================================================

-- 1. יצירת הטבלה (אם לא קיימת)
CREATE TABLE IF NOT EXISTS public.parcels_meta (
  id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  gush                     INTEGER NOT NULL DEFAULT 3852,
  parcel                   INTEGER NOT NULL,
  total_registered_area    NUMERIC(12,2) NOT NULL,    -- שטח רשום בטאבו (מ"ר)
  total_included_area      NUMERIC(12,2) NOT NULL,    -- שטח הנכלל באיחוד (מ"ר)
  road_area                NUMERIC(12,2) DEFAULT 0,   -- חלק דרך — חלק מהנכלל אך ללא ערך
  agricultural_area        NUMERIC(12,2) NOT NULL,    -- חלק חקלאי — חלק מהנכלל עם ערך
  participation_factor     NUMERIC(8,6) GENERATED ALWAYS AS (
                             total_included_area / NULLIF(total_registered_area, 0)
                           ) STORED,
  participation_type       TEXT NOT NULL CHECK (participation_type IN ('full', 'partial')),
  source_version           TEXT DEFAULT 'נספח א׳ · 01/03/2026',
  notes                    TEXT,
  created_at               TIMESTAMPTZ DEFAULT NOW(),
  updated_at               TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (gush, parcel)
);

CREATE INDEX IF NOT EXISTS idx_parcels_meta_parcel ON public.parcels_meta(gush, parcel);

-- 2. טריגר עדכון אוטומטי של updated_at
CREATE OR REPLACE FUNCTION public.update_parcels_meta_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_parcels_meta_updated_at ON public.parcels_meta;
CREATE TRIGGER trg_parcels_meta_updated_at
  BEFORE UPDATE ON public.parcels_meta
  FOR EACH ROW
  EXECUTE FUNCTION public.update_parcels_meta_updated_at();

-- 3. ניקוי לפני ייבוא חוזר (idempotent — ניתן להריץ שוב בלי נזק)
DELETE FROM public.parcels_meta WHERE source_version = 'נספח א׳ · 01/03/2026';

-- 4. ייבוא 45 החלקות
INSERT INTO public.parcels_meta
  (gush, parcel, total_registered_area, total_included_area, road_area, agricultural_area, participation_type, notes)
VALUES
  (3852, 3,  2266,  2266,  0,    2266,  'full',    NULL),
  (3852, 5,  13794, 13794, 0,    13794, 'full',    NULL),
  (3852, 6,  7764,  7764,  0,    7764,  'full',    NULL),
  (3852, 7,  5096,  5096,  0,    5096,  'full',    NULL),
  (3852, 8,  11969, 11969, 0,    11969, 'full',    NULL),
  (3852, 9,  9126,  9126,  0,    9126,  'full',    NULL),
  (3852, 11, 5357,  5357,  0,    5357,  'full',    NULL),
  (3852, 12, 12232, 12232, 0,    12232, 'full',    NULL),
  (3852, 13, 302,   302,   0,    302,   'full',    NULL),
  (3852, 14, 14152, 14152, 0,    14152, 'full',    NULL),
  (3852, 15, 17264, 17264, 0,    17264, 'full',    NULL),
  (3852, 16, 9022,  9022,  0,    9022,  'full',    NULL),
  (3852, 17, 16987, 16987, 0,    16987, 'full',    NULL),
  (3852, 18, 16830, 16830, 0,    16830, 'full',    NULL),
  (3852, 19, 26980, 26980, 0,    26980, 'full',    NULL),
  (3852, 20, 12468, 10904, 0,    10904, 'partial', '12.5% מחוץ לאיחוד'),
  (3852, 21, 13926, 4573,  39,   4534,  'partial', '67.2% מחוץ לאיחוד; 39 מ"ר דרך'),
  (3852, 22, 10000, 155,   68,   87,    'partial', '98.4% מחוץ לאיחוד; השתתפות מינורית'),
  (3852, 26, 6706,  183,   0,    183,   'partial', '97.3% מחוץ לאיחוד'),
  (3852, 28, 27335, 27335, 0,    27335, 'full',    NULL),
  (3852, 31, 22270, 22270, 0,    22270, 'full',    NULL),
  (3852, 32, 22393, 22393, 0,    22393, 'full',    NULL),
  (3852, 34, 7400,  7400,  0,    7400,  'full',    NULL),
  (3852, 36, 70,    70,    0,    70,    'full',    NULL),
  (3852, 39, 15000, 15000, 0,    15000, 'full',    NULL),
  (3852, 40, 7371,  7371,  0,    7371,  'full',    NULL),
  (3852, 41, 10667, 351,   0,    351,   'partial', '96.7% מחוץ לאיחוד'),
  (3852, 42, 9500,  1807,  0,    1807,  'partial', '81.0% מחוץ לאיחוד'),
  (3852, 44, 13169, 13169, 0,    13169, 'full',    NULL),
  (3852, 45, 18236, 10104, 0,    10104, 'partial', '44.6% מחוץ לאיחוד'),
  (3852, 46, 5922,  5628,  0,    5628,  'partial', '5.0% מחוץ לאיחוד'),
  (3852, 49, 1105,  1105,  0,    1105,  'full',    NULL),
  (3852, 51, 24918, 24918, 0,    24918, 'full',    NULL),
  (3852, 53, 12926, 12926, 0,    12926, 'full',    NULL),
  (3852, 55, 14600, 14600, 0,    14600, 'full',    NULL),
  (3852, 57, 6138,  5327,  0,    5327,  'partial', '13.2% מחוץ לאיחוד'),
  (3852, 59, 12461, 12461, 0,    12461, 'full',    NULL),
  (3852, 61, 9451,  9451,  101,  9350,  'full',    'מלא 100% — 101 מ"ר דרך'),
  (3852, 66, 824,   824,   0,    824,   'full',    NULL),
  (3852, 67, 10036, 10036, 0,    10036, 'full',    NULL),
  (3852, 68, 10032, 10032, 0,    10032, 'full',    NULL),
  (3852, 69, 10035, 10035, 0,    10035, 'full',    NULL),
  (3852, 70, 10039, 10039, 0,    10039, 'full',    NULL);

-- ============================================================
-- 5. אימות
-- ============================================================

-- 5.1 רשימת חלקות חלקיות בלבד
SELECT
  parcel              AS "חלקה",
  total_registered_area AS "רשום",
  total_included_area   AS "נכלל",
  agricultural_area    AS "חקלאי",
  ROUND(participation_factor * 100, 1) AS "מקדם %",
  notes               AS "הערה"
FROM public.parcels_meta
WHERE participation_type = 'partial'
ORDER BY parcel;

-- 5.2 סיכומים — אמורים להתאים לטבלת השמאי: רשום, נכלל=439,608, חקלאי=439,400, דרך=208
SELECT
  COUNT(*)                       AS "סה״כ חלקות",
  SUM(total_registered_area)     AS "סה״כ רשום",
  SUM(total_included_area)       AS "סה״כ נכלל",
  SUM(agricultural_area)         AS "סה״כ חקלאי",
  SUM(road_area)                 AS "סה״כ דרך"
FROM public.parcels_meta;

-- ============================================================
-- סיום · הקובץ אידמפוטנטי — ניתן להריץ שוב בלי נזק
-- ============================================================

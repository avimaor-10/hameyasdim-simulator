# סימולטור עסקת קומבינציה ושיתוף — מתחם המייסדים

**קבוצת חנן מור · תמ"ל 3010 · נס ציונה**

מערכת אינטרנט לבעלי קרקע במתחם המייסדים: הדמיית עסקת הקומבינציה הצפויה, שמירת בחירות, וניהול בעלים עבור צוות מור.

---

## 🏗 מבנה המערכת

### דפים ציבוריים (לא דורשים התחברות)
- `login.html` — מסך כניסה
- `register.html` — מסך הרשמה (עם העלאת נסח טאבו)
- `pending.html` — מסך המתנה לאישור אדמין

### דפים מוגנים (דורשים משתמש מאושר)
- `index.html` — הסימולטור עצמו (חישובי יח"ק, קומבינציה, שמירת בחירה)

### דפים לאדמין בלבד
- `admin.html` — דשבורד ניהול משתמשים
- `matching.html` — כלי חיבור בעלים להשלמת חלקות

### תשתית
- `supabase-config.js` — קונפיגורציה משותפת ל-Supabase + פונקציות עזר
- `site-plan.jpg` — תרשים המתחם (משמש כ-Base64 בתוך `index.html`)

---

## 🔐 טכנולוגיה

- **Frontend**: HTML/CSS/JS טהור (ללא framework, ES Modules)
- **Backend**: Supabase (Auth + PostgreSQL + Storage)
- **Hosting**: Netlify (פריסה אוטומטית מגיטהאב)

---

## 🚀 פיתוח מקומי

1. הפעל שרת מקומי:
   ```
   python -m http.server 8000
   ```
2. פתח בדפדפן: `http://localhost:8000/login.html`

---

## 👤 משתמש אדמין ראשון

לאחר הרשמה, הפוך את עצמך לאדמין דרך SQL Editor של Supabase:

```sql
UPDATE public.profiles
SET role = 'admin',
    approval_status = 'approved',
    approved_at = NOW()
WHERE email = 'YOUR_EMAIL@example.com';
```

---

## 📝 סכמת מסד נתונים

ראה `supabase-schema.sql` (לא נכלל בגיטהאב — שמור מקומית).

טבלאות עיקריות:
- `profiles` — פרטי משתמש + סטטוס אישור
- `user_parcels` — חלקות בבעלות המשתמש
- `selections` — בחירות שמורות בסימולטור
- `admin_access_log` — תיעוד פעולות אדמין

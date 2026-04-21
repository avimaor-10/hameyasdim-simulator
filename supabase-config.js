// ============================================================
// תצורת Supabase משותפת לכל הדפים
// סימולטור עסקת קומבינציה ושיתוף - מתחם המייסדים
// ============================================================

export const SUPABASE_URL = 'https://hgoctpmuswvnflfeqlad.supabase.co';
export const SUPABASE_KEY = 'sb_publishable_mQF2M7UBBHXqt8k9jSLIEg_pE421ti1';

// ==== יבוא לקוח Supabase ויצירת מופע גלובלי ====
import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm';
export const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

// ==== פונקציות עזר נפוצות ====

/**
 * מחזיר את המשתמש המחובר הנוכחי + הפרופיל שלו
 */
export async function getCurrentUser() {
  const { data: { session } } = await supabase.auth.getSession();
  if (!session) return null;

  const { data: profile, error } = await supabase
    .from('profiles')
    .select('*')
    .eq('id', session.user.id)
    .single();

  if (error) {
    console.error('שגיאה בטעינת פרופיל:', error);
    return { session, profile: null };
  }
  return { session, profile };
}

/**
 * מוודא שהמשתמש מחובר ומאושר. מפנה אחרת.
 * @param {Object} options
 * @param {boolean} options.requireAdmin - נדרש אדמין
 * @param {string} options.loginUrl - URL להפניה אם לא מחובר
 * @param {string} options.pendingUrl - URL להפניה אם לא מאושר
 */
export async function requireAuth(options = {}) {
  const {
    requireAdmin = false,
    loginUrl = 'login.html',
    pendingUrl = 'pending.html',
  } = options;

  const user = await getCurrentUser();

  if (!user) {
    window.location.href = loginUrl;
    return null;
  }

  if (!user.profile) {
    alert('שגיאה: לא נמצא פרופיל. אנא התנתק ונסה להירשם שוב.');
    await supabase.auth.signOut();
    window.location.href = loginUrl;
    return null;
  }

  if (user.profile.approval_status !== 'approved') {
    if (window.location.pathname.indexOf('pending') === -1) {
      window.location.href = pendingUrl;
      return null;
    }
    return user; // אנחנו כבר על pending.html
  }

  if (requireAdmin && user.profile.role !== 'admin') {
    alert('אין לך הרשאת אדמין לגשת לדף זה.');
    window.location.href = 'index.html';
    return null;
  }

  return user;
}

/**
 * התנתקות מהמערכת + הפניה לדף הכניסה
 */
export async function logout() {
  await supabase.auth.signOut();
  window.location.href = 'login.html';
}

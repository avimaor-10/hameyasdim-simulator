"""
פיענוח כל נסחי הטאבו וחילוץ בעלי הזכויות הפעילים.
מקור: נסחים מרץ 2026/3852-X.pdf
תוצר: assets/tabu_owners.json
"""
import pdfplumber
import re
import os
import sys
import json
from glob import glob

sys.stdout.reconfigure(encoding='utf-8')
BASE_DIR = r'C:\Users\User2\Desktop\סימולטור עסקת קומבינציה וטבלאות ההקצעה'
os.chdir(BASE_DIR)

# שטחי החלקות (PARCEL_AREAS) — לחישוב שטח מהשבר
PARCEL_AREAS = {
    3: 2266, 5: 13794, 6: 7764, 7: 5096, 8: 11969, 9: 9126,
    11: 5357, 12: 12232, 13: 302, 14: 14152, 15: 17264, 16: 9022,
    17: 16987, 18: 16830, 19: 26980, 20: 10904, 21: 4573, 22: 155,
    26: 183, 28: 27335, 31: 22270, 32: 22393, 34: 7400, 36: 70,
    39: 15000, 40: 7371, 41: 351, 42: 1807, 44: 13169, 45: 18236,
    46: 5628, 49: 1105, 51: 24918, 53: 12926, 55: 14600, 57: 5327,
    59: 12461, 61: 10000, 66: 7000, 67: 10036, 68: 10032, 69: 10035, 70: 10039,
}

def parse_tabu(pdf_path, parcel_num):
    """חולץ בעלי זכויות פעילים (לא מבוטלים) מנסח טאבו."""
    parcel_area = PARCEL_AREAS.get(parcel_num, 0)
    if parcel_area == 0:
        return []

    with pdfplumber.open(pdf_path) as pdf:
        full = ''
        for page in pdf.pages:
            full += (page.extract_text() or '') + '\n'

    lines = full.split('\n')
    records = []
    current = None

    for line in lines:
        line = line.strip()

        # תבנית 1: ת.ז (תעודת זהות)
        m1 = re.match(r'^(\d{5,10})\s+ז\.ת\s+(.+?)\s*(X)?\s*$', line)
        if m1:
            id_, rest, x = m1.group(1), m1.group(2), m1.group(3)
            current = {'id': id_, 'kind': 'תז', 'desc': rest, 'cancelled': bool(x), 'share': None}
            records.append(current)
            continue

        # תבנית 2: ח.פ (חברה בע"מ)
        m2 = re.match(r'^(\d{5,10})\s+הרבח מ"עב\s+(.+?)\s*(X)?\s*$', line)
        if m2:
            id_, rest, x = m2.group(1), m2.group(2), m2.group(3)
            current = {'id': id_, 'kind': 'חפ', 'desc': rest, 'cancelled': bool(x), 'share': None}
            records.append(current)
            continue

        # תבנית 3: דרכון זר
        m3 = re.match(r'^([A-Z0-9]{5,15})\s+דנלוה ןוכרד\s+(.+?)\s*(X)?\s*$', line)
        if m3:
            id_, rest, x = m3.group(1), m3.group(2), m3.group(3)
            current = {'id': id_, 'kind': 'דרכון', 'desc': rest, 'cancelled': bool(x), 'share': None}
            records.append(current)
            continue

        # שבר X/Y
        sm = re.match(r'^(\d+)\s*/\s*(\d+)\s*$', line)
        if sm and current and current['share'] is None:
            current['share'] = (int(sm.group(1)), int(sm.group(2)))
            continue

        # תומלשב = בשלמות
        if 'תומלשב' in line and current and current['share'] is None:
            current['share'] = (1, 1)
            continue

    # פילטר רק פעילים עם שבר תקף
    active = []
    for r in records:
        if r['cancelled'] or not r['share']:
            continue
        n, d = r['share']
        if d <= 0:
            continue
        # ניקוי שם — היפוך עברית
        raw_name = r['desc']
        # שלב 1: ניקוי תאריכים ומספרי שטרות מהטקסט המקורי לפני ההיפוך
        # תאריכים: DD/MM/YYYY
        cleaned = re.sub(r'\d{1,2}/\d{1,2}/\d{4}', '', raw_name).strip()
        # מספרי שטרות: DDDD/YYYY/D או דומה
        cleaned = re.sub(r'\d+/\d+/\d+', '', cleaned).strip()
        cleaned = re.sub(r'\d+/\d+', '', cleaned).strip()
        # שלב 2: היפוך לטקסט עברי תקין
        clean_name = cleaned[::-1].strip()
        # שלב 3: הסרת מילות פעולה אם נכנסו לשם
        action = None
        for act_kw in ['מכר ללא תמורה', 'העברה ללא תמורה', 'הסכם פירוק', 'מכר', 'ירושה', 'צוואה', 'עודף']:
            if act_kw in clean_name:
                action = act_kw
                clean_name = clean_name.replace(act_kw, '').strip()
                break
        # שלב 4: ניקוי רווחים מיותרים
        clean_name = re.sub(r'\s+', ' ', clean_name).strip()
        # אם נשארו ספרות בתחילת השם — הסר אותן
        clean_name = re.sub(r'^[\d/\s]+', '', clean_name).strip()
        clean_name = re.sub(r'[\d/\s]+$', '', clean_name).strip()

        # חישוב שטח
        area = (n / d) * parcel_area

        active.append({
            'name': clean_name,
            'id': r['id'],
            'kind': r['kind'],
            'share_n': n,
            'share_d': d,
            'share_str': f'{n}/{d}',
            'area_sqm': round(area, 2),
            'action': action,
        })

    # מיון: מהשטח הגדול לקטן
    active.sort(key=lambda x: -x['area_sqm'])
    return active


# הרץ על כל הנסחים
result = {}
TABU_DIR = 'נסחים מרץ 2026'
files = sorted(glob(os.path.join(TABU_DIR, '3852-*.pdf')),
               key=lambda f: int(re.search(r'3852-(\d+)\.pdf', f).group(1)))

print(f'מפענח {len(files)} נסחים...')
for f in files:
    m = re.search(r'3852-(\d+)\.pdf', f)
    if not m:
        continue
    parcel_num = int(m.group(1))
    if parcel_num not in PARCEL_AREAS:
        print(f'  ⚠ דילוג על חלקה {parcel_num} — אין שטח רישומי בטבלה')
        continue
    owners = parse_tabu(f, parcel_num)
    total = sum(o['area_sqm'] for o in owners)
    result[str(parcel_num)] = {
        'parcel_area': PARCEL_AREAS[parcel_num],
        'owners_count': len(owners),
        'owners_total_area': round(total, 2),
        'owners': owners,
    }
    diff = total - PARCEL_AREAS[parcel_num]
    diff_str = f'{diff:+.0f} מ"ר' if abs(diff) > 5 else 'תואם'
    print(f'  חלקה {parcel_num:>3}: {len(owners):>2} בעלים · {total:>8.0f} מ"ר · {diff_str}')

# שמירה ל-JSON
out_path = 'assets/tabu_owners.json'
with open(out_path, 'w', encoding='utf-8') as f:
    json.dump(result, f, ensure_ascii=False, indent=2)

print()
print(f'✅ נשמר: {out_path}')
print(f'   סה"כ {len(result)} חלקות עם נתוני טאבו')

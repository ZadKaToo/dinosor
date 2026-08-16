# Skillpass / LearnPro — Complete Package

## ไฟล์ใน zip
- `lib_fixed/` → เอาไปแทนที่โฟลเดอร์ `lib` ในโปรเจกต์ Flutter
- `supabase_schema.sql` → รันก่อนใน SQL Editor (สร้างตารางทั้งหมด)
- `supabase_persistence_migration.sql` → รันต่อ (ไฟล์โค้ด + ประวัติแชท/รัน)
- `README_SETUP.md` → คู่มือนี้

## ขั้นตอนติดตั้ง

### 1. Supabase SQL
1. เปิด SQL Editor ของโปรเจกต์ `rbdjjzqdhftrzlwrewej`
2. รัน `supabase_schema.sql` ทั้งไฟล์
3. รัน `supabase_persistence_migration.sql` ทั้งไฟล์
4. Authentication → Providers → Email → ปิด Confirm email (ตอนทดสอบ)

### 2. Flutter
1. แตก zip แล้วคัดลอกเนื้อใน `lib_fixed/` ไปทับ `lib/`
2. ใน `pubspec.yaml` ให้มีอย่างน้อย:
   ```yaml
   dependencies:
     supabase_flutter: ^2.0.0
     provider: any
     webview_flutter: ^4.7.0
     http: any
     flutter_markdown: any
   ```
3. `flutter pub get` แล้ว hot restart

### 3. ทดสอบ
1. สมัคร / Login
2. เขียนโค้ด → สร้างไฟล์ → Save → Logout → Login ใหม่ ต้องเห็นไฟล์ครบ
3. AI Mentor คุยแล้วเปิดใหม่ ต้องมีประวัติ (ต้อง deploy Edge Function `mentor` แยก)

## สิ่งที่รวมในเวอร์ชันนี้
- Login / Register (Supabase Auth) + บังคับ login
- แก้ crash Container color+decoration
- URL + anon key โปรเจกต์ใหม่
- Live Sandbox + Pyodide 0.25
- เมนู "เขียนโค้ด"
- บันทึกไฟล์โค้ด / ประวัติรัน / แชท ลง Supabase
- Schema + RLS + seed ตัวอย่าง

## ยังต้องทำเอง
- Deploy Edge Function `mentor` + ใส่ secret `GEMINI_API_KEY`

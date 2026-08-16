****Skill Up****

โปรเจกต์นี้ทำมาช่วยคนที่อยากเริ่มสาย IT หรืออยากอัปสกิลตัวเองให้มี Roadmap ชัดเจน ไม่ต้องเดาทางเอง มีระบบลองเขียนโค้ดจริง ปรึกษา AI ได้ตลอด แถมยังคอยวัดระดับสกิลเพื่อปลดล็อก Tier เงินเดือนให้เห็นภาพการเติบโตแบบชัดๆ ด้วย

****ฟีเจอร์เด็ดๆ ในแอป****
    
    IT Center Dashboard: หน้าเช็กสถานะตัวเอง ดูสกิลที่สะสมมา Badge ที่ได้ แล้วก็ Tier เงินเดือนปัจจุบัน
    
    Career Roadmap & IT Tracks: เลือกเลยว่าอยากไปสายไหน ระบบจะวางลำดับคอร์สที่ต้องเรียนมาให้เรียบร้อย
    
    Live Sandbox: มีที่ให้ลองเขียน Python แล้วกดรันจริงบนแอปได้เลย (ผ่าน Pyodide) เอาไว้ทำภารกิจฝึกมือ
    
    AI Mentor Chat: เขียนโค้ดแล้วติดบั๊ก หรืออยากรู้ว่าสายนี้ต้องเตรียมตัวยังไง แชทถาม AI ได้ทันที
    
    Gamification: มีควิซและภารกิจรายวันให้ทำ ยิ่งทำยิ่งได้ Badge เอาไว้ปลดล็อกขั้นเงินเดือน

****วิธีใช้งานเบื้องต้น****

    สมัคร / เข้าสู่ระบบ: สร้างแอคเคาน์ไว้เก็บ Progress และสกิลของตัวเอง
    
    เลือกสายงานที่สนใจ: เข้าไปที่ Career Roadmap แล้วเลือกเป้าหมายอาชีพ
    
    ลุยเรียนและทำภารกิจ: เข้าเรียน ทำแบบทดสอบ แล้วลองฝึกเขียนโค้ดใน Live Sandbox
    
    ถาม AI เวลาติดขัด: ถ้าโค้ดไม่ผ่านหรือสงสัยตรงไหน ให้เปิดแชทถาม AI Mentor ได้เลย
    
    เก็บ Badge อัปเงินเดือน: สะสมผลงานไปเรื่อยๆ เพื่อปลดล็อก Tier เงินเดือนใหม่ๆ

****โครงสร้างโปรเจกต์ (Project Structure)****

        lib/screens/ - รวมหน้าจอหลักทั้งหมด (Dashboard, Roadmap, Sandbox, Chat)
        
        lib/services/ - โค้ดฝั่งจัดการข้อมูลและ Logic (Auth, Course, Skill, AI Chat ฯลฯ)
        
        lib/models/ - Data Models ต่างๆ ในแอป
        
        lib/assets/ - เก็บไฟล์ pyodide_sandbox.html ที่ใช้รัน Python
        
        supabase_schema.sql - ไฟล์ SQL สำหรับตั้งค่า Database บน Supabase

**Tech Stack ที่ใช้**

        Frontend: Flutter (Dart)
        
        Backend: Supabase (PostgreSQL)
        
        Code Runner: Pyodide (Python WebAssembly)

****สำหรับ Dev ที่จะเอาไปรันต่อ****

ลง Dependencies ก่อน

        flutter pub get
        
เอาไฟล์ supabase_schema.sql (และ supabase_persistence_migration.sql ถ้ามี) ไปรันใน SQL Editor ของ Supabase
        
สั่งรันแอปได้เลย:
        
        flutter run   

import os
import uuid
import json
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse, FileResponse
from pydantic import BaseModel
from google import genai
from google.genai import types
from supabase import create_client, Client

app = FastAPI()

# ตั้งค่า CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 1. กำหนดค่า Gemini Client (ระวังเรื่อง API Key!)
gemini_client = genai.Client(api_key="YOUR_GEMINI_API_KEY")

# 2. กำหนดค่า Supabase Client
SUPABASE_URL = "YOUR_SUPABASE_URL"
SUPABASE_KEY = "YOUR_SUPABASE_ANON_KEY"
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# ================= โครงสร้างข้อมูล (Schemas) =================
class ChatRequest(BaseModel):
    message: str
    user_id: str | None = None

class CareerRequest(BaseModel):
    user_id: str

# Pydantic Model สำหรับบังคับให้ Gemini ตอบเป็น JSON โครงสร้างนี้เป๊ะๆ
class CareerMatch(BaseModel):
    role: str
    percentage: int
    reason: str

class CareerAnalysisResponse(BaseModel):
    keywords: list[str]
    careers: list[CareerMatch]

# ================= Helper Functions =================
def get_valid_uuid(val: str | None) -> str | None:
    if not val or val.lower() == "anonymous":
        return None
    try:
        return str(uuid.UUID(val))
    except ValueError:
        return None

# ================= API Routes =================
@app.get("/", response_class=HTMLResponse)
async def serve_index():
    return "<h1>AI Mentor API is working!</h1>"

@app.post("/api/mentor")
async def ai_mentor(request: ChatRequest):
    last_error = ""
    reply_text = ""
    
    system_prompt = """
    คุณคือ AI Mentor ผู้เชี่ยวชาญด้านสายงาน IT
    กฎเหล็กในการตอบ:
    1. ตอบให้ตรงประเด็นและสั้นกระชับที่สุด
    2. คำถามเกี่ยวกับสายงาน IT ให้สรุปเป็นหัวข้อสั้นๆ หรือ Bullet points ชัดเจน
    """

    FALLBACK_MODELS = ["gemini-2.5-flash", "gemini-1.5-flash"] # อัปเดตชื่อโมเดลเป็นตัวล่าสุด

    # 1. ดึงคำตอบจาก Gemini AI
    for model_name in FALLBACK_MODELS:
        try:
            response = gemini_client.models.generate_content(
                model=model_name,
                contents=request.message,
                config=types.GenerateContentConfig(
                    system_instruction=system_prompt,
                    temperature=0.2,
                ),
            )
            reply_text = response.text
            break
        except Exception as e:
            last_error = str(e)
            print(f"⚠️ โมเดล {model_name} ไม่ว่าง ({e})")
            continue
            
    if not reply_text:
        return {"reply": f"เกิดข้อผิดพลาดในการประมวลผล: {last_error}"}

    # 2. บันทึกประวัติบทสนทนาลง Supabase
    valid_user_id = get_valid_uuid(request.user_id)
    if valid_user_id:
        try:
            supabase.table("chat_history").insert({
                "user_id": valid_user_id,
                "user_message": request.message,
                "bot_reply": reply_text
            }).execute()
        except Exception as db_err:
            print(f"⚠️ บันทึกลง Supabase ไม่สำเร็จ: {db_err}")

    return {"reply": reply_text}


# ================= ฟีเจอร์ใหม่: วิเคราะห์อาชีพ =================
@app.post("/api/analyze-career")
async def analyze_career(request: CareerRequest):
    valid_user_id = get_valid_uuid(request.user_id)
    if not valid_user_id:
        raise HTTPException(status_code=400, detail="Invalid User ID")

    try:
        # 1. ดึงประวัติการแชททั้งหมดของผู้ใช้คนนี้จาก Supabase
        history = supabase.table("chat_history").select("user_message").eq("user_id", valid_user_id).execute()
        
        if not history.data:
            return {"status": "no_data", "message": "ไม่พบประวัติการแชทเพียงพอสำหรับการวิเคราะห์"}

        # นำข้อความแชทมาต่อกัน
        all_messages = "\n".join([row["user_message"] for row in history.data])

        # 2. สร้าง Prompt ส่งให้ Gemini วิเคราะห์
        analysis_prompt = f"""
        จงวิเคราะห์ประวัติการแชทของผู้ใช้งานต่อไปนี้ เพื่อทำ Career Profiling สำหรับสายงาน IT
        1. สกัด Keyword สำคัญที่เกี่ยวกับทักษะ ความสนใจ เครื่องมือ หรือเทคโนโลยี
        2. ประเมินโอกาสความเหมาะสม (เป็นเปอร์เซ็นต์ 1-100) สำหรับอาชีพสาย IT หลักๆ ทั้งหมด (เช่น Frontend, Backend, Data, QA, DevOps, UX/UI, System Analyst เป็นต้น)
        3. ให้อธิบายเหตุผลสั้นๆ (reason) ว่าทำไมถึงให้เปอร์เซ็นต์เท่านี้ อ้างอิงจากสิ่งที่เขาพิมพ์มา
        
        ประวัติแชทผู้ใช้:
        {all_messages}
        """

        # 3. เรียกใช้ Gemini โดยบังคับให้ตอบกลับมาเป็น JSON ตาม Schema ที่เรากำหนด
        response = gemini_client.models.generate_content(
            model="gemini-2.5-flash",
            contents=analysis_prompt,
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                response_schema=CareerAnalysisResponse, # บังคับโครงสร้าง JSON
                temperature=0.1, # ใช้ค่าน้อยๆ เพื่อให้ผลลัพธ์คงที่ (Deterministic)
            ),
        )

        # 4. แปลงข้อความ JSON ที่ Gemini ตอบกลับมาให้อยู่ในรูป Dictionary ของ Python
        analysis_result = json.loads(response.text)

        # 5. บันทึก / อัปเดต ผลลัพธ์ลง Supabase (ตาราง user_career_profiles)
        # ใช้ upsert เพื่อที่ว่าถ้ามีข้อมูล user_id นี้อยู่แล้ว จะเป็นการอัปเดตข้อมูลทับของเดิม
        supabase.table("user_career_profiles").upsert({
            "user_id": valid_user_id,
            "keywords": analysis_result["keywords"],
            "careers_analysis": analysis_result["careers"]
        }).execute()

        return {
            "status": "success",
            "message": "วิเคราะห์และบันทึกข้อมูลสำเร็จ",
            "data": analysis_result
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

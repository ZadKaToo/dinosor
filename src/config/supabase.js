const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

// ใช้ Service Key เพื่อให้ Backend มีสิทธิ์จัดการ Database ได้เต็มที่
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_KEY
);

module.exports = supabase;
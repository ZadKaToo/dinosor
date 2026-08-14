// ตัวอย่างใน aiController.js ของเพื่อน
const axios = require('axios');

exports.chatWithAI = async (req, res) => {
    try {
        const { message } = req.body;
        // ยิงต่อไปหา FastAPI ของคุณ (ใช้ LocalTunnel หรือ IP)
        const response = await axios.post('https://heavy-buses-accept.loca.lt/api/mentor', {
            message: message
        }, {
            headers: { 'Bypass-Tunnel-Reminder': 'true' }
        });

        res.json({ reply: response.data.reply });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

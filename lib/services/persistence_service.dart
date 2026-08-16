import 'package:supabase_flutter/supabase_flutter.dart';

/// บันทึก/โหลด ประวัติการใช้งานของผู้ใช้ลง Supabase
/// - บทสนทนา AI Mentor
/// - ไฟล์โค้ดใน Sandbox
/// - ประวัติการรันโค้ด
class PersistenceService {
  static final SupabaseClient _db = Supabase.instance.client;

  static String? get _userId => _db.auth.currentUser?.id;

  // ─────────────────────────────────────────────
  // AI Mentor — บทสนทนา
  // ─────────────────────────────────────────────

  /// โหลดประวัติแชทล่าสุด (เรียงเก่า → ใหม่)
  static Future<List<Map<String, dynamic>>> loadChatHistory({int limit = 50}) async {
    final uid = _userId;
    if (uid == null) return [];
    try {
      final rows = await _db
          .from('chat_history')
          .select('id, user_message, bot_reply, created_at, session_id')
          .eq('user_id', uid)
          .order('created_at', ascending: true)
          .limit(limit);
      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      return [];
    }
  }

  /// บันทึก 1 รอบคำถาม–คำตอบ
  static Future<void> saveChatTurn({
    required String userMessage,
    required String botReply,
    String? sessionId,
  }) async {
    final uid = _userId;
    if (uid == null) return;
    try {
      await _db.from('chat_history').insert({
        'user_id': uid,
        'user_message': userMessage,
        'bot_reply': botReply,
        if (sessionId != null) 'session_id': sessionId,
      });
    } catch (_) {}
  }

  /// สร้าง session แชทใหม่
  static Future<String?> createChatSession({String title = 'แชทใหม่'}) async {
    final uid = _userId;
    if (uid == null) return null;
    try {
      final row = await _db
          .from('chat_sessions')
          .insert({'user_id': uid, 'title': title})
          .select('id')
          .single();
      return row['id'] as String?;
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // Sandbox — ไฟล์โปรเจกต์
  // ─────────────────────────────────────────────

  /// โหลดไฟล์ทั้งหมดของ user → Map fileName → content
  static Future<Map<String, String>> loadSandboxFiles() async {
    final uid = _userId;
    if (uid == null) return {};
    try {
      final rows = await _db
          .from('user_sandbox_files')
          .select('file_name, content')
          .eq('user_id', uid)
          .order('file_name');
      final map = <String, String>{};
      for (final r in rows) {
        map[r['file_name'] as String] = (r['content'] as String?) ?? '';
      }
      return map;
    } catch (e) {
      // ตารางยังไม่มี หรือ RLS บล็อก → ดู debug console
      assert(() {
        // ignore: avoid_print
        print('loadSandboxFiles error: $e');
        return true;
      }());
      return {};
    }
  }

  /// บันทึก/อัปเดตไฟล์หนึ่งไฟล์
  static Future<void> saveSandboxFile(String fileName, String content) async {
    final uid = _userId;
    if (uid == null) return;
    try {
      await _db.from('user_sandbox_files').upsert({
        'user_id': uid,
        'file_name': fileName,
        'content': content,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,file_name');
    } catch (e) {
      assert(() {
        // ignore: avoid_print
        print('saveSandboxFile error: $e');
        return true;
      }());
    }
  }

  /// บันทึกหลายไฟล์พร้อมกัน
  static Future<void> saveAllSandboxFiles(Map<String, String> files) async {
    final uid = _userId;
    if (uid == null || files.isEmpty) return;
    try {
      final rows = files.entries
          .map((e) => {
                'user_id': uid,
                'file_name': e.key,
                'content': e.value,
                'updated_at': DateTime.now().toIso8601String(),
              })
          .toList();
      await _db.from('user_sandbox_files').upsert(rows, onConflict: 'user_id,file_name');
    } catch (e) {
      assert(() {
        // ignore: avoid_print
        print('saveAllSandboxFiles error: $e');
        return true;
      }());
    }
  }

  /// ลบไฟล์
  static Future<void> deleteSandboxFile(String fileName) async {
    final uid = _userId;
    if (uid == null) return;
    try {
      await _db
          .from('user_sandbox_files')
          .delete()
          .eq('user_id', uid)
          .eq('file_name', fileName);
    } catch (_) {}
  }

  // ─────────────────────────────────────────────
  // Sandbox — ประวัติการรัน
  // ─────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> loadCodeRuns({int limit = 30}) async {
    final uid = _userId;
    if (uid == null) return [];
    try {
      final rows = await _db
          .from('user_code_runs')
          .select('*')
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveCodeRun({
    required String code,
    String? output,
    bool success = true,
    String fileName = 'main.py',
    String? missionId,
    int? durationMs,
  }) async {
    final uid = _userId;
    if (uid == null) return;
    try {
      await _db.from('user_code_runs').insert({
        'user_id': uid,
        'file_name': fileName,
        'code': code,
        'output': output,
        'success': success,
        if (missionId != null) 'mission_id': missionId,
        if (durationMs != null) 'duration_ms': durationMs,
      });
    } catch (_) {}
  }
}

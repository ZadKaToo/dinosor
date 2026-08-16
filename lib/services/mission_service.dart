import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ย้ายจาก backend Node.js (127.0.0.1:3000/api/missions) มาคุยกับ Supabase โดยตรง
class MissionService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static String? get _userId => _supabase.auth.currentUser?.id;

  /// 1. ดึงรายการภารกิจทั้งหมด (ใช้ในหน้าเลือกด่าน)
  static Future<List<dynamic>> getMissions({String? track}) async {
    try {
      var query = _supabase
          .from('missions')
          .select('id, track, title, description, xp_reward, order_index');
      if (track != null && track.isNotEmpty) {
        query = query.eq('track', track);
      }
      final result = await query.order('order_index');
      return result;
    } catch (e) {
      debugPrint('Error fetching missions: $e');
      return [];
    }
  }

  /// 2. ดึงสถานะภารกิจของผู้ใช้ (ว่าด่านไหนผ่านแล้วบ้าง)
  /// ทำเทียบเท่า LEFT JOIN missions กับ user_missions ด้วยการ query แยก 2 ครั้ง
  /// แล้ว merge เอง (เลี่ยงปัญหาเรื่อง PostgREST embed ต้องพึ่ง FK relationship)
  static Future<List<dynamic>> getMyMissions() async {
    final userId = _userId;
    if (userId == null) return [];
    try {
      final missions = await _supabase
          .from('missions')
          .select('id, title, track, xp_reward')
          .order('order_index');

      final userMissions = await _supabase
          .from('user_missions')
          .select('mission_id, status, completed_at')
          .eq('user_id', userId);

      final statusByMissionId = {
        for (final um in (userMissions as List)) um['mission_id'] as String: um,
      };

      return (missions as List).map((m) {
        final um = statusByMissionId[m['id']];
        return {
          'id': m['id'],
          'mission_id': m['id'],
          'title': m['title'],
          'track': m['track'],
          'xp_reward': m['xp_reward'],
          'status': um?['status'],
          'completed_at': um?['completed_at'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching my missions: $e');
      return [];
    }
  }

  /// 3. ดึงรายละเอียดโจทย์ (โค้ดเริ่มต้น, คำอธิบาย ฯลฯ)
  static Future<Map<String, dynamic>?> getMissionDetail(String id) async {
    try {
      final result = await _supabase.from('missions').select('*').eq('id', id).maybeSingle();
      return result;
    } catch (e) {
      debugPrint('Error fetching mission detail: $e');
      return null;
    }
  }

  /// ตั้งสถานะภารกิจเป็น in_progress (ถ้ายังไม่เคยมีแถวของผู้ใช้กับภารกิจนี้)
  static Future<void> startMission(String missionId) async {
    final userId = _userId;
    if (userId == null) return;
    try {
      await _supabase.from('user_missions').upsert(
        {'user_id': userId, 'mission_id': missionId, 'status': 'in_progress'},
        onConflict: 'user_id,mission_id',
        ignoreDuplicates: true,
      );
    } catch (e) {
      debugPrint('Error starting mission: $e');
    }
  }

  /// 4. ส่งผลการรันโค้ด (อัปเดตสถานะ + แจก XP ให้ครั้งแรกที่ผ่านเท่านั้น)
  /// หมายเหตุ: เหมือน progress_service.dart, ทำเป็นอ่าน-แล้ว-เขียนต่อเนื่อง ไม่ใช่
  /// atomic transaction แบบฝั่ง Node.js เดิม — ถ้าต้องการความชัวร์ 100% ควรทำเป็น
  /// Postgres function แล้วเรียกผ่าน rpc() แทน
  static Future<Map<String, dynamic>?> submitMission(String id, String code, bool passed) async {
    final userId = _userId;
    if (userId == null) return null;
    try {
      final mission =
          await _supabase.from('missions').select('xp_reward').eq('id', id).maybeSingle();
      if (mission == null) return null;

      final existing = await _supabase
          .from('user_missions')
          .select('status')
          .eq('user_id', userId)
          .eq('mission_id', id)
          .maybeSingle();
      final wasCompleted = existing?['status'] == 'completed';
      final status = passed ? 'completed' : 'in_progress';

      await _supabase.from('user_missions').upsert({
        'user_id': userId,
        'mission_id': id,
        'status': status,
        'submitted_code': code,
        if (passed && !wasCompleted) 'completed_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,mission_id');

      int xpAwarded = 0;
      if (passed && !wasCompleted) {
        xpAwarded = mission['xp_reward'] as int;

        final currentProgress = await _supabase
            .from('user_progress')
            .select('total_xp')
            .eq('user_id', userId)
            .maybeSingle();
        if (currentProgress != null) {
          final newTotalXp = (currentProgress['total_xp'] as int) + xpAwarded;
          await _supabase
              .from('user_progress')
              .update({'total_xp': newTotalXp, 'updated_at': DateTime.now().toIso8601String()})
              .eq('user_id', userId);
        }

        await _supabase.from('user_badges').upsert(
          {'user_id': userId, 'badge_id': 'mission1'},
          onConflict: 'user_id,badge_id',
          ignoreDuplicates: true,
        );
      }

      return {
        'status': status,
        'xp_awarded': xpAwarded,
        'first_completion': passed && !wasCompleted,
      };
    } catch (e) {
      debugPrint('Error submitting mission: $e');
      return null;
    }
  }
}

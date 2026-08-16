import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ย้ายจาก backend Node.js (127.0.0.1:3000/api/progress) มาคุยกับ Supabase โดยตรง
///
/// หมายเหตุสำคัญ: ฝั่ง Node.js เดิมทำ addXp / incrementRunCount แบบ transaction
/// (BEGIN...COMMIT) เพื่อกันข้อมูลเพี้ยนถ้ามีการยิงพร้อมกัน ที่นี่ทำเป็นการอ่าน-แล้ว-เขียน
/// ต่อเนื่องกันแทน (ไม่ใช่ atomic 100%) ซึ่งเพียงพอสำหรับแอปที่ผู้ใช้กดเองทีละคน
/// ถ้าต้องการความถูกต้องแบบ atomic จริงๆ ควรย้าย logic นี้ไปเป็น Postgres function
/// แล้วเรียกผ่าน `_supabase.rpc(...)` แทน
class ProgressService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static String? get _userId => _supabase.auth.currentUser?.id;

  // ตรงกับ threshold ฝั่ง Node.js เดิม (progressController.js) และ
  // AppState._checkBadgesLocal() ฝั่ง Flutter
  static const _xpBadges = [
    {'id': 'first_pass', 'minXp': 40},
    {'id': 'xp50', 'minXp': 50},
    {'id': 'xp100', 'minXp': 100},
    {'id': 'xp200', 'minXp': 200},
  ];

  static Future<void> _awardBadgeIfMissing(String userId, String badgeId) async {
    try {
      await _supabase.from('user_badges').upsert(
        {'user_id': userId, 'badge_id': badgeId},
        onConflict: 'user_id,badge_id',
        ignoreDuplicates: true,
      );
    } catch (e) {
      debugPrint('Error awarding badge $badgeId: $e');
    }
  }

  /// 1. ดึงข้อมูลความคืบหน้า (XP, Streak, Run Count และ Badges ทั้งหมด)
  static Future<Map<String, dynamic>?> getMyProgress() async {
    final userId = _userId;
    if (userId == null) return null;
    try {
      final progress = await _supabase
          .from('user_progress')
          .select('total_xp, streak_days, run_count, last_active_date')
          .eq('user_id', userId)
          .maybeSingle();
      if (progress == null) return null;

      final badgesRows = await _supabase
          .from('user_badges')
          .select('earned_at, badges(id, title, description, icon_name)')
          .eq('user_id', userId)
          .order('earned_at');

      final badges = (badgesRows as List)
          .map((row) {
            final b = row['badges'] as Map<String, dynamic>?;
            if (b == null) return null;
            return {...b, 'earned_at': row['earned_at']};
          })
          .whereType<Map<String, dynamic>>()
          .toList();

      return {...progress, 'badges': badges};
    } catch (e) {
      debugPrint('Error fetching progress: $e');
      return null;
    }
  }

  /// 2. เพิ่ม XP (คำนวณ streak multiplier + แจก badge เหมือน backend เดิม)
  static Future<Map<String, dynamic>?> addXp(int amount) async {
    final userId = _userId;
    if (userId == null || amount <= 0) return null;
    try {
      final current = await _supabase
          .from('user_progress')
          .select('total_xp, streak_days, run_count')
          .eq('user_id', userId)
          .maybeSingle();
      if (current == null) return null;

      final streakDays = (current['streak_days'] ?? 0) as int;
      final multiplier = streakDays >= 7 ? 3 : (streakDays >= 3 ? 2 : 1);
      final gained = amount * multiplier;
      final newTotalXp = (current['total_xp'] as int) + gained;

      final updated = await _supabase
          .from('user_progress')
          .update({'total_xp': newTotalXp, 'updated_at': DateTime.now().toIso8601String()})
          .eq('user_id', userId)
          .select('total_xp, streak_days, run_count')
          .single();

      for (final badge in _xpBadges) {
        if (newTotalXp >= (badge['minXp'] as int)) {
          await _awardBadgeIfMissing(userId, badge['id'] as String);
        }
      }

      return {'gained': gained, ...updated};
    } catch (e) {
      debugPrint('Error adding XP: $e');
      return null;
    }
  }

  /// 3. เพิ่มจำนวนครั้งที่รันโค้ด (เรียกใช้เมื่อกดรันโค้ดใน Sandbox)
  static Future<Map<String, dynamic>?> incrementRunCount() async {
    final userId = _userId;
    if (userId == null) return null;
    try {
      final current = await _supabase
          .from('user_progress')
          .select('run_count')
          .eq('user_id', userId)
          .maybeSingle();
      if (current == null) return null;

      final newRunCount = (current['run_count'] as int) + 1;
      final updated = await _supabase
          .from('user_progress')
          .update({'run_count': newRunCount, 'updated_at': DateTime.now().toIso8601String()})
          .eq('user_id', userId)
          .select('run_count')
          .single();

      if (newRunCount >= 1) await _awardBadgeIfMissing(userId, 'first_run');
      if (newRunCount >= 10) await _awardBadgeIfMissing(userId, 'coder');

      return updated;
    } catch (e) {
      debugPrint('Error incrementing run count: $e');
      return null;
    }
  }
}

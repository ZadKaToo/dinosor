import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_guide.dart';

/// ย้ายจาก backend Node.js (127.0.0.1:3000/api/guides) มาคุยกับ Supabase โดยตรง
/// อ้างอิงตาราง public.user_guides
class GuideService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// 1. ดึงรายการบทความทั้งหมด หรือดึงตามหมวดหมู่
  Future<List<UserGuide>> listGuides({String? category}) async {
    try {
      var query = _supabase.from('user_guides').select('*');
      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }
      final result = await query.order('created_at', ascending: false);
      return (result as List)
          .map((row) => UserGuide.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching guides: $e');
      return [];
    }
  }

  /// 2. ดึงรายละเอียดบทความ 1 เรื่อง พร้อม +1 views_count อัตโนมัติ
  Future<UserGuide> getGuide(int id) async {
    // +1 views_count ก่อน แล้วค่อยอ่านค่าล่าสุดกลับมา (เทียบเท่าพฤติกรรมเดิมของ backend)
    try {
      final current = await _supabase
          .from('user_guides')
          .select('views_count')
          .eq('id', id)
          .maybeSingle();
      if (current != null) {
        final newViews = ((current['views_count'] ?? 0) as int) + 1;
        await _supabase.from('user_guides').update({'views_count': newViews}).eq('id', id);
      }
    } catch (e) {
      debugPrint('Error incrementing guide views: $e');
    }

    final row = await _supabase.from('user_guides').select('*').eq('id', id).single();
    return UserGuide.fromJson(row);
  }
}

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ย้ายจาก backend Node.js (127.0.0.1:3000/api/jobs) มาคุยกับ Supabase โดยตรง
class JobService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// 1. ดึงรายการงานทั้งหมด (สามารถส่ง category หรือ experience ไปกรองได้)
  static Future<List<dynamic>> getJobs({String? category, String? experience}) async {
    try {
      var query = _supabase.from('jobs').select('*');
      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }
      if (experience != null && experience.isNotEmpty) {
        query = query.eq('experience', experience);
      }
      final result = await query.order('created_at', ascending: false);
      return result;
    } catch (e) {
      debugPrint('Error fetching jobs: $e');
      return [];
    }
  }

  /// 2. ดึงรายละเอียดงานพร้อม Required Skills
  static Future<Map<String, dynamic>?> getJobDetail(String id) async {
    try {
      final job = await _supabase.from('jobs').select('*').eq('id', id).maybeSingle();
      if (job == null) return null;

      final skillLinks = await _supabase
          .from('job_skills')
          .select('skills_tags(id, name, category)')
          .eq('job_id', id);

      final requiredSkills = (skillLinks as List)
          .map((row) => row['skills_tags'])
          .whereType<Map<String, dynamic>>()
          .toList();

      return {...job, 'required_skills': requiredSkills};
    } catch (e) {
      debugPrint('Error fetching job detail: $e');
      return null;
    }
  }
}

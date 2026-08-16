import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../widgets/google_fonts_shim.dart';
import '../widgets/app_toast.dart';

class ITTracksScreen extends StatelessWidget {
  const ITTracksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      backgroundColor: state.bgColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('เลือกสายงาน IT (Specialization Tracks)',
                style: GoogleFonts.prompt(color: state.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('แตะเพื่อเลือกสายงานที่คุณสนใจ ระบบจะจดจำสายงานที่เลือกไว้',
                style: GoogleFonts.prompt(color: const Color(0xFF64748B), fontSize: 12)),
            const SizedBox(height: 16),
            _buildTrackCard(context, state, 'swe', 'Software & Web Development', 'Frontend / Backend / Full-Stack',
                'พัฒนาแอปพลิเคชัน เว็บไซต์ และซอฟต์แวร์ระบบ', Icons.code, Colors.blue,
                ['Python', 'Node.js', 'React', 'SQL']),
            _buildTrackCard(context, state, 'data', 'Data & AI Engineering', 'Data Science / ML / Data Analyst',
                'วิเคราะห์ข้อมูล และสร้างแบบจำลอง AI Machine Learning', Icons.psychology, Colors.purple,
                ['Python', 'Pandas', 'SQL', 'PowerBI']),
            _buildTrackCard(context, state, 'devops', 'Cloud & DevOps', 'Cloud Engineer / SysAdmin / CI/CD',
                'ดูแลโครงสร้างพื้นฐานคลาวด์ และระบบอัตโนมัติ', Icons.cloud, const Color(0xFF10B981),
                ['AWS/GCP', 'Docker', 'Linux', 'Terraform']),
            _buildTrackCard(context, state, 'sec', 'Cybersecurity', 'SOC Analyst / Security / Pentester',
                'คุ้มครองและป้องกันระบบสารสนเทศ ตรวจจับช่องโหว่', Icons.security, const Color(0xFFF43F5E),
                ['Network', 'Linux', 'SIEM', 'Wireshark']),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackCard(
      BuildContext context,
      AppState state,
      String id,
      String title,
      String subtitle,
      String desc,
      IconData icon,
      Color color,
      List<String> tags) {
    final active = state.selectedTrack == id;
    return InkWell(
      onTap: () {
        context.read<AppState>().selectTrack(id);
        showAppToast(context, 'เปลี่ยนเป็นสายงาน: $title', type: ToastType.info);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF10B981).withValues(alpha:0.08) : state.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: active ? const Color(0xFF10B981) : state.borderColor,
              width: active ? 1.5 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(backgroundColor: color.withValues(alpha:0.2), radius: 24, child: Icon(icon, color: color)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                              child: Text(title,
                                  style: GoogleFonts.prompt(color: state.textPrimary, fontSize: 15, fontWeight: FontWeight.bold))),
                          if (active)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFF065F46), borderRadius: BorderRadius.circular(6)),
                                child: Text('เลือกอยู่',
                                    style: GoogleFonts.prompt(color: const Color(0xFF34D399), fontSize: 9, fontWeight: FontWeight.bold)),
                              ),
                            ),
                        ],
                      ),
                      Text(subtitle, style: GoogleFonts.jetBrainsMono(color: color, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(desc, style: GoogleFonts.prompt(color: const Color(0xFF64748B), fontSize: 12)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tags
                  .map((t) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: state.cardAltColor, borderRadius: BorderRadius.circular(6)),
                child: Text(t, style: GoogleFonts.jetBrainsMono(color: state.textSecondary, fontSize: 10)),
              ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
